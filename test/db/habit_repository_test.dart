import 'dart:convert';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker_nepali/core/db/app_database.dart';
import 'package:habit_tracker_nepali/features/habits/data/habit_repository.dart';
import 'package:habit_tracker_nepali/features/habits/data/legacy_habit_migrator.dart';
import 'package:habit_tracker_nepali/models/habit.dart';
import 'package:habit_tracker_nepali/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Realistic v1.0.0 records, one per category, using every field screens write.
List<Map<String, dynamic>> legacyFixture() => [
      {
        'id': '1730000000000000123', 'name': 'Metformin 💊', 'enabled': true,
        'reminderHour': 8, 'reminderMinute': 0, 'reminderTimes': ['08:00', '20:00'],
        'category': 'medicine', 'streak': 4, 'lastCompleted': '2026-11-23T08:05:00.000',
        'medicineName': 'Metformin', 'medicineDose': '500mg', 'medicineNotes': 'after food',
        'medicineStartDate': '2026-11-01', 'medicineEndDate': '2026-12-31',
      },
      {
        'id': '1730000000000000456', 'name': 'Drink Water 💧', 'enabled': true,
        'reminderHour': 8, 'reminderMinute': 0,
        'reminderTimes': ['08:00', '10:00', '12:00', '14:00', '16:00', '18:00'],
        'category': 'water', 'streak': 0, 'lastCompleted': null,
        'waterTarget': 8, 'waterCompleted': 5, 'waterLastDate': '2026-11-23',
      },
      {
        'id': '1730000000000000789', 'name': 'Meditation 🧘', 'enabled': false,
        'reminderHour': 6, 'reminderMinute': 30, 'reminderTimes': ['06:30', '20:00'],
        'category': 'meditation', 'streak': 0, 'lastCompleted': null,
        'meditationGoalMin': 10, 'meditationTodayMin': 15, 'meditationLastDate': '2026-11-22',
      },
      {
        'id': '1730000000000000999', 'name': 'Exercise 💪', 'enabled': true,
        'reminderHour': 7, 'reminderMinute': 0, 'reminderTimes': ['07:00'],
        'category': 'exercise', 'streak': 0, 'lastCompleted': null,
        'exerciseGoalMin': 30, 'exerciseTodayMin': 20, 'exerciseLastDate': '2026-11-23',
        'stepsGoal': 8000, 'stepsToday': 3500, 'stepsLastDate': '2026-11-23',
        'officeWalkEveryMin': 60, 'officeStretchEveryMin': 120,
        'exerciseScheduleJson': '{"Mon":[{"name":"Squats","bodyPart":"Legs","level":"Easy"}]}',
        'exerciseMilestonesJson': '[{"title":"First 5k","done":false}]',
      },
      {
        'id': '1730000000000001000', 'name': 'Reading 📖', 'enabled': true,
        'reminderHour': 21, 'reminderMinute': 0, 'reminderTimes': [],
        'category': 'reading', 'streak': 2, 'lastCompleted': '2026-11-22T21:30:00.000',
        'oneTimeReminders': ['2026-12-01T07:00:00.000'],
      },
      {
        'id': '1730000000000001111', 'name': 'Journal', 'enabled': true,
        'reminderHour': 22, 'reminderMinute': 15, 'reminderTimes': [],
        'category': 'generic', 'streak': 0, 'lastCompleted': null,
      },
    ];

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late HabitRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = HabitRepository(db);
    LegacyHabitMigrator.resetForTest();
  });
  tearDown(() => db.close());

  group('HabitRepository', () {
    test('round-trips every legacy field losslessly', () async {
      final input = legacyFixture().map(Habit.fromJson).toList();
      await repo.saveAll(input);
      final out = await repo.loadAll();
      expect(out.map((h) => h.toJson()).toList(), input.map((h) => h.toJson()).toList());
    });

    test('keeps list order', () async {
      final input = legacyFixture().map(Habit.fromJson).toList().reversed.toList();
      await repo.saveAll(input);
      expect((await repo.loadAll()).map((h) => h.id), input.map((h) => h.id));
    });

    test('daily counters accumulate as history; loader returns the latest day', () async {
      final water = Habit.fromJson(legacyFixture()[1]);
      await repo.saveAll([water]);
      water
        ..waterLastDate = '2026-11-24'
        ..waterCompleted = 2;
      await repo.saveAll([water]);

      final loaded = (await repo.loadAll()).single;
      expect(loaded.waterLastDate, '2026-11-24');
      expect(loaded.waterCompleted, 2);

      final totals = await repo.dailyTotals(fromDay: '2026-11-20', toDay: '2026-11-30');
      expect(totals[HabitMetric.waterGlasses], {'2026-11-23': 5, '2026-11-24': 2});
    });

    test('same day saved twice updates instead of duplicating', () async {
      final water = Habit.fromJson(legacyFixture()[1]);
      await repo.saveAll([water]);
      water.waterCompleted = 7;
      await repo.saveAll([water]);
      final totals = await repo.dailyTotals(fromDay: '2026-11-23', toDay: '2026-11-23');
      expect(totals[HabitMetric.waterGlasses], {'2026-11-23': 7});
    });

    test('removing a habit from the list deletes it with settings and history', () async {
      await repo.saveAll(legacyFixture().map(Habit.fromJson).toList());
      await repo.saveAll([Habit.fromJson(legacyFixture()[5])]);
      expect((await repo.loadAll()).single.name, 'Journal');
      expect(await db.select(db.habitLogs).get(), isEmpty);
      expect(await db.select(db.medicineDetails).get(), isEmpty);
      expect(await db.select(db.exerciseSettings).get(), isEmpty);
    });

    test('clearing medicine end date is persisted', () async {
      final med = Habit.fromJson(legacyFixture()[0]);
      await repo.saveAll([med]);
      med.medicineEndDate = null;
      await repo.saveAll([med]);
      expect((await repo.loadAll()).single.medicineEndDate, isNull);
    });

    test('watchAll emits after a save', () async {
      final emissions = <int>[];
      final sub = repo.watchAll().listen((l) => emissions.add(l.length));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await repo.saveAll(legacyFixture().map(Habit.fromJson).toList());
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await sub.cancel();
      expect(emissions.first, 0);
      expect(emissions.last, 6);
    });
  });

  group('LegacyHabitMigrator', () {
    test('imports habits_v1 exactly and leaves the JSON untouched', () async {
      final raw = jsonEncode(legacyFixture());
      SharedPreferences.setMockInitialValues({'habits_v1': raw});

      await LegacyHabitMigrator.ensureMigrated(db);

      final out = await repo.loadAll();
      expect(out.map((h) => h.toJson()).toList(),
          legacyFixture().map((j) => Habit.fromJson(j).toJson()).toList());
      expect(await db.getMeta(LegacyHabitMigrator.doneFlag), isNotNull);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('habits_v1'), raw);
    });

    test('runs only once (does not resurrect habits deleted after migration)', () async {
      SharedPreferences.setMockInitialValues({'habits_v1': jsonEncode(legacyFixture())});
      await LegacyHabitMigrator.ensureMigrated(db);
      await repo.saveAll([]);
      LegacyHabitMigrator.resetForTest();
      await LegacyHabitMigrator.ensureMigrated(db);
      expect(await repo.loadAll(), isEmpty);
    });

    test('fresh install: nothing to import, flag set', () async {
      SharedPreferences.setMockInitialValues({});
      await LegacyHabitMigrator.ensureMigrated(db);
      expect(await repo.loadAll(), isEmpty);
      expect(await db.getMeta(LegacyHabitMigrator.doneFlag), isNotNull);
    });

    test('duplicate ids in legacy JSON are de-duplicated, migration succeeds', () async {
      final dup = [...legacyFixture(), {...legacyFixture()[5], 'name': 'Journal (newer)'}];
      SharedPreferences.setMockInitialValues({'habits_v1': jsonEncode(dup)});
      await LegacyHabitMigrator.ensureMigrated(db);
      final out = await repo.loadAll();
      expect(out.length, 6);
      expect(out.firstWhere((h) => h.id == '1730000000000001111').name, 'Journal (newer)');
    });

    test('corrupt JSON: no partial import, no flag, retried later', () async {
      SharedPreferences.setMockInitialValues({'habits_v1': '[{"id": "x", "name": '});
      await expectLater(LegacyHabitMigrator.ensureMigrated(db), throwsA(anything));
      expect(await db.getMeta(LegacyHabitMigrator.doneFlag), isNull);
      expect(await db.select(db.habits).get(), isEmpty);
    });
  });

  group('StorageService facade', () {
    test('migrates on first load, saves to DB and mirrors legacy JSON', () async {
      SharedPreferences.setMockInitialValues({'habits_v1': jsonEncode(legacyFixture())});
      final storage = StorageService(db: db);

      final loaded = await storage.loadHabits();
      expect(loaded.length, 6);

      await storage.saveHabits(loaded.take(2).toList());
      expect((await repo.loadAll()).length, 2);
      final prefs = await SharedPreferences.getInstance();
      expect((jsonDecode(prefs.getString('habits_v1')!) as List).length, 2);
    });

    test('falls back to legacy JSON when the DB cannot migrate', () async {
      SharedPreferences.setMockInitialValues({'habits_v1': '[{"id": "x", "name": '});
      final storage = StorageService(db: db);
      // Legacy loader hits the same corrupt JSON -> surfaces the error the
      // v1.0.0 app would also have hit; nothing is lost or overwritten.
      await expectLater(storage.loadHabits(), throwsA(isA<FormatException>()));
    });
  });
}
