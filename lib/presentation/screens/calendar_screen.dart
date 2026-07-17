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
import '../widgets/month_jump_dialog.dart';
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

class _CalendarScreenState extends ConsumerState<CalendarScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onFirstFrame());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Background isolates (widget/notification check-offs) write through
    // their own DB connection, invisible to this isolate's streams — re-run
    // them whenever the user comes back to the app.
    if (state == AppLifecycleState.resumed) {
      ref.read(todoRepositoryProvider).invalidateStreams();
    }
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

    // Alarms/snapshot/midnight-task/service re-sync — idempotent. A failure
    // here must not block the rest of startup (launch payload, permissions).
    try {
      await ref.read(todoActionsProvider).appStartSync();
    } catch (error) {
      debugPrint('appStartSync failed: $error');
    }

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
                    // Tapping the title jumps straight to any month/year —
                    // no swiping through months in between.
                    child: InkWell(
                      onTap: () => showMonthJump(context, ref),
                      borderRadius: BorderRadius.circular(12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              DateFormat('MMMM yyyy').format(focusedMonth),
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_drop_down,
                            color: scheme.onSurfaceVariant,
                          ),
                        ],
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
