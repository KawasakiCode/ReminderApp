package com.example.reminder_app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.util.Locale

/**
 * Home-screen widget: a resizable card that always shows today's todos.
 *
 * Rendering is classic AppWidget + RemoteViews: the scrollable list is backed
 * by TodoWidgetService's RemoteViewsFactory, which reads the same JSON
 * snapshot Dart maintains (never SQLite — see TodaySnapshot).
 *
 * Update triggers:
 *  * Dart calls HomeWidget.updateWidget after every DB mutation → the system
 *    delivers APPWIDGET_UPDATE → onUpdate below;
 *  * the midnight WorkManager task does the same for the day rollover;
 *  * notifyAppWidgetViewDataChanged forces the factory to re-read the
 *    snapshot even when only row *content* changed.
 */
class TodoWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val snapshot = TodaySnapshot.load(context)
        val fresh = snapshot?.isForToday == true

        // Header always shows the real current date — even while the
        // snapshot is stale right after midnight.
        val dateLabel = if (fresh && snapshot.dateLabel.isNotEmpty()) {
            snapshot.dateLabel
        } else {
            LocalDate.now().format(DateTimeFormatter.ofPattern("EEE, MMM d", Locale.getDefault()))
        }
        val openCount = if (fresh) snapshot.openTodos.size else 0
        val countLabel = when {
            !fresh || snapshot.todos.isEmpty() -> ""
            openCount == 0 -> context.getString(R.string.notif_all_done)
            else -> context.getString(R.string.widget_count, openCount)
        }

        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.todo_widget).apply {
                setTextViewText(R.id.widget_title, dateLabel)
                setTextViewText(R.id.widget_count, countLabel)

                // Header tap opens the app.
                setOnClickPendingIntent(
                    R.id.widget_header,
                    HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
                )

                // Scrollable rows come from the RemoteViewsFactory. The
                // widget id in the data URI keeps adapter connections
                // distinct when multiple instances are placed.
                val adapterIntent = Intent(context, TodoWidgetService::class.java).apply {
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
                    data = Uri.parse(toUri(Intent.URI_INTENT_SCHEME))
                }
                setRemoteAdapter(R.id.widget_list, adapterIntent)
                setEmptyView(R.id.widget_list, R.id.widget_empty)

                // Row taps: template + per-row fill-in (todo id) → receiver.
                setPendingIntentTemplate(
                    R.id.widget_list,
                    TodoActionReceiver.toggleTemplate(context),
                )
            }
            appWidgetManager.updateAppWidget(widgetId, views)
            appWidgetManager.notifyAppWidgetViewDataChanged(widgetId, R.id.widget_list)
        }
    }
}
