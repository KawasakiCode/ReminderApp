import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

/// The single Drift table. The row class is named [TodoRow] to avoid clashing
/// with the domain entity.
@DataClassName('TodoRow')
class Todos extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 500)();
  TextColumn get note => text().nullable()();

  /// Local calendar day as days-since-epoch (see `core/day_key.dart`).
  IntColumn get date => integer()();

  /// Minutes since local midnight; null for all-day todos.
  IntColumn get startTime => integer().nullable()();

  BoolColumn get isAllDay => boolean().withDefault(const Constant(true))();
  BoolColumn get isDone => boolean().withDefault(const Constant(false))();

  BoolColumn get reminderEnabled =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get reminderDateTime => dateTime().nullable()();

  /// flutter_local_notifications id for the scheduled reminder, kept so the
  /// alarm can be cancelled or replaced when the todo changes.
  IntColumn get notificationId => integer().nullable()();

  /// Optional ARGB category color.
  IntColumn get colorTag => integer().nullable()();

  /// Reserved for future recurrence support; never interpreted in v1.
  TextColumn get recurrenceRule => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [Todos])
class AppDatabase extends _$AppDatabase {
  AppDatabase._(super.e);

  /// For tests: inject an in-memory executor.
  AppDatabase.forTesting(super.e);

  static AppDatabase? _instance;

  /// Opens (or returns) the process-wide database.
  ///
  /// `shareAcrossIsolates: true` is load-bearing: the home_widget
  /// interactivity callback, the Workmanager midnight task and the
  /// flutter_local_notifications background action handler all run in their
  /// own background isolates. With this flag every isolate connects to one
  /// shared drift server instead of opening the SQLite file concurrently, so
  /// there are no lock conflicts and stream queries in the UI isolate update
  /// when a background isolate writes.
  factory AppDatabase.open() => _instance ??= AppDatabase._(
        driftDatabase(
          name: 'reminder_app',
          native: const DriftNativeOptions(shareAcrossIsolates: true),
        ),
      );

  @override
  int get schemaVersion => 1;

  Stream<List<TodoRow>> watchDay(int dayKey) =>
      (select(todos)..where((t) => t.date.equals(dayKey))).watch();

  Future<List<TodoRow>> getDay(int dayKey) =>
      (select(todos)..where((t) => t.date.equals(dayKey))).get();

  Stream<List<int>> watchDistinctDays() {
    final query = selectOnly(todos, distinct: true)..addColumns([todos.date]);
    return query.watch().map(
          (rows) => rows.map((row) => row.read(todos.date)!).toList(),
        );
  }

  Future<TodoRow?> getById(int id) =>
      (select(todos)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> insertTodo(TodosCompanion companion) =>
      into(todos).insert(companion);

  Future<void> updateTodo(int id, TodosCompanion companion) =>
      (update(todos)..where((t) => t.id.equals(id))).write(companion);

  Future<void> deleteTodo(int id) =>
      (delete(todos)..where((t) => t.id.equals(id))).go();

  Future<List<TodoRow>> getPendingRemindersAfter(DateTime instant) =>
      (select(todos)
            ..where((t) =>
                t.reminderEnabled.equals(true) &
                t.isDone.equals(false) &
                t.reminderDateTime.isBiggerThanValue(instant)))
          .get();
}
