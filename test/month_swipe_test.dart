import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/domain/entities/todo_entity.dart';
import 'package:reminder_app/domain/repositories/todo_repository.dart';
import 'package:reminder_app/presentation/providers/calendar_providers.dart';
import 'package:reminder_app/presentation/providers/core_providers.dart';
import 'package:reminder_app/presentation/widgets/month_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// In-memory stand-in so the calendar renders without a database.
class _FakeTodoRepository implements TodoRepository {
  @override
  Stream<List<TodoEntity>> watchDay(int dayKey) => Stream.value(const []);

  @override
  Stream<Set<int>> watchDaysWithTodos() => Stream.value(const <int>{});

  @override
  Future<List<TodoEntity>> getDay(int dayKey) async => const [];

  @override
  Future<TodoEntity?> getById(int id) async => null;

  @override
  Future<TodoEntity> insert(TodoEntity todo) async => todo;

  @override
  Future<void> update(TodoEntity todo) async {}

  @override
  Future<void> delete(int id) async {}

  @override
  Future<void> setDone(int id, bool isDone) async {}

  @override
  Future<List<TodoEntity>> getPendingRemindersAfter(DateTime instant) async =>
      const [];

  @override
  void invalidateStreams() {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> pumpCalendar(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(const {});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        todoRepositoryProvider.overrideWithValue(_FakeTodoRepository()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: MonthCalendar())),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  DateTime monthOf(ProviderContainer container) {
    final focused = container.read(focusedMonthProvider);
    return DateTime(focused.year, focused.month);
  }

  DateTime addMonths(DateTime month, int delta) =>
      DateTime(month.year, month.month + delta);

  PageController pageControllerOf(WidgetTester tester) =>
      tester.widget<PageView>(find.byType(PageView)).controller!;

  group('month swiping', () {
    // Test surface width is 800 -> the 15% commit threshold is 120 px.

    testWidgets('page follows the finger mid-drag', (tester) async {
      await pumpCalendar(tester);
      final controller = pageControllerOf(tester);
      final startPage = controller.page!;

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(MonthCalendar)),
      );
      await gesture.moveBy(const Offset(-200, 0));
      await tester.pump();

      // Mid-drag: 200/800 = a quarter of the next month is already showing.
      expect(controller.page! - startPage, moreOrLessEquals(0.25, epsilon: 0.05));

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('short slow drag snaps back to the same month', (tester) async {
      final container = await pumpCalendar(tester);
      final before = monthOf(container);

      // 60 px < 120 px threshold, ~100 px/s < 250 px/s fling threshold.
      await tester.timedDrag(
        find.byType(MonthCalendar),
        const Offset(-60, 0),
        const Duration(milliseconds: 600),
      );
      await tester.pumpAndSettle();

      expect(monthOf(container), before);
    });

    testWidgets('slow drag past 15% commits to the next month', (tester) async {
      final container = await pumpCalendar(tester);
      final before = monthOf(container);

      // 200 px > 120 px threshold at ~133 px/s (below the fling threshold),
      // so this is the *distance* rule committing.
      await tester.timedDrag(
        find.byType(MonthCalendar),
        const Offset(-200, 0),
        const Duration(milliseconds: 1500),
      );
      await tester.pumpAndSettle();

      expect(monthOf(container), addMonths(before, 1));
    });

    testWidgets('light fling commits even on a short drag', (tester) async {
      final container = await pumpCalendar(tester);
      final before = monthOf(container);

      await tester.fling(
        find.byType(MonthCalendar),
        const Offset(-80, 0),
        600, // px/s, above the 250 px/s threshold
      );
      await tester.pumpAndSettle();

      expect(monthOf(container), addMonths(before, 1));
    });

    testWidgets('swiping right goes to the previous month', (tester) async {
      final container = await pumpCalendar(tester);
      final before = monthOf(container);

      await tester.timedDrag(
        find.byType(MonthCalendar),
        const Offset(200, 0),
        const Duration(milliseconds: 1500),
      );
      await tester.pumpAndSettle();

      expect(monthOf(container), addMonths(before, -1));
    });
  });
}
