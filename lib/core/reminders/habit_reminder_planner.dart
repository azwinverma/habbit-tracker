import '../../models/habit.dart';
import 'reminder_spec.dart';

/// Pure function from a [Habit] to the set of alarms it needs.
///
/// This is the single source of truth for "what reminders does this habit
/// have". Screens edit the habit's data; the reminder service turns that data
/// into alarms via this planner. Keeping it pure (no I/O, injectable `now`)
/// makes it unit-testable.
class HabitReminderPlanner {
  const HabitReminderPlanner._();

  static List<ReminderSpec> plan(Habit h, DateTime now) {
    if (!h.enabled) return const [];

    final copy = _copyFor(h);
    final specs = <ReminderSpec>[];

    DateTime notBefore = now;
    DateTime? endAt;

    if (h.category == HabitCategory.medicine) {
      var start = _parseYmd(h.medicineStartDate);
      var end = _parseYmd(h.medicineEndDate);
      if (start != null && end != null && end.isBefore(start)) {
        final tmp = start;
        start = end;
        end = tmp;
      }
      if (end != null) {
        endAt = DateTime(end.year, end.month, end.day, 23, 59, 59, 999);
        if (!endAt.isAfter(now)) return const []; // course finished
      }
      if (start != null && start.isAfter(notBefore)) notBefore = start;
    }

    for (final hhmm in _dailyTimes(h)) {
      final t = Habit.parseHHmm(hhmm);
      final first = nextOccurrence(t.hour, t.minute, now: now, notBefore: notBefore);
      if (endAt != null && first.isAfter(endAt)) continue;
      specs.add(ReminderSpec(
        key: '${h.id}|daily|${Habit.fmt(t)}',
        kind: ReminderKind.daily,
        firstAt: first,
        hour: t.hour,
        minute: t.minute,
        endAt: endAt,
        title: copy.title,
        body: copy.dailyBody(Habit.fmt(t)),
      ));
    }

    for (final iso in h.oneTimeReminders.toSet()) {
      final at = DateTime.tryParse(iso);
      if (at == null || !at.isAfter(now)) continue;
      specs.add(ReminderSpec(
        key: '${h.id}|once|${at.toIso8601String()}',
        kind: ReminderKind.once,
        firstAt: at,
        hour: at.hour,
        minute: at.minute,
        title: copy.title,
        body: copy.onceBody,
      ));
    }

    return specs;
  }

  /// Next local occurrence of [hour]:[minute] strictly after [now] and on or
  /// after [notBefore]'s calendar day. Uses calendar arithmetic (not
  /// `Duration(days: 1)`) so it stays correct across DST changes.
  static DateTime nextOccurrence(int hour, int minute,
      {required DateTime now, DateTime? notBefore}) {
    final base = (notBefore != null && notBefore.isAfter(now)) ? notBefore : now;
    var candidate = DateTime(base.year, base.month, base.day, hour, minute);
    var guard = 0;
    while (!candidate.isAfter(now) && guard++ < 3) {
      candidate = DateTime(
          candidate.year, candidate.month, candidate.day + 1, hour, minute);
    }
    return candidate;
  }

  static List<String> _dailyTimes(Habit h) {
    final raw = h.reminderTimes.isNotEmpty
        ? h.reminderTimes
        : ['${h.reminderHour.clamp(0, 23)}:${h.reminderMinute.clamp(0, 59)}'];
    // Normalise ("8:0" -> "08:00") and de-duplicate, preserving order.
    final seen = <String>{};
    final out = <String>[];
    for (final s in raw) {
      final n = Habit.fmt(Habit.parseHHmm(s));
      if (seen.add(n)) out.add(n);
    }
    return out;
  }

  static DateTime? _parseYmd(String? ymd) {
    if (ymd == null || ymd.isEmpty) return null;
    final d = DateTime.tryParse(ymd);
    return d == null ? null : DateTime(d.year, d.month, d.day);
  }

  static _Copy _copyFor(Habit h) {
    switch (h.category) {
      case HabitCategory.medicine:
        final name = (h.medicineName?.trim().isNotEmpty ?? false)
            ? h.medicineName!.trim()
            : h.name;
        final dose = h.medicineDose?.trim() ?? '';
        final body = 'Take: $name${dose.isNotEmpty ? ' ($dose)' : ''}';
        return _Copy('Medicine Reminder', (_) => body, body);
      case HabitCategory.water:
        return _Copy('Hydration Reminder', (_) => 'Drink water 💧', 'Drink water 💧');
      case HabitCategory.meditation:
        return _Copy('Meditation Reminder', (_) => 'Time to meditate 🧘',
            'One-time reminder 🧘');
      case HabitCategory.reading:
        return _Copy('Reading Reminder', (t) => 'Time to read 📚 ($t)',
            'One-time reading reminder 📚');
      case HabitCategory.exercise:
        return _Copy('Exercise Reminder', (t) => 'Time to workout 💪 ($t)',
            'One-time workout reminder 💪');
      case HabitCategory.generic:
        return _Copy('Habit Reminder', (_) => 'Time for: ${h.name}',
            'Time for: ${h.name}');
    }
  }
}

class _Copy {
  final String title;
  final String Function(String hhmm) dailyBody;
  final String onceBody;
  const _Copy(this.title, this.dailyBody, this.onceBody);
}
