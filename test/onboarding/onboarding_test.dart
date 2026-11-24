import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:habit_tracker_nepali/core/db/app_database.dart';
import 'package:habit_tracker_nepali/core/reminders/reminder_service.dart';
import 'package:habit_tracker_nepali/core/reminders/reminder_spec.dart';
import 'package:habit_tracker_nepali/features/habits/data/habit_repository.dart';
import 'package:habit_tracker_nepali/features/onboarding/onboarding_logic.dart';
import 'package:habit_tracker_nepali/features/onboarding/onboarding_screen.dart';
import 'package:habit_tracker_nepali/l10n/app_localizations.dart';
import 'package:habit_tracker_nepali/models/habit.dart';
import 'package:habit_tracker_nepali/services/native_alarm.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeBackend implements AlarmBackend {
  final armed = <int>{};
  @override
  Future<void> schedule(ReminderSpec spec) async => armed.add(spec.id);
  @override
  Future<void> scheduleRaw({required int id, required DateTime at, required String title, required String body}) async =>
      armed.add(id);
  @override
  Future<void> cancel(int id) async => armed.remove(id);
  @override
  Future<void> enableLegacyCleanup() async {}
  @override
  Future<int> cancelLegacyPluginAlarms() async => 0;
  @override
  Future<bool> canScheduleExact() async => true;
  @override
  Future<void> openExactAlarmSettings() async {}
  @override
  Future<List<String>> drainDoseActions() async => const [];
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('OnboardingLogic', () {
    test('suggests up to three starters from goals, in priority order', () {
      expect(OnboardingLogic.suggest({OnboardingGoal.health}), [Starter.water, Starter.medicine]);
      expect(
        OnboardingLogic.suggest(OnboardingGoal.values.toSet()).length,
        maxStarters,
      );
      expect(OnboardingLogic.suggest({}), [Starter.water]);
    });

    test('builds category habits with chosen times and localized names', () {
      var n = 0;
      final habits = OnboardingLogic.buildHabits(
        {
          Starter.water: const TimeOfDay(hour: 8, minute: 0),
          Starter.read: const TimeOfDay(hour: 22, minute: 15),
          Starter.journal: const TimeOfDay(hour: 21, minute: 30),
        },
        {Starter.water: 'पानी पिउने', Starter.read: 'Read', Starter.journal: 'Reflect'},
        idGen: () => 'id${n++}',
      );
      expect(habits.map((h) => h.category),
          [HabitCategory.water, HabitCategory.reading, HabitCategory.generic]);
      expect(habits[0].name, 'पानी पिउने 💧');
      expect(habits[0].reminderTimes, waterTimes);
      expect(habits[1].reminderTimes, ['22:15']);
      expect(habits.every((h) => h.enabled), isTrue);
      expect(habits.map((h) => h.id).toSet().length, 3);
    });

    test('shown only to new users; upgrading users with habits skip it', () async {
      SharedPreferences.setMockInitialValues({});
      expect(await OnboardingLogic.isNeeded(const []), isTrue);
      final h = Habit(id: 'x', name: 'x', enabled: true, reminderHour: 8, reminderMinute: 0);
      expect(await OnboardingLogic.isNeeded([h]), isFalse);
      expect(await OnboardingLogic.isNeeded(const []), isFalse); // remembered
    });
  });

  group('ReminderService permission prompt', () {
    test('asked once, only after a reminder is actually armed', () async {
      SharedPreferences.setMockInitialValues({});
      var asked = 0;
      ReminderService.permissionRequester = () async => asked++;
      final svc = ReminderService(backend: _FakeBackend());

      await svc.syncHabit(Habit(id: 'off', name: 'off', enabled: false, reminderHour: 8, reminderMinute: 0));
      expect(asked, 0);
      await svc.syncHabit(Habit(id: 'a', name: 'a', enabled: true, reminderHour: 8, reminderMinute: 0));
      await svc.syncHabit(Habit(id: 'b', name: 'b', enabled: true, reminderHour: 9, reminderMinute: 0));
      expect(asked, 1);
      ReminderService.permissionRequester = null;
    });
  });

  testWidgets('onboarding: goals → starters → start creates habits and opens Today', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final db = AppDatabase(NativeDatabase.memory());
    AppDatabase.instance = db;
    final backend = _FakeBackend();
    ReminderService.instance = ReminderService(backend: backend);

    final router = GoRouter(initialLocation: '/onboarding', routes: [
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/today', builder: (_, __) => const Scaffold(body: Text('TODAY'))),
    ]);
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp.router(
        routerConfig: router,
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Small habits. Better days.'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Calm'));
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Calm suggests meditation + evening reflection, preselected.
    final meditate = tester.widget<CheckboxListTile>(find.widgetWithText(CheckboxListTile, 'Meditate 10 minutes'));
    expect(meditate.value, isTrue);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start my day'));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pumpAndSettle();

    expect(find.text('TODAY'), findsOneWidget);
    final saved = await tester.runAsync(() => HabitRepository(db).loadAll());
    expect(saved!.map((h) => h.category).toSet(), {HabitCategory.meditation, HabitCategory.generic});
    expect(backend.armed.length, 2); // one reminder each
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(OnboardingLogic.doneKey), isTrue);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
    await tester.runAsync(() => db.close());
  });

  testWidgets('onboarding: Skip finishes without creating habits', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final db = AppDatabase(NativeDatabase.memory());
    AppDatabase.instance = db;
    ReminderService.instance = ReminderService(backend: _FakeBackend());
    final router = GoRouter(initialLocation: '/onboarding', routes: [
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/today', builder: (_, __) => const Scaffold(body: Text('TODAY'))),
    ]);
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: const [AppLocalizations.delegate, GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate],
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Skip'));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pumpAndSettle();
    expect(find.text('TODAY'), findsOneWidget);
    expect(await tester.runAsync(() => HabitRepository(db).loadAll()), isEmpty);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
    await tester.runAsync(() => db.close());
  });
}
