import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/day_key.dart';
import '../../domain/entities/todo_entity.dart';
import '../providers/core_providers.dart';
import '../providers/todo_actions.dart';

/// Alarm-style full-screen view shown when a reminder fires (via the
/// notification's full-screen intent on the lock screen) or when the user
/// taps a reminder notification.
class ReminderScreen extends ConsumerWidget {
  const ReminderScreen({super.key, required this.todoId});

  final int todoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [scheme.primary, scheme.primary.withValues(alpha: 0.75)],
          ),
        ),
        child: SafeArea(
          child: FutureBuilder<TodoEntity?>(
            future: ref.read(todoRepositoryProvider).getById(todoId),
            builder: (context, todoSnapshot) {
              final todo = todoSnapshot.data;
              if (todoSnapshot.connectionState != ConnectionState.done) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
              }
              if (todo == null) {
                // Deleted or already handled elsewhere.
                return _Missing(onClose: () => Navigator.pop(context));
              }
              return _ReminderBody(todo: todo);
            },
          ),
        ),
      ),
    );
  }
}

class _ReminderBody extends ConsumerWidget {
  const _ReminderBody({required this.todo});

  final TodoEntity todo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const onColor = Colors.white;
    final timeLabel = todo.startMinutes == null
        ? 'All day'
        : timeLabelOfMinutes(todo.startMinutes!);

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          const Spacer(),
          Icon(Icons.notifications_active,
              size: 64, color: onColor.withValues(alpha: 0.9)),
          const SizedBox(height: 24),
          Text(
            '${DateFormat('EEE, MMM d').format(dateOfDayKey(todo.dayKey))}'
            ' · $timeLabel',
            style: TextStyle(
                fontSize: 16, color: onColor.withValues(alpha: 0.85)),
          ),
          const SizedBox(height: 12),
          Text(
            todo.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: onColor,
            ),
          ),
          if (todo.note != null && todo.note!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              todo.note!.trim(),
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 16, color: onColor.withValues(alpha: 0.85)),
            ),
          ],
          const Spacer(flex: 2),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: onColor,
              foregroundColor: Theme.of(context).colorScheme.primary,
              minimumSize: const Size.fromHeight(52),
            ),
            onPressed: () async {
              if (!todo.isDone) {
                await ref.read(todoActionsProvider).toggleDone(todo);
              }
              if (context.mounted) Navigator.pop(context);
            },
            icon: const Icon(Icons.check),
            label: const Text('Complete'),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Dismiss',
              style: TextStyle(color: onColor.withValues(alpha: 0.9)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Missing extends StatelessWidget {
  const _Missing({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'This todo no longer exists.',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onClose,
            child: const Text('Close', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
