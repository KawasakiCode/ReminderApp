/// Calendar days are stored as an integer "day key": the number of days since
/// the Unix epoch of the *local* calendar date (java.time's
/// `LocalDate.toEpochDay()` uses the same convention, which is what the
/// Kotlin side uses — the two must stay in sync).
library;

const int _msPerDay = 86400000;

/// Day key for the local calendar date of [dateTime].
int dayKeyOf(DateTime dateTime) {
  final local = dateTime.toLocal();
  // Re-interpret the local Y/M/D as a UTC date so the division is exact and
  // unaffected by DST shifts.
  return DateTime.utc(local.year, local.month, local.day)
          .millisecondsSinceEpoch ~/
      _msPerDay;
}

/// Day key of the current local date.
int todayKey() => dayKeyOf(DateTime.now());

/// The local midnight `DateTime` a day key refers to.
DateTime dateOfDayKey(int dayKey) {
  final utc = DateTime.fromMillisecondsSinceEpoch(dayKey * _msPerDay, isUtc: true);
  return DateTime(utc.year, utc.month, utc.day);
}

/// Local midnight of the given date (normalizes away the time component).
DateTime dateOnly(DateTime dateTime) =>
    DateTime(dateTime.year, dateTime.month, dateTime.day);

/// The next local midnight strictly after [now].
DateTime nextMidnight(DateTime now) => DateTime(now.year, now.month, now.day + 1);

/// Duration from [now] until the next local midnight.
Duration untilNextMidnight(DateTime now) => nextMidnight(now).difference(now);

/// "9:30 AM"-style label for minutes-since-midnight.
String timeLabelOfMinutes(int minutesSinceMidnight) {
  final hour = minutesSinceMidnight ~/ 60;
  final minute = minutesSinceMidnight % 60;
  final h12 = hour % 12 == 0 ? 12 : hour % 12;
  final mm = minute.toString().padLeft(2, '0');
  return '$h12:$mm ${hour < 12 ? 'AM' : 'PM'}';
}

/// Combines a day key and minutes-since-midnight into a local DateTime.
DateTime combineDayAndMinutes(int dayKey, int minutesSinceMidnight) {
  final date = dateOfDayKey(dayKey);
  return DateTime(
    date.year,
    date.month,
    date.day,
    minutesSinceMidnight ~/ 60,
    minutesSinceMidnight % 60,
  );
}
