import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../../../models/habit.dart';

/// Source of truth for habits (SQLite via Drift).
///
/// Phase 1 keeps the legacy [Habit] class as the *view model* the existing
/// screens use, and maps it onto normalised tables:
///   habits (common) + medicine_details / water_settings / meditation_settings
///   / exercise_settings (per category) + habit_logs (per-day history).
/// The legacy class is retired screen by screen in Phase 2/3.
class HabitRepository {
  HabitRepository(this._db);

  final AppDatabase _db;

  // ---------------------------------------------------------------- reads

  Future<List<Habit>> loadAll() async {
    final rows = await (_db.select(_db.habits)
          ..where((t) => t.archived.equals(false))
          ..orderBy([(t) => OrderingTerm(expression: t.sortOrder)]))
        .get();
    return _hydrate(rows);
  }

  /// Emits the full habit list whenever any habit-related table changes.
  Stream<List<Habit>> watchAll() {
    final q = _db.select(_db.habits)
      ..where((t) => t.archived.equals(false))
      ..orderBy([(t) => OrderingTerm(expression: t.sortOrder)]);
    return q.watch().asyncMap(_hydrate);
  }

  Future<List<Habit>> _hydrate(List<HabitRow> rows) async {
    if (rows.isEmpty) return [];
    final med = {for (final r in await _db.select(_db.medicineDetails).get()) r.habitId: r};
    final water = {for (final r in await _db.select(_db.waterSettings).get()) r.habitId: r};
    final medit = {for (final r in await _db.select(_db.meditationSettings).get()) r.habitId: r};
    final ex = {for (final r in await _db.select(_db.exerciseSettings).get()) r.habitId: r};
    final latest = await _latestLogs();

    return rows.map((r) {
      final m = med[r.id];
      final w = water[r.id];
      final me = medit[r.id];
      final e = ex[r.id];
      final logs = latest[r.id] ?? const <String, _Log>{};
      final wl = logs[HabitMetric.waterGlasses];
      final ml = logs[HabitMetric.meditationMinutes];
      final el = logs[HabitMetric.exerciseMinutes];
      final sl = logs[HabitMetric.steps];
      return Habit(
        id: r.id,
        name: r.name,
        enabled: r.enabled,
        reminderHour: r.reminderHour,
        reminderMinute: r.reminderMinute,
        reminderTimes: List<String>.from(r.reminderTimes),
        category: HabitCategory.values.firstWhere(
          (c) => c.name == r.category,
          orElse: () => HabitCategory.generic,
        ),
        streak: r.streak,
        lastCompleted: r.lastCompletedAt,
        medicineName: m?.medicineName,
        medicineDose: m?.dose,
        medicineNotes: m?.notes,
        medicineStartDate: m?.startDate,
        medicineEndDate: m?.endDate,
        waterTarget: w?.targetGlasses,
        waterCompleted: wl?.value,
        waterLastDate: wl?.day,
        meditationGoalMin: me?.goalMinutes,
        meditationTodayMin: ml?.value,
        meditationLastDate: ml?.day,
        exerciseGoalMin: e?.goalMinutes,
        exerciseTodayMin: el?.value,
        exerciseLastDate: el?.day,
        stepsGoal: e?.stepsGoal,
        stepsToday: sl?.value,
        stepsLastDate: sl?.day,
        officeWalkEveryMin: e?.walkEveryMinutes,
        officeStretchEveryMin: e?.stretchEveryMinutes,
        exerciseScheduleJson: e?.weekPlanJson,
        exerciseMilestonesJson: e?.milestonesJson,
        oneTimeReminders: List<String>.from(r.oneTimeReminders),
      );
    }).toList();
  }

  /// Most recent log per (habit, metric).
  Future<Map<String, Map<String, _Log>>> _latestLogs() async {
    final rows = await _db.customSelect(
      'SELECT l.habit_id, l.metric, l.day, l.value FROM habit_logs l '
      'WHERE l.day = (SELECT MAX(day) FROM habit_logs x '
      'WHERE x.habit_id = l.habit_id AND x.metric = l.metric)',
      readsFrom: {_db.habitLogs},
    ).get();
    final out = <String, Map<String, _Log>>{};
    for (final r in rows) {
      out.putIfAbsent(r.read<String>('habit_id'), () => {})[r.read<String>('metric')] =
          _Log(r.read<String>('day'), r.readNullable<int>('value'));
    }
    return out;
  }

  /// Daily values for Insights: metric -> day -> summed value across habits.
  Future<Map<String, Map<String, int>>> dailyTotals({
    required String fromDay,
    required String toDay,
  }) async {
    final rows = await (_db.select(_db.habitLogs)
          ..where((t) => t.day.isBetweenValues(fromDay, toDay)))
        .get();
    final out = <String, Map<String, int>>{};
    for (final r in rows) {
      final byDay = out.putIfAbsent(r.metric, () => {});
      byDay[r.day] = (byDay[r.day] ?? 0) + (r.value ?? 0);
    }
    return out;
  }

  Stream<void> watchLogs() => _db.select(_db.habitLogs).watch().map((_) {});

  // --------------------------------------------------------------- writes

