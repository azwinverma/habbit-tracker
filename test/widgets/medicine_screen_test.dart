import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker_nepali/app/providers.dart';
import 'package:habit_tracker_nepali/core/db/app_database.dart';
import 'package:habit_tracker_nepali/features/habits/data/habit_repository.dart';
import 'package:habit_tracker_nepali/features/medicine/data/dose_log_repository.dart';
import 'package:habit_tracker_nepali/l10n/app_localizations.dart';
import 'package:habit_tracker_nepali/models/habit.dart';
import 'package:habit_tracker_nepali/screens/medicine_screen.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump();
    await tester.pump();
  }

  testWidgets('today\'s doses: mark Taken, then Undo; no ads on screen', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.6;
    addTearDown(tester.view.reset);

    final db = AppDatabase(NativeDatabase.memory());
    final now = DateTime.now();
    final today = HabitRepository.ymd(now);
    final h = Habit(
      id: 'm1', name: 'Metformin', enabled: true, reminderHour: 0, reminderMinute: 0,
      reminderTimes: ['00:00', '23:59'], category: HabitCategory.medicine,
      medicineName: 'Metformin', medicineDose: '500 mg',
      medicineStartDate: today, medicineEndDate: today,
    );
    await tester.runAsync(() => HabitRepository(db).saveAll([h]));

    await tester.pumpWidget(ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: MedicineScreen(habit: h),
      ),
    ));
    await settle(tester);

    expect(find.text("Today's doses"), findsOneWidget);
    expect(find.text('00:00 · Not yet'), findsOneWidget);
    expect(find.text('23:59 · Not yet'), findsOneWidget);
    expect(find.text('No doses were due in the last 7 days.'), findsNothing); // 00:00 is due
    expect(find.text('Last 7 days: 0 of 1 doses taken'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Taken').first);
    await settle(tester);
    expect(find.text('00:00 · Taken'), findsOneWidget);
    expect(find.text('Last 7 days: 1 of 1 doses taken'), findsOneWidget);
    final stored = await tester.runAsync(() => DoseLogRepository(db).statuses('m1', fromDay: today, toDay: today));
    expect(stored, {today: {'00:00': DoseStatus.taken}});

    await tester.tap(find.widgetWithText(TextButton, 'Undo'));
    await settle(tester);
    expect(find.text('00:00 · Not yet'), findsOneWidget);

    expect(find.byWidgetPredicate((w) => w.runtimeType.toString() == 'AdBanner'), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
    await tester.runAsync(() => db.close());
  });
}
