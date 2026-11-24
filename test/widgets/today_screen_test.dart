import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker_nepali/app/providers.dart';
import 'package:habit_tracker_nepali/app/theme.dart';
import 'package:habit_tracker_nepali/core/db/app_database.dart';
import 'package:habit_tracker_nepali/core/reminders/reminder_service.dart';
import 'package:habit_tracker_nepali/features/habits/data/habit_repository.dart';
import 'package:habit_tracker_nepali/features/habits/data/legacy_habit_migrator.dart';
import 'package:habit_tracker_nepali/l10n/app_localizations.dart';
import 'package:habit_tracker_nepali/models/habit.dart';
import 'package:habit_tracker_nepali/screens/home_screen.dart';
import 'package:habit_tracker_nepali/services/ad_service.dart';
import 'package:habit_tracker_nepali/services/storage_service.dart';
import 'package:habit_tracker_nepali/widgets/habit_tile.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../reminders/reminder_service_test.dart' show FakeBackend;

/// Sample data used by the Today test and the screenshot harness.
List<Habit> sampleHabits(DateTime now) {
  final today = HabitRepository.ymd(now);
  return [
    Habit(id: 'w', name: 'Drink water', enabled: true, reminderHour: 8, reminderMinute: 0,
        reminderTimes: ['08:00', '11:00', '14:00', '17:00', '20:00'], category: HabitCategory.water,
        waterTarget: 8, waterCompleted: 3, waterLastDate: today, streak: 4),
    Habit(id: 'm', name: 'Metformin', enabled: true, reminderHour: 0, reminderMinute: 0,
        reminderTimes: ['00:00', '23:59'], category: HabitCategory.medicine, medicineName: 'Metformin',
        medicineDose: '500 mg', medicineStartDate: today, medicineEndDate: today),
    Habit(id: 'e', name: 'Morning walk', enabled: true, reminderHour: 7, reminderMinute: 0,
        reminderTimes: ['23:58'], category: HabitCategory.exercise, exerciseGoalMin: 30,
        exerciseTodayMin: 12, exerciseLastDate: today, stepsToday: 4200, stepsLastDate: today),
    Habit(id: 'j', name: 'Evening journal', enabled: true, reminderHour: 21, reminderMinute: 30,
        reminderTimes: ['21:30'], category: HabitCategory.generic, lastCompleted: now, streak: 6),
  ];
}

Widget wrap(AppDatabase db, Widget child,
        {Brightness b = Brightness.light, Locale locale = const Locale('en'), List<Override> overrides = const []}) =>
    ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(db), ...overrides],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildTheme(b),
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: child,
      ),
    );

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets('Today shows real progress, bento tiles, and logs water with one tap', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.6;
    addTearDown(tester.view.reset);
    AdService.enabled = false;
    SharedPreferences.setMockInitialValues({});
    LegacyHabitMigrator.resetForTest();
    final db = AppDatabase(NativeDatabase.memory());
    AppDatabase.instance = db;
    ReminderService.instance = ReminderService(backend: FakeBackend());
    final now = DateTime.now();
    await tester.runAsync(() => StorageService().saveHabits(sampleHabits(now))); // runs the migration first

    await tester.pumpWidget(wrap(db, const HomeScreen()));
    for (var i = 0; i < 3; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 150)));
      await tester.pump();
    }

    expect(find.text('1 of 4 done today'), findsOneWidget); // journal done
    expect(find.text('3 of 8 glasses'), findsOneWidget);
    expect(find.text('6-day streak'), findsOneWidget);
    // The habit list sits below the fold; "Up next" content depends on the clock.
    await tester.scrollUntilVisible(find.widgetWithText(HabitTile, 'Evening journal'), 400,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('Evening journal'), findsWidgets);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 4000));
    await tester.pump();

    await tester.tap(find.byTooltip('Add a glass'));
    for (var i = 0; i < 3; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 150)));
      await tester.pump();
    }
    expect(find.text('4 of 8 glasses'), findsOneWidget);
    final saved = await tester.runAsync(() => HabitRepository(db).loadAll());
    expect(saved!.firstWhere((h) => h.id == 'w').waterCompleted, 4);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
    await tester.runAsync(() => db.close());
  });
}
