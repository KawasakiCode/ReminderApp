import 'package:permission_handler/permission_handler.dart';

import 'notification_service.dart';
import 'persistent_notification_controller.dart';

/// Snapshot of everything permission-shaped the settings screen reports on.
class PermissionOverview {
  const PermissionOverview({
    required this.notificationsGranted,
    required this.exactAlarmsGranted,
    required this.fullScreenGranted,
    required this.batteryUnrestricted,
  });

  final bool notificationsGranted;
  final bool exactAlarmsGranted;
  final bool fullScreenGranted;
  final bool batteryUnrestricted;
}

/// Orchestrates the permission dance around reminders. Every request degrades
/// gracefully: reminders fall back to inexact scheduling, the persistent
/// notification simply stays invisible until POST_NOTIFICATIONS is granted.
class PermissionService {
  const PermissionService(this._notifications, this._native);

  final NotificationService _notifications;
  final PersistentNotificationController _native;

  Future<PermissionOverview> overview() async => PermissionOverview(
        notificationsGranted: await _notifications.areNotificationsEnabled(),
        exactAlarmsGranted: await _notifications.canScheduleExactAlarms(),
        fullScreenGranted: await _native.canUseFullScreenIntent(),
        batteryUnrestricted:
            await Permission.ignoreBatteryOptimizations.isGranted,
      );

  Future<bool> requestNotifications() =>
      _notifications.requestNotificationsPermission();

  Future<bool> requestExactAlarms() =>
      _notifications.requestExactAlarmsPermission();

  /// Only reachable on Android 14+, where the appop can be revoked — the
  /// settings row shows "granted" everywhere else. Deep-links to the system
  /// "Full screen notifications" screen.
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
