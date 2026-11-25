// lib/screens/splash_screen.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../design/backdrop.dart';
import '../l10n/app_localizations.dart';
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

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _ac;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  String? _error;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    // Lock to portrait on splash for a cleaner look (optional).
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

    _ac = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fade = CurvedAnimation(parent: _ac, curve: Curves.easeOutCubic);
    _scale = Tween<double>(begin: 0.9, end: 1.0).animate(CurvedAnimation(parent: _ac, curve: Curves.easeOutBack));

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
      // Never blocks start-up (consent + SDK init can take a few seconds).
      unawaited(InterstitialHelper().load().catchError((_) {}));

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
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    // Brand splash: Deep Teal tonal backdrop, Mint mark tile, white text.
    const bg = BrandColors.deepTeal;
    const fg = Colors.white;
    final brandImage = _tryAsset('assets/branding/daily_mantra_logo_light.png');

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: bg,
        body: SplashBackdrop(
          child: SafeArea(
            child: Stack(
              children: [
                Center(
                  child: FadeTransition(
                    opacity: _fade,
                    child: ScaleTransition(
                      scale: _scale,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 104,
                            height: 104,
                            decoration: BoxDecoration(color: BrandColors.mint, borderRadius: BorderRadius.circular(32)),
                            padding: const EdgeInsets.all(18),
                            child:
                                brandImage != null
                                    ? Image(
                                      image: brandImage,
                                      fit: BoxFit.contain,
                                      errorBuilder:
                                          (_, __, ___) =>
                                              const Icon(Icons.spa_rounded, size: 56, color: BrandColors.deepTeal),
                                    )
                                    : const Icon(Icons.spa_rounded, size: 56, color: BrandColors.deepTeal),
                          ),
                          const SizedBox(height: Space.xl),
                          Text(
                            l.appTitle,
                            style: theme.textTheme.headlineLarge?.copyWith(color: fg, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: Space.sm),
                          Text(
                            l.tagline,
                            style: theme.textTheme.bodyLarge?.copyWith(color: fg.withValues(alpha: 0.85)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: Space.xxl,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_error == null) ...[
                          LinearProgressIndicator(
                            minHeight: 4,
                            color: BrandColors.mint,
                            backgroundColor: fg.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(Radii.pill),
                          ),
                          const SizedBox(height: Space.md),
                          Text(
                            l.splashPreparing,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(color: fg.withValues(alpha: 0.8)),
                          ),
                        ] else ...[
                          Text(
                            l.splashError,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(color: fg),
                          ),
                          if (kDebugMode)
                            Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall?.copyWith(color: fg.withValues(alpha: 0.7)),
                            ),
                          const SizedBox(height: Space.md),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: BrandColors.mint,
                              foregroundColor: BrandColors.ink,
                            ),
                            onPressed: () {
                              setState(() => _error = null);
                              _init();
                            },
                            icon: const Icon(Icons.refresh_rounded),
                            label: Text(l.retry),
                          ),
                        ],
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
