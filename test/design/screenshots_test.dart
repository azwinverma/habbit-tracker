// Visual review harness (not part of the normal suite).
//
//   SHOTS=1 flutter test --update-goldens test/design/screenshots_test.dart
//
// Renders key screens with the real brand fonts in light, dark and Nepali
// and writes PNGs to test/design/screenshots/ (git-ignored).
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker_nepali/core/db/app_database.dart';
import 'package:habit_tracker_nepali/core/reminders/reminder_service.dart';
import 'package:habit_tracker_nepali/features/habits/data/habit_repository.dart';
import 'package:habit_tracker_nepali/features/habits/data/legacy_habit_migrator.dart';
import 'package:habit_tracker_nepali/features/insights/insights_screen.dart';
import 'package:habit_tracker_nepali/features/plan/plan_screen.dart';
import 'package:habit_tracker_nepali/features/profile/profile_screen.dart';
import 'package:habit_tracker_nepali/app/providers.dart';
import 'package:habit_tracker_nepali/screens/home_screen.dart';
import 'package:habit_tracker_nepali/screens/medicine_screen.dart';
import 'package:habit_tracker_nepali/services/ad_service.dart';
import 'package:habit_tracker_nepali/services/storage_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../reminders/reminder_service_test.dart' show FakeBackend;
import '../widgets/today_screen_test.dart' show sampleHabits, wrap;

Future<void> _loadFonts() async {
  Future<ByteData> f(String p) async => ByteData.view((await File(p).readAsBytes()).buffer);
  final jakarta = FontLoader('PlusJakartaSans');
  for (final w in [400, 500, 600, 700, 800]) {
    jakarta.addFont(f('assets/fonts/PlusJakartaSans-$w.ttf'));
  }
  await jakarta.load();
  final noto = FontLoader('NotoSansDevanagari');
  for (final w in [400, 500, 600, 700]) {
    noto.addFont(f('assets/fonts/NotoSansDevanagari-$w.ttf'));
  }
  await noto.load();
  final flutterRoot = Platform.environment['FLUTTER_ROOT'] ??
      File(Platform.resolvedExecutable).parent.parent.parent.parent.parent.path;
  final icons = FontLoader('MaterialIcons')
    ..addFont(f('$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf'));
  await icons.load();
}

void main() {
  final enabled = Platform.environment['SHOTS'] == '1';
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  setUpAll(() async {
    if (enabled) await _loadFonts();
  });

  Future<void> shot(WidgetTester tester, String name, Widget Function(AppDatabase db) screen,
      {Brightness b = Brightness.light, Locale locale = const Locale('en'), double height = 2400,
      Future<void> Function(WidgetTester)? after, List<Override> overrides = const []}) async {
    tester.view.physicalSize = Size(1080, height);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    AdService.enabled = false;
    SharedPreferences.setMockInitialValues({});
    LegacyHabitMigrator.resetForTest();
    final db = AppDatabase(NativeDatabase.memory());
    AppDatabase.instance = db;
    ReminderService.instance = ReminderService(backend: FakeBackend());
    final now = DateTime.now();
    await tester.runAsync(() async {
      final habits = sampleHabits(now);
      final storage = StorageService();
      // A week of history for Insights.
      for (var i = 6; i >= 0; i--) {
        final d = DateTime(now.year, now.month, now.day - i);
        habits[0]
          ..waterLastDate = HabitRepository.ymd(d)
          ..waterCompleted = [5, 7, 4, 8, 6, 8, 3][6 - i];
        habits[2]
          ..exerciseLastDate = HabitRepository.ymd(d)
          ..exerciseTodayMin = [20, 0, 35, 15, 30, 0, 12][6 - i];
        await storage.saveHabits(habits);
      }
    });
    await tester.pumpWidget(wrap(db, screen(db), b: b, locale: locale, overrides: overrides));
    for (var i = 0; i < 4; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 150)));
      await tester.pump(const Duration(milliseconds: 600));
    }
    if (after != null) await after(tester);
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('screenshots/$name.png'));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
    await tester.runAsync(() => db.close());
  }

  final skip = !enabled;
  testWidgets('today light', (t) => shot(t, 'today_light', (_) => const HomeScreen(), height: 3000), skip: skip);
  testWidgets('today dark', (t) => shot(t, 'today_dark', (_) => const HomeScreen(), b: Brightness.dark, height: 3000), skip: skip);
  testWidgets('today nepali', (t) => shot(t, 'today_ne', (_) => const HomeScreen(), locale: const Locale('ne'), height: 3000), skip: skip);
  testWidgets('insights', (t) => shot(t, 'insights_light', (_) => const InsightsScreen(), height: 3200), skip: skip);
  testWidgets('insights dark', (t) => shot(t, 'insights_dark', (_) => const InsightsScreen(), b: Brightness.dark, height: 3200), skip: skip);
  // Plan reads platform permission state; pin it for screenshots.
  final pinned = [
    exactAlarmAllowedProvider.overrideWith((ref) async => true),
    notificationsEnabledProvider.overrideWith((ref) async => true),
  ];
  testWidgets('plan', (t) => shot(t, 'plan_light', (_) => const PlanScreen(), overrides: pinned), skip: skip);
  testWidgets('you', (t) => shot(t, 'you_light', (_) => const ProfileScreen(), height: 3600), skip: skip);
  testWidgets('medicine', (t) => shot(t, 'medicine_light',
      (_) => MedicineScreen(habit: sampleHabits(DateTime.now())[1]), height: 3200), skip: skip);
}

