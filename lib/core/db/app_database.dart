import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables.dart';

export 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  Habits,
  MedicineDetails,
  WaterSettings,
  MeditationSettings,
  ExerciseSettings,
  HabitLogs,
  ContentItems,
  ContentSyncStates,
  AppMeta,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// The on-device database (SQLite file `dailymantra.sqlite`).
  factory AppDatabase.device() => AppDatabase(driftDatabase(name: 'dailymantra'));

  static AppDatabase? _instance;

  /// Process-wide instance shared by legacy services and Riverpod providers.
  static AppDatabase get instance => _instance ??= AppDatabase.device();

  /// For tests.
  static set instance(AppDatabase db) => _instance = db;

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  // ---- AppMeta helpers ----

  Future<String?> getMeta(String key) async {
    final row = await (select(appMeta)..where((t) => t.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<void> setMeta(String key, String value) =>
      into(appMeta).insertOnConflictUpdate(AppMetaCompanion.insert(key: key, value: value));
}
