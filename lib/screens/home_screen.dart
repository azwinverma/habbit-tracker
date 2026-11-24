import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app/providers.dart';
import '../core/reminders/reminder_service.dart';
import '../features/habits/presentation/habit_flows.dart';
import '../models/habit.dart';
import '../services/ad_service.dart';
import '../services/quote_service.dart';
import '../services/storage_service.dart';
import '../widgets/ad_banner.dart';
import '../widgets/habit_tile.dart';

/// Today tab: greeting + progress, quote, quick add, the user's habits.
/// Habits come from a live database stream, so changes made anywhere (Add
/// sheet, category screens) show up immediately.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _storage = StorageService();
  final _interstitial = InterstitialHelper();
  List<Habit> _habits = [];
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
    await _interstitial.load();
    final list = await _storage.loadHabits(); // also runs the one-time DB migration
    if (!mounted) return;
    setState(() => _habits = list);
    _sub = ref.read(habitRepositoryProvider).watchAll().listen(
      (l) {
        if (mounted) setState(() => _habits = l);
      },
      onError: (_) {}, // DB unavailable: keep the legacy-loaded list
    );
    // One coordinated pass: retire pre-2.0 alarms (first run only), re-arm
    // every habit's reminders from saved data, cancel deleted habits' alarms.
    await ReminderService.instance.startup(list);
    await _maybeAskForExactAlarms();
  }

  /// Android 12+: without "Alarms & reminders" access, reminders still fire
  /// but may be delayed by several minutes. Ask once, only if the user has
  /// reminders, with an explanation (never a bare system prompt).
  Future<void> _maybeAskForExactAlarms() async {
    if (_habits.every((h) => !h.enabled)) return;
    if (await ReminderService.instance.canScheduleExact()) return;
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('exact_alarm_prompt_shown') ?? false) return;
    await prefs.setBool('exact_alarm_prompt_shown', true);
    if (!mounted) return;
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('On-time reminders'),
        content: const Text(
          'To deliver medicine and habit reminders at the exact minute, '
          'DailyMantra needs the "Alarms & reminders" permission. Without it, '
          'reminders may arrive a few minutes late.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Not now')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Allow')),
        ],
      ),
    );
    if (go == true) {
      await ReminderService.instance.openExactAlarmSettings();
    }
  }

  Future<void> _refresh() async {
    final list = await _storage.loadHabits();
    if (mounted) setState(() => _habits = list);
  }

  bool _doneToday(Habit h) {
    final d = h.lastCompleted;
    if (d == null) return false;
    final n = DateTime.now();
    return d.year == n.year && d.month == n.month && d.day == n.day;
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final quote = QuoteService.quoteForDate(DateTime.now());
    final newCount = ref.watch(newContentCountProvider).valueOrNull ?? 0;
    final active = _habits.where((h) => h.enabled).toList();
    final done = active.where(_doneToday).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('DailyMantra'),
        actions: [
          IconButton(
            tooltip: newCount > 0 ? 'Discover ($newCount new)' : 'Discover',
            onPressed: () => context.push('/discover'),
            icon: Badge(
              isLabelVisible: newCount > 0,
              label: Text(newCount > 99 ? '99+' : '$newCount'),
              child: const Icon(Icons.explore_outlined),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          slivers: [
            // Greeting + today's progress
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_greeting(), style: theme.textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    if (active.isNotEmpty) ...[
                      Text('$done of ${active.length} done today', style: theme.textTheme.bodyMedium),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: active.isEmpty ? 0 : done / active.length,
                          minHeight: 8,
                          semanticsLabel: 'Today\'s progress',
                          semanticsValue: '$done of ${active.length}',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // Quote
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.format_quote),
                        const SizedBox(width: 8),
                        Expanded(child: Text(quote, style: theme.textTheme.titleMedium)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: AdBanner(placement: 'home_bottom', padding: EdgeInsets.only(bottom: 8)),
              ),
            ),
            // Quick add
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: Text('Quick Add', style: theme.textTheme.titleLarge),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final k = QuickAddKind.values[index];
                    return _GridTile(
                      title: k == QuickAddKind.custom ? 'Others' : k.label,
                      icon: k.icon,
                      onTap: () => HabitFlows.startQuickAdd(context, k),
                    );
                  },
                  childCount: QuickAddKind.values.length,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, mainAxisSpacing: 10, crossAxisSpacing: 10,
                ),
              ),
            ),
            // Habits
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                child: Text('Your Habits', style: theme.textTheme.titleLarge),
              ),
            ),
            _habits.isEmpty
                ? SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Start small: tap a tile above to add your first habit.'),
                            const SizedBox(height: 8),
                            FilledButton.icon(
                              onPressed: () => HabitFlows.startQuickAdd(context, QuickAddKind.custom),
                              icon: const Icon(Icons.add),
                              label: const Text('Add a habit'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : SliverList.separated(
                    itemCount: _habits.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 4),
                    itemBuilder: (c, i) {
                      final h = _habits[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: HabitTile(
                          habit: h,
                          onToggleComplete: () => HabitFlows.toggleToday(h),
                          onOpen: h.category == HabitCategory.generic
                              ? null
                              : () => HabitFlows.openHabit(context, h),
                          onEdit: () => HabitFlows.editGeneric(context, h),
                          onDelete: () => HabitFlows.delete(h),
                        ),
                      );
                    },
                  ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}

class _GridTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  const _GridTile({required this.title, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              decoration: BoxDecoration(color: theme.colorScheme.surface, shape: BoxShape.circle),
              padding: const EdgeInsets.all(10),
              child: Icon(icon, size: 28, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 6),
            Text(title,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
