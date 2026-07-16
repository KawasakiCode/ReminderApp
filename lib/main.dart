import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import 'app.dart';
import 'background/background_entrypoints.dart';
import 'presentation/providers/core_providers.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Settings must be readable synchronously by the first frame.
  final prefs = await SharedPreferences.getInstance();

  // Notifications: timezone db + channels + tap/action callbacks. The
  // background handler runs "Mark as done" while the app is dead.
  await NotificationService.instance.initForUi(
    onBackgroundAction: notificationActionBackground,
  );

  // Widget/notification check-taps land in this background entry point.
  await HomeWidget.registerInteractivityCallback(homeWidgetBackgroundCallback);

  // Midnight rollover task dispatcher (the task itself is (re)armed in
  // TodoActions.appStartSync).
  await Workmanager().initialize(workmanagerDispatcher);

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const ReminderApp(),
    ),
  );
}
