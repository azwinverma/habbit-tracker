import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/habit.dart';
import '../../services/native_alarm.dart';
import 'alarm_id.dart';
import 'habit_reminder_planner.dart';

/// The one place in the app that schedules or cancels reminders.
///
/// It keeps a registry (habitId -> alarm ids it armed) in SharedPreferences,
/// so that editing times, disabling, or deleting a habit cancels exactly the
/// alarms that belong to it — no orphans, no duplicates.
class ReminderService {
  ReminderService({AlarmBackend? backend}) : _backend = backend ?? NativeAlarmBackend();

  static ReminderService instance = ReminderService();

  static const registryKey = 'reminder_registry_v1';
  static const migratedKey = 'reminders_migrated_v2';

  final AlarmBackend _backend;

  /// Run once per app start (before any screen schedules anything):
  /// retires pre-2.0 alarms on first run, then re-arms every habit's
  /// reminders from its saved data and cancels reminders of deleted habits.
  Future<void> startup(List<Habit> habits, {DateTime? now}) async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(migratedKey) ?? false)) {
      try {
        await _backend.enableLegacyCleanup();
        final n = await _backend.cancelLegacyPluginAlarms();
        debugPrint('[Reminders] legacy migration: cancelled $n plugin alarms');
        await prefs.setBool(migratedKey, true);
      } catch (e) {
        // Leave the flag unset so we retry next launch.
        debugPrint('[Reminders] legacy migration failed: $e');
      }
    }
    await reconcileAll(habits, now: now);
  }

  /// Makes the OS alarms match [habits] exactly.
  Future<void> reconcileAll(List<Habit> habits, {DateTime? now}) async {
    final registry = await _loadRegistry();
    final liveIds = habits.map((h) => h.id).toSet();
    for (final orphan in registry.keys.where((k) => !liveIds.contains(k)).toList()) {
      await _cancelIds(registry.remove(orphan)!);
    }
    await _saveRegistry(registry);
    for (final h in habits) {
      await syncHabit(h, now: now);
    }
  }

  /// Re-plans one habit: arms its current reminders and cancels any it no
  /// longer has (removed times, disabled, finished medicine course...).
  Future<void> syncHabit(Habit h, {DateTime? now}) async {
    final specs = HabitReminderPlanner.plan(h, now ?? DateTime.now());
    final registry = await _loadRegistry();
    final previous = registry[h.id] ?? const <int>[];
    final next = specs.map((s) => s.id).toList();

    await _cancelIds(previous.where((id) => !next.contains(id)));
    final armed = <int>[];
    for (final s in specs) {
      try {
        await _backend.schedule(s);
        armed.add(s.id);
      } catch (e) {
        debugPrint('[Reminders] schedule failed for ${s.key}: $e');
      }
    }
    if (armed.isEmpty) {
      registry.remove(h.id);
    } else {
      registry[h.id] = armed;
    }
    await _saveRegistry(registry);
  }

  /// Cancels every reminder belonging to a habit (call on delete).
  Future<void> cancelHabit(String habitId) async {
    final registry = await _loadRegistry();
    final ids = registry.remove(habitId);
    if (ids != null) await _cancelIds(ids);
    await cancelSessionEnd(habitId);
    await _saveRegistry(registry);
  }

  // ---- Session-end alarms (meditation / reading / workout timers) ----

  static int sessionAlarmId(String habitId) => stableAlarmId('$habitId|session');

  Future<void> scheduleSessionEnd(String habitId, DateTime at,
      {required String title, required String body}) async {
    try {
      await _backend.scheduleRaw(
          id: sessionAlarmId(habitId), at: at, title: title, body: body);
    } catch (e) {
      debugPrint('[Reminders] session alarm failed: $e');
    }
  }

  Future<void> cancelSessionEnd(String habitId) async {
    try {
      await _backend.cancel(sessionAlarmId(habitId));
    } catch (e) {
      debugPrint('[Reminders] cancel session alarm failed: $e');
    }
  }

  // ---- Exact-alarm permission (Android 12+) ----

  Future<bool> canScheduleExact() async {
    try {
      return await _backend.canScheduleExact();
    } catch (_) {
      return true;
    }
  }

  Future<void> openExactAlarmSettings() => _backend.openExactAlarmSettings();

  // ---- internals ----

  Future<void> _cancelIds(Iterable<int> ids) async {
    for (final id in ids) {
      try {
        await _backend.cancel(id);
      } catch (e) {
        debugPrint('[Reminders] cancel $id failed: $e');
      }
    }
  }

  Future<Map<String, List<int>>> _loadRegistry() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(registryKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return m.map((k, v) => MapEntry(k, (v as List).cast<int>().toList()));
    } catch (_) {
      return {};
    }
  }

  Future<void> _saveRegistry(Map<String, List<int>> r) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(registryKey, jsonEncode(r));
  }
}
