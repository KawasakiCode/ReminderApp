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
/// internal PageView's physics, for two reasons:
///  * PageScrollPhysics needs a half-screen drag (or a hard fling) to commit
///    a page — unresponsive on a calendar. We commit at 15% / a light fling.
///  * We still want the page to *follow the finger* (drag halfway → half of
///    the next month visible), so drag updates are fed straight into the
///    PageController's scroll position ([TableCalendar.onCalendarCreated]
///    hands us the controller; its own input is disabled via
///    [AvailableGestures.none], which still allows programmatic scrolling).
///    On release the page settles with a short ease-out animation.
class MonthCalendar extends ConsumerStatefulWidget {
  const MonthCalendar({super.key});

  @override
  ConsumerState<MonthCalendar> createState() => _MonthCalendarState();
}

class _MonthCalendarState extends ConsumerState<MonthCalendar> {
  PageController? _pageController;

  /// The page the current drag started on — the reference point for the
  /// commit decision in [_onDragEnd].
  int _dragStartPage = 0;

  /// The month the grid is on. Kept as plain state (NOT a `ref.watch` on
  /// [focusedMonthProvider]): watching would rebuild this widget — and hand
  /// TableCalendar a new focusedDay — *while the page animation is still
  /// running*, which visibly stutters the swipe. The provider is only
  /// written (for the header) and listened to for external jumps
  /// (the "Today" button).
  late DateTime _focusedDay;

  /// Commit the month change once 15% of the page width has been dragged…
  static const double _commitFraction = 0.15;

  /// …or on a light fling, whichever comes first.
  static const double _velocityThreshold = 250; // logical px/s

  static const _settleDuration = Duration(milliseconds: 220);
  static const _settleCurve = Curves.easeOutCubic;

  /// TableCalendar's monthly PageView indexes pages as months since
  /// `firstDay` (Jan 2000 here); last page is Dec 2100.
  static int _pageIndexOf(DateTime month) =>
      (month.year - 2000) * 12 + (month.month - 1);

  static final int _maxPageIndex = _pageIndexOf(DateTime(2100, 12));

  @override
  void initState() {
    super.initState();
    _focusedDay = ref.read(focusedMonthProvider);
  }

  void _onDragStart(DragStartDetails details) {
    final controller = _pageController;
    if (controller == null || !controller.hasClients) return;
    _dragStartPage = (controller.page ?? 0).round();
  }

  /// Follow the finger: move the PageView's scroll position 1:1 with the
  /// drag, so half a swipe shows half of the adjacent month.
  void _onDragUpdate(DragUpdateDetails details) {
    final controller = _pageController;
    if (controller == null || !controller.hasClients) return;
    final position = controller.position;
    position.jumpTo(
      (position.pixels - details.delta.dx)
          .clamp(position.minScrollExtent, position.maxScrollExtent),
    );
  }

  void _onDragEnd(DragEndDetails details) {
    final controller = _pageController;
    if (controller == null || !controller.hasClients) return;
    final velocity = details.primaryVelocity ?? 0;
    final moved = (controller.page ?? _dragStartPage.toDouble()) - _dragStartPage;

    int target = _dragStartPage;
    if (velocity <= -_velocityThreshold) {
      target = _dragStartPage + 1; // fling left → next month
    } else if (velocity >= _velocityThreshold) {
      target = _dragStartPage - 1; // fling right → previous month
    } else if (moved >= _commitFraction) {
      target = _dragStartPage + 1;
    } else if (moved <= -_commitFraction) {
      target = _dragStartPage - 1;
    }

    controller.animateToPage(
      target.clamp(0, _maxPageIndex),
      duration: _settleDuration,
      curve: _settleCurve,
    );
  }

  /// Drag interrupted (e.g. a vertical scroll won the gesture arena):
  /// glide back to where the drag started.
  void _onDragCancel() {
    final controller = _pageController;
    if (controller == null || !controller.hasClients) return;
    controller.animateToPage(
      _dragStartPage,
      duration: _settleDuration,
      curve: _settleCurve,
    );
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
      onHorizontalDragStart: _onDragStart,
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      onHorizontalDragCancel: _onDragCancel,
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
