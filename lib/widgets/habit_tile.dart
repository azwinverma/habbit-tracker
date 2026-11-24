// lib/widgets/habit_tile.dart
import 'package:flutter/material.dart';
import '../models/habit.dart';

class HabitTile extends StatelessWidget {
  final Habit habit;
  final VoidCallback? onToggleComplete;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const HabitTile({
    super.key,
    required this.habit,
    this.onToggleComplete,
    this.onEdit,
    this.onDelete,
  });

  String _fmt2(int n) => n.toString().padLeft(2, '0');

  /// Build the reminder summary from the *saved* reminderTimes if available,
  /// otherwise fall back to single hour/minute in the model.
  String _reminderSummary(Habit h) {
    if (h.reminderTimes.isNotEmpty) {
      // reminderTimes are strings "HH:mm" — show up to 3, then "+N more"
      final times = h.reminderTimes;
      if (times.length <= 3) return times.join(' • ');
      final shown = times.take(3).join(' • ');
      final more = times.length - 3;
      return '$shown  •  +$more more';
    }
    // Fallback: display the single reminder time on the habit
    final hh = _fmt2(h.reminderHour);
    final mm = _fmt2(h.reminderMinute);
    return '$hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDoneToday = _isDoneToday(habit);
    final streak = habit.streak;

    return Card(
      elevation: 1,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        leading: InkResponse(
          onTap: onToggleComplete,
          radius: 24,
          child: CircleAvatar(
            backgroundColor: isDoneToday
                ? theme.colorScheme.primary
                : theme.colorScheme.surfaceVariant,
            child: Icon(
              isDoneToday ? Icons.check : Icons.circle_outlined,
              color: isDoneToday
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        title: Text(
          habit.name,
          style: theme.textTheme.titleMedium,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Icon(Icons.schedule, size: 16, color: theme.colorScheme.outline),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  _reminderSummary(habit),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.75),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              Icon(Icons.local_fire_department, size: 16, color: theme.colorScheme.outline),
              const SizedBox(width: 4),
              Text(
                '${streak}d',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.75),
                ),
              ),
            ],
          ),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (v) {
            if (v == 'edit') onEdit?.call();
            if (v == 'delete') onDelete?.call();
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'edit', child: Text('Edit')),
            PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
        onTap: onToggleComplete,
      ),
    );
  }

  bool _isDoneToday(Habit h) {
    if (h.lastCompleted == null) return false;
    final d = h.lastCompleted!;
    final today = DateTime.now();
    return d.year == today.year && d.month == today.month && d.day == today.day;
  }
}

