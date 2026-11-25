import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/db/tables.dart';
import '../habits/data/habit_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../app/theme.dart';
import '../../design/components.dart';
import '../../models/habit.dart';
import '../../design/backdrop.dart';
import '../../design/motion.dart';
import '../../widgets/ad_banner.dart';

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

    return BrandBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: Text(l.insightsTitle)),
        body: totals.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text(l.couldNotLoad('$e'), textAlign: TextAlign.center)),
          data: (m) {
            final cards = <Widget>[
              _MetricCard(
                title: l.metricCompleted,
                unit: '',
                category: HabitCategory.generic,
                values: _series(m[HabitMetric.completed], dayKeys),
                dayKeys: dayKeys,
              ),
              _MetricCard(
                title: l.metricWater,
                unit: l.unitGlasses,
                category: HabitCategory.water,
                values: _series(m[HabitMetric.waterGlasses], dayKeys),
                dayKeys: dayKeys,
              ),
              _MetricCard(
                title: l.metricMeditation,
                unit: l.unitMin,
                category: HabitCategory.meditation,
                values: _series(m[HabitMetric.meditationMinutes], dayKeys),
                dayKeys: dayKeys,
              ),
              _MetricCard(
                title: l.metricExercise,
                unit: l.unitMin,
                category: HabitCategory.exercise,
                values: _series(m[HabitMetric.exerciseMinutes], dayKeys),
                dayKeys: dayKeys,
              ),
              _MetricCard(
                title: l.metricSteps,
                unit: l.unitSteps,
                category: HabitCategory.exercise,
                icon: Icons.directions_walk_rounded,
                values: _series(m[HabitMetric.steps], dayKeys),
                dayKeys: dayKeys,
              ),
            ];
            final anyData = m.values.any((byDay) => byDay.values.any((v) => v > 0));
            return LayoutBuilder(
              builder: (context, c) {
                final cols = c.maxWidth >= 720 ? 2 : 1;
                final w = (c.maxWidth - Space.page * 2 - Space.md * (cols - 1)) / cols;
                return ListView(
                  padding: const EdgeInsets.fromLTRB(Space.page, Space.sm, Space.page, Space.xxl),
                  children: [
                    Text(l.last7Days, style: theme.textTheme.titleLarge),
                    const SizedBox(height: Space.xs),
                    Text(anyData ? l.basedOnLogged : l.nothingLogged, style: theme.textTheme.bodySmall),
                    const SizedBox(height: Space.lg),
                    Wrap(
                      spacing: Space.md,
                      runSpacing: Space.md,
                      children: [
                        for (var i = 0; i < cards.length; i++)
                          SizedBox(width: w, child: Entrance(index: i, child: cards[i])),
                      ],
                    ),
                    const SizedBox(height: Space.lg),
                    Text(l.historyNote, style: theme.textTheme.bodySmall),
                    const SizedBox(height: Space.lg),
                    const AdBanner(placement: 'insights_bottom'),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  static List<int> _series(Map<String, int>? byDay, List<String> keys) => [for (final k in keys) byDay?[k] ?? 0];
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.unit,
    required this.category,
    required this.values,
    required this.dayKeys,
    this.icon,
  });

  final String title;
  final String unit;
  final HabitCategory category;
  final IconData? icon;
  final List<int> values;
  final List<String> dayKeys;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final palette = paletteFor(category, context.dm);
    final total = values.fold<int>(0, (a, b) => a + b);
    final activeDays = values.where((v) => v > 0).length;
    final maxV = values.fold<int>(0, (a, b) => a > b ? a : b);
    const barMax = 64.0;

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CategoryBadge(icon: icon ?? iconFor(category), palette: palette, size: 40),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium),
                    Text(l.loggedOnDays(activeDays, values.length), style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              Text(
                unit.isEmpty ? '$total' : '$total $unit',
                style: theme.textTheme.titleLarge?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
              ),
            ],
          ),
          const SizedBox(height: Space.lg),
          Semantics(
            label: '$title per day: ${values.join(', ')}',
            child: SizedBox(
              height: barMax + 24,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < values.length; i++)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            AnimatedContainer(
                              width: 14,
                              duration: Motion.of(context, Motion.medium),
                              curve: Motion.curve,
                              height: maxV == 0 ? 14 : (barMax * values[i] / maxV).clamp(14, barMax).toDouble(),
                              decoration: BoxDecoration(
                                color:
                                    values[i] > 0
                                        ? (i == values.length - 1
                                            ? palette.accent
                                            : palette.accent.withValues(alpha: 0.55))
                                        : palette.container,
                                borderRadius: BorderRadius.circular(Radii.pill),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              MaterialLocalizations.of(context).narrowWeekdays[DateTime.parse(dayKeys[i]).weekday % 7],
                              style: theme.textTheme.labelSmall?.copyWith(
                                color:
                                    i == values.length - 1
                                        ? theme.colorScheme.onSurface
                                        : theme.colorScheme.onSurfaceVariant,
                                fontWeight: i == values.length - 1 ? FontWeight.w700 : null,
                              ),
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
    );
  }
}
