import 'package:go_router/go_router.dart';

import '../features/content/presentation/discover_screen.dart';
import '../features/insights/insights_screen.dart';
import '../features/plan/plan_screen.dart';
import '../features/profile/profile_screen.dart';
import '../screens/home_screen.dart';
import '../screens/splash_screen.dart';
import 'app_shell.dart';

GoRouter buildRouter() => GoRouter(
      initialLocation: '/splash',
      routes: [
        GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) => AppShell(shell: shell),
          branches: [
            StatefulShellBranch(routes: [GoRoute(path: '/today', builder: (_, __) => const HomeScreen())]),
            StatefulShellBranch(routes: [GoRoute(path: '/plan', builder: (_, __) => const PlanScreen())]),
            StatefulShellBranch(routes: [GoRoute(path: '/insights', builder: (_, __) => const InsightsScreen())]),
            StatefulShellBranch(routes: [GoRoute(path: '/you', builder: (_, __) => const ProfileScreen())]),
          ],
        ),
        // Full-screen, above the bottom navigation.
        GoRoute(path: '/discover', builder: (_, __) => const DiscoverScreen()),
      ],
    );
