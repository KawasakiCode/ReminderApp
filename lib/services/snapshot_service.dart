import 'dart:convert';

import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';

import '../core/app_constants.dart';
import '../core/day_key.dart';
import '../domain/repositories/todo_repository.dart';

/// The Dart half of the native bridge.
///
/// Native surfaces (home-screen widget, persistent notification) never read
/// SQLite. Instead, after **every** database mutation this service writes a
/// denormalized JSON snapshot of *today's* todos into the `home_widget`
/// SharedPreferences store and pokes the widget. The Kotlin side
/// (`TodaySnapshot.kt`) parses the same schema:
///
/// ```json
/// {
///   "dayKey": 20650,              // epoch-day this snapshot describes
///   "dateLabel": "Wed, Jul 16",
///   "todos": [
///     { "id": 1, "title": "Buy milk", "time": "9:30 AM",
///       "allDay": false, "done": false, "color": 4280391411 }
///   ]
/// }
/// ```
///
/// `dayKey` lets native code detect a stale snapshot after midnight (it then
/// renders an empty state instead of yesterday's list until the midnight
/// Workmanager task rewrites it).
///
/// The foreground service registers an `OnSharedPreferenceChangeListener` on
/// this store, so saving the snapshot automatically refreshes the persistent
/// notification too — no explicit ping required.
class SnapshotService {
  const SnapshotService._();

  static Future<void> refresh(TodoRepository repository) async {
    final dayKey = todayKey();
    final todos = await repository.getDay(dayKey);

    final snapshot = <String, Object?>{
      'dayKey': dayKey,
      'dateLabel': DateFormat('EEE, MMM d').format(dateOfDayKey(dayKey)),
      'todos': [
        for (final todo in todos)
          {
            'id': todo.id,
            'title': todo.title,
            'time': todo.isAllDay || todo.startMinutes == null
                ? null
                : timeLabelOfMinutes(todo.startMinutes!),
            'allDay': todo.isAllDay,
            'done': todo.isDone,
            'color': todo.colorTag,
          },
      ],
    };

    await HomeWidget.saveWidgetData<String>(
      WidgetPrefsKeys.todaySnapshot,
      jsonEncode(snapshot),
    );
    await HomeWidget.updateWidget(
      qualifiedAndroidName: WidgetInfo.qualifiedAndroidName,
    );
  }
}
