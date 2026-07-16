package com.example.reminder_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.net.Uri
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetPlugin

/**
 * Restores app state after a reboot (and after app updates, which also stop
 * services and — on some OEMs — clear alarms):
 *
 *  1. **Reminder alarms** — nothing to do here: flutter_local_notifications
 *     ships its own ScheduledNotificationBootReceiver that re-registers every
 *     scheduled notification from its persisted store (which our Dart layer
 *     keeps in sync with the database on every mutation). The Dart side
 *     additionally re-syncs alarms from the DB on every app start.
 *  2. **Persistent notification** — restart the foreground service if the
 *     user had it enabled. The setting is mirrored into the home_widget
 *     SharedPreferences store precisely so this decision needs no Dart.
 *     BOOT_COMPLETED is an allowed launch path for a specialUse FGS.
 *  3. **Widget/notification data** — the snapshot on disk predates the
 *     reboot and may describe an older day, so ask Dart (background isolate)
 *     to recompute it; that refresh also updates the widget.
 */
class BootReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            "android.intent.action.QUICKBOOT_POWERON", // HTC/older Samsung fast-boot
            -> Unit
            else -> return
        }

        val prefs = HomeWidgetPlugin.getData(context)
        if (prefs.getBoolean(TodaySnapshot.KEY_PERSISTENT_ENABLED, false)) {
            TodoForegroundService.start(context)
        }

        HomeWidgetBackgroundIntent
            .getBroadcast(context, Uri.parse("reminderapp://refresh"))
            .send()
    }
}
