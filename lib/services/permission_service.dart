import 'package:permission_handler/permission_handler.dart';

import 'notification_service.dart';

/// Snapshot of everything permission-shaped the settings screen reports on.
class PermissionOverview {
  const PermissionOverview({
    required this.notificationsGranted,
    required this.exactAlarmsGranted,
    required this.batteryUnrestricted,
  });

  final bool notificationsGranted;
  final bool exactAlarmsGranted;
  final bool batteryUnrestricted;
}

/// Orchestrates the permission dance around reminders. Every request degrades
/// gracefully: reminders fall back to inexact scheduling, the persistent
/// notification simply stays invisible until POST_NOTIFICATIONS is granted.
class PermissionService {
  const PermissionService(this._notifications);

  final NotificationService _notifications;

  Future<PermissionOverview> overview() async => PermissionOverview(
        notificationsGranted: await _notifications.areNotificationsEnabled(),
        exactAlarmsGranted: await _notifications.canScheduleExactAlarms(),
        batteryUnrestricted:
            await Permission.ignoreBatteryOptimizations.isGranted,
      );

  Future<bool> requestNotifications() =>
      _notifications.requestNotificationsPermission();

  Future<bool> requestExactAlarms() =>
      _notifications.requestExactAlarmsPermission();

  Future<bool> requestFullScreenIntent() =>
      _notifications.requestFullScreenIntentPermission();

  /// Doze/battery optimization can delay even "exact while idle" alarms on
  /// aggressive OEM builds (Samsung in particular). This fires the system
  /// dialog asking to exempt the app (REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).
  Future<bool> requestIgnoreBatteryOptimizations() async {
    final status = await Permission.ignoreBatteryOptimizations.request();
    return status.isGranted;
  }
}
