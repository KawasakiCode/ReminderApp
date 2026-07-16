import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'presentation/providers/settings_provider.dart';
import 'presentation/screens/calendar_screen.dart';
import 'presentation/theme.dart';

class ReminderApp extends ConsumerWidget {
  const ReminderApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return MaterialApp(
      title: 'Reminder',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: settings.themeMode,
      home: const CalendarScreen(),
    );
  }
}
