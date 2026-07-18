import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import '../../core/app_constants.dart';
import '../../domain/entities/todo_entity.dart';
import '../../domain/repositories/todo_repository.dart';
import '../../services/midnight_refresh.dart';
import '../../services/notification_service.dart';
import '../../services/snapshot_service.dart';
import 'core_providers.dart';
import 'settings_provider.dart';

/// Every write path goes through here so the invariants hold in one place:
/// after any mutation the reminder alarm matches the row, and the native
/// snapshot (widget + persistent notification) is rewritten.
class TodoActions {
  TodoActions(this._ref);

  final Ref _ref;

  TodoRepository get _repository => _ref.read(todoRepositoryProvider);
  NotificationService get _notifications =>
      _ref.read(notificationServiceProvider);

  /// Insert or update, then (re)schedule the reminder. Returns the scheduling
  /// outcome so the UI can tell the user about inexact fallback / alarm cap.
  Future<ReminderScheduleResult> save(TodoEntity draft) async {
    TodoEntity todo;
    if (draft.id == null) {
      todo = await _repository.insert(draft);
      // Persist the stable notification id derived from the row id.
      todo = todo.copyWith(
        notificationId: NotificationService.notificationIdFor(todo.id!),
      );
      await _repository.update(todo);
    } else {
      todo = draft.copyWith(
        notificationId: draft.notificationId ??
            NotificationService.notificationIdFor(draft.id!),
      );
      await _repository.update(todo);
    }

    // scheduleReminder cancels when there is nothing (left) to remind about,
    // so a plain "reminder switched off" edit also cleans up its alarm.
    final result = await _notifications.scheduleReminder(todo);
    await SnapshotService.refresh(_repository);
    return result;
  }

  Future<void> toggleDone(TodoEntity todo) async {
    final id = todo.id;
    if (id == null) return;
    final nowDone = !todo.isDone;
    await _repository.setDone(id, nowDone);

    if (nowDone) {
      await _notifications.cancelReminder(
        todo.notificationId ?? NotificationService.notificationIdFor(id),
      );
    } else {
      // Restores the alarm if the reminder is still in the future.
      await _notifications.scheduleReminder(todo.copyWith(isDone: false));
    }
    await SnapshotService.refresh(_repository);
  }

  Future<void> remove(TodoEntity todo) async {
    final id = todo.id;
    if (id == null) return;
    await _notifications.cancelReminder(
      todo.notificationId ?? NotificationService.notificationIdFor(id),
    );
    await _repository.delete(id);
    await SnapshotService.refresh(_repository);
  }

  /// Run once per app start (idempotent):
  ///  * re-sync all alarms from the DB (covers force-stop wiping alarms),
  ///  * rewrite the snapshot (covers day changes while the app was dead),
  ///  * re-arm the midnight rollover task,
  ///  * make sure the foreground service matches the setting (covers app
  ///    updates, which stop services).
  Future<void> appStartSync() async {
    await _notifications.rescheduleAllPending(_repository);
    await SnapshotService.refresh(_repository);
    await MidnightRefresh.ensureScheduled();

    // Reconcile the persistent-notification state in BOTH directions: the
    // native mirror flag (read by BootReceiver) and the service itself must
    // match the app setting, even if a past crash or kill left them apart.
    final settings = _ref.read(settingsProvider);
    await HomeWidget.saveWidgetData<bool>(
      WidgetPrefsKeys.persistentNotificationEnabled,
      settings.persistentNotificationEnabled,
    );
    await _ref
        .read(persistentNotificationControllerProvider)
        .setEnabled(settings.persistentNotificationEnabled);
  }
}

final todoActionsProvider = Provider<TodoActions>(TodoActions.new);
