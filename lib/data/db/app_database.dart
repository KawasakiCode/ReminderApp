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

  /// Opens (or returns) this isolate's database connection.
  ///
  /// Each isolate (UI, home_widget callback, Workmanager midnight task,
  /// notification-action handler) opens its **own** connection to the same
  /// SQLite file. WAL mode plus a generous busy timeout makes that safe:
  /// SQLite serializes the writers, and background writers hold the lock
  /// only for single-row updates.
  ///
  /// Deliberately NOT drift_flutter's `shareAcrossIsolates`: that routes all
  /// isolates through one server isolate advertised via IsolateNameServer,
  /// and a background engine being torn down (e.g. after the BootReceiver's
  /// refresh on app update) leaves a dead port registered in the cached
  /// process — every later connection then hangs forever with no error.
  /// Per-isolate connections cannot hang that way. The one trade-off is that
  /// UI stream queries don't observe writes made by *other* isolates, which
  /// is handled by [TodoRepository.invalidateStreams] on app resume.
  factory AppDatabase.open() => _instance ??= AppDatabase._(
        driftDatabase(
          name: 'reminder_app',
          native: DriftNativeOptions(
            setup: (db) {
              db.execute('PRAGMA journal_mode = WAL;');
              db.execute('PRAGMA busy_timeout = 5000;');
            },
          ),
        ),
      );

  /// Re-runs every active stream query. Called when the app returns to the
  /// foreground, because a background isolate (widget/notification check-off)
  /// may have written rows this isolate's drift connection knows nothing
  /// about.
  void invalidateStreams() => markTablesUpdated([todos]);

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
