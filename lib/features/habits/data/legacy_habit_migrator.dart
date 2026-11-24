import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/db/app_database.dart';
import '../../../models/habit.dart';
import 'habit_repository.dart';

/// One-time import of v1.0.0 data (`habits_v1` JSON in SharedPreferences)
/// into the SQLite database.
///
/// - Runs in a single transaction and verifies the imported row count before
///   setting the done-flag; any failure rolls back and is retried next launch.
/// - Never modifies or deletes `habits_v1` (rollback safety).
/// - Idempotent and safe to call concurrently.
class LegacyHabitMigrator {
  static const prefsKey = 'habits_v1';
  static const doneFlag = 'migrated_habits_v1';

  static Future<void>? _inflight;

  static Future<void> ensureMigrated(AppDatabase db) {
    return _inflight ??= _run(db).catchError((Object e, StackTrace st) {
      _inflight = null; // allow a retry
      debugPrint('[Migration] habits_v1 import failed: $e');
      Error.throwWithStackTrace(e, st);
    });
  }

  @visibleForTesting
  static void resetForTest() => _inflight = null;

  static Future<void> _run(AppDatabase db) async {
    if (await db.getMeta(doneFlag) != null) return;

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(prefsKey);
    final habits = <String, Habit>{};
    if (raw != null && raw.isNotEmpty) {
      for (final e in (jsonDecode(raw) as List).cast<Map<String, dynamic>>()) {
        final h = Habit.fromJson(e);
        habits[h.id] = h; // de-duplicate by id (last write wins, as before)
      }
    }

    final repo = HabitRepository(db);
    await db.transaction(() async {
      await repo.saveAll(habits.values.toList());
      final count = (await db.select(db.habits).get()).length;
      if (count != habits.length) {
        throw StateError('verification failed: expected ${habits.length}, found $count');
      }
      await db.setMeta(doneFlag, DateTime.now().toIso8601String());
    });
    debugPrint('[Migration] imported ${habits.length} habits from habits_v1');
  }
}
