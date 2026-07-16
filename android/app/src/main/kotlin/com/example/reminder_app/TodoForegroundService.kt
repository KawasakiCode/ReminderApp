package com.example.reminder_app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.content.pm.ServiceInfo
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.view.View
import android.widget.RemoteViews
import androidx.core.app.NotificationCompat
import androidx.core.app.ServiceCompat
import androidx.core.content.ContextCompat
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import java.time.Duration
import java.time.LocalDateTime

/**
 * Foreground service backing the persistent ("ongoing") notification that
 * lists today's incomplete todos as a checkable list.
 *
 * ## Why the rows are built with RemoteViews.addView, not a RemoteViewsFactory
 * RemoteViews collections (`setRemoteAdapter` + RemoteViewsService) can only
 * be inflated by an *app-widget host*. SystemUI's notification inflater never
 * binds a RemoteViewsService, so a ListView inside a notification renders
 * permanently empty. A notification's expanded custom view is also hard-capped
 * (~256dp) and cannot scroll, so an adapter would buy nothing anyway. The
 * correct pattern — used here — is a custom collapsed + expanded RemoteViews
 * where each visible row is `addView`-ed dynamically, capped at [MAX_ROWS]
 * with a "+N more" footer. (The RemoteViewsFactory lives where the platform
 * supports it: the home-screen widget, see TodoWidgetService.)
 *
 * ## Data flow
 * The service renders ONLY the JSON snapshot maintained by Dart (see
 * TodaySnapshot). It registers an OnSharedPreferenceChangeListener on the
 * home_widget store, so every snapshot rewrite — regardless of which isolate
 * or surface caused it — refreshes the notification automatically. Check-taps
 * on rows go through TodoActionReceiver → Dart → snapshot rewrite → listener.
 *
 * ## Lifecycle
 * Started/stopped by the Settings toggle (MethodChannel in MainActivity) and
 * restarted after reboot by BootReceiver when the setting is on. START_STICKY
 * brings it back if the system kills it. At midnight it re-renders and asks
 * Dart for a fresh snapshot so the list rolls over to the new day.
 *
 * Note: since Android 14 users can swipe away even ongoing FGS notifications;
 * the service keeps running and the notification reappears on the next
 * snapshot change (documented in the README).
 */
class TodoForegroundService : Service() {

    companion object {
        private const val CHANNEL_ID = "persistent_todos"
        private const val NOTIFICATION_ID = 1000

        private const val ACTION_START = "com.example.reminder_app.action.SERVICE_START"
        private const val ACTION_STOP = "com.example.reminder_app.action.SERVICE_STOP"

        /** Rows the fixed-height expanded notification can show. */
        private const val MAX_ROWS = 6

        fun start(context: Context) {
            ContextCompat.startForegroundService(
                context,
                Intent(context, TodoForegroundService::class.java).setAction(ACTION_START),
            )
        }

        fun stop(context: Context) {
            // Delivered to the running instance; it stops itself.
            context.startService(
                Intent(context, TodoForegroundService::class.java).setAction(ACTION_STOP),
            )
        }
    }

    private lateinit var prefs: SharedPreferences
    private val handler = Handler(Looper.getMainLooper())

    // Must stay a field: SharedPreferences keeps listeners in a WeakHashMap.
    private val prefsListener =
        SharedPreferences.OnSharedPreferenceChangeListener { _, key ->
            if (key == TodaySnapshot.KEY_SNAPSHOT) postNotification()
        }

    private val midnightTick = object : Runnable {
        override fun run() {
            // Render the new-day state immediately (the dayKey check makes
            // yesterday's snapshot count as empty) and ask Dart to rebuild
            // the snapshot for the new day.
            postNotification()
            requestDartRefresh()
            scheduleMidnightTick()
        }
    }

