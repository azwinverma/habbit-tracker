import 'alarm_id.dart';

enum ReminderKind { daily, once }

/// A single OS-level alarm the app wants armed.
///
/// [key] is the logical identity (e.g. `"<habitId>|daily|08:00"`); [id] is
/// derived from it with [stableAlarmId], so the same reminder always maps to
/// the same AlarmManager request code and re-scheduling replaces it instead
/// of creating a duplicate.
class ReminderSpec {
  final String key;
  final ReminderKind kind;

  /// First trigger time (local).
  final DateTime firstAt;

  /// Wall-clock time used to re-arm daily reminders.
  final int hour;
  final int minute;

  /// Daily reminders stop after this instant (inclusive). Null = no end.
  final DateTime? endAt;

  final String title;
  final String body;

  ReminderSpec({
    required this.key,
    required this.kind,
    required this.firstAt,
    required this.hour,
    required this.minute,
    required this.title,
    required this.body,
    this.endAt,
  });

  int get id => stableAlarmId(key);

  @override
  String toString() =>
      'ReminderSpec($key, ${kind.name}, first=$firstAt, end=$endAt, "$title")';
}
