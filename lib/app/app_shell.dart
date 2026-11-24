import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/habits/presentation/habit_flows.dart';
import 'providers.dart';
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
          NavigationDestination(icon: const Icon(Icons.today_outlined), selectedIcon: const Icon(Icons.today), label: l.navToday),
          NavigationDestination(icon: const Icon(Icons.event_note_outlined), selectedIcon: const Icon(Icons.event_note), label: l.navPlan),
          NavigationDestination(icon: const Icon(Icons.add_circle_outline, size: 32), label: l.navAdd),
          NavigationDestination(icon: const Icon(Icons.insights_outlined), selectedIcon: const Icon(Icons.insights), label: l.navInsights),
          NavigationDestination(icon: const Icon(Icons.person_outline), selectedIcon: const Icon(Icons.person), label: l.navYou),
        ],
      ),
    );
  }
}

class _AddSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.addSheetTitle, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            for (final k in QuickAddKind.values)
              ListTile(
                leading: Icon(k.icon, color: theme.colorScheme.primary),
                title: Text(k.localized(l)),
                onTap: () => Navigator.pop(context, k),
              ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.explore_outlined, color: theme.colorScheme.primary),
              title: Text(l.addBrowseContent),
              onTap: () => Navigator.pop(context, 'discover'),
            ),
          ],
        ),
      ),
    );
  }
}
