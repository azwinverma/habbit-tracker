import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker_nepali/widgets/reminder_schedule_editor.dart';

void main() {
  test('normalize sorts and de-duplicates', () {
    final out = ReminderScheduleEditor.normalize(const [
      TimeOfDay(hour: 20, minute: 0),
      TimeOfDay(hour: 8, minute: 0),
      TimeOfDay(hour: 20, minute: 0),
    ]);
    expect(out.map(ReminderScheduleEditor.fmtTime), ['08:00', '20:00']);
  });

  testWidgets('shows times and one-time reminders; delete reports new lists', (tester) async {
    List<TimeOfDay>? daily;
    List<DateTime>? once;
    final future = DateTime(2030, 1, 2, 7, 15);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: ReminderScheduleEditor(
            dailyTimes: const [TimeOfDay(hour: 8, minute: 0), TimeOfDay(hour: 20, minute: 30)],
            onDailyTimesChanged: (l) => daily = l,
            oneTimeReminders: [future],
            onOneTimeRemindersChanged: (l) => once = l,
          ),
        ),
      ),
    ));

    expect(find.text('08:00'), findsOneWidget);
    expect(find.text('20:30'), findsOneWidget);
    expect(find.text('2 Jan 2030, 07:15'), findsOneWidget);

    await tester.tap(find.byTooltip('Remove 08:00'));
    expect(daily!.map(ReminderScheduleEditor.fmtTime), ['20:30']);

    await tester.tap(find.byTooltip('Remove reminder on 2 Jan 2030, 07:15'));
    expect(once, isEmpty);
  });

  testWidgets('one-time section hidden when not supported', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ReminderScheduleEditor(dailyTimes: const [], onDailyTimesChanged: (_) {}),
      ),
    ));
    expect(find.text('No daily times yet.'), findsOneWidget);
    expect(find.text('One-time reminders'), findsNothing);
  });
}
