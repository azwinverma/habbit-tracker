import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker_nepali/core/reminders/alarm_id.dart';

void main() {
  test('is deterministic and matches known FNV-1a values', () {
    // Pinned values: if these change, every alarm already armed on users'
    // phones becomes un-cancellable. Do not change the algorithm.
    expect(stableAlarmId('habit-1|daily|08:00'), stableAlarmId('habit-1|daily|08:00'));
    expect(stableAlarmId(''), 0x811c9dc5 & 0x7fffffff);
    expect(stableAlarmId('a'), 0xe40c292c & 0x7fffffff);
  });

  test('always a positive 31-bit int (valid Android request code)', () {
    for (var i = 0; i < 5000; i++) {
      final id = stableAlarmId('h$i|daily|${i % 24}:${i % 60}');
      expect(id, greaterThan(0));
      expect(id, lessThanOrEqualTo(0x7fffffff));
    }
  });

  test('different keys give different ids for typical reminder sets', () {
    final ids = <int>{};
    for (var h = 0; h < 50; h++) {
      for (var t = 0; t < 24; t++) {
        ids.add(stableAlarmId('habit$h|daily|${t.toString().padLeft(2, '0')}:00'));
      }
    }
    expect(ids.length, 50 * 24);
  });
}
