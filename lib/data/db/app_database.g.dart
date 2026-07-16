// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $TodosTable extends Todos with TableInfo<$TodosTable, TodoRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TodosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 500,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<int> date = GeneratedColumn<int>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startTimeMeta = const VerificationMeta(
    'startTime',
  );
  @override
  late final GeneratedColumn<int> startTime = GeneratedColumn<int>(
    'start_time',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isAllDayMeta = const VerificationMeta(
    'isAllDay',
  );
  @override
  late final GeneratedColumn<bool> isAllDay = GeneratedColumn<bool>(
    'is_all_day',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_all_day" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _isDoneMeta = const VerificationMeta('isDone');
  @override
  late final GeneratedColumn<bool> isDone = GeneratedColumn<bool>(
    'is_done',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_done" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _reminderEnabledMeta = const VerificationMeta(
    'reminderEnabled',
  );
  @override
  late final GeneratedColumn<bool> reminderEnabled = GeneratedColumn<bool>(
    'reminder_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("reminder_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _reminderDateTimeMeta = const VerificationMeta(
    'reminderDateTime',
  );
  @override
  late final GeneratedColumn<DateTime> reminderDateTime =
      GeneratedColumn<DateTime>(
        'reminder_date_time',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _notificationIdMeta = const VerificationMeta(
    'notificationId',
  );
  @override
  late final GeneratedColumn<int> notificationId = GeneratedColumn<int>(
    'notification_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _colorTagMeta = const VerificationMeta(
    'colorTag',
  );
  @override
  late final GeneratedColumn<int> colorTag = GeneratedColumn<int>(
    'color_tag',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _recurrenceRuleMeta = const VerificationMeta(
    'recurrenceRule',
  );
  @override
  late final GeneratedColumn<String> recurrenceRule = GeneratedColumn<String>(
    'recurrence_rule',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    note,
    date,
    startTime,
    isAllDay,
    isDone,
    reminderEnabled,
    reminderDateTime,
    notificationId,
    colorTag,
    recurrenceRule,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'todos';
  @override
  VerificationContext validateIntegrity(
    Insertable<TodoRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('start_time')) {
      context.handle(
        _startTimeMeta,
        startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta),
      );
    }
    if (data.containsKey('is_all_day')) {
      context.handle(
        _isAllDayMeta,
        isAllDay.isAcceptableOrUnknown(data['is_all_day']!, _isAllDayMeta),
      );
    }
    if (data.containsKey('is_done')) {
      context.handle(
        _isDoneMeta,
        isDone.isAcceptableOrUnknown(data['is_done']!, _isDoneMeta),
      );
    }
    if (data.containsKey('reminder_enabled')) {
      context.handle(
        _reminderEnabledMeta,
        reminderEnabled.isAcceptableOrUnknown(
          data['reminder_enabled']!,
          _reminderEnabledMeta,
        ),
      );
    }
    if (data.containsKey('reminder_date_time')) {
      context.handle(
        _reminderDateTimeMeta,
        reminderDateTime.isAcceptableOrUnknown(
          data['reminder_date_time']!,
          _reminderDateTimeMeta,
        ),
      );
    }
    if (data.containsKey('notification_id')) {
      context.handle(
        _notificationIdMeta,
        notificationId.isAcceptableOrUnknown(
          data['notification_id']!,
          _notificationIdMeta,
        ),
      );
    }
    if (data.containsKey('color_tag')) {
      context.handle(
        _colorTagMeta,
        colorTag.isAcceptableOrUnknown(data['color_tag']!, _colorTagMeta),
      );
    }
    if (data.containsKey('recurrence_rule')) {
      context.handle(
        _recurrenceRuleMeta,
        recurrenceRule.isAcceptableOrUnknown(
          data['recurrence_rule']!,
          _recurrenceRuleMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TodoRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TodoRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}date'],
      )!,
      startTime: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_time'],
      ),
      isAllDay: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_all_day'],
      )!,
      isDone: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_done'],
      )!,
      reminderEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}reminder_enabled'],
      )!,
      reminderDateTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}reminder_date_time'],
      ),
      notificationId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}notification_id'],
      ),
      colorTag: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color_tag'],
      ),
      recurrenceRule: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recurrence_rule'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $TodosTable createAlias(String alias) {
    return $TodosTable(attachedDatabase, alias);
  }
}

class TodoRow extends DataClass implements Insertable<TodoRow> {
  final int id;
  final String title;
  final String? note;

