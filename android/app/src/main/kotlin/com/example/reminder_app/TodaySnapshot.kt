package com.example.reminder_app

import android.content.Context
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONException
import org.json.JSONObject
import java.time.LocalDate

/**
 * The native half of the bridge contract.
 *
 * Kotlin NEVER reads the SQLite database — the schema lives in Dart only.
 * Instead, Dart's SnapshotService writes a denormalized JSON snapshot of
 * today's todos into the home_widget SharedPreferences store after every
 * mutation, and this class is the single parser both native surfaces
 * (widget + persistent notification) use.
 *
 * Schema (must match lib/services/snapshot_service.dart):
 * ```json
 * {
 *   "dayKey": 20650,              // epoch-day the snapshot describes
 *   "dateLabel": "Wed, Jul 16",
 *   "todos": [
 *     { "id": 1, "title": "Buy milk", "time": "9:30 AM",
 *       "allDay": false, "done": false, "color": -14536718 }
 *   ]
 * }
 * ```
 */
data class SnapshotTodo(
    val id: Int,
    val title: String,
    val time: String?,
    val allDay: Boolean,
    val done: Boolean,
    /** ARGB color, already in Int range (Dart writes an unsigned 32-bit value). */
    val color: Int?,
)

class TodaySnapshot private constructor(
    val dayKey: Long,
    val dateLabel: String,
    val todos: List<SnapshotTodo>,
) {

    /**
     * Guard against stale data after midnight: Dart re-writes the snapshot at
     * 00:00 via WorkManager, but Doze may delay that by minutes. Until the
     * fresh snapshot lands, renderers must show an empty "new day" state
     * rather than yesterday's list. Dart's dayKey convention is identical to
     * java.time's LocalDate.toEpochDay().
     */
    val isForToday: Boolean
        get() = dayKey == LocalDate.now().toEpochDay()

    val openTodos: List<SnapshotTodo>
        get() = todos.filter { !it.done }

    companion object {
        /** Must match WidgetPrefsKeys.todaySnapshot (Dart). */
        const val KEY_SNAPSHOT = "today_snapshot"

        /** Must match WidgetPrefsKeys.persistentNotificationEnabled (Dart). */
        const val KEY_PERSISTENT_ENABLED = "persistent_notification_enabled"

        /** Returns null when no snapshot exists yet or it cannot be parsed. */
        fun load(context: Context): TodaySnapshot? {
            val raw = HomeWidgetPlugin.getData(context)
                .getString(KEY_SNAPSHOT, null) ?: return null
            return try {
                parse(raw)
            } catch (e: JSONException) {
                null // Corrupt/old snapshot — treat as absent.
            }
        }

        private fun parse(raw: String): TodaySnapshot {
            val root = JSONObject(raw)
            val array = root.getJSONArray("todos")
            val todos = buildList {
                for (i in 0 until array.length()) {
                    val item = array.getJSONObject(i)
                    add(
                        SnapshotTodo(
                            id = item.getInt("id"),
                            title = item.getString("title"),
                            time = if (item.isNull("time")) null else item.getString("time"),
                            allDay = item.optBoolean("allDay", true),
                            done = item.optBoolean("done", false),
                            // Stored unsigned by Dart (e.g. 4281558783); the
                            // narrowing conversion restores the ARGB Int.
                            color = if (item.isNull("color")) null else item.getLong("color").toInt(),
                        )
                    )
                }
            }
            return TodaySnapshot(
                dayKey = root.getLong("dayKey"),
                dateLabel = root.optString("dateLabel", ""),
                todos = todos,
            )
        }
    }
}
