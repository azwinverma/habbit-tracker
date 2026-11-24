import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app/providers.dart';
import '../app/theme.dart';
import '../core/db/app_database.dart' show DoseStatus;
import '../core/reminders/reminder_service.dart';
import '../design/components.dart';
import '../features/habits/data/habit_repository.dart';
import '../features/habits/presentation/habit_flows.dart';
import '../features/today/today_summary.dart';
import '../l10n/app_localizations.dart';
import '../models/habit.dart';
import '../services/ad_service.dart';
import '../services/quote_service.dart';
import '../services/storage_service.dart';
import '../widgets/ad_banner.dart';
import '../widgets/habit_tile.dart';

/// Today: greeting, progress ring, category snapshot (bento), what's next,
/// habits with one-tap completion, and a thought for the day.
/// All numbers come from the user's own data via a live database stream.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _storage = StorageService();
  final _interstitial = InterstitialHelper();
  List<Habit>? _habits;
  StreamSubscription<List<Habit>>? _sub;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    // Never let ads block the user's data (fire-and-forget, errors ignored).
    unawaited(_interstitial.load().catchError((Object _) {}));
    final list = await _storage.loadHabits(); // also runs the one-time DB migration
    if (!mounted) return;
    setState(() => _habits = list);
    _sub = ref.read(habitRepositoryProvider).watchAll().listen(
      (l) {
        if (mounted) setState(() => _habits = l);
      },
      onError: (_) {}, // DB unavailable: keep the legacy-loaded list
    );
    // Retire pre-2.0 alarms (first run only), re-arm every habit's reminders
    // from saved data, cancel deleted habits' alarms.
    await ReminderService.instance.startup(list);
    await _maybeAskForExactAlarms();
  }

  /// Android 12+: ask once, with an explanation, only if the user has reminders.
  Future<void> _maybeAskForExactAlarms() async {
    if ((_habits ?? const []).every((h) => !h.enabled)) return;
    if (await ReminderService.instance.canScheduleExact()) return;
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('exact_alarm_prompt_shown') ?? false) return;
    await prefs.setBool('exact_alarm_prompt_shown', true);
    if (!mounted) return;
    final l = AppLocalizations.of(context);
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.alarm_on_rounded),
        title: Text(l.exactDialogTitle),
        content: Text(l.exactDialogBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.notNow)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.allow)),
        ],
      ),
    );
    if (go == true) await ReminderService.instance.openExactAlarmSettings();
  }

  Future<void> _refresh() async {
    final list = await _storage.loadHabits();
    if (mounted) setState(() => _habits = list);
  }

  String _greeting(AppLocalizations l, DateTime now) {
    if (now.hour < 12) return l.greetingMorning;
    if (now.hour < 17) return l.greetingAfternoon;
    return l.greetingEvening;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final now = DateTime.now();
    final habits = _habits;
    final newCount = ref.watch(newContentCountProvider).valueOrNull ?? 0;
    final date = MaterialLocalizations.of(context).formatFullDate(now);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 840),
              child: CustomScrollView(
                slivers: [
                  // Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(Space.page, Space.lg, Space.md, Space.sm),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(date.toUpperCase(),
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant, letterSpacing: 0.8)),
                                const SizedBox(height: Space.xs),
                                Semantics(
                                  header: true,
                                  child: Text(_greeting(l, now), style: theme.textTheme.headlineMedium),
                                ),
                              ],
                            ),
                          ),
                          IconButton.filledTonal(
                            tooltip: newCount > 0 ? l.discoverNew(newCount) : l.discover,
                            onPressed: () => context.push('/discover'),
                            icon: Badge(
                              isLabelVisible: newCount > 0,
                              backgroundColor: context.dm.celebrate,
                              textColor: BrandColors.ink,
                              label: Text(newCount > 99 ? '99+' : '$newCount'),
                              child: const Icon(Icons.explore_outlined),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (habits == null)
                    const SliverToBoxAdapter(child: _TodaySkeleton())
                  else if (habits.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          EmptyState(
                            icon: Icons.spa_rounded,
                            title: l.emptyTodayTitle,
                            body: l.emptyTodayBody,
                            actionLabel: l.addAHabit,
                            onAction: () => HabitFlows.startQuickAdd(context, QuickAddKind.water),
                          ),
                          _QuickStartRow(l: l),
                        ],
                      ),
                    )
                  else
                    ..._dashboard(context, l, TodaySummary.from(habits, now), habits),
                  const SliverToBoxAdapter(child: SizedBox(height: Space.xxl)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _dashboard(BuildContext context, AppLocalizations l, TodaySummary t, List<Habit> habits) {
    final quote = QuoteService.quoteForDate(t.now);
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(Space.page, Space.sm, Space.page, 0),
        sliver: SliverToBoxAdapter(child: _HeroProgress(t: t)),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(Space.page, Space.md, Space.page, 0),
        sliver: SliverToBoxAdapter(child: _Bento(t: t)),
      ),
      SliverToBoxAdapter(
        child: SectionHeader(l.upNextToday, action: l.seeAll, onAction: () => context.go('/plan')),
      ),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: Space.page),
        sliver: SliverToBoxAdapter(child: _UpNext(t: t)),
      ),
      SliverToBoxAdapter(child: SectionHeader(l.yourHabits)),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: Space.page),
        sliver: SliverList.separated(
          itemCount: habits.length,
          separatorBuilder: (_, __) => const SizedBox(height: Space.sm),
          itemBuilder: (c, i) {
            final h = habits[i];
            return HabitTile(
              habit: h,
              doneToday: TodaySummary.isDoneToday(h, t.now),
              onToggleComplete: () => HabitFlows.toggleToday(h),
              onOpen: h.category == HabitCategory.generic ? null : () => HabitFlows.openHabit(context, h),
              onEdit: () => HabitFlows.editGeneric(context, h),
              onDelete: () => HabitFlows.delete(h),
            );
          },
        ),
      ),
      SliverToBoxAdapter(child: SectionHeader(l.thoughtForToday)),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: Space.page),
        sliver: SliverToBoxAdapter(child: _QuoteCard(quote: quote)),
      ),
      // Ads stay below the user's own content (never between core tasks).
      const SliverPadding(
        padding: EdgeInsets.fromLTRB(Space.page, Space.lg, Space.page, 0),
        sliver: SliverToBoxAdapter(child: AdBanner(placement: 'home_bottom')),
      ),
    ];
  }
}

