// lib/widgets/habit_tile.dart
import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../design/components.dart';
import '../l10n/app_localizations.dart';
import '../models/habit.dart';

/// One habit row: category badge, name, reminder times, streak, and a round
/// one-tap completion button. Tapping the row opens the habit's own screen.
class HabitTile extends StatelessWidget {
  final Habit habit;
  final VoidCallback? onToggleComplete;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  /// Opens the habit's own screen (player, reader, tracker). When null,
  /// tapping the tile toggles completion.
  final VoidCallback? onOpen;

  /// Overrides the "done today" state (e.g. category goal reached). Defaults
  /// to "marked complete today".
  final bool? doneToday;

  const HabitTile({
    super.key,
    required this.habit,
    this.onToggleComplete,
    this.onEdit,
    this.onDelete,
    this.onOpen,
    this.doneToday,
  });

  static String reminderSummary(Habit h) {
    final times = h.reminderTimes.isNotEmpty
        ? h.reminderTimes.map((s) => Habit.fmt(Habit.parseHHmm(s))).toList()
        : [Habit.fmt(TimeOfDay(hour: h.reminderHour, minute: h.reminderMinute))];
    if (times.length <= 3) return times.join(' · ');
    return '${times.take(3).join(' · ')} +${times.length - 3}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final done = doneToday ?? _isDoneToday(habit);
    final palette = paletteFor(habit.category, context.dm);
    final muted = theme.colorScheme.onSurfaceVariant;

    return SurfaceCard(
      onTap: onOpen ?? onToggleComplete,
      padding: const EdgeInsets.fromLTRB(Space.md, Space.md, 0, Space.md),
      child: Row(
        children: [
          CategoryBadge(icon: iconFor(habit.category), palette: palette),
          const SizedBox(width: Space.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  habit.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    decoration: done ? TextDecoration.lineThrough : null,
                    decorationColor: muted,
                    color: done ? muted : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(habit.enabled ? Icons.schedule_rounded : Icons.notifications_off_outlined,
                        size: 14, color: muted),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(reminderSummary(habit),
                          style: theme.textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    if (habit.streak > 0) ...[
                      const SizedBox(width: Space.md),
                      Icon(Icons.local_fire_department_rounded, size: 14, color: context.dm.celebrate),
                      const SizedBox(width: 2),
                      Text(l.streakShort(habit.streak), style: theme.textTheme.bodySmall),
                    ],
                  ],
                ),
              ],
            ),
          ),
          CompleteButton(
            done: done,
            color: palette.accent,
            onTap: onToggleComplete,
            semanticLabel: done ? l.markNotDone(habit.name) : l.markDone(habit.name),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, color: muted),
            onSelected: (v) {
              if (v == 'edit') onEdit?.call();
              if (v == 'delete') onDelete?.call();
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'edit', child: Text(l.menuEdit)),
              PopupMenuItem(value: 'delete', child: Text(l.menuDelete)),
            ],
          ),
        ],
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
