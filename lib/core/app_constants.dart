/// Constants shared between Dart and the native (Kotlin) side.
///
/// The Kotlin counterparts live in
/// `android/app/src/main/kotlin/com/example/reminder_app/` — if you change a
/// key or an action name here, change it there too. They are duplicated on
/// purpose: the native side must be able to read the snapshot without
/// spinning up a Dart isolate.
library;

/// SharedPreferences keys written through `home_widget`
/// (HomeWidget.saveWidgetData). The native widget, the foreground service and
/// the boot receiver read these via `HomeWidgetPlugin.getData(context)`.
abstract final class WidgetPrefsKeys {
  /// JSON snapshot of today's todos (see [SnapshotService] for the schema).
  static const todaySnapshot = 'today_snapshot';

  /// Mirror of the "persistent notification" setting so the native
  /// BootReceiver can decide whether to restart the foreground service
  /// without starting Flutter.
  static const persistentNotificationEnabled = 'persistent_notification_enabled';
}

/// Plain SharedPreferences keys for app settings (Dart-only).
abstract final class SettingsKeys {
  static const themeMode = 'settings_theme_mode';
  static const firstDayOfWeek = 'settings_first_day_of_week';
  static const persistentNotification = 'settings_persistent_notification';
  static const onboardedNotifications = 'settings_onboarded_notifications';

  // Feature flags behind the permission toggles. Turning a feature off does
  // NOT revoke the OS permission (that isn't possible programmatically and
  // is not wanted): the app simply stops using it, so toggling back on needs
  // no new system prompt. Read by NotificationService on every schedule —
  // including from background isolates — hence stored in plain prefs.
  static const remindersEnabled = 'settings_reminders_enabled';
  static const exactAlarmsEnabled = 'settings_exact_alarms_enabled';
  static const fullScreenEnabled = 'settings_full_screen_enabled';
}

/// URIs delivered to the `home_widget` background (interactivity) callback.
/// Sent natively via `HomeWidgetBackgroundIntent.getBroadcast(context, uri)`.
abstract final class BackgroundUris {
  static const scheme = 'reminderapp';

  /// `reminderapp://toggle?id=<todoId>` — flip a todo's done state.
  static const hostToggle = 'toggle';

  /// reminderapp://refresh — recompute today's snapshot (boot, midnight).
  static const hostRefresh = 'refresh';
}

/// MethodChannel used by [PersistentNotificationController] to start/stop the
/// Kotlin foreground service. Registered in MainActivity.
abstract final class NativeChannel {
  static const name = 'com.example.reminder_app/service';
  static const startPersistentNotification = 'startPersistentNotification';
  static const stopPersistentNotification = 'stopPersistentNotification';

  /// True on Android < 14 (granted via the manifest permission alone) or when
  /// the Android 14+ appop has not been revoked.
  static const canUseFullScreenIntent = 'canUseFullScreenIntent';

  /// Opens the system "battery optimization" list — the only way to give the
  /// exemption *back*, since apps cannot re-optimize themselves.
  static const openBatteryOptimizationSettings = 'openBatteryOptimizationSettings';
}

/// Notification identity.
abstract final class NotificationIds {
  /// Reminder notification id = [reminderBase] + todo id. Keeps reminder ids
  /// clear of the foreground-service notification (id 1000, native side).
  static const reminderBase = 100000;

  /// Samsung (and some other OEMs) silently drop alarms once an app has
  /// ~500 scheduled with AlarmManager. Stay well under that: we only schedule
  /// *future* reminders and refuse to schedule beyond this count.
  static const maxScheduledAlarms = 450;

  static const reminderChannelId = 'todo_reminders';
  static const reminderChannelName = 'Todo reminders';
  static const reminderChannelDescription =
      'Exact-time, alarm-style reminders for todos';

  /// Action id of the "Mark as done" button on a reminder notification.
  static const actionMarkDone = 'mark_done';
}

/// Name of the Workmanager task that rolls the snapshot over at midnight.
abstract final class MidnightTask {
  static const uniqueName = 'midnight-rollover';
  static const taskName = 'midnightRollover';
}

/// The widget provider class, for HomeWidget.updateWidget.
abstract final class WidgetInfo {
  static const qualifiedAndroidName = 'com.example.reminder_app.TodoWidgetProvider';
}
