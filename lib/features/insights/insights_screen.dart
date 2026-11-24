import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/db/tables.dart';
import '../habits/data/habit_repository.dart';
import '../../l10n/app_localizations.dart';

/// Insights: the last 7 days from the local history. Statements stay modest
/// and factual ("4 of 7 days") — no health claims (blueprint §3.5).
class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  static const days = 7;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totals = ref.watch(dailyTotalsProvider(days));
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final now = DateTime.now();
    final dayKeys = [
      for (var i = days - 1; i >= 0; i--) HabitRepository.ymd(DateTime(now.year, now.month, now.day - i)),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l.insightsTitle)),
      body: totals.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l.couldNotLoad('$e'), textAlign: TextAlign.center)),
        data: (m) {
          final cards = <Widget>[
            _MetricCard(title: l.metricCompleted, unit: '', icon: Icons.check_circle_outline,
                values: _series(m[HabitMetric.completed], dayKeys), dayKeys: dayKeys),
            _MetricCard(title: l.metricWater, unit: l.unitGlasses, icon: Icons.local_drink_outlined,
                values: _series(m[HabitMetric.waterGlasses], dayKeys), dayKeys: dayKeys),
            _MetricCard(title: l.metricMeditation, unit: l.unitMin, icon: Icons.self_improvement,
                values: _series(m[HabitMetric.meditationMinutes], dayKeys), dayKeys: dayKeys),
            _MetricCard(title: l.metricExercise, unit: l.unitMin, icon: Icons.fitness_center,
                values: _series(m[HabitMetric.exerciseMinutes], dayKeys), dayKeys: dayKeys),
            _MetricCard(title: l.metricSteps, unit: l.unitSteps, icon: Icons.directions_walk,
                values: _series(m[HabitMetric.steps], dayKeys), dayKeys: dayKeys),
          ];
          final anyData = m.values.any((byDay) => byDay.values.any((v) => v > 0));
          return ListView(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
            children: [
              Text(l.last7Days, style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                anyData ? l.basedOnLogged : l.nothingLogged,
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              ...cards,
              const SizedBox(height: 8),
              Text(l.historyNote, style: theme.textTheme.bodySmall),
            ],
          );
        },
      ),
    );
  }

  static List<int> _series(Map<String, int>? byDay, List<String> keys) =>
      [for (final k in keys) byDay?[k] ?? 0];
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.unit,
    required this.icon,
    required this.values,
    required this.dayKeys,
  });

  final String title;
  final String unit;
  final IconData icon;
  final List<int> values;
  final List<String> dayKeys;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final total = values.fold<int>(0, (a, b) => a + b);
    final activeDays = values.where((v) => v > 0).length;
    final maxV = values.fold<int>(0, (a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
              Text(unit.isEmpty ? '$total' : '$total $unit', style: theme.textTheme.titleSmall),
            ]),
            const SizedBox(height: 4),
            Text(l.loggedOnDays(activeDays, values.length), style: theme.textTheme.bodySmall),
            const SizedBox(height: 12),
            Semantics(
              label: '$title per day: ${values.join(', ')}',
              child: SizedBox(
                height: 72,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var i = 0; i < values.length; i++)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                height: maxV == 0 ? 2 : (52 * values[i] / maxV).clamp(2, 52).toDouble(),
                                decoration: BoxDecoration(
                                  color: values[i] > 0 ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                MaterialLocalizations.of(context).narrowWeekdays[DateTime.parse(dayKeys[i]).weekday % 7],
                                style: theme.textTheme.labelSmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
