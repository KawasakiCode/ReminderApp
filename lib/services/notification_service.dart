import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../core/app_constants.dart';
import '../core/day_key.dart';
import '../domain/entities/todo_entity.dart';
import '../domain/repositories/todo_repository.dart';

/// What happened when a reminder was (not) scheduled — the UI turns the
/// non-happy paths into user-visible notices.
enum ReminderScheduleResult {
  /// Exact alarm scheduled (AndroidScheduleMode.exactAllowWhileIdle).
  scheduledExact,

  /// Exact alarms unavailable (SCHEDULE_EXACT_ALARM revoked on Android 12);
  /// fell back to an inexact alarm so the reminder still fires, just not to
  /// the second.
  scheduledInexact,

  /// Nothing to schedule (no reminder, in the past, or todo already done).
  notScheduled,

  /// Refused to schedule: the app already has ~450 pending alarms. Samsung
  /// (and some other OEMs) silently drop alarms past ~500 per app, so we stop
  /// before that cliff. See NotificationIds.maxScheduledAlarms.
  alarmCapReached,

  /// The global "Reminders" toggle in Settings is off — the todo keeps its
  /// reminder configuration, but no alarm was registered.
  remindersDisabled,
}

/// Payload carried inside a reminder notification, so a tap (or the
/// "Mark as done" action) can find the todo again.
class ReminderPayload {
  const ReminderPayload({required this.todoId, required this.dayKey});

  final int todoId;
  final int dayKey;

  String encode() => jsonEncode({'todoId': todoId, 'dayKey': dayKey});

  static ReminderPayload? decode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return ReminderPayload(
        todoId: map['todoId'] as int,
        dayKey: map['dayKey'] as int,
      );
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }
}

