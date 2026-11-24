import '../../core/reminders/habit_reminder_planner.dart';
import '../../core/reminders/reminder_spec.dart';
import '../../models/habit.dart';
import '../habits/data/habit_repository.dart';

/// Everything the Today dashboard shows, derived from the user's real data
/// (pure; `now` injectable for tests).
class TodaySummary {
  TodaySummary._(this.now, this.active, this.doneIds, this.upcoming);

  final DateTime now;
  final List<Habit> active;
  final Set<String> doneIds;

  /// Remaining reminders today, soonest first.
  final List<({DateTime at, Habit habit, ReminderSpec spec})> upcoming;

  int get done => doneIds.length;
  int get total => active.length;
  int get left => total - done;
  double get progress => total == 0 ? 0 : done / total;
  bool get allDone => total > 0 && done == total;

  /// Longest current streak among active habits.
  int get bestStreak => active.fold(0, (m, h) => h.streak > m ? h.streak : m);

  Habit? first(HabitCategory c) {
    for (final h in active) {
      if (h.category == c) return h;
    }
    return null;
  }

  bool isDone(Habit h) => doneIds.contains(h.id);

  factory TodaySummary.from(List<Habit> habits, DateTime now) {
    final active = habits.where((h) => h.enabled).toList();
    final done = {for (final h in active) if (isDoneToday(h, now)) h.id};
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final upcoming = <({DateTime at, Habit habit, ReminderSpec spec})>[
      for (final h in active)
        for (final s in HabitReminderPlanner.plan(h, now))
          if (!s.firstAt.isAfter(endOfDay)) (at: s.firstAt, habit: h, spec: s),
    ]..sort((a, b) => a.at.compareTo(b.at));
    return TodaySummary._(now, active, done, upcoming);
  }

  /// Today's value of a daily counter (counters belong to the day they were
  /// last written; anything older reads as 0).
  static int todayValue(String? lastDate, int? value, DateTime now) =>
      lastDate == HabitRepository.ymd(now) ? (value ?? 0) : 0;

  /// Done = marked complete today, or the category's daily goal is reached.
  static bool isDoneToday(Habit h, DateTime now) {
    final d = h.lastCompleted;
    if (d != null && d.year == now.year && d.month == now.month && d.day == now.day) return true;
    switch (h.category) {
      case HabitCategory.water:
        final target = h.waterTarget ?? 0;
        return target > 0 && todayValue(h.waterLastDate, h.waterCompleted, now) >= target;
      case HabitCategory.meditation:
        final goal = h.meditationGoalMin ?? 0;
        return goal > 0 && todayValue(h.meditationLastDate, h.meditationTodayMin, now) >= goal;
      case HabitCategory.exercise:
        final goal = h.exerciseGoalMin ?? 0;
        return goal > 0 && todayValue(h.exerciseLastDate, h.exerciseTodayMin, now) >= goal;
      case HabitCategory.medicine:
      case HabitCategory.reading:
      case HabitCategory.generic:
        return false;
    }
  }
}
