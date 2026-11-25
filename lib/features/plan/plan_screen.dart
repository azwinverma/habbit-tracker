import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/reminders/habit_reminder_planner.dart';
import '../../core/reminders/reminder_service.dart';
import '../../core/reminders/reminder_spec.dart';
import '../../models/habit.dart';
import '../habits/presentation/habit_flows.dart';
import '../../l10n/app_localizations.dart';
import '../../app/theme.dart';
import '../../design/components.dart';
import '../../design/backdrop.dart';
import '../../design/motion.dart';

/// Plan: what's coming up, and whether reminders can actually be delivered
/// ("Reminder health", blueprint §7).
class PlanScreen extends ConsumerWidget {
  const PlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habits = ref.watch(habitsProvider);
    final l = AppLocalizations.of(context);
    return BrandBackdrop(child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: Text(l.planTitle)),
      body: habits.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l.couldNotLoad('$e'), textAlign: TextAlign.center)),
        data: (list) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(exactAlarmAllowedProvider);
            ref.invalidate(notificationsEnabledProvider);
          },
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 840),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(Space.page, Space.sm, Space.page, Space.xxl),
                children: Entrance.list([
                  const _ReminderHealthCard(),
                  const SizedBox(height: Space.xl),
                  _Upcoming(habits: list),
                ]),
              ),
            ),
          ),
        ),
      ),
    ));
  }
}

class _ReminderHealthCard extends ConsumerWidget {
  const _ReminderHealthCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final exact = ref.watch(exactAlarmAllowedProvider).valueOrNull;
    final notif = ref.watch(notificationsEnabledProvider).valueOrNull;

    Widget row(IconData icon, String title, String subtitle, bool? ok, {VoidCallback? fix, String? fixLabel}) {
      final dm = context.dm;
      final color = ok == null
          ? theme.colorScheme.outline
          : ok
              ? dm.success
              : theme.colorScheme.error;
      return ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.14), shape: BoxShape.circle),
          child: Icon(ok == false ? Icons.priority_high_rounded : (ok == true ? Icons.check_rounded : icon),
              color: color, size: 22),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: (ok == false && fix != null) ? TextButton(onPressed: fix, child: Text(fixLabel ?? l.allow)) : null,
      );
    }

    return SurfaceCard(
      padding: const EdgeInsets.fromLTRB(Space.lg, Space.lg, Space.lg, Space.md),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.reminderHealth, style: theme.textTheme.titleLarge),
            const SizedBox(height: Space.xs),
            row(
              Icons.notifications_active_outlined,
              l.notifications,
              notif == false ? l.notificationsOff : l.notificationsAllowed,
              notif,
            ),
            row(
              Icons.alarm_on_outlined,
              l.onTimeDelivery,
              exact == false ? l.onTimeLate : l.onTimeOk,
              exact,
              fix: () async {
                await ReminderService.instance.openExactAlarmSettings();
                ref.invalidate(exactAlarmAllowedProvider);
              },
              fixLabel: l.allow,
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                icon: const Icon(Icons.send_outlined),
                label: Text(l.sendTestReminder),
                onPressed: () async {
                  await ReminderService.instance.sendTestReminder();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l.testReminderSent)),
                    );
                  }
                },
              ),
            ),
            Text(l.reminderAidDisclaimer, style: theme.textTheme.bodySmall),
          ],
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
    final l = AppLocalizations.of(context);
    final now = DateTime.now();
    final entries = <({DateTime at, Habit habit, ReminderSpec spec})>[];
    for (final h in habits) {
      for (final s in HabitReminderPlanner.plan(h, now)) {
        entries.add((at: s.firstAt, habit: h, spec: s));
      }
    }
    entries.sort((a, b) => a.at.compareTo(b.at));

    if (entries.isEmpty) {
      return EmptyState(icon: Icons.event_available_rounded, title: l.noUpcoming, body: l.noUpcomingHint);
    }

    String dayLabel(DateTime d) {
      final today = DateTime(now.year, now.month, now.day);
      final day = DateTime(d.year, d.month, d.day);
      final diff = day.difference(today).inDays;
      if (diff == 0) return l.dayToday;
      if (diff == 1) return l.dayTomorrow;
      return MaterialLocalizations.of(context).formatMediumDate(d);
    }

    final dm = context.dm;
    final groups = <String, List<({DateTime at, Habit habit, ReminderSpec spec})>>{};
    for (final e in entries) {
      groups.putIfAbsent(dayLabel(e.at), () => []).add(e);
    }
    final children = <Widget>[Text(l.upNext, style: theme.textTheme.titleLarge)];
    for (final g in groups.entries) {
      children.add(Padding(
        padding: const EdgeInsets.only(top: Space.lg, bottom: Space.sm, left: Space.xs),
        child: Text(g.key.toUpperCase(),
            style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.primary, letterSpacing: 0.8)),
      ));
      children.add(SurfaceCard(
        padding: const EdgeInsets.symmetric(vertical: Space.xs),
        child: Column(children: [
          for (var i = 0; i < g.value.length; i++) ...[
            if (i > 0) const Divider(indent: 72, endIndent: Space.lg),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: Space.lg),
              leading: CategoryBadge(
                icon: iconFor(g.value[i].habit.category),
                palette: paletteFor(g.value[i].habit.category, dm),
                size: 40,
              ),
              title: Text(g.value[i].habit.name, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(
                g.value[i].spec.kind == ReminderKind.once
                    ? '${l.reminderOnce} · ${g.value[i].spec.body}'
                    : '${l.reminderDaily} · ${g.value[i].spec.body}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Text(
                Habit.fmt(TimeOfDay.fromDateTime(g.value[i].at)),
                style: theme.textTheme.titleMedium?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
              ),
              onTap: () => HabitFlows.openHabit(context, g.value[i].habit),
            ),
          ],
        ]),
      ));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children);
  }
}
