import 'dart:async';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker_nepali/core/db/app_database.dart';
import 'package:habit_tracker_nepali/features/habits/data/legacy_habit_migrator.dart';
import 'package:habit_tracker_nepali/features/steps/step_service.dart';
import 'package:habit_tracker_nepali/models/habit.dart';
import 'package:habit_tracker_nepali/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final t0 = DateTime(2026, 11, 25, 8);

  group('StepState.apply', () {
    test('first reading starts counting from now', () {
      final s = StepState.apply(StepState(), 52000, t0);
      expect(s.totalFor('2026-11-25'), 0);
      expect(s.lastRaw, 52000);
    });

    test('adds the difference between readings', () {
      var s = StepState.apply(StepState(), 52000, t0);
      s = StepState.apply(s, 53200, t0.add(const Duration(minutes: 15)));
      s = StepState.apply(s, 55000, t0.add(const Duration(minutes: 30)));
      expect(s.totalFor('2026-11-25'), 3000);
    });

    test('Android reboot: counter restarts at 0, new total is all new steps', () {
      var s = StepState.apply(StepState(), 52000, t0);
      s = StepState.apply(s, 53000, t0.add(const Duration(hours: 1)));
      s = StepState.apply(s, 400, t0.add(const Duration(hours: 2))); // rebooted, walked 400
      expect(s.totalFor('2026-11-25'), 1400);
    });

    test('iPhone: a smaller total just re-baselines (no double counting)', () {
      var s = StepState.apply(StepState(), 90000, t0, rebootResets: false);
      s = StepState.apply(s, 80000, t0.add(const Duration(hours: 1)), rebootResets: false);
      s = StepState.apply(s, 80500, t0.add(const Duration(hours: 2)), rebootResets: false);
      expect(s.totalFor('2026-11-25'), 500);
    });

    test('ignores impossible jumps (sensor glitch)', () {
      var s = StepState.apply(StepState(), 1000, t0);
      s = StepState.apply(s, 1000 + 200000, t0.add(const Duration(minutes: 15)));
      expect(s.totalFor('2026-11-25'), 0);
    });

    test('new day starts at 0; steps after the last reading go to the new day', () {
      var s = StepState.apply(StepState(), 1000, DateTime(2026, 11, 25, 23, 40));
      s = StepState.apply(s, 1600, DateTime(2026, 11, 25, 23, 55));
      s = StepState.apply(s, 1900, DateTime(2026, 11, 26, 0, 10));
      expect(s.totalFor('2026-11-25'), 600);
      expect(s.totalFor('2026-11-26'), 300);
    });

    test('keeps 14 days, manual counted separately, survives JSON', () {
      final s = StepState(days: {'2026-11-01': 5000, '2026-11-24': 7000}, manual: {'2026-11-25': 300});
      StepState.apply(s, 10, t0);
      expect(s.days.containsKey('2026-11-01'), isFalse);
      final back = StepState.fromJson(s.toJson());
      expect(back.totalFor('2026-11-24'), 7000);
      expect(back.totalFor('2026-11-25'), 300);
      expect(back.lastRaw, 10);
      expect(StepState.fromJson('garbage').days, isEmpty);
    });
  });

  group('StepService', () {
    late AppDatabase db;
    late StreamController<int> sensor;
    late StepService svc;
    var now = t0;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      LegacyHabitMigrator.resetForTest();
      db = AppDatabase(NativeDatabase.memory());
      AppDatabase.instance = db;
      sensor = StreamController<int>.broadcast();
      now = t0;
      svc = StepService(db, sensor: () => sensor.stream, isAndroid: false, clock: () => now);
      await StorageService().saveHabits([
        Habit(id: 'e', name: 'Walk', enabled: true, reminderHour: 7, reminderMinute: 0,
            category: HabitCategory.exercise, stepsGoal: 8000, stepsToday: 0),
      ]);
    });
    tearDown(() async {
      await sensor.close();
      await db.close();
    });

    /// Runs [action] and delivers one sensor reading while it waits.
    Future<T> withReading<T>(Future<T> Function() action, int raw) async {
      final f = action();
      for (var i = 0; i < 20; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        if (sensor.hasListener) break;
      }
      sensor.add(raw);
      return f;
    }

    test("enable → walk → sync writes today's steps into the exercise habit", () async {
      expect(await withReading(svc.enable, 20000), StepEnableResult.enabled);
      expect(await svc.isEnabled(), isTrue);
      now = t0.add(const Duration(hours: 2));
      await withReading(svc.sync, 23500);
      final h = (await StorageService().loadHabits()).single;
      expect(h.stepsToday, 3500);
      expect(h.stepsLastDate, '2026-11-25');
      expect(svc.today.value, 3500);
    });

    test('no sensor reading → noSensor, stays off', () async {
      final r = await svc.enable(); // nothing emitted: times out
      expect(r, StepEnableResult.noSensor);
      expect(await svc.isEnabled(), isFalse);
    }, timeout: const Timeout(Duration(seconds: 20)));

    test('manual steps add on top of sensor steps and reset separately', () async {
      await withReading(svc.enable, 1000);
      await withReading(svc.sync, 1800);
      await svc.addManual(500);
      expect((await StorageService().loadHabits()).single.stepsToday, 1300);
      await svc.resetManual();
      expect((await StorageService().loadHabits()).single.stepsToday, 800);
    });
  });
}
