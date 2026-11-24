import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/db/app_database.dart';
import '../features/habits/data/habit_repository.dart';
import '../features/habits/data/legacy_habit_migrator.dart';
import '../models/habit.dart';

/// Facade used by the existing screens. Since Phase 1 the source of truth is
/// SQLite ([HabitRepository]); this class keeps the old API so screens did not
/// need to change.
///
/// Safety net (Phase 1–2): every save is mirrored to the legacy `habits_v1`
/// JSON so a downgrade to v1.0.0 loses nothing, and if the database cannot be
/// opened or migrated the app falls back to that JSON instead of failing.
class StorageService {
  StorageService({AppDatabase? db}) : _db = db ?? AppDatabase.instance;

  static const _kKey = LegacyHabitMigrator.prefsKey;

  final AppDatabase _db;

  HabitRepository get _repo => HabitRepository(_db);

  Future<List<Habit>> loadHabits() async {
    try {
      await LegacyHabitMigrator.ensureMigrated(_db);
      return await _repo.loadAll();
    } catch (e) {
      debugPrint('[Storage] DB unavailable, using legacy JSON: $e');
      return _loadLegacy();
    }
  }

  Future<void> saveHabits(List<Habit> habits) async {
    Object? dbError;
    try {
      await LegacyHabitMigrator.ensureMigrated(_db);
      await _repo.saveAll(habits);
    } catch (e) {
      dbError = e;
    }
    await _saveLegacy(habits);
    if (dbError != null) debugPrint('[Storage] DB save failed (legacy JSON saved): $dbError');
  }

  Future<List<Habit>> _loadLegacy() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kKey);
    if (raw == null || raw.isEmpty) return [];
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    return list.map((e) => Habit.fromJson(e)).toList();
  }

  Future<void> _saveLegacy(List<Habit> habits) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kKey, jsonEncode(habits.map((e) => e.toJson()).toList()));
  }
}
