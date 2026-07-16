import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/app_constants.dart';
import '../../core/day_key.dart';
import '../providers/calendar_providers.dart';
import '../providers/core_providers.dart';
import '../providers/todo_actions.dart';
import '../widgets/day_todo_list.dart';
import '../widgets/month_calendar.dart';
import '../widgets/todo_editor_sheet.dart';
import 'reminder_screen.dart';
import 'settings_screen.dart';

/// Home screen: One-UI-style header, swipeable month grid, selected day's
/// todos underneath, FAB to add.
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _onFirstFrame());
  }

  Future<void> _onFirstFrame() async {
    final notifications = ref.read(notificationServiceProvider);

    // Route reminder taps (app alive) to the full-screen reminder view.
    notifications.onReminderOpened = (payload) {
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ReminderScreen(todoId: payload.todoId),
          fullscreenDialog: true,
        ),
      );
    };

    // Alarms/snapshot/midnight-task/service re-sync — idempotent.
    await ref.read(todoActionsProvider).appStartSync();

    // If the process was cold-started by a reminder (incl. the full-screen
    // intent firing on the lock screen), open that reminder now.
    final launchPayload = await notifications.getLaunchPayload();
    if (launchPayload != null) {
      notifications.onReminderOpened?.call(launchPayload);
    }

    // First run: ask for POST_NOTIFICATIONS once (Android 13+). Everything
    // else is requested in context (reminder toggle, settings screen).
    final prefs = ref.read(sharedPreferencesProvider);
    if (!(prefs.getBool(SettingsKeys.onboardedNotifications) ?? false)) {
      await prefs.setBool(SettingsKeys.onboardedNotifications, true);
      await notifications.requestNotificationsPermission();
    }
  }

  @override
  Widget build(BuildContext context) {
    final focusedMonth = ref.watch(focusedMonthProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 8, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      DateFormat('MMMM yyyy').format(focusedMonth),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Go to today',
                    onPressed: () {
                      final today = dateOnly(DateTime.now());
                      ref.read(selectedDayProvider.notifier).select(today);
                      ref.read(focusedMonthProvider.notifier).set(today);
                    },
                    icon: Icon(Icons.today_outlined,
                        color: scheme.onSurfaceVariant),
                  ),
                  IconButton(
                    tooltip: 'Settings',
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const SettingsScreen(),
                      ),
                    ),
                    icon: Icon(Icons.settings_outlined,
                        color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: MonthCalendar(),
            ),
            const SizedBox(height: 2),
            const Divider(indent: 20, endIndent: 20),
            const Expanded(child: DayTodoList()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showTodoEditor(
          context,
          initialDate: ref.read(selectedDayProvider),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}
