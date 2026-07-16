package com.example.reminder_app

import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.net.Uri
import es.antonborri.home_widget.HomeWidgetBackgroundIntent

/**
 * Single funnel for "the user checked a todo" from BOTH native surfaces:
 *
 *  * widget rows — the ListView's PendingIntent template ([toggleTemplate])
 *    merged with each row's fill-in intent carrying the todo id;
 *  * persistent-notification rows — one explicit [togglePendingIntent] per
 *    visible row.
 *
 * The receiver does not touch data itself. It forwards the action into the
 * Dart background isolate (home_widget's interactivity callback,
 * `homeWidgetBackgroundCallback` in lib/background/background_entrypoints.dart),
 * which owns the database. Dart then rewrites the snapshot, which in turn
 * refreshes the widget and — via the foreground service's preference
 * listener — the notification. One data flow, no native DB access.
 */
class TodoActionReceiver : BroadcastReceiver() {

    companion object {
        const val ACTION_TOGGLE = "com.example.reminder_app.action.TOGGLE_TODO"
        const val EXTRA_TODO_ID = "todo_id"

        /** Per-row intent for notification rows (request code = todo id keeps them distinct). */
        fun togglePendingIntent(context: Context, todoId: Int): PendingIntent =
            PendingIntent.getBroadcast(
                context,
                todoId,
                Intent(context, TodoActionReceiver::class.java)
                    .setAction(ACTION_TOGGLE)
                    .putExtra(EXTRA_TODO_ID, todoId),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )

        /**
         * Template for the widget ListView. MUTABLE is required — the widget
         * host applies each row's fill-in intent (the todo id) onto it;
         * that's the RemoteViewsFactory collection-click contract.
         */
        fun toggleTemplate(context: Context): PendingIntent =
            PendingIntent.getBroadcast(
                context,
                0,
                Intent(context, TodoActionReceiver::class.java).setAction(ACTION_TOGGLE),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE,
            )
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != ACTION_TOGGLE) return
        val todoId = intent.getIntExtra(EXTRA_TODO_ID, -1)
        if (todoId < 0) return

        // Fire-and-forget into Dart. The URI is parsed by
        // homeWidgetBackgroundCallback; scheme/host/param must match
        // BackgroundUris in lib/core/app_constants.dart.
        HomeWidgetBackgroundIntent
            .getBroadcast(context, Uri.parse("reminderapp://toggle?id=$todoId"))
            .send()
    }
}
