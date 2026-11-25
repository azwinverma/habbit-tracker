import 'dart:convert';

import 'package:drift/drift.dart';

/// JSON-encoded `List<String>` column.
class StringListConverter extends TypeConverter<List<String>, String> {
  const StringListConverter();

  @override
  List<String> fromSql(String fromDb) {
    if (fromDb.isEmpty) return [];
    try {
      return (jsonDecode(fromDb) as List).map((e) => e.toString()).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  String toSql(List<String> value) => jsonEncode(value);
}

// ---------------------------------------------------------------------------
// Habits — common fields only. Category-specific settings live in their own
// tables instead of one model with dozens of unrelated nullable fields.
// ---------------------------------------------------------------------------

@DataClassName('HabitRow')
class Habits extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();

  /// HabitCategory.name: generic | medicine | water | meditation | reading | exercise
  TextColumn get category => text()();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
  IntColumn get reminderHour => integer().withDefault(const Constant(8))();
  IntColumn get reminderMinute => integer().withDefault(const Constant(0))();

  /// Daily reminder times as "HH:mm".
  TextColumn get reminderTimes =>
      text().map(const StringListConverter()).withDefault(const Constant('[]'))();

  /// One-time reminders as ISO-8601 local date-times.
  TextColumn get oneTimeReminders =>
      text().map(const StringListConverter()).withDefault(const Constant('[]'))();
  IntColumn get streak => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastCompletedAt => dateTime().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('MedicineDetailsRow')
class MedicineDetails extends Table {
  TextColumn get habitId => text().references(Habits, #id, onDelete: KeyAction.cascade)();
  TextColumn get medicineName => text().nullable()();
  TextColumn get dose => text().nullable()();
  TextColumn get notes => text().nullable()();

  /// "YYYY-MM-DD" (local calendar date).
  TextColumn get startDate => text().nullable()();
  TextColumn get endDate => text().nullable()();

  @override
  Set<Column> get primaryKey => {habitId};
}

@DataClassName('WaterSettingsRow')
class WaterSettings extends Table {
  TextColumn get habitId => text().references(Habits, #id, onDelete: KeyAction.cascade)();
  IntColumn get targetGlasses => integer().nullable()();

  @override
  Set<Column> get primaryKey => {habitId};
}

@DataClassName('MeditationSettingsRow')
class MeditationSettings extends Table {
  TextColumn get habitId => text().references(Habits, #id, onDelete: KeyAction.cascade)();
  IntColumn get goalMinutes => integer().nullable()();

  @override
  Set<Column> get primaryKey => {habitId};
}

@DataClassName('ExerciseSettingsRow')
class ExerciseSettings extends Table {
  TextColumn get habitId => text().references(Habits, #id, onDelete: KeyAction.cascade)();
  IntColumn get goalMinutes => integer().nullable()();
  IntColumn get stepsGoal => integer().nullable()();
  IntColumn get walkEveryMinutes => integer().nullable()();
  IntColumn get stretchEveryMinutes => integer().nullable()();
  TextColumn get weekPlanJson => text().nullable()();
  TextColumn get milestonesJson => text().nullable()();

  @override
  Set<Column> get primaryKey => {habitId};
}

/// One row per habit, local day and metric — the history that powers
/// Insights. Writing the same (habit, day, metric) again updates the row,
/// so logging is idempotent.
@DataClassName('HabitLogRow')
class HabitLogs extends Table {
  TextColumn get habitId => text().references(Habits, #id, onDelete: KeyAction.cascade)();

  /// Local calendar day "YYYY-MM-DD".
  TextColumn get day => text()();

  /// See [HabitMetric].
  TextColumn get metric => text()();
  IntColumn get value => integer().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {habitId, day, metric};
}

abstract final class HabitMetric {
  static const waterGlasses = 'water_glasses';
  static const meditationMinutes = 'meditation_minutes';
  static const exerciseMinutes = 'exercise_minutes';
  static const steps = 'steps';
  static const completed = 'completed';

  /// Medicine dose outcome for one scheduled time: `dose@HH:mm`, value is a
  /// [DoseStatus] code. Kept in habit_logs so history cascades with the habit.
  static const dosePrefix = 'dose@';
  static String dose(String hhmm) => '$dosePrefix$hhmm';
}

/// Values stored for [HabitMetric.dose] rows.
abstract final class DoseStatus {
  static const taken = 1;
  static const skipped = 2;
}

// ---------------------------------------------------------------------------
// Content catalogue (free / openly licensed providers), cached for offline.
// ---------------------------------------------------------------------------

@DataClassName('ContentItemRow')
class ContentItems extends Table {
  /// `provider:externalId`, e.g. `gutenberg:1342`.
  TextColumn get id => text()();
  TextColumn get provider => text()();

  /// book | audio | exercise | video | audiobook
  TextColumn get kind => text()();
  TextColumn get title => text()();
  TextColumn get subtitle => text().nullable()();
  TextColumn get description => text().nullable()();

  /// Direct media link (EPUB, MP3, …) — fetched only when the user opens it.
  TextColumn get mediaUrl => text().nullable()();

  /// epub | html | mp3 | video | audiobook | none
  TextColumn get mediaFormat => text().withDefault(const Constant('none'))();

  /// Second rendition for platforms that can't play [mediaUrl] (e.g. an
  /// MPEG-4 copy of a VP9 WebM for iOS). Schema v2.
  TextColumn get altMediaUrl => text().nullable()();

  /// Approximate media size, shown before streaming/downloading. Schema v2.
  IntColumn get mediaBytes => integer().nullable()();
  TextColumn get imageUrl => text().nullable()();
  TextColumn get sourceUrl => text().nullable()();
  TextColumn get license => text()();
  TextColumn get licenseUrl => text().nullable()();
  TextColumn get attribution => text().nullable()();
  TextColumn get tags =>
      text().map(const StringListConverter()).withDefault(const Constant('[]'))();
  TextColumn get language => text().nullable()();
  IntColumn get durationSeconds => integer().nullable()();
  IntColumn get popularity => integer().withDefault(const Constant(0))();
  DateTimeColumn get firstSeenAt => dateTime()();
  DateTimeColumn get lastSeenAt => dateTime()();

  /// False for items that arrived in a refresh after the first one, until the
  /// user has viewed them — drives the "New" badges.
  BoolColumn get seen => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Media saved on the device for offline use (schema v2). Rows survive
/// catalogue refreshes; downloaded items are never pruned.
@DataClassName('ContentDownloadRow')
class ContentDownloads extends Table {
  TextColumn get contentId => text()();

  /// Which URL was saved (main or alternate rendition, or a chapter).
  TextColumn get url => text()();

  /// Absolute path inside the app's private storage.
  TextColumn get localPath => text()();
  IntColumn get bytes => integer().withDefault(const Constant(0))();
  DateTimeColumn get savedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {contentId, url};
}

@DataClassName('ContentSyncStateRow')
class ContentSyncStates extends Table {
  TextColumn get provider => text()();
  DateTimeColumn get lastAttemptAt => dateTime().nullable()();
  DateTimeColumn get lastSuccessAt => dateTime().nullable()();
  TextColumn get lastError => text().nullable()();
  IntColumn get itemCount => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {provider};
}

/// Small key/value store for app-level flags (migrations, preferences).
@DataClassName('AppMetaRow')
class AppMeta extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}
