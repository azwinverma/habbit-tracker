import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker_nepali/features/today/today_summary.dart';
import 'package:habit_tracker_nepali/models/habit.dart';

void main() {
  final now = DateTime(2026, 11, 24, 13, 0);
  const today = '2026-11-24';

  Habit h(String id, HabitCategory c, {bool enabled = true, DateTime? done, List<String> times = const ['18:00'],
          int streak = 0, int? water, int? target, String? waterDay, int? medMin, int? medGoal}) =>
      Habit(id: id, name: id, enabled: enabled, reminderHour: 8, reminderMinute: 0, reminderTimes: times,
          category: c, lastCompleted: done, streak: streak, waterCompleted: water, waterTarget: target,
          waterLastDate: waterDay, meditationTodayMin: medMin, meditationGoalMin: medGoal,
          meditationLastDate: medMin == null ? null : today);

  test('progress counts only enabled habits; done = marked today or goal reached', () {
    final t = TodaySummary.from([
      h('journal', HabitCategory.generic, done: DateTime(2026, 11, 24, 7)),
      h('old', HabitCategory.generic, done: DateTime(2026, 11, 23, 7)),
      h('water', HabitCategory.water, water: 8, target: 8, waterDay: today),
      h('calm', HabitCategory.meditation, medMin: 5, medGoal: 10),
      h('off', HabitCategory.generic, enabled: false, done: DateTime(2026, 11, 24, 7)),
    ], now);
    expect(t.total, 4);
    expect(t.done, 2);
    expect(t.left, 2);
    expect(t.progress, 0.5);
    expect(t.allDone, isFalse);
  });

  test("yesterday's water count does not count today", () {
    final w = h('water', HabitCategory.water, water: 8, target: 8, waterDay: '2026-11-23');
    expect(TodaySummary.isDoneToday(w, now), isFalse);
    expect(TodaySummary.todayValue(w.waterLastDate, w.waterCompleted, now), 0);
  });

  test('upcoming lists only the rest of today, soonest first', () {
    final t = TodaySummary.from([
      h('a', HabitCategory.generic, times: ['08:00', '20:00']),
      h('b', HabitCategory.generic, times: ['14:30']),
    ], now);
    expect(t.upcoming.map((e) => '${e.habit.id}@${e.at.hour}:${e.at.minute}'), ['b@14:30', 'a@20:0']);
  });

  test('best streak and allDone', () {
    final t = TodaySummary.from([
      h('a', HabitCategory.generic, done: now, streak: 3),
      h('b', HabitCategory.generic, done: now, streak: 9),
    ], now);
    expect(t.allDone, isTrue);
    expect(t.bestStreak, 9);
  });

  test('empty list is safe', () {
    final t = TodaySummary.from(const [], now);
    expect([t.total, t.done, t.progress], [0, 0, 0]);
    expect(t.allDone, isFalse);
  });
}
