import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/habits/presentation/habit_flows.dart';
import 'providers.dart';

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
        destinations: const [
          NavigationDestination(icon: Icon(Icons.today_outlined), selectedIcon: Icon(Icons.today), label: 'Today'),
          NavigationDestination(icon: Icon(Icons.event_note_outlined), selectedIcon: Icon(Icons.event_note), label: 'Plan'),
          NavigationDestination(icon: Icon(Icons.add_circle_outline, size: 32), label: 'Add'),
          NavigationDestination(icon: Icon(Icons.insights_outlined), selectedIcon: Icon(Icons.insights), label: 'Insights'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'You'),
        ],
      ),
    );
  }
}

class _AddSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            for (final k in QuickAddKind.values)
              ListTile(
                leading: Icon(k.icon, color: theme.colorScheme.primary),
                title: Text(k.label),
                onTap: () => Navigator.pop(context, k),
              ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.explore_outlined, color: theme.colorScheme.primary),
              title: const Text('Browse free books, sounds & exercises'),
              onTap: () => Navigator.pop(context, 'discover'),
            ),
          ],
        ),
      ),
    );
  }
}
