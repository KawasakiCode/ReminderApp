/// Top-level `@pragma('vm:entry-point')` functions executed in **background
/// isolates** — the app UI may not be running when any of these fire. Each
/// entry point connects to the shared drift database (see
/// `AppDatabase.open()`), mutates it, and rewrites the native snapshot so the
/// widget and the persistent notification stay consistent.
library;

import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';

import '../core/app_constants.dart';
import '../data/db/app_database.dart';
import '../data/repositories/drift_todo_repository.dart';
import '../domain/repositories/todo_repository.dart';
import '../services/midnight_refresh.dart';
import '../services/notification_service.dart';
import '../services/snapshot_service.dart';

/// home_widget interactivity callback.
///
/// Reached whenever native code fires a `HomeWidgetBackgroundIntent`:
///  * a row tap on the home-screen widget (via TodoActionReceiver),
///  * a check tap on the persistent notification (same receiver),
///  * BootReceiver / the foreground service asking for a snapshot refresh.
@pragma('vm:entry-point')
Future<void> homeWidgetBackgroundCallback(Uri? uri) async {
  if (uri == null || uri.scheme != BackgroundUris.scheme) return;
  _ensureBackgroundIsolateReady();

  final repository = DriftTodoRepository(AppDatabase.open());

  switch (uri.host) {
    case BackgroundUris.hostToggle:
      final id = int.tryParse(uri.queryParameters['id'] ?? '');
      if (id != null) await _toggleDone(repository, id);
    case BackgroundUris.hostRefresh:
      break; // The unconditional snapshot refresh below is the whole job.
  }

  await SnapshotService.refresh(repository);
}

Future<void> _toggleDone(TodoRepository repository, int id) async {
  final todo = await repository.getById(id);
  if (todo == null) return; // Stale row (deleted meanwhile) — ignore.

  final nowDone = !todo.isDone;
  await repository.setDone(id, nowDone);

  // Keep the alarm consistent with the new state: a completed todo must not
  // still ring; un-completing restores a still-future reminder.
  final notifications = NotificationService.instance;
  if (nowDone) {
    await notifications.cancelReminder(
      todo.notificationId ?? NotificationService.notificationIdFor(id),
    );
  } else if (todo.reminderEnabled &&
      (todo.reminderDateTime?.isAfter(DateTime.now()) ?? false)) {
    await notifications.scheduleReminder(todo.copyWith(isDone: false));
  }
}

/// Plugin channels (shared_preferences via home_widget, path_provider via
/// drift_flutter, notifications) must be registered before use in a
/// background isolate. Idempotent and cheap.
void _ensureBackgroundIsolateReady() {
  WidgetsFlutterBinding.ensureInitialized();
  ui.DartPluginRegistrant.ensureInitialized();
}

/// Workmanager dispatcher — currently a single task: the midnight rollover.
@pragma('vm:entry-point')
void workmanagerDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    _ensureBackgroundIsolateReady();
    switch (taskName) {
      case MidnightTask.taskName:
        final repository = DriftTodoRepository(AppDatabase.open());
        await SnapshotService.refresh(repository);
        await MidnightRefresh.ensureScheduled(); // Re-arm for tomorrow.
    }
    return true;
  });
}

/// flutter_local_notifications background handler: the "Mark as done" action
/// button on a fired reminder. Runs without any UI.
@pragma('vm:entry-point')
Future<void> notificationActionBackground(NotificationResponse response) async {
  if (response.actionId != NotificationIds.actionMarkDone) return;
  final payload = ReminderPayload.decode(response.payload);
  if (payload == null) return;
  _ensureBackgroundIsolateReady();

  final repository = DriftTodoRepository(AppDatabase.open());
  await repository.setDone(payload.todoId, true);
  await SnapshotService.refresh(repository);
}
