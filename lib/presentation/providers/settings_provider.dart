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
  });

  final ThemeMode themeMode;
  final FirstDayOfWeek firstDayOfWeek;
  final bool persistentNotificationEnabled;

  AppSettings copyWith({
    ThemeMode? themeMode,
    FirstDayOfWeek? firstDayOfWeek,
    bool? persistentNotificationEnabled,
  }) =>
      AppSettings(
        themeMode: themeMode ?? this.themeMode,
        firstDayOfWeek: firstDayOfWeek ?? this.firstDayOfWeek,
        persistentNotificationEnabled:
            persistentNotificationEnabled ?? this.persistentNotificationEnabled,
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
