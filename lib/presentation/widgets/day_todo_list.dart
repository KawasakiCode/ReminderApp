import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/day_key.dart';
import '../providers/calendar_providers.dart';
import 'todo_tile.dart';

/// The selected day's todos, listed under the month grid (all-day first,
/// then by time — ordering comes from the repository).
class DayTodoList extends ConsumerWidget {
  const DayTodoList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDay = ref.watch(selectedDayProvider);
    final dayKey = dayKeyOf(selectedDay);
    final todosAsync = ref.watch(todosForDayProvider(dayKey));
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  DateFormat('EEEE, MMM d').format(selectedDay),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              todosAsync.maybeWhen(
                data: (todos) {
                  final remaining = todos.where((t) => !t.isDone).length;
                  return Text(
                    todos.isEmpty
                        ? ''
                        : remaining == 0
                            ? 'All done'
                            : '$remaining task${remaining == 1 ? '' : 's'} left',
                    style: TextStyle(fontSize: 12, color: scheme.primary),
                  );
                },
                orElse: () => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
        Expanded(
          child: todosAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Text(
                'Could not load todos.\n$error',
                textAlign: TextAlign.center,
                style: TextStyle(color: scheme.error),
              ),
            ),
            data: (todos) => todos.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.event_available_outlined,
                            size: 42,
                            color: scheme.onSurface.withValues(alpha: 0.25)),
                        const SizedBox(height: 8),
                        Text(
                          'Nothing planned',
                          style: TextStyle(
                            color: scheme.onSurface.withValues(alpha: 0.45),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 2, 16, 96),
                    itemCount: todos.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) =>
                        TodoTile(todo: todos[index]),
                  ),
          ),
        ),
      ],
    );
  }
}