/// Wraps flutter_local_notifications. Usable from the UI isolate *and* from
/// short-lived background isolates (widget callbacks, workmanager): the
/// timezone database is initialized lazily per isolate, and every
/// notification passes its own small icon so nothing depends on
/// [initForUi] having run in the current isolate.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _tzReady = false;

  /// Set by the app shell; called when the user taps a reminder notification
  /// while the app is alive.
  void Function(ReminderPayload payload)? onReminderOpened;

  static int notificationIdFor(int todoId) =>
      NotificationIds.reminderBase + todoId;

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  /// Timezone setup, once per isolate. Without a correct local location,
  /// zonedSchedule would fire at the wrong wall-clock time.
  Future<void> _ensureTimezone() async {
    if (_tzReady) return;
    tzdata.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      // Keep the package default. Alarms would be offset, but scheduling
      // still works; this only happens if the platform lookup itself fails.
    }
    _tzReady = true;
  }

  /// Full initialization for the UI isolate: response callbacks + launch
  /// detection. [onBackgroundAction] must be a top-level
  /// `@pragma('vm:entry-point')` function (see background_entrypoints.dart) —
  /// it handles the "Mark as done" action while the app is dead.
  Future<void> initForUi({
    required DidReceiveBackgroundNotificationResponseCallback
        onBackgroundAction,
  }) async {
    await _ensureTimezone();
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_reminder'),
      ),
      onDidReceiveNotificationResponse: _onResponse,
      onDidReceiveBackgroundNotificationResponse: onBackgroundAction,
    );
  }

  void _onResponse(NotificationResponse response) {
    // Action presses are handled in the background callback; this fires for
    // plain taps (notificationResponseType == selectedNotification).
    final payload = ReminderPayload.decode(response.payload);
    if (payload != null &&
        response.notificationResponseType ==
            NotificationResponseType.selectedNotification) {
      onReminderOpened?.call(payload);
    }
  }

  /// If the app process was launched by tapping a reminder (including the
  /// full-screen intent firing on the lock screen), returns its payload.
  Future<ReminderPayload?> getLaunchPayload() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp ?? false) {
      return ReminderPayload.decode(details!.notificationResponse?.payload);
    }
    return null;
  }

  // ---------------------------------------------------------------------
  // Permissions
  // ---------------------------------------------------------------------

  Future<bool> areNotificationsEnabled() async =>
      await _android?.areNotificationsEnabled() ?? false;

  /// Android 13+ POST_NOTIFICATIONS runtime permission.
  Future<bool> requestNotificationsPermission() async =>
      await _android?.requestNotificationsPermission() ?? false;

  /// Whether SCHEDULE_EXACT_ALARM / USE_EXACT_ALARM currently allows exact
  /// alarms. On Android 13+ this is auto-granted through USE_EXACT_ALARM
  /// (calendar/alarm app); on Android 12 the user may need to grant it.
  Future<bool> canScheduleExactAlarms() async =>
      await _android?.canScheduleExactNotifications() ?? false;

  /// Opens the "Alarms & reminders" system screen when needed (Android 12/12L
  /// with SCHEDULE_EXACT_ALARM not yet granted).
  Future<bool> requestExactAlarmsPermission() async =>
      await _android?.requestExactAlarmsPermission() ?? false;

  /// Android 14+ full-screen intent appop. Deep-links to the system setting
  /// if it has been revoked.
  Future<bool> requestFullScreenIntentPermission() async =>
      await _android?.requestFullScreenIntentPermission() ?? false;

  // ---------------------------------------------------------------------
  // Scheduling
  // ---------------------------------------------------------------------

  /// Schedules (or replaces — same notification id) the wake-up reminder for
  /// [todo]. Safe to call unconditionally after any mutation.
  Future<ReminderScheduleResult> scheduleReminder(TodoEntity todo) async {
    final todoId = todo.id;
    if (todoId == null) return ReminderScheduleResult.notScheduled;
    final notificationId = todo.notificationId ?? notificationIdFor(todoId);
    final when = todo.reminderDateTime;

    if (!todo.reminderEnabled ||
        todo.isDone ||
        when == null ||
        !when.isAfter(DateTime.now())) {
      // Only *future* reminders may occupy an alarm slot.
      await cancelReminder(notificationId);
      return ReminderScheduleResult.notScheduled;
    }

    // The Settings feature toggles. Read from prefs (not a provider) because
    // scheduling also happens in background isolates. Turning a feature off
    // never revokes the OS permission — the app just stops using it.
    final prefs = await SharedPreferences.getInstance();
    final remindersEnabled =
        prefs.getBool(SettingsKeys.remindersEnabled) ?? true;
    if (!remindersEnabled) {
      await cancelReminder(notificationId);
      return ReminderScheduleResult.remindersDisabled;
    }
    final exactWanted = prefs.getBool(SettingsKeys.exactAlarmsEnabled) ?? true;
    final fullScreenWanted =
        prefs.getBool(SettingsKeys.fullScreenEnabled) ?? true;

    await _ensureTimezone();

    // Guard the OEM alarm cap (see NotificationIds.maxScheduledAlarms).
    final pending = await _plugin.pendingNotificationRequests();
    final alreadyMine = pending.any((p) => p.id == notificationId);
    if (!alreadyMine && pending.length >= NotificationIds.maxScheduledAlarms) {
      return ReminderScheduleResult.alarmCapReached;
    }

    final exact = exactWanted && await canScheduleExactAlarms();

    await _plugin.zonedSchedule(
      id: notificationId,
      title: todo.title,
      body: _reminderBody(todo),
      scheduledDate: tz.TZDateTime.from(when, tz.local),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          NotificationIds.reminderChannelId,
          NotificationIds.reminderChannelName,
          channelDescription: NotificationIds.reminderChannelDescription,
          // Icon passed explicitly so scheduling also works from background
          // isolates where initialize() (and thus the default icon) never ran.
          icon: 'ic_stat_reminder',
          importance: Importance.max,
          priority: Priority.high,
          category: AndroidNotificationCategory.alarm,
          audioAttributesUsage: AudioAttributesUsage.alarm,
          visibility: NotificationVisibility.public,
          // Samsung-Calendar-style behavior: wake the screen and show over
          // the lock screen. Requires USE_FULL_SCREEN_INTENT (manifest) and,
          // on Android 14+, the un-revoked full-screen-intent appop. The
          // user can also opt out in Settings without touching permissions.
          fullScreenIntent: fullScreenWanted,
          actions: const [
            AndroidNotificationAction(
              NotificationIds.actionMarkDone,
              'Mark as done',
              showsUserInterface: false,
              cancelNotification: true,
            ),
          ],
        ),
      ),
      payload: ReminderPayload(todoId: todoId, dayKey: todo.dayKey).encode(),
      // alarmClock (AlarmManager.setAlarmClock), NOT exactAllowWhileIdle.
      // Verified on a Galaxy A32 (One UI 5): exactAllowWhileIdle alarms are
      // *delivered* by AlarmManager, but Samsung silently drops the receiver
      // broadcast when the app was swiped away / its process is frozen — the
      // notification never appears. alarmClock is the privileged tier used
      // by real alarm clocks: One UI never suppresses its delivery (and the
      // status bar shows an alarm icon, which is appropriate here). Falls
      // back to inexact when exact alarms are unavailable/disabled (the
      // caller surfaces a notice so the user can grant the permission).
      androidScheduleMode: exact
          ? AndroidScheduleMode.alarmClock
          : AndroidScheduleMode.inexactAllowWhileIdle,
    );

    return exact
        ? ReminderScheduleResult.scheduledExact
        : ReminderScheduleResult.scheduledInexact;
  }

  Future<void> cancelReminder(int? notificationId) async {
    if (notificationId == null) return;
    await _plugin.cancel(id: notificationId);
  }

  /// Used by the Settings "Reminders" toggle when switching off. Reminder
  /// notifications are the only ones this plugin instance schedules, so a
  /// blanket cancel is safe (the persistent notification is owned natively
  /// by the foreground service and unaffected).
  Future<void> cancelAllReminders() => _plugin.cancelAll();

  /// Re-registers every future reminder. flutter_local_notifications already
  /// restores its alarms after reboot via its own BOOT_COMPLETED receiver,
  /// but a "Force stop" clears alarms *without* a reboot — so the app also
  /// re-syncs from the database (the source of truth) on every start.
  /// zonedSchedule with an existing id replaces, so this is idempotent.
  Future<void> rescheduleAllPending(TodoRepository repository) async {
    final todos = await repository.getPendingRemindersAfter(DateTime.now());
    todos.sort((a, b) => a.reminderDateTime!.compareTo(b.reminderDateTime!));
    // Soonest first, so if the cap ever bites it drops the farthest-out ones.
    for (final todo in todos.take(NotificationIds.maxScheduledAlarms)) {
      await scheduleReminder(todo);
    }
  }

  String _reminderBody(TodoEntity todo) {
    final time = todo.startMinutes == null
        ? 'All day'
        : timeLabelOfMinutes(todo.startMinutes!);
    final note = todo.note;
    return note == null || note.trim().isEmpty ? time : '$time · ${note.trim()}';
  }
}