  /// Replaces the stored set with [habits] (legacy "save the whole list"
  /// semantics used by the existing screens). Habits missing from the list
  /// are deleted together with their settings and history (cascade).
  Future<void> saveAll(List<Habit> habits) async {
    final now = DateTime.now();
    await _db.transaction(() async {
      final existing = {
        for (final r in await _db.select(_db.habits).get()) r.id: r,
      };
      for (var i = 0; i < habits.length; i++) {
        await _upsert(habits[i], sortOrder: i, now: now, createdAt: existing[habits[i].id]?.createdAt);
      }
      final keep = habits.map((h) => h.id).toSet();
      final toDelete = existing.keys.where((id) => !keep.contains(id)).toList();
      if (toDelete.isNotEmpty) {
        await (_db.delete(_db.habits)..where((t) => t.id.isIn(toDelete))).go();
      }
    });
  }

  Future<void> _upsert(Habit h,
      {required int sortOrder, required DateTime now, DateTime? createdAt}) async {
    await _db.into(_db.habits).insertOnConflictUpdate(HabitsCompanion.insert(
          id: h.id,
          name: h.name,
          category: h.category.name,
          enabled: Value(h.enabled),
          reminderHour: Value(h.reminderHour),
          reminderMinute: Value(h.reminderMinute),
          reminderTimes: Value(h.reminderTimes),
          oneTimeReminders: Value(h.oneTimeReminders),
          streak: Value(h.streak),
          lastCompletedAt: Value(h.lastCompleted),
          sortOrder: Value(sortOrder),
          createdAt: createdAt ?? now,
          updatedAt: now,
        ));

    // Per-category settings: stored whenever any field is set, so nothing a
    // legacy record carried is lost; removed when all fields are cleared.
    final hasMed = h.category == HabitCategory.medicine ||
        [h.medicineName, h.medicineDose, h.medicineNotes, h.medicineStartDate, h.medicineEndDate]
            .any((v) => v != null);
    if (hasMed) {
      await _db.into(_db.medicineDetails).insertOnConflictUpdate(MedicineDetailsCompanion.insert(
            habitId: h.id,
            medicineName: Value(h.medicineName),
            dose: Value(h.medicineDose),
            notes: Value(h.medicineNotes),
            startDate: Value(h.medicineStartDate),
            endDate: Value(h.medicineEndDate),
          ));
    } else {
      await (_db.delete(_db.medicineDetails)..where((t) => t.habitId.equals(h.id))).go();
    }

    if (h.waterTarget != null) {
      await _db.into(_db.waterSettings).insertOnConflictUpdate(
          WaterSettingsCompanion.insert(habitId: h.id, targetGlasses: Value(h.waterTarget)));
    } else {
      await (_db.delete(_db.waterSettings)..where((t) => t.habitId.equals(h.id))).go();
    }

    if (h.meditationGoalMin != null) {
      await _db.into(_db.meditationSettings).insertOnConflictUpdate(
          MeditationSettingsCompanion.insert(habitId: h.id, goalMinutes: Value(h.meditationGoalMin)));
    } else {
      await (_db.delete(_db.meditationSettings)..where((t) => t.habitId.equals(h.id))).go();
    }

    final hasEx = [
      h.exerciseGoalMin,
      h.stepsGoal,
      h.officeWalkEveryMin,
      h.officeStretchEveryMin,
      h.exerciseScheduleJson,
      h.exerciseMilestonesJson,
    ].any((v) => v != null);
    if (hasEx) {
      await _db.into(_db.exerciseSettings).insertOnConflictUpdate(ExerciseSettingsCompanion.insert(
            habitId: h.id,
            goalMinutes: Value(h.exerciseGoalMin),
            stepsGoal: Value(h.stepsGoal),
            walkEveryMinutes: Value(h.officeWalkEveryMin),
            stretchEveryMinutes: Value(h.officeStretchEveryMin),
            weekPlanJson: Value(h.exerciseScheduleJson),
            milestonesJson: Value(h.exerciseMilestonesJson),
          ));
    } else {
      await (_db.delete(_db.exerciseSettings)..where((t) => t.habitId.equals(h.id))).go();
    }

    // Daily counters become one history row per day (previous days are kept).
    Future<void> log(String metric, String? day, int? value) async {
      if (day == null) return;
      await _db.into(_db.habitLogs).insertOnConflictUpdate(HabitLogsCompanion.insert(
            habitId: h.id,
            day: day,
            metric: metric,
            value: Value(value),
            updatedAt: now,
          ));
    }

    await log(HabitMetric.waterGlasses, h.waterLastDate, h.waterCompleted);
    await log(HabitMetric.meditationMinutes, h.meditationLastDate, h.meditationTodayMin);
    await log(HabitMetric.exerciseMinutes, h.exerciseLastDate, h.exerciseTodayMin);
    await log(HabitMetric.steps, h.stepsLastDate, h.stepsToday);
    if (h.lastCompleted != null) {
      await log(HabitMetric.completed, ymd(h.lastCompleted!), 1);
    }
    // Undo of today's completion: drop today's completion row.
    final today = ymd(now);
    if (h.lastCompleted == null || ymd(h.lastCompleted!) != today) {
      await (_db.delete(_db.habitLogs)
            ..where((t) => t.habitId.equals(h.id) & t.day.equals(today) & t.metric.equals(HabitMetric.completed)))
          .go();
    }
  }

  static String ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

class _Log {
  final String day;
  final int? value;
  const _Log(this.day, this.value);
}
