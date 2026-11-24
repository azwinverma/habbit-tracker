// lib/screens/splash_screen.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Your app screens/services
import 'package:go_router/go_router.dart';
import '../features/onboarding/onboarding_logic.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import '../services/ad_service.dart'; // contains InterstitialHelper (used in your HomeScreen)

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  String? _error;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    // Lock to portrait on splash for a cleaner look (optional).
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    _ac = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = CurvedAnimation(parent: _ac, curve: Curves.easeOutCubic);
    _scale = Tween<double>(begin: 0.9, end: 1.0)
        .animate(CurvedAnimation(parent: _ac, curve: Curves.easeOutBack));

    // Kick off animation quickly, then init subsystems.
    _ac.forward();
    // Small delay so users see the animation even on fast devices.
    Future.delayed(const Duration(milliseconds: 300), _init);
  }

  Future<void> _init() async {
    try {
      // 1) Initialize notifications (channels + tz + android 13+ permission).
await NotificationService.initializeForeground();
await NotificationService.initializeBackground();
      // Notification permission is requested in context, when the first
      // reminder is created (ReminderService.permissionRequester).

      // 2) Load habits (also runs the one-time DB migration) and decide
      //    whether this is a first run that needs onboarding.
      var needsOnboarding = false;
      try {
        final habits = await StorageService().loadHabits();
        needsOnboarding = await OnboardingLogic.isNeeded(habits);
      } catch (_) {
        // Storage problems must never block app start.
      }

      // 3) Preload your interstitial ads helper (optional but matches your app’s pattern).
      try {
        await InterstitialHelper().load();
      } catch (_) {
        // Ads failing to preload shouldn't block app start.
      }

      // 4) Keep splash visible just a touch for brand feel.
      await Future.delayed(const Duration(milliseconds: 500));

      // 5) Navigate to Home (guard from double navigation).
      if (mounted && !_navigated) {
        _navigated = true;
        context.go(needsOnboarding ? '/onboarding' : '/today');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  @override
  void dispose() {
    _ac.dispose();
    // Restore orientation to app default (optional).
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Prefer dedicated light/dark brand marks; fall back to generic icon.
    final AssetImage? brandImage = _tryAsset(
      isDark
          ? 'assets/branding/daily_mantra_logo_dark.png'
          : 'assets/branding/daily_mantra_logo_light.png',
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            // Soft gradient background
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      const Color(0xFF0F1221),
                      const Color(0xFF1A1F36),
                    ]
                  : [
                      const Color(0xFFF9FAFB),
                      const Color(0xFFEFF6FF),
                    ],
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                // Centerpiece: logo + title
                Center(
                  child: FadeTransition(
                    opacity: _fade,
                    child: ScaleTransition(
                      scale: _scale,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                              color: isDark
                                  ? const Color(0xFF1E2238)
                                  : Colors.white,
                            ),
                            padding: const EdgeInsets.all(18),
                            child: ClipOval(
                              child: brandImage != null
                                  ? Image(
                                      image: brandImage,
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) => Icon(
                                        Icons.self_improvement,
                                        size: 60,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                    )
                                  : Icon(
                                      Icons.self_improvement,
                                      size: 60,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Daily Mantra',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.2,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Habits • Mindfulness • Health',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.color
                                      ?.withValues(alpha: 0.75),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Bottom progress / error + retry
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 28,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_error == null) ...[
                          LinearProgressIndicator(
                            minHeight: 4,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Preparing your experience…',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ] else ...[
                          Text(
                            'Startup error:\n$_error',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: Colors.redAccent),
                          ),
                          const SizedBox(height: 8),
                          FilledButton.icon(
                            onPressed: () {
                              setState(() => _error = null);
                              _init();
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          )
                        ],
                        if (kDebugMode) ...[
                          const SizedBox(height: 6),
                          Text(
                            'DEBUG build',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: 0.8),
                                ),
                          ),
                        ]
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Try creating an AssetImage; return null if the asset likely doesn't exist.
  AssetImage? _tryAsset(String path) {
    // This heuristic avoids a hard crash if the asset isn't listed in pubspec.
    try {
      return AssetImage(path);
    } catch (_) {
      return null;
    }
  }
}