// ---------------------------------------------------------------- hero

class _HeroProgress extends StatelessWidget {
  const _HeroProgress({required this.t});
  final TodaySummary t;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = theme.colorScheme;
    final l = AppLocalizations.of(context);
    final message = t.allDone
        ? l.heroAllDone
        : t.done == 0
            ? l.heroStart
            : l.heroKeepGoing(t.left);
    return Container(
      padding: const EdgeInsets.all(Space.xl - 4),
      decoration: BoxDecoration(
        color: s.primaryContainer,
        borderRadius: BorderRadius.circular(Radii.lg + 4),
      ),
      child: Row(
        children: [
          ProgressRing(
            value: t.progress,
            size: 96,
            stroke: 10,
            color: s.primary,
            trackColor: s.surface.withValues(alpha: 0.7),
            semanticsLabel: l.todayProgressLabel,
            semanticsValue: l.todayProgress(t.done, t.total),
            child: t.allDone
                ? Icon(Icons.celebration_rounded, color: s.onPrimaryContainer, size: 36)
                : Text(l.doneTodayCount(t.done, t.total),
                    style: theme.textTheme.titleLarge?.copyWith(color: s.onPrimaryContainer)),
          ),
          const SizedBox(width: Space.lg + 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.todayProgress(t.done, t.total),
                    style: theme.textTheme.titleLarge?.copyWith(color: s.onPrimaryContainer)),
                const SizedBox(height: Space.xs),
                Text(message,
                    style: theme.textTheme.bodyMedium?.copyWith(color: s.onPrimaryContainer.withValues(alpha: 0.85))),
                if (t.bestStreak > 1) ...[
                  const SizedBox(height: Space.md),
                  StatusChip(
                    icon: Icons.local_fire_department_rounded,
                    label: l.streakDays(t.bestStreak),
                    background: s.surface.withValues(alpha: 0.75),
                    color: s.onSurface,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- bento

class _Bento extends ConsumerWidget {
  const _Bento({required this.t});
  final TodaySummary t;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final dm = context.dm;
    final now = t.now;
    final tiles = <Widget>[];

    final water = t.first(HabitCategory.water);
    if (water != null) {
      final done = TodaySummary.todayValue(water.waterLastDate, water.waterCompleted, now);
      final target = water.waterTarget ?? 8;
      tiles.add(_Tile(
        palette: dm.water,
        icon: Icons.water_drop_rounded,
        title: l.tileWater,
        value: l.tileWaterValue(done, target),
        progress: target == 0 ? 0 : done / target,
        onTap: () => HabitFlows.openHabit(context, water),
        action: _TileAction(
          icon: Icons.add_rounded,
          tooltip: l.tileAddGlass,
          color: dm.water.accent,
          onPressed: () => HabitFlows.addWater(water),
        ),
      ));
    }

    final med = t.first(HabitCategory.medicine);
    if (med != null) tiles.add(_MedicineTile(habit: med, now: now));

    final ex = t.first(HabitCategory.exercise);
    if (ex != null) {
      final mins = TodaySummary.todayValue(ex.exerciseLastDate, ex.exerciseTodayMin, now);
      final goal = ex.exerciseGoalMin ?? 30;
      final steps = TodaySummary.todayValue(ex.stepsLastDate, ex.stepsToday, now);
      tiles.add(_Tile(
        palette: dm.movement,
        icon: Icons.directions_run_rounded,
        title: l.tileMovement,
        value: steps > 0 ? '${l.tileMinutesValue(mins, goal)} · ${l.tileStepsValue(steps)}' : l.tileMinutesValue(mins, goal),
        progress: goal == 0 ? 0 : mins / goal,
        onTap: () => HabitFlows.openHabit(context, ex),
      ));
    }

    final mind = t.first(HabitCategory.meditation);
    tiles.add(mind == null
        ? _Tile(
            palette: dm.mind,
            icon: Icons.self_improvement_rounded,
            title: l.tileMind,
            value: l.tileMindStart,
            onTap: () => context.push('/discover'),
          )
        : () {
            final done = TodaySummary.todayValue(mind.meditationLastDate, mind.meditationTodayMin, now);
            final goal = mind.meditationGoalMin ?? 10;
            return _Tile(
              palette: dm.mind,
              icon: Icons.self_improvement_rounded,
              title: l.tileMind,
              value: done == 0 ? l.tileMindStart : l.tileMindValue(done, goal),
              progress: goal == 0 ? 0 : done / goal,
              onTap: () => HabitFlows.openHabit(context, mind),
            );
          }());

    final reading = t.first(HabitCategory.reading);
    tiles.add(_Tile(
      palette: dm.reading,
      icon: Icons.auto_stories_rounded,
      title: l.tileReading,
      value: reading == null ? l.tileFindBook : l.tileReadingContinue,
      onTap: reading == null ? () => context.push('/discover') : () => HabitFlows.openHabit(context, reading),
    ));

    return LayoutBuilder(builder: (context, c) {
      final cols = c.maxWidth >= 640 ? 4 : 2;
      final w = (c.maxWidth - Space.md * (cols - 1)) / cols;
      return Wrap(
        spacing: Space.md,
        runSpacing: Space.md,
        children: [
          for (var i = 0; i < tiles.length; i++)
            SizedBox(
              // An odd last tile spans the row instead of leaving a hole.
              width: (cols == 2 && tiles.length.isOdd && i == tiles.length - 1) ? c.maxWidth : w,
              child: tiles[i],
            ),
        ],
      );
    });
  }
}

class _TileAction {
  const _TileAction({required this.icon, required this.tooltip, required this.onPressed, required this.color});
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color color;
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.palette,
    required this.icon,
    required this.title,
    required this.value,
    this.progress,
    this.onTap,
    this.action,
  });
  final CategoryPalette palette;
  final IconData icon;
  final String title;
  final String value;
  final double? progress;
  final VoidCallback? onTap;
  final _TileAction? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SurfaceCard(
      onTap: onTap,
      semanticLabel: '$title, $value',
      padding: const EdgeInsets.fromLTRB(Space.lg, Space.lg, Space.sm, Space.lg),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 112),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (progress != null)
                  ProgressRing(
                    value: progress!,
                    size: 44,
                    stroke: 5,
                    color: palette.accent,
                    trackColor: palette.container,
                    child: Icon(icon, size: 20, color: palette.accent),
                  )
                else
                  CategoryBadge(icon: icon, palette: palette),
                const Spacer(),
                if (action != null)
                  IconButton.filledTonal(
                    tooltip: action!.tooltip,
                    onPressed: action!.onPressed,
                    style: IconButton.styleFrom(
                      backgroundColor: palette.container,
                      foregroundColor: palette.onContainer,
                    ),
                    icon: Icon(action!.icon),
                  ),
              ],
            ),
            const SizedBox(height: Space.md),
            ExcludeSemantics(child: Text(title, style: theme.textTheme.titleMedium)),
            const SizedBox(height: 2),
            ExcludeSemantics(
              child: Text(value, style: theme.textTheme.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}

/// Medicine tile: next dose today that isn't logged yet, with one-tap Taken.
class _MedicineTile extends ConsumerWidget {
  const _MedicineTile({required this.habit, required this.now});
  final Habit habit;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final dm = context.dm;
    final today = HabitRepository.ymd(now);
    final statuses = ref.watch(doseStatusesProvider(habit.id)).valueOrNull?[today] ?? const <String, int>{};
    final start = DateTime.tryParse(habit.medicineStartDate ?? '');
    final end = DateTime.tryParse(habit.medicineEndDate ?? '');
    final day = DateTime(now.year, now.month, now.day);
    final inCourse = (start == null || !day.isBefore(start)) && (end == null || !day.isAfter(end));
    final times = (habit.reminderTimes.map((s) => Habit.fmt(Habit.parseHHmm(s))).toSet().toList()..sort());
    final pending = inCourse ? times.where((t) => statuses[t] == null).toList() : <String>[];
    final logged = inCourse ? times.length - pending.length : 0;

    final value = !inCourse || times.isEmpty
        ? l.tileNoDoseToday
        : pending.isEmpty
            ? l.tileDosesLogged
            : l.tileNextDose(pending.first);
    return _Tile(
      palette: dm.medicine,
      icon: Icons.medication_rounded,
      title: habit.medicineName?.isNotEmpty == true ? habit.medicineName! : l.tileMedicine,
      value: value,
      progress: inCourse && times.isNotEmpty ? logged / times.length : null,
      onTap: () => HabitFlows.openHabit(context, habit),
      action: pending.isEmpty
          ? null
          : _TileAction(
              icon: Icons.check_rounded,
              tooltip: '${l.medTaken} · ${pending.first}',
              color: dm.medicine.accent,
              onPressed: () =>
                  ref.read(doseLogRepositoryProvider).setStatus(habit.id, today, pending.first, DoseStatus.taken),
            ),
    );
  }
}

// ---------------------------------------------------------------- up next

class _UpNext extends StatelessWidget {
  const _UpNext({required this.t});
  final TodaySummary t;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final dm = context.dm;
    if (t.upcoming.isEmpty) {
      return SurfaceCard(
        child: Row(children: [
          Icon(Icons.nightlight_round, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: Space.md),
          Expanded(child: Text(l.nothingLeftToday, style: theme.textTheme.bodyMedium)),
        ]),
      );
    }
    final items = t.upcoming.take(3).toList();
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(vertical: Space.sm),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const Divider(indent: 72, endIndent: Space.lg),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: Space.lg),
              leading: CategoryBadge(
                icon: iconFor(items[i].habit.category),
                palette: paletteFor(items[i].habit.category, dm),
                size: 40,
              ),
              title: Text(items[i].habit.name, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(items[i].spec.body, maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: Text(
                Habit.fmt(TimeOfDay.fromDateTime(items[i].at)),
                style: theme.textTheme.titleMedium?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
              ),
              onTap: () => HabitFlows.openHabit(context, items[i].habit),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- misc

class _QuoteCard extends StatelessWidget {
  const _QuoteCard({required this.quote});
  final String quote;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SurfaceCard(
      color: theme.colorScheme.tertiaryContainer,
      padding: const EdgeInsets.all(Space.xl - 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.format_quote_rounded, color: theme.colorScheme.onTertiaryContainer, size: 28),
          const SizedBox(width: Space.md),
          Expanded(
            child: Text(quote,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onTertiaryContainer,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                )),
          ),
        ],
      ),
    );
  }
}

