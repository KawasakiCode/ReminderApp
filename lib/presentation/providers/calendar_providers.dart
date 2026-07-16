import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/day_key.dart';
import '../../domain/entities/todo_entity.dart';
import 'core_providers.dart';

/// The day whose todo list is shown under the month grid.
class SelectedDayNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => dateOnly(DateTime.now());

  void select(DateTime day) => state = dateOnly(day);
}

final selectedDayProvider =
    NotifierProvider<SelectedDayNotifier, DateTime>(SelectedDayNotifier.new);

/// The month the grid is currently swiped to (drives the header label).
class FocusedMonthNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => dateOnly(DateTime.now());

  void set(DateTime day) => state = dateOnly(day);
}

final focusedMonthProvider =
    NotifierProvider<FocusedMonthNotifier, DateTime>(FocusedMonthNotifier.new);

/// Reactive todos of one day (keyed by day key) — live from Drift.
final todosForDayProvider =
    StreamProvider.autoDispose.family<List<TodoEntity>, int>(
  (ref, dayKey) => ref.watch(todoRepositoryProvider).watchDay(dayKey),
);

/// Every day that has at least one todo — the calendar indicator dots.
final daysWithTodosProvider = StreamProvider<Set<int>>(
  (ref) => ref.watch(todoRepositoryProvider).watchDaysWithTodos(),
);
