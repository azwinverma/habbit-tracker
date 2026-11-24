import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/db/app_database.dart';
import '../core/reminders/reminder_service.dart';
import '../features/content/data/content_repository.dart';
import '../features/content/data/content_sync_service.dart';
import '../features/content/domain/content_item.dart';
import '../features/habits/data/habit_repository.dart';
import '../models/habit.dart';
import '../services/notification_service.dart';

// ---- data ----

final appDatabaseProvider = Provider<AppDatabase>((ref) => AppDatabase.instance);

final habitRepositoryProvider =
    Provider<HabitRepository>((ref) => HabitRepository(ref.watch(appDatabaseProvider)));

final habitsProvider =
    StreamProvider<List<Habit>>((ref) => ref.watch(habitRepositoryProvider).watchAll());

final contentRepositoryProvider =
    Provider<ContentRepository>((ref) => ContentRepository(ref.watch(appDatabaseProvider)));

final contentSyncServiceProvider =
    Provider<ContentSyncService>((ref) => ContentSyncService.instance);

final newContentCountProvider =
    StreamProvider<int>((ref) => ref.watch(contentRepositoryProvider).watchNewCount());

final contentSyncStatesProvider = StreamProvider<List<ContentSyncStateRow>>(
    (ref) => ref.watch(contentRepositoryProvider).watchSyncStates());

typedef ContentQuery = ({ContentKind kind, String search, String? tag});

final contentListProvider = StreamProvider.family<List<ContentItemRow>, ContentQuery>(
  (ref, q) => ref.watch(contentRepositoryProvider).watch(q.kind, search: q.search, tag: q.tag),
);

/// Insights: per-metric daily totals for the last [days] days, refreshed
/// whenever habit logs change.
final dailyTotalsProvider = StreamProvider.family<Map<String, Map<String, int>>, int>((ref, days) async* {
  final repo = ref.watch(habitRepositoryProvider);
  Future<Map<String, Map<String, int>>> load() {
    final now = DateTime.now();
    final from = DateTime(now.year, now.month, now.day - (days - 1));
    return repo.dailyTotals(fromDay: HabitRepository.ymd(from), toDay: HabitRepository.ymd(now));
  }

  yield await load();
  await for (final _ in repo.watchLogs()) {
    yield await load();
  }
});

// ---- reminders diagnostics ----

final exactAlarmAllowedProvider =
    FutureProvider.autoDispose<bool>((ref) => ReminderService.instance.canScheduleExact());

final notificationsEnabledProvider =
    FutureProvider.autoDispose<bool?>((ref) => NotificationService.areNotificationsEnabled());

// ---- preferences ----

class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const _key = 'theme_mode';

  @override
  ThemeMode build() {
    _load();
    return ThemeMode.system;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString(_key);
    final mode = ThemeMode.values.where((m) => m.name == v).firstOrNull;
    if (mode != null && mode != state) state = mode;
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode.name);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

/// null = follow the phone's language.
class LocaleNotifier extends Notifier<Locale?> {
  static const _key = 'app_locale';

  @override
  Locale? build() {
    _load();
    return null;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString(_key);
    if (v != null && v.isNotEmpty) state = Locale(v);
  }

  Future<void> set(Locale? locale) async {
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    if (locale == null) {
      await prefs.remove(_key);
    } else {
      await prefs.setString(_key, locale.languageCode);
    }
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale?>(LocaleNotifier.new);
