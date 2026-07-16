import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/day_key.dart';
import '../providers/calendar_providers.dart';
import '../providers/settings_provider.dart';
import '../theme.dart';

/// Samsung-Calendar-style month grid: swipeable months, today filled with the
/// accent color, selected day outlined, indicator dot under days with todos.
class MonthCalendar extends ConsumerWidget {
  const MonthCalendar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDay = ref.watch(selectedDayProvider);
    final focusedMonth = ref.watch(focusedMonthProvider);
    final settings = ref.watch(settingsProvider);
    final daysWithTodos = ref.watch(daysWithTodosProvider).value ?? const <int>{};
    final scheme = Theme.of(context).colorScheme;

    return TableCalendar<int>(
      firstDay: DateTime(2000, 1, 1),
      lastDay: DateTime(2100, 12, 31),
      focusedDay: focusedMonth,
      headerVisible: false, // The screen renders its own One-UI-style header.
      startingDayOfWeek: settings.firstDayOfWeek.startingDayOfWeek,
      selectedDayPredicate: (day) => isSameDay(day, selectedDay),
      onDaySelected: (selected, focused) {
        ref.read(selectedDayProvider.notifier).select(selected);
        ref.read(focusedMonthProvider.notifier).set(focused);
      },
      onPageChanged: (focused) =>
          ref.read(focusedMonthProvider.notifier).set(focused),
      eventLoader: (day) =>
          daysWithTodos.contains(dayKeyOf(day)) ? const [1] : const [],
      availableGestures: AvailableGestures.horizontalSwipe,
      sixWeekMonthsEnforced: true,
      rowHeight: 46,
      daysOfWeekHeight: 22,
      calendarStyle: CalendarStyle(
        outsideDaysVisible: true,
        outsideTextStyle:
            TextStyle(color: scheme.onSurface.withValues(alpha: 0.3)),
        todayDecoration: BoxDecoration(
          color: scheme.primary,
          shape: BoxShape.circle,
        ),
        todayTextStyle: TextStyle(
          color: scheme.onPrimary,
          fontWeight: FontWeight.w600,
        ),
        selectedDecoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: scheme.primary, width: 1.6),
        ),
        selectedTextStyle:
            TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w600),
        markersMaxCount: 1,
        markerSize: 5,
        markerMargin: const EdgeInsets.only(top: 1.5),
        markerDecoration: BoxDecoration(
          color: scheme.primary.withValues(alpha: 0.85),
          shape: BoxShape.circle,
        ),
      ),
      calendarBuilders: CalendarBuilders(
        dowBuilder: (context, day) => Center(
          child: Text(
            const ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN']
                [day.weekday - 1],
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: _weekdayColor(day, scheme) ??
                  scheme.onSurfaceVariant.withValues(alpha: 0.8),
            ),
          ),
        ),
        defaultBuilder: (context, day, focusedDay) {
          final weekend = _weekdayColor(day, scheme);
          if (weekend == null) return null; // fall back to default rendering
          return Center(
            child: Text('${day.day}', style: TextStyle(color: weekend)),
          );
        },
      ),
    );
  }

  Color? _weekdayColor(DateTime day, ColorScheme scheme) => switch (day.weekday) {
        DateTime.sunday => AppTheme.sundayRed,
        DateTime.saturday => AppTheme.saturdayBlue,
        _ => null,
      };
}