class _QuickStartRow extends StatelessWidget {
  const _QuickStartRow({required this.l});
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    final dm = context.dm;
    final kinds = {
      QuickAddKind.water: (HabitCategory.water, l.qaWater),
      QuickAddKind.medicine: (HabitCategory.medicine, l.qaMedicine),
      QuickAddKind.meditation: (HabitCategory.meditation, l.qaMeditation),
      QuickAddKind.reading: (HabitCategory.reading, l.qaReading),
      QuickAddKind.exercise: (HabitCategory.exercise, l.qaExercise),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.page),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: Space.sm,
        runSpacing: Space.sm,
        children: [
          for (final e in kinds.entries)
            ActionChip(
              avatar: Icon(iconFor(e.value.$1), color: paletteFor(e.value.$1, dm).accent, size: 18),
              label: Text(e.value.$2),
              onPressed: () => HabitFlows.startQuickAdd(context, e.key),
            ),
        ],
      ),
    );
  }
}

class _TodaySkeleton extends StatelessWidget {
  const _TodaySkeleton();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.all(Space.page),
        child: Column(children: [
          Skeleton(height: 136, radius: Radii.lg + 4),
          SizedBox(height: Space.md),
          Row(children: [
            Expanded(child: Skeleton(height: 150, radius: Radii.lg)),
            SizedBox(width: Space.md),
            Expanded(child: Skeleton(height: 150, radius: Radii.lg)),
          ]),
          SizedBox(height: Space.md),
          Skeleton(height: 72, radius: Radii.lg),
        ]),
      );
}
