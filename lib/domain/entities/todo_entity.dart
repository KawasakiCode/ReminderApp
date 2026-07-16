/// Domain entity — plain Dart, no Flutter/DB imports.
class TodoEntity {
  const TodoEntity({
    this.id,
    required this.title,
    this.note,
    required this.dayKey,
    this.startMinutes,
    this.isAllDay = true,
    this.isDone = false,
    this.reminderEnabled = false,
    this.reminderDateTime,
    this.notificationId,
    this.colorTag,
    this.recurrenceRule,
    this.createdAt,
    this.updatedAt,
  });

  /// Null until persisted.
  final int? id;

  final String title;
  final String? note;

  /// Local calendar day, encoded as days-since-epoch (see `day_key.dart`).
  final int dayKey;

  /// Minutes since local midnight; null when [isAllDay].
  final int? startMinutes;

  final bool isAllDay;
  final bool isDone;

  final bool reminderEnabled;

  /// The exact instant the wake-up reminder fires (local wall time).
  final DateTime? reminderDateTime;

  /// Stable id used with flutter_local_notifications so the reminder can be
  /// cancelled/rescheduled.
  final int? notificationId;

  /// Optional ARGB category color.
  final int? colorTag;

  /// Reserved for a future recurrence feature (RFC 5545 RRULE). Not
  /// interpreted anywhere in v1.
  final String? recurrenceRule;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  static const _unset = Object();

  TodoEntity copyWith({
    Object? id = _unset,
    String? title,
    Object? note = _unset,
    int? dayKey,
    Object? startMinutes = _unset,
    bool? isAllDay,
    bool? isDone,
    bool? reminderEnabled,
    Object? reminderDateTime = _unset,
    Object? notificationId = _unset,
    Object? colorTag = _unset,
    Object? recurrenceRule = _unset,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TodoEntity(
      id: id == _unset ? this.id : id as int?,
      title: title ?? this.title,
      note: note == _unset ? this.note : note as String?,
      dayKey: dayKey ?? this.dayKey,
      startMinutes:
          startMinutes == _unset ? this.startMinutes : startMinutes as int?,
      isAllDay: isAllDay ?? this.isAllDay,
      isDone: isDone ?? this.isDone,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderDateTime: reminderDateTime == _unset
          ? this.reminderDateTime
          : reminderDateTime as DateTime?,
      notificationId: notificationId == _unset
          ? this.notificationId
          : notificationId as int?,
      colorTag: colorTag == _unset ? this.colorTag : colorTag as int?,
      recurrenceRule: recurrenceRule == _unset
          ? this.recurrenceRule
          : recurrenceRule as String?,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
