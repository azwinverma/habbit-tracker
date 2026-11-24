import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker_nepali/core/db/app_database.dart';
import 'package:habit_tracker_nepali/features/habits/data/habit_repository.dart';
import 'package:habit_tracker_nepali/features/medicine/data/dose_log_repository.dart';
import 'package:habit_tracker_nepali/models/habit.dart';

import '../reminders/reminder_service_test.dart' show FakeBackend;

Habit med({String id = 'm1', List<String> times = const ['08:00', '20:00'], String? start, String? end}) => Habit(
      id: id, name: 'Metformin', enabled: true, reminderHour: 8, reminderMinute: 0,
      reminderTimes: times, category: HabitCategory.medicine,
      medicineName: 'Metformin', medicineStartDate: start, medicineEndDate: end,
    );

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('DoseAction.tryParse', () {
    test('parses taken and skipped lines', () {
      final a = DoseAction.tryParse('1730|2026-11-24|08:00|taken')!;
      expect([a.habitId, a.day, a.hhmm, a.status], ['1730', '2026-11-24', '08:00', DoseStatus.taken]);
      expect(DoseAction.tryParse('x|2026-11-24|20:30|skipped')!.status, DoseStatus.skipped);
    });

    test('rejects malformed lines', () {
      for (final bad in ['', 'a|b|c', 'id|2026-1-1|08:00|taken', 'id|2026-11-24|8:00|taken',
          'id|2026-11-24|08:00|snoozed', '|2026-11-24|08:00|taken']) {
        expect(DoseAction.tryParse(bad), isNull, reason: bad);
      }
    });
  });

  group('Adherence', () {
    final now = DateTime(2026, 11, 24, 12, 0); // 08:00 passed, 20:00 not yet

    test('counts only doses that were due, inside the course', () {
      final h = med(start: '2026-11-22', end: '2026-12-31');
      // Due: 22nd ×2, 23rd ×2, 24th 08:00 → 5.
      final a = Adherence.compute(h, {
        '2026-11-22': {'08:00': DoseStatus.taken, '20:00': DoseStatus.taken},
        '2026-11-23': {'08:00': DoseStatus.skipped},
        '2026-11-24': {'08:00': DoseStatus.taken},
      }, now: now);
      expect([a.due, a.taken, a.skipped], [5, 3, 1]);
      expect(a.rate, closeTo(0.6, 1e-9));
    });

    test('a later dose marked early still counts', () {
      final a = Adherence.compute(med(start: '2026-11-24'), {
        '2026-11-24': {'20:00': DoseStatus.taken},
      }, now: now);
      expect([a.due, a.taken], [2, 1]);
    });

    test('course not started -> nothing due', () {
      final a = Adherence.compute(med(start: '2026-12-01'), const {}, now: now);
      expect(a.due, 0);
      expect(a.rate, isNull);
    });
  });

  group('DoseLogRepository', () {
    late AppDatabase db;
    late DoseLogRepository repo;
    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      repo = DoseLogRepository(db);
      await HabitRepository(db).saveAll([med()]);
    });
    tearDown(() => db.close());

    test('set, read back, and clear a dose', () async {
      await repo.setStatus('m1', '2026-11-24', '08:00', DoseStatus.taken);
      await repo.setStatus('m1', '2026-11-24', '20:00', DoseStatus.skipped);
      expect(await repo.statuses('m1', fromDay: '2026-11-18', toDay: '2026-11-24'), {
        '2026-11-24': {'08:00': DoseStatus.taken, '20:00': DoseStatus.skipped},
      });
      await repo.setStatus('m1', '2026-11-24', '20:00', null);
      expect((await repo.statuses('m1', fromDay: '2026-11-24', toDay: '2026-11-24'))['2026-11-24'],
          {'08:00': DoseStatus.taken});
    });

    test('dose rows do not leak into habit hydration or Insights totals', () async {
      await repo.setStatus('m1', HabitRepository.ymd(DateTime.now()), '08:00', DoseStatus.taken);
      final h = (await HabitRepository(db).loadAll()).single;
      expect(h.toJson(), med().toJson());
    });

    test('imports native notification actions; drops unknown habits and junk', () async {
      final backend = FakeBackend()
        ..pendingDoseActions = [
          'm1|2026-11-24|08:00|taken',
          'deleted-habit|2026-11-24|08:00|taken',
          'garbage',
        ];
      expect(await repo.importNativeActions(backend), 1);
      expect(backend.pendingDoseActions, isEmpty);
      expect((await repo.statuses('m1', fromDay: '2026-11-24', toDay: '2026-11-24'))['2026-11-24'],
          {'08:00': DoseStatus.taken});
    });

    test('dose history is deleted with the habit', () async {
      await repo.setStatus('m1', '2026-11-24', '08:00', DoseStatus.taken);
      await HabitRepository(db).saveAll([]);
      expect(await repo.statuses('m1', fromDay: '2026-01-01', toDay: '2026-12-31'), isEmpty);
    });
  });
}
