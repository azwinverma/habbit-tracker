import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker_nepali/models/habit.dart';

void main() {
  group('Habit JSON', () {
    test('decodes a pre-2.0 record that has no oneTimeReminders field', () {
      // Shape written by v1.0.0 builds (subset of fields).
      final legacy = {
        'id': '1730000000000000123',
        'name': 'Vitamin D',
        'enabled': true,
        'reminderHour': 8,
        'reminderMinute': 0,
        'reminderTimes': ['08:00', '20:00'],
        'category': 'medicine',
        'streak': 3,
        'lastCompleted': null,
        'medicineName': 'Vitamin D',
        'medicineDose': '1 tab',
        'medicineStartDate': '2026-11-01',
        'medicineEndDate': '2026-11-30',
      };
      final h = Habit.fromJson(legacy);
      expect(h.category, HabitCategory.medicine);
      expect(h.reminderTimes, ['08:00', '20:00']);
      expect(h.oneTimeReminders, isEmpty);
      expect(h.medicineEndDate, '2026-11-30');
    });

    test('round-trips every field including oneTimeReminders', () {
      final h = Habit(
        id: 'abc',
        name: 'Read',
        enabled: false,
        reminderHour: 21,
        reminderMinute: 30,
        reminderTimes: ['21:30'],
        category: HabitCategory.reading,
        streak: 5,
        lastCompleted: DateTime(2026, 11, 20, 21, 45),
        oneTimeReminders: ['2026-12-01T07:00:00.000'],
      );
      final back = Habit.fromJson(h.toJson());
      expect(back.toJson(), h.toJson());
    });

    test('unknown category falls back to generic', () {
      final h = Habit.fromJson({'id': 'x', 'name': 'n', 'category': 'sleep'});
      expect(h.category, HabitCategory.generic);
    });

    test('oneTimeReminders list is mutable (not a shared const)', () {
      final a = Habit(id: 'a', name: 'a', enabled: true, reminderHour: 8, reminderMinute: 0);
      final b = Habit(id: 'b', name: 'b', enabled: true, reminderHour: 8, reminderMinute: 0);
      a.oneTimeReminders.add('2030-01-01T00:00:00.000');
      expect(b.oneTimeReminders, isEmpty);
    });
  });
}
