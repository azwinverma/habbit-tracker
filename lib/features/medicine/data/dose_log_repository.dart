import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../../../core/db/app_database.dart';
import '../../../models/habit.dart';
import '../../../services/native_alarm.dart';
import '../../habits/data/habit_repository.dart';

/// Taken / skipped history for medicine doses, one row per scheduled time per
/// day (`habit_logs` with metric `dose@HH:mm`).
class DoseLogRepository {
  DoseLogRepository(this._db);

  final AppDatabase _db;

  /// Sets (or clears, when [status] is null) the outcome of one dose.
  Future<void> setStatus(String habitId, String day, String hhmm, int? status) async {
    final metric = HabitMetric.dose(hhmm);
    if (status == null) {
      await (_db.delete(_db.habitLogs)
            ..where((t) => t.habitId.equals(habitId) & t.day.equals(day) & t.metric.equals(metric)))
          .go();
      return;
    }
    await _db.into(_db.habitLogs).insertOnConflictUpdate(HabitLogsCompanion.insert(
          habitId: habitId,
          day: day,
          metric: metric,
          value: Value(status),
          updatedAt: DateTime.now(),
        ));
  }

  /// day -> HH:mm -> status, for [habitId] between [fromDay] and [toDay].
  Future<Map<String, Map<String, int>>> statuses(String habitId,
      {required String fromDay, required String toDay}) async {
    final rows = await (_db.select(_db.habitLogs)
          ..where((t) =>
              t.habitId.equals(habitId) &
              t.day.isBetweenValues(fromDay, toDay) &
              t.metric.like('${HabitMetric.dosePrefix}%')))
        .get();
    final out = <String, Map<String, int>>{};
    for (final r in rows) {
      if (r.value == null) continue;
      out.putIfAbsent(r.day, () => {})[r.metric.substring(HabitMetric.dosePrefix.length)] = r.value!;
    }
    return out;
  }

  /// Fires whenever any log row changes (so dose lists refresh live).
  Stream<void> watch() => _db.select(_db.habitLogs).watch().map((_) {});

  /// Imports actions taken on notifications (the "Taken" button) while the
  /// app was not running. Lines for habits that no longer exist are dropped.
  /// Returns the number of doses recorded.
  Future<int> importNativeActions(AlarmBackend backend) async {
    List<String> lines;
    try {
      lines = await backend.drainDoseActions();
    } catch (e) {
      debugPrint('[Doses] drain failed: $e');
      return 0;
    }
    if (lines.isEmpty) return 0;
    final known = {for (final r in await _db.select(_db.habits).get()) r.id};
    var n = 0;
    for (final line in lines) {
      final a = DoseAction.tryParse(line);
      if (a == null || !known.contains(a.habitId)) continue;
      await setStatus(a.habitId, a.day, a.hhmm, a.status);
      n++;
    }
    return n;
  }
}

/// One action recorded by the native notification receiver.
class DoseAction {
  final String habitId;
  final String day;
  final String hhmm;
  final int status;
  const DoseAction(this.habitId, this.day, this.hhmm, this.status);

  static final _day = RegExp(r'^\d{4}-\d{2}-\d{2}$');
  static final _time = RegExp(r'^\d{2}:\d{2}$');

  /// Parses `"<habitId>|YYYY-MM-DD|HH:mm|taken|skipped"`. Habit ids never
  /// contain `|` (they are timestamps / UUIDs), but parse from the right to be
  /// safe.
  static DoseAction? tryParse(String line) {
    final parts = line.split('|');
    if (parts.length < 4) return null;
    final action = parts.removeLast();
    final hhmm = parts.removeLast();
    final day = parts.removeLast();
    final id = parts.join('|');
    if (id.isEmpty || !_day.hasMatch(day) || !_time.hasMatch(hhmm)) return null;
    final status = switch (action) {
      'taken' => DoseStatus.taken,
      'skipped' => DoseStatus.skipped,
      _ => null,
    };
    return status == null ? null : DoseAction(id, day, hhmm, status);
  }
}

/// Adherence over a window: doses that were due vs. doses marked taken.
class Adherence {
  final int due;
  final int taken;
  final int skipped;
  const Adherence(this.due, this.taken, this.skipped);

  /// 0..1, or null when nothing was due yet.
  double? get rate => due == 0 ? null : taken / due;

  /// Doses are "due" on days inside the course (start..end) for every dose
  /// time that has already passed (today's later doses are not due yet).
  static Adherence compute(Habit h, Map<String, Map<String, int>> statuses,
      {required DateTime now, int days = 7}) {
    final start = _parse(h.medicineStartDate);
    final end = _parse(h.medicineEndDate);
    final times = h.reminderTimes.map((s) => Habit.fmt(Habit.parseHHmm(s))).toSet();
    var due = 0, taken = 0, skipped = 0;
    for (var i = 0; i < days; i++) {
      final d = DateTime(now.year, now.month, now.day - i);
      if (start != null && d.isBefore(start)) continue;
      if (end != null && d.isAfter(end)) continue;
      final key = HabitRepository.ymd(d);
      for (final t in times) {
        final at = Habit.parseHHmm(t);
        final when = DateTime(d.year, d.month, d.day, at.hour, at.minute);
        final status = statuses[key]?[t];
        // A dose already marked counts even if its time hasn't come yet.
        if (when.isAfter(now) && status == null) continue;
        due++;
        if (status == DoseStatus.taken) taken++;
        if (status == DoseStatus.skipped) skipped++;
      }
    }
    return Adherence(due, taken, skipped);
  }

  static DateTime? _parse(String? ymd) {
    final d = ymd == null ? null : DateTime.tryParse(ymd);
    return d == null ? null : DateTime(d.year, d.month, d.day);
  }
}
