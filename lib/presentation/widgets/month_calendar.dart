import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/day_key.dart';
import '../providers/calendar_providers.dart';
import '../providers/settings_provider.dart';
import '../theme.dart';

/// Samsung-Calendar-style month grid: swipeable months, today filled with the
/// accent color, selected day outlined, indicator dot under days with todos.
///
/// Month swiping is handled by our own [GestureDetector] instead of the
/// internal PageView: PageScrollPhysics needs a half-screen drag (or a hard
/// fling) to commit a page, which feels unresponsive on a calendar. Here a
/// ~24 px drag or a light fling flips the month via the PageController that
/// [TableCalendar.onCalendarCreated] hands us.
class MonthCalendar extends ConsumerStatefulWidget {
  const MonthCalendar({super.key});

  @override
  ConsumerState<MonthCalendar> createState() => _MonthCalendarState();
}

class _MonthCalendarState extends ConsumerState<MonthCalendar> {
  PageController? _pageController;
  double _dragDx = 0;

  /// The month the grid is on. Kept as plain state (NOT a `ref.watch` on
  /// [focusedMonthProvider]): watching would rebuild this widget — and hand
  /// TableCalendar a new focusedDay — *while the page animation is still
  /// running*, which visibly stutters the swipe. The provider is only
  /// written (for the header) and listened to for external jumps
  /// (the "Today" button).
  late DateTime _focusedDay;

  static const double _distanceThreshold = 24; // logical px
  static const double _velocityThreshold = 200; // logical px/s

  /// TableCalendar's monthly PageView indexes pages as months since
  /// `firstDay` (Jan 2000 here).
  static int _pageIndexOf(DateTime month) =>
      (month.year - 2000) * 12 + (month.month - 1);

  @override
  void initState() {
    super.initState();
    _focusedDay = ref.read(focusedMonthProvider);
  }

  void _onDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (_dragDx <= -_distanceThreshold || velocity <= -_velocityThreshold) {
      _pageController?.nextPage(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    } else if (_dragDx >= _distanceThreshold ||
        velocity >= _velocityThreshold) {
      _pageController?.previousPage(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    }
    _dragDx = 0;
  }

  @override
  Widget build(BuildContext context) {
    final selectedDay = ref.watch(selectedDayProvider);
    final settings = ref.watch(settingsProvider);
    final daysWithTodos = ref.watch(daysWithTodosProvider).value ?? const <int>{};
    final scheme = Theme.of(context).colorScheme;

    // External month changes (the "Today" button) animate the page from
    // here; swipes handled below never re-enter (same month check).
    ref.listen(focusedMonthProvider, (_, next) {
      if (next.year != _focusedDay.year || next.month != _focusedDay.month) {
        _focusedDay = next;
        _pageController?.animateToPage(
          _pageIndexOf(next),
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
        );
      }
    });

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: (_) => _dragDx = 0,
      onHorizontalDragUpdate: (details) => _dragDx += details.delta.dx,
      onHorizontalDragEnd: _onDragEnd,
      child: TableCalendar<int>(
        firstDay: DateTime(2000, 1, 1),
        lastDay: DateTime(2100, 12, 31),
        focusedDay: _focusedDay,
        headerVisible: false, // The screen renders its own One-UI-style header.
        startingDayOfWeek: settings.firstDayOfWeek.startingDayOfWeek,
        selectedDayPredicate: (day) => isSameDay(day, selectedDay),
        onDaySelected: (selected, focused) {
          // Update our page state first so the provider listener above
          // recognizes the month as already-current and doesn't re-animate.
          _focusedDay = focused;
          ref.read(selectedDayProvider.notifier).select(selected);
          ref.read(focusedMonthProvider.notifier).set(focused);
        },
        onPageChanged: (focused) {
          // No setState: the new page already renders itself; only the
          // header (a different widget) needs the provider update.
          _focusedDay = focused;
          ref.read(focusedMonthProvider.notifier).set(focused);
        },
        onCalendarCreated: (controller) => _pageController = controller,
        eventLoader: (day) =>
            daysWithTodos.contains(dayKeyOf(day)) ? const [1] : const [],
        // Gestures are ours (see above); the internal PageView stays put.
        availableGestures: AvailableGestures.none,
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
            if (weekend == null) return null; // default rendering
            return Center(
              child: Text('${day.day}', style: TextStyle(color: weekend)),
            );
          },
        ),
      ),
    );
  }

  Color? _weekdayColor(DateTime day, ColorScheme scheme) => switch (day.weekday) {
        DateTime.sunday => AppTheme.sundayRed,
        DateTime.saturday => AppTheme.saturdayBlue,
        _ => null,
      };
}