  /// Local calendar day as days-since-epoch (see `core/day_key.dart`).
  final int date;

  /// Minutes since local midnight; null for all-day todos.
  final int? startTime;
  final bool isAllDay;
  final bool isDone;
  final bool reminderEnabled;
  final DateTime? reminderDateTime;

  /// flutter_local_notifications id for the scheduled reminder, kept so the
  /// alarm can be cancelled or replaced when the todo changes.
  final int? notificationId;

  /// Optional ARGB category color.
  final int? colorTag;

  /// Reserved for future recurrence support; never interpreted in v1.
  final String? recurrenceRule;
  final DateTime createdAt;
  final DateTime updatedAt;
  const TodoRow({
    required this.id,
    required this.title,
    this.note,
    required this.date,
    this.startTime,
    required this.isAllDay,
    required this.isDone,
    required this.reminderEnabled,
    this.reminderDateTime,
    this.notificationId,
    this.colorTag,
    this.recurrenceRule,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['date'] = Variable<int>(date);
    if (!nullToAbsent || startTime != null) {
      map['start_time'] = Variable<int>(startTime);
    }
    map['is_all_day'] = Variable<bool>(isAllDay);
    map['is_done'] = Variable<bool>(isDone);
    map['reminder_enabled'] = Variable<bool>(reminderEnabled);
    if (!nullToAbsent || reminderDateTime != null) {
      map['reminder_date_time'] = Variable<DateTime>(reminderDateTime);
    }
    if (!nullToAbsent || notificationId != null) {
      map['notification_id'] = Variable<int>(notificationId);
    }
    if (!nullToAbsent || colorTag != null) {
      map['color_tag'] = Variable<int>(colorTag);
    }
    if (!nullToAbsent || recurrenceRule != null) {
      map['recurrence_rule'] = Variable<String>(recurrenceRule);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  TodosCompanion toCompanion(bool nullToAbsent) {
    return TodosCompanion(
      id: Value(id),
      title: Value(title),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      date: Value(date),
      startTime: startTime == null && nullToAbsent
          ? const Value.absent()
          : Value(startTime),
      isAllDay: Value(isAllDay),
      isDone: Value(isDone),
      reminderEnabled: Value(reminderEnabled),
      reminderDateTime: reminderDateTime == null && nullToAbsent
          ? const Value.absent()
          : Value(reminderDateTime),
      notificationId: notificationId == null && nullToAbsent
          ? const Value.absent()
          : Value(notificationId),
      colorTag: colorTag == null && nullToAbsent
          ? const Value.absent()
          : Value(colorTag),
      recurrenceRule: recurrenceRule == null && nullToAbsent
          ? const Value.absent()
          : Value(recurrenceRule),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory TodoRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TodoRow(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      note: serializer.fromJson<String?>(json['note']),
      date: serializer.fromJson<int>(json['date']),
      startTime: serializer.fromJson<int?>(json['startTime']),
      isAllDay: serializer.fromJson<bool>(json['isAllDay']),
      isDone: serializer.fromJson<bool>(json['isDone']),
      reminderEnabled: serializer.fromJson<bool>(json['reminderEnabled']),
      reminderDateTime: serializer.fromJson<DateTime?>(
        json['reminderDateTime'],
      ),
      notificationId: serializer.fromJson<int?>(json['notificationId']),
      colorTag: serializer.fromJson<int?>(json['colorTag']),
      recurrenceRule: serializer.fromJson<String?>(json['recurrenceRule']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'note': serializer.toJson<String?>(note),
      'date': serializer.toJson<int>(date),
      'startTime': serializer.toJson<int?>(startTime),
      'isAllDay': serializer.toJson<bool>(isAllDay),
      'isDone': serializer.toJson<bool>(isDone),
      'reminderEnabled': serializer.toJson<bool>(reminderEnabled),
      'reminderDateTime': serializer.toJson<DateTime?>(reminderDateTime),
      'notificationId': serializer.toJson<int?>(notificationId),
      'colorTag': serializer.toJson<int?>(colorTag),
      'recurrenceRule': serializer.toJson<String?>(recurrenceRule),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  TodoRow copyWith({
    int? id,
    String? title,
    Value<String?> note = const Value.absent(),
    int? date,
    Value<int?> startTime = const Value.absent(),
    bool? isAllDay,
    bool? isDone,
    bool? reminderEnabled,
    Value<DateTime?> reminderDateTime = const Value.absent(),
    Value<int?> notificationId = const Value.absent(),
    Value<int?> colorTag = const Value.absent(),
    Value<String?> recurrenceRule = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => TodoRow(
    id: id ?? this.id,
    title: title ?? this.title,
    note: note.present ? note.value : this.note,
    date: date ?? this.date,
    startTime: startTime.present ? startTime.value : this.startTime,
    isAllDay: isAllDay ?? this.isAllDay,
    isDone: isDone ?? this.isDone,
    reminderEnabled: reminderEnabled ?? this.reminderEnabled,
    reminderDateTime: reminderDateTime.present
        ? reminderDateTime.value
        : this.reminderDateTime,
    notificationId: notificationId.present
        ? notificationId.value
        : this.notificationId,
    colorTag: colorTag.present ? colorTag.value : this.colorTag,
    recurrenceRule: recurrenceRule.present
        ? recurrenceRule.value
        : this.recurrenceRule,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  TodoRow copyWithCompanion(TodosCompanion data) {
    return TodoRow(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      note: data.note.present ? data.note.value : this.note,
      date: data.date.present ? data.date.value : this.date,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      isAllDay: data.isAllDay.present ? data.isAllDay.value : this.isAllDay,
      isDone: data.isDone.present ? data.isDone.value : this.isDone,
      reminderEnabled: data.reminderEnabled.present
          ? data.reminderEnabled.value
          : this.reminderEnabled,
      reminderDateTime: data.reminderDateTime.present
          ? data.reminderDateTime.value
          : this.reminderDateTime,
      notificationId: data.notificationId.present
          ? data.notificationId.value
          : this.notificationId,
      colorTag: data.colorTag.present ? data.colorTag.value : this.colorTag,
      recurrenceRule: data.recurrenceRule.present
          ? data.recurrenceRule.value
          : this.recurrenceRule,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TodoRow(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('note: $note, ')
          ..write('date: $date, ')
          ..write('startTime: $startTime, ')
          ..write('isAllDay: $isAllDay, ')
          ..write('isDone: $isDone, ')
          ..write('reminderEnabled: $reminderEnabled, ')
          ..write('reminderDateTime: $reminderDateTime, ')
          ..write('notificationId: $notificationId, ')
          ..write('colorTag: $colorTag, ')
          ..write('recurrenceRule: $recurrenceRule, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    note,
    date,
    startTime,
    isAllDay,
    isDone,
    reminderEnabled,
    reminderDateTime,
    notificationId,
    colorTag,
    recurrenceRule,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TodoRow &&
          other.id == this.id &&
          other.title == this.title &&
          other.note == this.note &&
          other.date == this.date &&
          other.startTime == this.startTime &&
          other.isAllDay == this.isAllDay &&
          other.isDone == this.isDone &&
          other.reminderEnabled == this.reminderEnabled &&
          other.reminderDateTime == this.reminderDateTime &&
          other.notificationId == this.notificationId &&
          other.colorTag == this.colorTag &&
          other.recurrenceRule == this.recurrenceRule &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class TodosCompanion extends UpdateCompanion<TodoRow> {
  final Value<int> id;
  final Value<String> title;
  final Value<String?> note;
  final Value<int> date;
  final Value<int?> startTime;
  final Value<bool> isAllDay;
  final Value<bool> isDone;
  final Value<bool> reminderEnabled;
  final Value<DateTime?> reminderDateTime;
  final Value<int?> notificationId;
  final Value<int?> colorTag;
  final Value<String?> recurrenceRule;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const TodosCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.note = const Value.absent(),
    this.date = const Value.absent(),
    this.startTime = const Value.absent(),
    this.isAllDay = const Value.absent(),
    this.isDone = const Value.absent(),
    this.reminderEnabled = const Value.absent(),
    this.reminderDateTime = const Value.absent(),
    this.notificationId = const Value.absent(),
    this.colorTag = const Value.absent(),
    this.recurrenceRule = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  TodosCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    this.note = const Value.absent(),
    required int date,
    this.startTime = const Value.absent(),
    this.isAllDay = const Value.absent(),
    this.isDone = const Value.absent(),
    this.reminderEnabled = const Value.absent(),
    this.reminderDateTime = const Value.absent(),
    this.notificationId = const Value.absent(),
    this.colorTag = const Value.absent(),
    this.recurrenceRule = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : title = Value(title),
       date = Value(date);
  static Insertable<TodoRow> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? note,
    Expression<int>? date,
    Expression<int>? startTime,
    Expression<bool>? isAllDay,
    Expression<bool>? isDone,
    Expression<bool>? reminderEnabled,
    Expression<DateTime>? reminderDateTime,
    Expression<int>? notificationId,
    Expression<int>? colorTag,
    Expression<String>? recurrenceRule,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (note != null) 'note': note,
      if (date != null) 'date': date,
      if (startTime != null) 'start_time': startTime,
      if (isAllDay != null) 'is_all_day': isAllDay,
      if (isDone != null) 'is_done': isDone,
      if (reminderEnabled != null) 'reminder_enabled': reminderEnabled,
      if (reminderDateTime != null) 'reminder_date_time': reminderDateTime,
      if (notificationId != null) 'notification_id': notificationId,
      if (colorTag != null) 'color_tag': colorTag,
      if (recurrenceRule != null) 'recurrence_rule': recurrenceRule,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  TodosCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<String?>? note,
    Value<int>? date,
    Value<int?>? startTime,
    Value<bool>? isAllDay,
    Value<bool>? isDone,
    Value<bool>? reminderEnabled,
    Value<DateTime?>? reminderDateTime,
    Value<int?>? notificationId,
    Value<int?>? colorTag,
    Value<String?>? recurrenceRule,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return TodosCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      note: note ?? this.note,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      isAllDay: isAllDay ?? this.isAllDay,
      isDone: isDone ?? this.isDone,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderDateTime: reminderDateTime ?? this.reminderDateTime,
      notificationId: notificationId ?? this.notificationId,
      colorTag: colorTag ?? this.colorTag,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (date.present) {
      map['date'] = Variable<int>(date.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<int>(startTime.value);
    }
    if (isAllDay.present) {
      map['is_all_day'] = Variable<bool>(isAllDay.value);
    }
    if (isDone.present) {
      map['is_done'] = Variable<bool>(isDone.value);
    }
    if (reminderEnabled.present) {
      map['reminder_enabled'] = Variable<bool>(reminderEnabled.value);
    }
    if (reminderDateTime.present) {
      map['reminder_date_time'] = Variable<DateTime>(reminderDateTime.value);
    }
    if (notificationId.present) {
      map['notification_id'] = Variable<int>(notificationId.value);
    }
    if (colorTag.present) {
      map['color_tag'] = Variable<int>(colorTag.value);
    }
    if (recurrenceRule.present) {
      map['recurrence_rule'] = Variable<String>(recurrenceRule.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TodosCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('note: $note, ')
          ..write('date: $date, ')
          ..write('startTime: $startTime, ')
          ..write('isAllDay: $isAllDay, ')
          ..write('isDone: $isDone, ')
          ..write('reminderEnabled: $reminderEnabled, ')
          ..write('reminderDateTime: $reminderDateTime, ')
          ..write('notificationId: $notificationId, ')
          ..write('colorTag: $colorTag, ')
          ..write('recurrenceRule: $recurrenceRule, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $TodosTable todos = $TodosTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [todos];
}

typedef $$TodosTableCreateCompanionBuilder =
    TodosCompanion Function({
      Value<int> id,
      required String title,
      Value<String?> note,
      required int date,
      Value<int?> startTime,
      Value<bool> isAllDay,
      Value<bool> isDone,
      Value<bool> reminderEnabled,
      Value<DateTime?> reminderDateTime,
      Value<int?> notificationId,
      Value<int?> colorTag,
      Value<String?> recurrenceRule,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$TodosTableUpdateCompanionBuilder =
    TodosCompanion Function({
      Value<int> id,
      Value<String> title,
      Value<String?> note,
      Value<int> date,
      Value<int?> startTime,
      Value<bool> isAllDay,
      Value<bool> isDone,
      Value<bool> reminderEnabled,
      Value<DateTime?> reminderDateTime,
      Value<int?> notificationId,
      Value<int?> colorTag,
      Value<String?> recurrenceRule,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

class $$TodosTableFilterComposer extends Composer<_$AppDatabase, $TodosTable> {
  $$TodosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isAllDay => $composableBuilder(
    column: $table.isAllDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDone => $composableBuilder(
    column: $table.isDone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get reminderEnabled => $composableBuilder(
    column: $table.reminderEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get reminderDateTime => $composableBuilder(
    column: $table.reminderDateTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get notificationId => $composableBuilder(
    column: $table.notificationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get colorTag => $composableBuilder(
    column: $table.colorTag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recurrenceRule => $composableBuilder(
    column: $table.recurrenceRule,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TodosTableOrderingComposer
    extends Composer<_$AppDatabase, $TodosTable> {
  $$TodosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isAllDay => $composableBuilder(
    column: $table.isAllDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDone => $composableBuilder(
    column: $table.isDone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get reminderEnabled => $composableBuilder(
    column: $table.reminderEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get reminderDateTime => $composableBuilder(
    column: $table.reminderDateTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get notificationId => $composableBuilder(
    column: $table.notificationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get colorTag => $composableBuilder(
    column: $table.colorTag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recurrenceRule => $composableBuilder(
    column: $table.recurrenceRule,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TodosTableAnnotationComposer
    extends Composer<_$AppDatabase, $TodosTable> {
  $$TodosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<int> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<int> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<bool> get isAllDay =>
      $composableBuilder(column: $table.isAllDay, builder: (column) => column);

  GeneratedColumn<bool> get isDone =>
      $composableBuilder(column: $table.isDone, builder: (column) => column);

  GeneratedColumn<bool> get reminderEnabled => $composableBuilder(
    column: $table.reminderEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get reminderDateTime => $composableBuilder(
    column: $table.reminderDateTime,
    builder: (column) => column,
  );

  GeneratedColumn<int> get notificationId => $composableBuilder(
    column: $table.notificationId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get colorTag =>
      $composableBuilder(column: $table.colorTag, builder: (column) => column);

  GeneratedColumn<String> get recurrenceRule => $composableBuilder(
    column: $table.recurrenceRule,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$TodosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TodosTable,
          TodoRow,
          $$TodosTableFilterComposer,
          $$TodosTableOrderingComposer,
          $$TodosTableAnnotationComposer,
          $$TodosTableCreateCompanionBuilder,
          $$TodosTableUpdateCompanionBuilder,
          (TodoRow, BaseReferences<_$AppDatabase, $TodosTable, TodoRow>),
          TodoRow,
          PrefetchHooks Function()
        > {
  $$TodosTableTableManager(_$AppDatabase db, $TodosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TodosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TodosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TodosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> date = const Value.absent(),
                Value<int?> startTime = const Value.absent(),
                Value<bool> isAllDay = const Value.absent(),
                Value<bool> isDone = const Value.absent(),
                Value<bool> reminderEnabled = const Value.absent(),
                Value<DateTime?> reminderDateTime = const Value.absent(),
                Value<int?> notificationId = const Value.absent(),
                Value<int?> colorTag = const Value.absent(),
                Value<String?> recurrenceRule = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => TodosCompanion(
                id: id,
                title: title,
                note: note,
                date: date,
                startTime: startTime,
                isAllDay: isAllDay,
                isDone: isDone,
                reminderEnabled: reminderEnabled,
                reminderDateTime: reminderDateTime,
                notificationId: notificationId,
                colorTag: colorTag,
                recurrenceRule: recurrenceRule,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                Value<String?> note = const Value.absent(),
                required int date,
                Value<int?> startTime = const Value.absent(),
                Value<bool> isAllDay = const Value.absent(),
                Value<bool> isDone = const Value.absent(),
                Value<bool> reminderEnabled = const Value.absent(),
                Value<DateTime?> reminderDateTime = const Value.absent(),
                Value<int?> notificationId = const Value.absent(),
                Value<int?> colorTag = const Value.absent(),
                Value<String?> recurrenceRule = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => TodosCompanion.insert(
                id: id,
                title: title,
                note: note,
                date: date,
                startTime: startTime,
                isAllDay: isAllDay,
                isDone: isDone,
                reminderEnabled: reminderEnabled,
                reminderDateTime: reminderDateTime,
                notificationId: notificationId,
                colorTag: colorTag,
                recurrenceRule: recurrenceRule,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TodosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TodosTable,
      TodoRow,
      $$TodosTableFilterComposer,
      $$TodosTableOrderingComposer,
      $$TodosTableAnnotationComposer,
      $$TodosTableCreateCompanionBuilder,
      $$TodosTableUpdateCompanionBuilder,
      (TodoRow, BaseReferences<_$AppDatabase, $TodosTable, TodoRow>),
      TodoRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TodosTableTableManager get todos =>
      $$TodosTableTableManager(_db, _db.todos);
}
