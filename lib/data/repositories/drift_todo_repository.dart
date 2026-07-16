import 'package:drift/drift.dart';

import '../../domain/entities/todo_entity.dart';
import '../../domain/repositories/todo_repository.dart';
import '../db/app_database.dart';

/// Drift-backed implementation of [TodoRepository]. This is the only place
/// where rows and entities are converted.
class DriftTodoRepository implements TodoRepository {
  DriftTodoRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<TodoEntity>> watchDay(int dayKey) =>
      _db.watchDay(dayKey).map(_sortedEntities);

  @override
  Future<List<TodoEntity>> getDay(int dayKey) async =>
      _sortedEntities(await _db.getDay(dayKey));

  @override
  Stream<Set<int>> watchDaysWithTodos() =>
      _db.watchDistinctDays().map((days) => days.toSet());

  @override
  Future<TodoEntity?> getById(int id) async {
    final row = await _db.getById(id);
    return row == null ? null : _toEntity(row);
  }

  @override
  Future<TodoEntity> insert(TodoEntity todo) async {
    final id = await _db.insertTodo(_toCompanion(todo, forInsert: true));
    return todo.copyWith(id: id);
  }

  @override
  Future<void> update(TodoEntity todo) {
    final id = todo.id;
    if (id == null) {
      throw ArgumentError('Cannot update a todo without an id');
    }
    return _db.updateTodo(id, _toCompanion(todo, forInsert: false));
  }

  @override
  Future<void> delete(int id) => _db.deleteTodo(id);

  @override
  Future<void> setDone(int id, bool isDone) => _db.updateTodo(
        id,
        TodosCompanion(
          isDone: Value(isDone),
          updatedAt: Value(DateTime.now()),
        ),
      );

  @override
  Future<List<TodoEntity>> getPendingRemindersAfter(DateTime instant) async =>
      (await _db.getPendingRemindersAfter(instant)).map(_toEntity).toList();

  /// Sort: all-day first, then by start time, ties broken by id so the order
  /// is stable.
  List<TodoEntity> _sortedEntities(List<TodoRow> rows) {
    final entities = rows.map(_toEntity).toList();
    entities.sort((a, b) {
      if (a.isAllDay != b.isAllDay) return a.isAllDay ? -1 : 1;
      final at = a.startMinutes ?? 0;
      final bt = b.startMinutes ?? 0;
      if (at != bt) return at.compareTo(bt);
      return (a.id ?? 0).compareTo(b.id ?? 0);
    });
    return entities;
  }

  TodoEntity _toEntity(TodoRow row) => TodoEntity(
        id: row.id,
        title: row.title,
        note: row.note,
        dayKey: row.date,
        startMinutes: row.startTime,
        isAllDay: row.isAllDay,
        isDone: row.isDone,
        reminderEnabled: row.reminderEnabled,
        reminderDateTime: row.reminderDateTime,
        notificationId: row.notificationId,
        colorTag: row.colorTag,
        recurrenceRule: row.recurrenceRule,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      );

  TodosCompanion _toCompanion(TodoEntity todo, {required bool forInsert}) =>
      TodosCompanion(
        id: forInsert || todo.id == null
            ? const Value.absent()
            : Value(todo.id!),
        title: Value(todo.title),
        note: Value(todo.note),
        date: Value(todo.dayKey),
        startTime: Value(todo.startMinutes),
        isAllDay: Value(todo.isAllDay),
        isDone: Value(todo.isDone),
        reminderEnabled: Value(todo.reminderEnabled),
        reminderDateTime: Value(todo.reminderDateTime),
        notificationId: Value(todo.notificationId),
        colorTag: Value(todo.colorTag),
        recurrenceRule: Value(todo.recurrenceRule),
        createdAt:
            todo.createdAt == null ? const Value.absent() : Value(todo.createdAt!),
        updatedAt: Value(DateTime.now()),
      );
}
