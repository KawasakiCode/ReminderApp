package com.example.reminder_app

import android.app.NotificationManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Standard Flutter activity plus one MethodChannel: the Dart settings toggle
 * starts/stops the persistent-notification foreground service through it.
 * (Dart cannot start an Android service on its own; this is the whole reason
 * the channel exists. Everything else in the native bridge goes through the
 * home_widget plugin.)
 *
 * The lock-screen behavior of reminder full-screen intents comes from the
 * `showWhenLocked` / `turnScreenOn` attributes on this activity in the
 * manifest — no code needed here.
 */
class MainActivity : FlutterActivity() {

    companion object {
        /** Must match NativeChannel.name in lib/core/app_constants.dart. */
        private const val CHANNEL = "com.example.reminder_app/service"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startPersistentNotification" -> {
                        TodoForegroundService.start(this)
                        result.success(null)
                    }
                    "stopPersistentNotification" -> {
                        TodoForegroundService.stop(this)
                        result.success(null)
                    }
                    // Below Android 14 the appop doesn't exist: holding
                    // USE_FULL_SCREEN_INTENT in the manifest is sufficient.
                    "canUseFullScreenIntent" -> {
                        result.success(
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                                getSystemService(NotificationManager::class.java)
                                    .canUseFullScreenIntent()
                            } else {
                                true
                            }
                        )
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
