import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/day_key.dart';
import '../../domain/entities/todo_entity.dart';
import '../../services/notification_service.dart';
import '../providers/calendar_providers.dart';
import '../providers/core_providers.dart';
import '../providers/todo_actions.dart';
import 'todo_tile.dart';

/// One-UI-style event colors offered in the editor.
const _colorChoices = <int>[
  0xFF2E6FF2, // blue
  0xFF00A884, // green
  0xFFF2A93B, // amber
  0xFFE54D4D, // red
  0xFF9C5FE0, // purple
  0xFF4DB6AC, // teal
];

/// Opens the add/edit bottom sheet. When [existing] is null a new todo is
/// created on [initialDate] (defaults to the currently selected day).
Future<void> showTodoEditor(
  BuildContext context, {
  TodoEntity? existing,
  DateTime? initialDate,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => Padding(
      // Keep the sheet above the keyboard.
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: _TodoEditorSheet(existing: existing, initialDate: initialDate),
    ),
  );
}

class _TodoEditorSheet extends ConsumerStatefulWidget {
  const _TodoEditorSheet({this.existing, this.initialDate});

  final TodoEntity? existing;
  final DateTime? initialDate;

  @override
  ConsumerState<_TodoEditorSheet> createState() => _TodoEditorSheetState();
}

class _TodoEditorSheetState extends ConsumerState<_TodoEditorSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _noteController;

  late DateTime _date;
  late bool _allDay;
  TimeOfDay? _time;
  late bool _reminder;
  int? _colorTag;
  bool _saving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _titleController = TextEditingController(text: existing?.title ?? '');
    _noteController = TextEditingController(text: existing?.note ?? '');
    _date = existing != null
        ? dateOfDayKey(existing.dayKey)
        : dateOnly(widget.initialDate ?? DateTime.now());
    _allDay = existing?.isAllDay ?? true;
    _time = existing?.startMinutes == null
        ? null
        : TimeOfDay(
            hour: existing!.startMinutes! ~/ 60,
            minute: existing.startMinutes! % 60,
          );
    _reminder = existing?.reminderEnabled ?? false;
    _colorTag = existing?.colorTag;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  bool get _reminderPossible => !_allDay && _time != null;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _isEditing ? 'Edit todo' : 'New todo',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _titleController,
            autofocus: !_isEditing,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Title',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _noteController,
            textCapitalization: TextCapitalization.sentences,
            maxLines: 2,
            decoration: const InputDecoration(
              hintText: 'Note (optional)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 6),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today_outlined),
            title: const Text('Date'),
            trailing: Text(
              DateFormat('EEE, MMM d, yyyy').format(_date),
              style: TextStyle(fontSize: 14, color: scheme.primary),
            ),
            onTap: _pickDate,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.schedule_outlined),
            title: const Text('All day'),
            value: _allDay,
            onChanged: (value) => setState(() {
              _allDay = value;
              if (value) _reminder = false;
            }),
          ),
          if (!_allDay)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.access_time),
              title: const Text('Time'),
              trailing: Text(
                _time == null ? 'Set time' : _time!.format(context),
                style: TextStyle(fontSize: 14, color: scheme.primary),
              ),
              onTap: _pickTime,
            ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.notifications_active_outlined),
            title: const Text('Reminder'),
            subtitle: Text(
              _reminderPossible
                  ? 'Alarm-style notification at ${_time!.format(context)}'
                  : 'Set a time to enable the reminder',
              style: const TextStyle(fontSize: 12),
            ),
            value: _reminder && _reminderPossible,
            onChanged:
                _reminderPossible ? (value) => _onReminderToggled(value) : null,
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const SizedBox(width: 4),
              Icon(Icons.palette_outlined, color: scheme.onSurfaceVariant),
              const SizedBox(width: 16),
              for (final color in _colorChoices) ...[
                _ColorDot(
                  color: Color(color),
                  selected: _colorTag == color,
                  onTap: () => setState(
                    () => _colorTag = _colorTag == color ? null : color,
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              if (_isEditing)
                IconButton(
                  onPressed: _saving ? null : _delete,
                  icon: Icon(Icons.delete_outline, color: scheme.error),
                  tooltip: 'Delete',
                ),
              const Spacer(),
              TextButton(
                onPressed: _saving ? null : () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(_isEditing ? 'Save' : 'Add'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = dateOnly(picked));
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _time = picked);
  }

  /// Turning the reminder on walks the permission chain right away so the
  /// user learns about problems now, not when the alarm silently fails.
  Future<void> _onReminderToggled(bool value) async {
    setState(() => _reminder = value);
    if (!value) return;

    final permissions = ref.read(permissionServiceProvider);
    final notificationsOk = await permissions.requestNotifications();
    if (!notificationsOk && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
          'Notifications are blocked — the reminder will not be visible.',
        ),
      ));
    }
    final overview = await permissions.overview();
    if (!overview.exactAlarmsGranted) {
      // Android 12/12L: SCHEDULE_EXACT_ALARM needs a user grant; this opens
      // the "Alarms & reminders" screen. On 13+ USE_EXACT_ALARM covers us.
      await permissions.requestExactAlarms();
    }
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a title first.')),
      );
      return;
    }
    setState(() => _saving = true);

    final note = _noteController.text.trim();
    final startMinutes =
        _allDay || _time == null ? null : _time!.hour * 60 + _time!.minute;
    final reminderEnabled = _reminder && _reminderPossible;
    final dayKey = dayKeyOf(_date);

    final draft = (widget.existing ?? TodoEntity(title: title, dayKey: dayKey))
        .copyWith(
      title: title,
      note: note.isEmpty ? null : note,
      dayKey: dayKey,
      startMinutes: startMinutes,
      isAllDay: _allDay,
      reminderEnabled: reminderEnabled,
      reminderDateTime: reminderEnabled
          ? combineDayAndMinutes(dayKey, startMinutes!)
          : null,
      colorTag: _colorTag,
    );

    final result = await ref.read(todoActionsProvider).save(draft);

    // Make the calendar jump to the day the todo landed on.
    ref.read(selectedDayProvider.notifier).select(_date);
    ref.read(focusedMonthProvider.notifier).set(_date);

    if (!mounted) return;
    Navigator.pop(context);

    final notice = switch (result) {
      ReminderScheduleResult.scheduledInexact =>
        'Reminder set, but exact alarms are off — it may arrive a few '
            'minutes late. Enable "Alarms & reminders" in Settings.',
      ReminderScheduleResult.alarmCapReached =>
        'Too many scheduled reminders — this one was saved without an alarm.',
      _ => null,
    };
    if (notice != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(notice)));
    }
  }

  Future<void> _delete() async {
    final todo = widget.existing!;
    final confirmed = await confirmTodoDeletion(context, todo);
    if (!confirmed || !mounted) return;
    await ref.read(todoActionsProvider).remove(todo);
    if (mounted) Navigator.pop(context);
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: selected
              ? Border.all(
                  color: Theme.of(context).colorScheme.onSurface, width: 2)
              : null,
        ),
        child: selected
            ? const Icon(Icons.check, size: 16, color: Colors.white)
            : null,
      ),
    );
  }
}
