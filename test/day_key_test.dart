import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/core/day_key.dart';
import 'package:reminder_app/domain/entities/todo_entity.dart';

void main() {
  group('day keys', () {
    test('round-trips through dateOfDayKey', () {
      final date = DateTime(2026, 7, 16, 13, 37); // time of day is ignored
      final key = dayKeyOf(date);
      expect(dateOfDayKey(key), DateTime(2026, 7, 16));
    });

    test('matches java.time LocalDate.toEpochDay convention', () {
      // LocalDate.of(1970, 1, 1).toEpochDay() == 0
      expect(dayKeyOf(DateTime(1970, 1, 1)), 0);
      // LocalDate.of(2026, 7, 16).toEpochDay() == 20650
      expect(dayKeyOf(DateTime(2026, 7, 16)), 20650);
    });

    test('is stable across the day regardless of time', () {
      expect(
        dayKeyOf(DateTime(2026, 3, 29, 0, 1)), // DST-change day in the EU
        dayKeyOf(DateTime(2026, 3, 29, 23, 59)),
      );
    });

    test('nextMidnight rolls into the next day, including month ends', () {
      expect(
        nextMidnight(DateTime(2026, 7, 31, 22, 15)),
        DateTime(2026, 8, 1),
      );
    });

    test('combineDayAndMinutes rebuilds the exact local instant', () {
      final key = dayKeyOf(DateTime(2026, 7, 16));
      expect(combineDayAndMinutes(key, 9 * 60 + 30), DateTime(2026, 7, 16, 9, 30));
    });

    test('timeLabelOfMinutes formats 12-hour labels', () {
      expect(timeLabelOfMinutes(0), '12:00 AM');
      expect(timeLabelOfMinutes(9 * 60 + 5), '9:05 AM');
      expect(timeLabelOfMinutes(12 * 60), '12:00 PM');
      expect(timeLabelOfMinutes(23 * 60 + 59), '11:59 PM');
    });
  });

  group('TodoEntity.copyWith', () {
    test('can null out nullable fields', () {
      const todo = TodoEntity(
        id: 1,
        title: 'x',
        dayKey: 20650,
        startMinutes: 90,
        note: 'note',
        colorTag: 0xFF000000,
      );
      final cleared = todo.copyWith(startMinutes: null, note: null, colorTag: null);
      expect(cleared.startMinutes, isNull);
      expect(cleared.note, isNull);
      expect(cleared.colorTag, isNull);
      // Untouched fields survive.
      expect(cleared.id, 1);
      expect(cleared.title, 'x');
    });
  });
}