    override fun onCreate() {
        super.onCreate()
        createChannel()
        prefs = HomeWidgetPlugin.getData(this)
        prefs.registerOnSharedPreferenceChangeListener(prefsListener)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            ServiceCompat.stopForeground(this, ServiceCompat.STOP_FOREGROUND_REMOVE)
            stopSelf()
            return START_NOT_STICKY
        }
        // ACTION_START, sticky restart (null intent) and boot all land here.
        startAsForeground()
        scheduleMidnightTick()
        return START_STICKY
    }

    override fun onDestroy() {
        prefs.unregisterOnSharedPreferenceChangeListener(prefsListener)
        handler.removeCallbacksAndMessages(null)
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    // ------------------------------------------------------------------
    // Notification plumbing
    // ------------------------------------------------------------------

    private fun createChannel() {
        // IMPORTANCE_LOW: visible in the status bar and shade, but silent —
        // this list must never beep or buzz.
        val channel = NotificationChannel(
            CHANNEL_ID,
            getString(R.string.notif_channel_name),
            NotificationManager.IMPORTANCE_LOW,
        ).apply {
            description = getString(R.string.notif_channel_description)
            setShowBadge(false)
        }
        getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
    }

    private fun startAsForeground() {
        val notification = buildNotification()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            // Android 14+ requires the FGS type at startForeground time; it
            // must match the manifest declaration (specialUse).
            ServiceCompat.startForeground(
                this,
                NOTIFICATION_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE,
            )
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
    }

    private fun postNotification() {
        getSystemService(NotificationManager::class.java)
            .notify(NOTIFICATION_ID, buildNotification())
    }

    private fun buildNotification(): Notification {
        val snapshot = TodaySnapshot.load(this)
        // Stale (pre-midnight) snapshots must not resurface yesterday's list.
        val open = if (snapshot?.isForToday == true) snapshot.openTodos else emptyList()

        val collapsed = RemoteViews(packageName, R.layout.notif_collapsed).apply {
            setTextViewText(R.id.notif_title, getString(R.string.notif_today_title))
            setTextViewText(R.id.notif_summary, summaryText(open.size))
        }

        val expanded = RemoteViews(packageName, R.layout.notif_expanded).apply {
            setTextViewText(R.id.notif_expanded_title, getString(R.string.notif_today_title))
            removeAllViews(R.id.notif_container)
            if (open.isEmpty()) {
                setViewVisibility(R.id.notif_empty, View.VISIBLE)
                setViewVisibility(R.id.notif_more, View.GONE)
            } else {
                setViewVisibility(R.id.notif_empty, View.GONE)
                for (todo in open.take(MAX_ROWS)) {
                    addView(R.id.notif_container, buildRow(todo))
                }
                val overflow = open.size - MAX_ROWS
                if (overflow > 0) {
                    setViewVisibility(R.id.notif_more, View.VISIBLE)
                    setTextViewText(R.id.notif_more, getString(R.string.notif_more, overflow))
                } else {
                    setViewVisibility(R.id.notif_more, View.GONE)
                }
            }
        }

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_stat_reminder)
            // DecoratedCustomViewStyle keeps the standard header (app icon,
            // name) around the custom rows — required for consistent
            // rendering across OEM skins.
            .setStyle(NotificationCompat.DecoratedCustomViewStyle())
            .setCustomContentView(collapsed)
            .setCustomBigContentView(expanded)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setShowWhen(false)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setForegroundServiceBehavior(NotificationCompat.FOREGROUND_SERVICE_IMMEDIATE)
            .setContentIntent(HomeWidgetLaunchIntent.getActivity(this, MainActivity::class.java))
            .build()
    }

    private fun buildRow(todo: SnapshotTodo): RemoteViews =
        RemoteViews(packageName, R.layout.notif_item).apply {
            setTextViewText(R.id.notif_item_title, todo.title)
            setTextViewText(
                R.id.notif_item_time,
                todo.time ?: getString(R.string.all_day),
            )
            setInt(
                R.id.notif_item_color,
                "setBackgroundColor",
                todo.color ?: ContextCompat.getColor(this@TodoForegroundService, R.color.accent),
            )
            // The check control marks the todo done (handled in Dart); the
            // row then disappears when the rewritten snapshot arrives.
            setOnClickPendingIntent(
                R.id.notif_item_check,
                TodoActionReceiver.togglePendingIntent(this@TodoForegroundService, todo.id),
            )
        }

    private fun summaryText(openCount: Int): String = when (openCount) {
        0 -> getString(R.string.notif_all_done)
        1 -> getString(R.string.notif_one_left)
        else -> getString(R.string.notif_n_left, openCount)
    }

    // ------------------------------------------------------------------
    // Midnight rollover
    // ------------------------------------------------------------------

    private fun scheduleMidnightTick() {
        handler.removeCallbacks(midnightTick)
        val now = LocalDateTime.now()
        val nextMidnight = now.toLocalDate().plusDays(1).atStartOfDay()
        // +2s of slack so LocalDate.now() has definitely rolled over.
        handler.postDelayed(midnightTick, Duration.between(now, nextMidnight).toMillis() + 2000)
    }

    private fun requestDartRefresh() {
        // Same background path the check-taps use; Dart recomputes today's
        // snapshot from the database and rewrites it.
        HomeWidgetBackgroundIntent
            .getBroadcast(this, Uri.parse("reminderapp://refresh"))
            .send()
    }
}
