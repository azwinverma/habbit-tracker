import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/habits/presentation/habit_flows.dart';
import '../services/native_alarm.dart';
import '../design/components.dart';
import '../models/habit.dart';
import 'providers.dart';
import 'theme.dart';
import '../l10n/app_localizations.dart';

/// Bottom navigation: Today | Plan | Add | Insights | You.
/// "Add" opens a sheet instead of a page (blueprint §3).
///
/// Also the trigger point for content refresh: on first show and every time
/// the app returns to the foreground, new content is pulled from the free
/// providers (each throttled to its own refresh interval).
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> with WidgetsBindingObserver {
  // nav index -> branch index (Add has no branch)
  static const _branchForNav = [0, 1, -1, 2, 3];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncContent());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _syncContent();
  }

  void _syncContent() {
    // Fire-and-forget; works offline (keeps cached catalogue).
    ref.read(contentSyncServiceProvider).syncIfStale();
    // Doses marked "Taken" from a notification while the app was closed.
    ref.read(doseLogRepositoryProvider).importNativeActions(NativeAlarmBackend());
  }

  int get _navIndex {
    final b = widget.shell.currentIndex;
    return _branchForNav.indexOf(b);
  }

  Future<void> _openAddSheet() async {
    final choice = await showModalBottomSheet<Object>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (ctx) => _AddSheet(),
    );
    if (!mounted || choice == null) return;
    if (choice is QuickAddKind) {
      await HabitFlows.startQuickAdd(context, choice);
    } else if (choice == 'discover') {
      context.push('/discover');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: widget.shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navIndex,
        onDestinationSelected: (i) {
          final branch = _branchForNav[i];
          if (branch < 0) {
            _openAddSheet();
          } else {
            widget.shell.goBranch(branch, initialLocation: branch == widget.shell.currentIndex);
          }
        },
        destinations: [
          NavigationDestination(icon: const Icon(Icons.wb_sunny_outlined), selectedIcon: const Icon(Icons.wb_sunny_rounded), label: l.navToday),
          NavigationDestination(icon: const Icon(Icons.calendar_month_outlined), selectedIcon: const Icon(Icons.calendar_month_rounded), label: l.navPlan),
          NavigationDestination(icon: const _AddNavIcon(), label: l.navAdd),
          NavigationDestination(icon: const Icon(Icons.insights_outlined), selectedIcon: const Icon(Icons.insights_rounded), label: l.navInsights),
          NavigationDestination(icon: const Icon(Icons.person_outline_rounded), selectedIcon: const Icon(Icons.person_rounded), label: l.navYou),
        ],
      ),
    );
  }
}

/// The centre "Add" destination: a filled brand pill so it reads as the
/// primary action without a floating button.
class _AddNavIcon extends StatelessWidget {
  const _AddNavIcon();

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return Container(
      width: 52,
      height: 34,
      decoration: BoxDecoration(color: s.primary, borderRadius: BorderRadius.circular(Radii.pill)),
      child: Icon(Icons.add_rounded, color: s.onPrimary, size: 26),
    );
  }
}

class _AddSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final dm = context.dm;
    String hint(QuickAddKind k) => switch (k) {
          QuickAddKind.medicine => l.addHintMedicine,
          QuickAddKind.water => l.addHintWater,
          QuickAddKind.meditation => l.addHintMeditation,
          QuickAddKind.reading => l.addHintReading,
          QuickAddKind.exercise => l.addHintExercise,
          QuickAddKind.custom => l.addHintCustom,
        };
    HabitCategory cat(QuickAddKind k) => switch (k) {
          QuickAddKind.medicine => HabitCategory.medicine,
          QuickAddKind.water => HabitCategory.water,
          QuickAddKind.meditation => HabitCategory.meditation,
          QuickAddKind.reading => HabitCategory.reading,
          QuickAddKind.exercise => HabitCategory.exercise,
          QuickAddKind.custom => HabitCategory.generic,
        };
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(Space.page, 0, Space.page, Space.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.addSheetTitle, style: theme.textTheme.headlineSmall),
            const SizedBox(height: Space.lg),
            LayoutBuilder(builder: (context, c) {
              final cols = c.maxWidth >= 560 ? 3 : 2;
              final w = (c.maxWidth - Space.md * (cols - 1)) / cols;
              return Wrap(
                spacing: Space.md,
                runSpacing: Space.md,
                children: [
                  for (final k in QuickAddKind.values)
                    SizedBox(
                      width: w,
                      child: SurfaceCard(
                        onTap: () => Navigator.pop(context, k),
                        semanticLabel: '${k.localized(l)}. ${hint(k)}',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CategoryBadge(icon: iconFor(cat(k)), palette: paletteFor(cat(k), dm)),
                            const SizedBox(height: Space.md),
                            ExcludeSemantics(child: Text(k.localized(l), style: theme.textTheme.titleMedium)),
                            const SizedBox(height: 2),
                            ExcludeSemantics(
                              child: Text(hint(k), style: theme.textTheme.bodySmall, maxLines: 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            }),
            const SizedBox(height: Space.md),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: Space.sm),
              leading: Icon(Icons.explore_outlined, color: theme.colorScheme.primary),
              title: Text(l.addBrowseContent),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.pop(context, 'discover'),
            ),
          ],
        ),
      ),
    );
  }
}
