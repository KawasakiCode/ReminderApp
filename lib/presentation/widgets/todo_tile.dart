import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/day_key.dart';
import '../../domain/entities/todo_entity.dart';
import '../providers/todo_actions.dart';
import 'todo_editor_sheet.dart';

/// One row in the day list: round check control, color bar, title/subtitle,
/// bell for reminders. Swipe left to delete (with confirmation).
class TodoTile extends ConsumerWidget {
  const TodoTile({super.key, required this.todo});

  final TodoEntity todo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final actions = ref.read(todoActionsProvider);
    final color = todo.colorTag != null ? Color(todo.colorTag!) : scheme.primary;

    return Dismissible(
      key: ValueKey('todo-${todo.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: scheme.errorContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(Icons.delete_outline, color: scheme.onErrorContainer),
      ),
      confirmDismiss: (_) => confirmTodoDeletion(context, todo),
      onDismissed: (_) => actions.remove(todo),
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => showTodoEditor(context, existing: todo),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => actions.toggleDone(todo),
                  icon: Icon(
                    todo.isDone
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: todo.isDone ? scheme.primary : scheme.outline,
                    size: 26,
                  ),
                  tooltip: todo.isDone ? 'Mark as not done' : 'Mark as done',
                ),
                Container(
                  width: 4,
                  height: 38,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: todo.isDone ? 0.35 : 1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        todo.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w500,
                          decoration:
                              todo.isDone ? TextDecoration.lineThrough : null,
                          color: todo.isDone
                              ? scheme.onSurface.withValues(alpha: 0.45)
                              : scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _subtitle(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                if (todo.reminderEnabled && !todo.isDone)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Icon(Icons.notifications_active_outlined,
                        size: 18, color: scheme.primary),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _subtitle() {
    final time = todo.isAllDay || todo.startMinutes == null
        ? 'All day'
        : timeLabelOfMinutes(todo.startMinutes!);
    final note = todo.note?.trim();
    return note == null || note.isEmpty ? time : '$time · $note';
  }
}

/// Shared delete confirmation (used by swipe and by the editor sheet).
Future<bool> confirmTodoDeletion(BuildContext context, TodoEntity todo) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete todo?'),
      content: Text('"${todo.title}" will be permanently deleted.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  return result ?? false;
}
