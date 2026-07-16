import 'package:flutter/services.dart';

import '../core/app_constants.dart';

/// Starts/stops the Kotlin foreground service that owns the persistent
/// checkable notification. The channel is registered in `MainActivity`, so
/// this is only callable from the UI isolate — which is fine: the toggle
/// lives on the settings screen, and boot restarts are handled natively by
/// `BootReceiver`.
class PersistentNotificationController {
  const PersistentNotificationController();

  static const _channel = MethodChannel(NativeChannel.name);

  Future<void> setEnabled(bool enabled) async {
    try {
      await _channel.invokeMethod<void>(
        enabled
            ? NativeChannel.startPersistentNotification
            : NativeChannel.stopPersistentNotification,
      );
    } on MissingPluginException {
      // No MainActivity in this engine (e.g. tests) — nothing to control.
    }
  }
}
