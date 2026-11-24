import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker_nepali/core/reminders/habit_reminder_planner.dart';
import 'package:habit_tracker_nepali/core/reminders/reminder_spec.dart';
import 'package:habit_tracker_nepali/models/habit.dart';

Habit _habit({
  HabitCategory category = HabitCategory.generic,
  bool enabled = true,
  List<String> times = const [],
  int hour = 8,
  int minute = 0,
  List<String>? oneTime,
  String? start,
  String? end,
  String name = 'Test',
}) =>
    Habit(
      id: 'h1',
      name: name,
      enabled: enabled,
      reminderHour: hour,
      reminderMinute: minute,
      reminderTimes: times,
      category: category,
      medicineName: category == HabitCategory.medicine ? 'Metformin' : null,
      medicineDose: category == HabitCategory.medicine ? '500mg' : null,
      medicineStartDate: start,
      medicineEndDate: end,
      oneTimeReminders: oneTime,
    );

void main() {
  final now = DateTime(2026, 11, 24, 10, 30); // Tue 10:30

  group('nextOccurrence', () {
    test('later today', () {
      expect(HabitReminderPlanner.nextOccurrence(18, 0, now: now), DateTime(2026, 11, 24, 18, 0));
    });
    test('already passed -> tomorrow', () {
      expect(HabitReminderPlanner.nextOccurrence(8, 0, now: now), DateTime(2026, 11, 25, 8, 0));
    });
    test('exactly now -> tomorrow (no immediate double fire)', () {
      expect(HabitReminderPlanner.nextOccurrence(10, 30, now: now), DateTime(2026, 11, 25, 10, 30));
    });
    test('month/year rollover', () {
      final eoy = DateTime(2026, 12, 31, 23, 0);
      expect(HabitReminderPlanner.nextOccurrence(7, 0, now: eoy), DateTime(2027, 1, 1, 7, 0));
    });
    test('respects notBefore (future start date)', () {
      expect(
        HabitReminderPlanner.nextOccurrence(8, 0, now: now, notBefore: DateTime(2026, 12, 1)),
        DateTime(2026, 12, 1, 8, 0),
      );
    });
    test('midnight dose on the start day is included', () {
      expect(
        HabitReminderPlanner.nextOccurrence(0, 0, now: now, notBefore: DateTime(2026, 12, 1)),
        DateTime(2026, 12, 1, 0, 0),
      );
    });
  });

  group('plan', () {
    test('disabled habit has no reminders', () {
      expect(HabitReminderPlanner.plan(_habit(enabled: false, times: ['08:00']), now), isEmpty);
    });

    test('one daily alarm per time, de-duplicated and normalised', () {
      final specs = HabitReminderPlanner.plan(_habit(times: ['08:00', '8:0', '20:15']), now);
      expect(specs.map((s) => s.key), ['h1|daily|08:00', 'h1|daily|20:15']);
      expect(specs.every((s) => s.kind == ReminderKind.daily), isTrue);
      expect(specs.first.firstAt, DateTime(2026, 11, 25, 8, 0));
      expect(specs.last.firstAt, DateTime(2026, 11, 24, 20, 15));
    });

    test('falls back to reminderHour/minute when no times list', () {
      final specs = HabitReminderPlanner.plan(_habit(hour: 21, minute: 5), now);
      expect(specs.single.key, 'h1|daily|21:05');
    });

    test('ids are stable across calls (re-plan replaces, never duplicates)', () {
      final a = HabitReminderPlanner.plan(_habit(times: ['08:00']), now);
      final b = HabitReminderPlanner.plan(_habit(times: ['08:00']), now.add(const Duration(hours: 5)));
      expect(a.single.id, b.single.id);
    });

    test('category copy', () {
      String title(HabitCategory c) => HabitReminderPlanner.plan(_habit(category: c), now).single.title;
      expect(title(HabitCategory.water), 'Hydration Reminder');
      expect(title(HabitCategory.meditation), 'Meditation Reminder');
      expect(title(HabitCategory.reading), 'Reading Reminder');
      expect(title(HabitCategory.exercise), 'Exercise Reminder');
      expect(title(HabitCategory.generic), 'Habit Reminder');
      expect(HabitReminderPlanner.plan(_habit(name: 'Journal'), now).single.body, 'Time for: Journal');
    });

    test('one-time reminders: future kept, past dropped, never repeat', () {
      final specs = HabitReminderPlanner.plan(
        _habit(oneTime: ['2026-11-24T09:00:00.000', '2026-11-30T07:15:00.000', 'garbage']),
        now,
      );
      final once = specs.where((s) => s.kind == ReminderKind.once).toList();
      expect(once.length, 1);
      expect(once.single.firstAt, DateTime(2026, 11, 30, 7, 15));
    });
  });

  group('medicine', () {
    test('course in progress: daily alarms bounded by end date, dose in body', () {
      final specs = HabitReminderPlanner.plan(
        _habit(category: HabitCategory.medicine, times: ['08:00', '20:00'], start: '2026-11-20', end: '2026-11-26'),
        now,
      );
      expect(specs.length, 2);
      for (final s in specs) {
        expect(s.kind, ReminderKind.daily);
        expect(s.endAt, DateTime(2026, 11, 26, 23, 59, 59, 999));
        expect(s.body, 'Take: Metformin (500mg)');
      }
    });

    test('finished course schedules nothing', () {
      final specs = HabitReminderPlanner.plan(
        _habit(category: HabitCategory.medicine, times: ['08:00'], start: '2026-11-01', end: '2026-11-23'),
        now,
      );
      expect(specs, isEmpty);
    });

    test('last day: remaining dose today kept, passed dose dropped', () {
      final specs = HabitReminderPlanner.plan(
        _habit(category: HabitCategory.medicine, times: ['08:00', '20:00'], start: '2026-11-01', end: '2026-11-24'),
        now,
      );
      expect(specs.map((s) => s.key), ['h1|daily|20:00']);
    });

    test('future start: first alarm on start date', () {
      final specs = HabitReminderPlanner.plan(
        _habit(category: HabitCategory.medicine, times: ['08:00'], start: '2026-12-05', end: '2026-12-10'),
        now,
      );
      expect(specs.single.firstAt, DateTime(2026, 12, 5, 8, 0));
    });

    test('swapped dates are corrected', () {
      final specs = HabitReminderPlanner.plan(
        _habit(category: HabitCategory.medicine, times: ['08:00'], start: '2026-12-10', end: '2026-12-05'),
        now,
      );
      expect(specs.single.firstAt, DateTime(2026, 12, 5, 8, 0));
      expect(specs.single.endAt, DateTime(2026, 12, 10, 23, 59, 59, 999));
    });

    test('no dates: open-ended daily reminders', () {
      final specs = HabitReminderPlanner.plan(_habit(category: HabitCategory.medicine, times: ['08:00']), now);
      expect(specs.single.endAt, isNull);
    });

    test('long course (1 year, 4 doses) needs only 4 alarms', () {
      final specs = HabitReminderPlanner.plan(
        _habit(
          category: HabitCategory.medicine,
          times: ['06:00', '12:00', '18:00', '23:00'],
          start: '2026-11-01',
          end: '2027-11-01',
        ),
        now,
      );
      expect(specs.length, 4); // was up to 480 one-shot alarms (Android caps ~500/app)
    });
  });
}
