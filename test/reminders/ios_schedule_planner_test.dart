import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker_nepali/core/reminders/habit_reminder_planner.dart';
import 'package:habit_tracker_nepali/core/reminders/reminder_spec.dart';
import 'package:habit_tracker_nepali/models/habit.dart';
import 'package:habit_tracker_nepali/services/ios_alarm_backend.dart';

void main() {
  final now = DateTime(2026, 11, 24, 12, 0);

  ReminderSpec daily({DateTime? first, DateTime? end, int h = 8}) => ReminderSpec(
        key: 'x|daily|$h', kind: ReminderKind.daily,
        firstAt: first ?? DateTime(2026, 11, 25, h), hour: h, minute: 0,
        endAt: end, title: 't', body: 'b');

  test('open-ended daily reminder uses one repeating slot', () {
    final p = IosSchedulePlanner.expand(daily(), now);
    expect(p.length, 1);
    expect(p.single.repeatDaily, isTrue);
    expect(p.single.id, daily().id);
  });

  test('medicine course ending far away still repeats', () {
    final p = IosSchedulePlanner.expand(daily(end: DateTime(2027, 1, 1, 23, 59)), now);
    expect(p.single.repeatDaily, isTrue);
  });

  test('course ending within the window becomes one-shots up to the end', () {
    final p = IosSchedulePlanner.expand(daily(end: DateTime(2026, 11, 27, 23, 59)), now);
    expect(p.map((e) => e.at.day), [25, 26, 27]);
    expect(p.every((e) => !e.repeatDaily), isTrue);
    expect(p.map((e) => e.id).toSet().length, 3);
    expect(p.map((e) => e.id), isNot(contains(daily().id)));
  });

  test('course starting later never fires early; capped to the 7-day window', () {
    final p = IosSchedulePlanner.expand(daily(first: DateTime(2026, 11, 28, 8)), now);
    expect(p.first.at, DateTime(2026, 11, 28, 8));
    expect(p.last.at.isAfter(now.add(IosSchedulePlanner.window)), isFalse);
    expect(p.every((e) => !e.repeatDaily), isTrue);
  });

  test('course too far in the future schedules nothing yet', () {
    expect(IosSchedulePlanner.expand(daily(first: DateTime(2026, 12, 20, 8)), now), isEmpty);
  });

  test('one-time reminders: future kept, past dropped', () {
    ReminderSpec once(DateTime at) => ReminderSpec(
        key: 'x|once|$at', kind: ReminderKind.once, firstAt: at,
        hour: at.hour, minute: at.minute, title: 't', body: 'b');
    expect(IosSchedulePlanner.expand(once(DateTime(2026, 11, 30, 7)), now).single.repeatDaily, isFalse);
    expect(IosSchedulePlanner.expand(once(DateTime(2026, 11, 20, 7)), now), isEmpty);
  });

  test('a typical setup fits within the 64-notification limit', () {
    final habits = [
      Habit(id: 'w', name: 'Water', enabled: true, reminderHour: 8, reminderMinute: 0,
          reminderTimes: ['08:00', '10:00', '12:00', '14:00', '16:00', '18:00', '20:00', '21:00'],
          category: HabitCategory.water),
      Habit(id: 'm', name: 'Med', enabled: true, reminderHour: 8, reminderMinute: 0,
          reminderTimes: ['08:00', '14:00', '20:00'], category: HabitCategory.medicine,
          medicineStartDate: '2026-11-20', medicineEndDate: '2026-11-28'),
      Habit(id: 'e', name: 'Ex', enabled: true, reminderHour: 7, reminderMinute: 0,
          reminderTimes: ['07:00'], category: HabitCategory.exercise,
          officeWalkEveryMin: 60, officeStretchEveryMin: 120),
    ];
    final total = habits
        .expand((h) => HabitReminderPlanner.plan(h, now))
        .expand((s) => IosSchedulePlanner.expand(s, now))
        .length;
    expect(total, lessThanOrEqualTo(IosSchedulePlanner.maxPending));
  });
}
