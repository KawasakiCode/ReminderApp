import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/calendar_providers.dart';

/// One-UI-style "jump to month" dialog: year stepper on top, 12-month grid
/// below. Opened by tapping the month title on the calendar screen, so far
/// dates are reachable without swiping through every month in between.
Future<void> showMonthJump(BuildContext context, WidgetRef ref) async {
  final current = ref.read(focusedMonthProvider);
  final picked = await showDialog<DateTime>(
    context: context,
    builder: (_) => _MonthJumpDialog(initial: current),
  );
  if (picked != null) {
    ref.read(selectedDayProvider.notifier).select(picked);
    ref.read(focusedMonthProvider.notifier).set(picked);
  }
}

class _MonthJumpDialog extends StatefulWidget {
  const _MonthJumpDialog({required this.initial});

  final DateTime initial;

  @override
  State<_MonthJumpDialog> createState() => _MonthJumpDialogState();
}

class _MonthJumpDialogState extends State<_MonthJumpDialog> {
  // Matches the calendar's firstDay/lastDay bounds (2000–2100).
  static const int _minYear = 2000;
  static const int _maxYear = 2100;

  static const List<String> _monthLabels = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  late int _year = widget.initial.year;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AlertDialog(
      contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      title: Row(
        children: [
          IconButton(
            tooltip: 'Previous year',
            onPressed:
                _year > _minYear ? () => setState(() => _year--) : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            child: Text(
              '$_year',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            tooltip: 'Next year',
            onPressed:
                _year < _maxYear ? () => setState(() => _year++) : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
      content: SizedBox(
        width: 300,
        child: GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          childAspectRatio: 1.7,
          children: [
            for (var month = 1; month <= 12; month++)
              _MonthChip(
                label: _monthLabels[month - 1],
                selected: _year == widget.initial.year &&
                    month == widget.initial.month,
                highlight: scheme,
                onTap: () =>
                    Navigator.pop(context, DateTime(_year, month, 1)),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

class _MonthChip extends StatelessWidget {
  const _MonthChip({
    required this.label,
    required this.selected,
    required this.highlight,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final ColorScheme highlight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? highlight.primary : null,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? highlight.onPrimary : highlight.onSurface,
          ),
        ),
      ),
    );
  }
}
