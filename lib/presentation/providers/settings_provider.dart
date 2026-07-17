import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/app_constants.dart';
import 'core_providers.dart';

enum FirstDayOfWeek {
  monday(StartingDayOfWeek.monday, 'Monday'),
  saturday(StartingDayOfWeek.saturday, 'Saturday'),
  sunday(StartingDayOfWeek.sunday, 'Sunday');

  const FirstDayOfWeek(this.startingDayOfWeek, this.label);

  final StartingDayOfWeek startingDayOfWeek;
  final String label;
}

@immutable
class AppSettings {
  const AppSettings({
    required this.themeMode,
    required this.firstDayOfWeek,
    required this.persistentNotificationEnabled,
    required this.remindersEnabled,
    required this.exactAlarmsEnabled,
    required this.fullScreenEnabled,
  });

  final ThemeMode themeMode;
  final FirstDayOfWeek firstDayOfWeek;
  final bool persistentNotificationEnabled;

  /// Feature flags behind the permission toggles (see SettingsKeys): the OS
  /// permission stays granted; these only control whether the app USES it.
  final bool remindersEnabled;
  final bool exactAlarmsEnabled;
  final bool fullScreenEnabled;

  AppSettings copyWith({
    ThemeMode? themeMode,
    FirstDayOfWeek? firstDayOfWeek,
    bool? persistentNotificationEnabled,
    bool? remindersEnabled,
    bool? exactAlarmsEnabled,
    bool? fullScreenEnabled,
  }) =>
      AppSettings(
        themeMode: themeMode ?? this.themeMode,
        firstDayOfWeek: firstDayOfWeek ?? this.firstDayOfWeek,
        persistentNotificationEnabled:
            persistentNotificationEnabled ?? this.persistentNotificationEnabled,
        remindersEnabled: remindersEnabled ?? this.remindersEnabled,
        exactAlarmsEnabled: exactAlarmsEnabled ?? this.exactAlarmsEnabled,
        fullScreenEnabled: fullScreenEnabled ?? this.fullScreenEnabled,
      );
}

class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return AppSettings(
      themeMode: _enumFromName(
        ThemeMode.values,
        prefs.getString(SettingsKeys.themeMode),
        ThemeMode.system,
      ),
      firstDayOfWeek: _enumFromName(
        FirstDayOfWeek.values,
        prefs.getString(SettingsKeys.firstDayOfWeek),
        FirstDayOfWeek.monday,
      ),
      persistentNotificationEnabled:
          prefs.getBool(SettingsKeys.persistentNotification) ?? false,
      remindersEnabled: prefs.getBool(SettingsKeys.remindersEnabled) ?? true,
      exactAlarmsEnabled:
          prefs.getBool(SettingsKeys.exactAlarmsEnabled) ?? true,
      fullScreenEnabled: prefs.getBool(SettingsKeys.fullScreenEnabled) ?? true,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await ref
        .read(sharedPreferencesProvider)
        .setString(SettingsKeys.themeMode, mode.name);
  }

  Future<void> setFirstDayOfWeek(FirstDayOfWeek day) async {
    state = state.copyWith(firstDayOfWeek: day);
    await ref
        .read(sharedPreferencesProvider)
        .setString(SettingsKeys.firstDayOfWeek, day.name);
  }

  Future<void> setPersistentNotificationEnabled(bool enabled) async {
    state = state.copyWith(persistentNotificationEnabled: enabled);
    await ref
        .read(sharedPreferencesProvider)
        .setBool(SettingsKeys.persistentNotification, enabled);
    // Mirror into the home_widget store so the native BootReceiver can
    // restart the foreground service after a reboot without starting Dart.
    await HomeWidget.saveWidgetData<bool>(
      WidgetPrefsKeys.persistentNotificationEnabled,
      enabled,
    );
    await ref
        .read(persistentNotificationControllerProvider)
        .setEnabled(enabled);
  }

  /// Reminders on/off. On: makes sure POST_NOTIFICATIONS is granted (the
  /// system prompt only ever appears if it isn't yet) and re-schedules every
  /// pending reminder from the database. Off: cancels the scheduled alarms —
  /// the todos keep their reminder settings, so re-enabling restores them.
  Future<void> setRemindersEnabled(bool enabled) async {
    state = state.copyWith(remindersEnabled: enabled);
    await ref
        .read(sharedPreferencesProvider)
        .setBool(SettingsKeys.remindersEnabled, enabled);
    final notifications = ref.read(notificationServiceProvider);
    if (enabled) {
      await notifications.requestNotificationsPermission();
      await notifications
          .rescheduleAllPending(ref.read(todoRepositoryProvider));
    } else {
      await notifications.cancelAllReminders();
    }
  }

  /// Exact alarms on/off. The permission (if held) is untouched; scheduling
  /// just switches between exact and inexact modes.
  Future<void> setExactAlarmsEnabled(bool enabled) async {
    state = state.copyWith(exactAlarmsEnabled: enabled);
    await ref
        .read(sharedPreferencesProvider)
        .setBool(SettingsKeys.exactAlarmsEnabled, enabled);
    final notifications = ref.read(notificationServiceProvider);
    if (enabled && !await notifications.canScheduleExactAlarms()) {
      await notifications.requestExactAlarmsPermission();
    }
    // Re-register pending alarms so the new mode takes effect immediately.
    if (state.remindersEnabled) {
      await notifications
          .rescheduleAllPending(ref.read(todoRepositoryProvider));
    }
  }

  /// Full-screen reminder wake-up on/off.
  Future<void> setFullScreenEnabled(bool enabled) async {
    state = state.copyWith(fullScreenEnabled: enabled);
    await ref
        .read(sharedPreferencesProvider)
        .setBool(SettingsKeys.fullScreenEnabled, enabled);
    final notifications = ref.read(notificationServiceProvider);
    if (enabled) {
      // No-op below Android 14; opens the system toggle if revoked on 14+.
      await notifications.requestFullScreenIntentPermission();
    }
    if (state.remindersEnabled) {
      await notifications
          .rescheduleAllPending(ref.read(todoRepositoryProvider));
    }
  }

  static T _enumFromName<T extends Enum>(List<T> values, String? name, T fallback) {
    if (name == null) return fallback;
    for (final value in values) {
      if (value.name == name) return value;
    }
    return fallback;
  }
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);
