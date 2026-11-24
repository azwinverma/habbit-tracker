import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/reminders/habit_reminder_planner.dart';
import '../../core/reminders/reminder_service.dart';
import '../../core/reminders/reminder_spec.dart';
import '../../models/habit.dart';
import '../habits/presentation/habit_flows.dart';

/// Plan: what's coming up, and whether reminders can actually be delivered
/// ("Reminder health", blueprint §7).
class PlanScreen extends ConsumerWidget {
  const PlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habits = ref.watch(habitsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Plan')),
      body: habits.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load your plan.\n$e', textAlign: TextAlign.center)),
        data: (list) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(exactAlarmAllowedProvider);
            ref.invalidate(notificationsEnabledProvider);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
            children: [
              const _ReminderHealthCard(),
              const SizedBox(height: 12),
              _Upcoming(habits: list),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReminderHealthCard extends ConsumerWidget {
  const _ReminderHealthCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final exact = ref.watch(exactAlarmAllowedProvider).valueOrNull;
    final notif = ref.watch(notificationsEnabledProvider).valueOrNull;

    Widget row(IconData icon, String title, String subtitle, bool? ok, {VoidCallback? fix, String? fixLabel}) {
      final color = ok == null
          ? theme.colorScheme.outline
          : ok
              ? theme.colorScheme.primary
              : theme.colorScheme.error;
      return ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(ok == false ? Icons.error_outline : icon, color: color),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: (ok == false && fix != null) ? TextButton(onPressed: fix, child: Text(fixLabel ?? 'Fix')) : null,
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reminder health', style: theme.textTheme.titleMedium),
            row(
              Icons.notifications_active_outlined,
              'Notifications',
              notif == false ? 'Turned off — reminders cannot appear' : 'Allowed',
              notif,
            ),
            row(
              Icons.alarm_on_outlined,
              'On-time delivery',
              exact == false
                  ? 'Reminders may arrive a few minutes late'
                  : 'Reminders are scheduled for the exact minute',
              exact,
              fix: () async {
                await ReminderService.instance.openExactAlarmSettings();
                ref.invalidate(exactAlarmAllowedProvider);
              },
              fixLabel: 'Allow',
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                icon: const Icon(Icons.send_outlined),
                label: const Text('Send a test reminder'),
                onPressed: () async {
                  await ReminderService.instance.sendTestReminder();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('A test reminder will arrive in about 10 seconds.')),
                    );
                  }
                },
              ),
            ),
            Text(
              'DailyMantra is a reminder aid. Phones can delay notifications in '
              'battery-saving modes, so don\'t rely on it as your only safeguard for medicine.',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _Upcoming extends StatelessWidget {
  const _Upcoming({required this.habits});
  final List<Habit> habits;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final entries = <({DateTime at, Habit habit, ReminderSpec spec})>[];
    for (final h in habits) {
      for (final s in HabitReminderPlanner.plan(h, now)) {
        entries.add((at: s.firstAt, habit: h, spec: s));
      }
    }
    entries.sort((a, b) => a.at.compareTo(b.at));

    if (entries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.event_available_outlined, size: 48, color: theme.colorScheme.outline),
            const SizedBox(height: 8),
            const Text('No upcoming reminders.', textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text('Add a habit with a reminder time to see your plan here.',
                textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
          ],
        ),
      );
    }

    String dayLabel(DateTime d) {
      final today = DateTime(now.year, now.month, now.day);
      final day = DateTime(d.year, d.month, d.day);
      final diff = day.difference(today).inDays;
      if (diff == 0) return 'Today';
      if (diff == 1) return 'Tomorrow';
      const wd = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return '${wd[d.weekday - 1]} ${d.day}/${d.month}';
    }

    final children = <Widget>[Text('Up next', style: theme.textTheme.titleMedium)];
    String? lastLabel;
    for (final e in entries) {
      final label = dayLabel(e.at);
      if (label != lastLabel) {
        children.add(Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 4),
          child: Text(label, style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary)),
        ));
        lastLabel = label;
      }
      final hhmm = '${e.at.hour.toString().padLeft(2, '0')}:${e.at.minute.toString().padLeft(2, '0')}';
      children.add(Card(
        child: ListTile(
          leading: Text(hhmm, style: theme.textTheme.titleMedium),
          title: Text(e.habit.name, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            e.spec.kind == ReminderKind.once ? 'One-time · ${e.spec.body}' : 'Daily · ${e.spec.body}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () => HabitFlows.openHabit(context, e.habit),
        ),
      ));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children);
  }
}
