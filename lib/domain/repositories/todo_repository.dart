import '../entities/todo_entity.dart';

/// Repository contract. Implemented by the data layer (Drift); the domain and
/// presentation layers only ever see this interface.
abstract interface class TodoRepository {
  /// Reactive list of a single day's todos, sorted all-day first, then by
  /// start time.
  Stream<List<TodoEntity>> watchDay(int dayKey);

  /// Reactive set of every day key that has at least one todo — drives the
  /// calendar indicator dots.
  Stream<Set<int>> watchDaysWithTodos();

  /// One-shot read of a day's todos (used by the snapshot writer, which also
  /// runs in short-lived background isolates where streams are overkill).
  Future<List<TodoEntity>> getDay(int dayKey);

  Future<TodoEntity?> getById(int id);

  /// Inserts and returns the persisted entity (with its assigned id).
  Future<TodoEntity> insert(TodoEntity todo);

  Future<void> update(TodoEntity todo);

  Future<void> delete(int id);

  Future<void> setDone(int id, bool isDone);

  /// Todos with an enabled, not-yet-fired reminder after [instant] that are
  /// not done — the set that must be (re)scheduled with AlarmManager.
  Future<List<TodoEntity>> getPendingRemindersAfter(DateTime instant);
}
