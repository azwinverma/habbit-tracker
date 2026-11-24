// lib/models/habit.dart
import 'dart:convert';
import 'package:flutter/material.dart';

enum HabitCategory { medicine, generic, water, meditation, reading, exercise }

class Habit {
  // ---- Identity / base ----
  final String id;
  String name;
  bool enabled;

  // Primary fallback time (used when reminderTimes is empty)
  int reminderHour;   // 0-23
  int reminderMinute; // 0-59

  // Multiple daily times in "HH:mm" (e.g., ["06:30","20:00"])
  List<String> reminderTimes;

  HabitCategory category;

  // Completion meta (for generic streaks)
  int streak;
  DateTime? lastCompleted;

  // ---- Water ----
  int? waterTarget;        // glasses/day
  int? waterCompleted;     // today
  String? waterLastDate;   // "YYYY-MM-DD"

  // ---- Meditation ----
  int? meditationGoalMin;      // minutes/day
  int? meditationTodayMin;     // minutes done today
  String? meditationLastDate;  // "YYYY-MM-DD"

  // ---- Reading (no dedicated fields required yet) ----
  // (Your Reading screen tracks reminders + session only.)

  // ---- Medicine ----
  String? medicineName;
  String? medicineDose;
  String? medicineNotes;
  String? medicineStartDate; // "YYYY-MM-DD"
  String? medicineEndDate;   // "YYYY-MM-DD"

  // ---- Exercise ----
  // Minutes goal/progress (used by Exercise screen)
  int? exerciseGoalMin;      // minutes/day
  int? exerciseTodayMin;     // minutes done today
  String? exerciseLastDate;  // "YYYY-MM-DD"

  // Steps counters
  int? stepsGoal;            // default 6000
  int? stepsToday;           // counted today
  String? stepsLastDate;     // "YYYY-MM-DD"

  // Office worker helpers (optional recurring cues, minutes interval)
  int? officeWalkEveryMin;       // null = disabled
  int? officeStretchEveryMin;    // null = disabled

  // Schedule & milestones JSON blobs (stringified JSON)
  // Expected shapes:
  //   exerciseScheduleJson: Map<String, List<Map<String,String>>>
  //     e.g. { "Monday": [ {"name":"Flat push-ups","level":"Beginner"} ], ... }
  //   exerciseMilestonesJson: List<Map<String,dynamic>> (free-form)
  String? exerciseScheduleJson;
  String? exerciseMilestonesJson;

  /// One-time reminders as ISO-8601 local date-times. Persisted so they can
  /// be cancelled, restored after reboot, and rescheduled on app start.
  List<String> oneTimeReminders;

  // ---- ctor ----
  Habit({
    required this.id,
    required this.name,
    required this.enabled,
    required this.reminderHour,
    required this.reminderMinute,
    this.reminderTimes = const [],
    this.category = HabitCategory.generic,
    this.streak = 0,
    this.lastCompleted,

    // water
    this.waterTarget,
    this.waterCompleted,
    this.waterLastDate,

    // meditation
    this.meditationGoalMin,
    this.meditationTodayMin,
    this.meditationLastDate,

    // medicine
    this.medicineName,
    this.medicineDose,
    this.medicineNotes,
    this.medicineStartDate,
    this.medicineEndDate,

    // exercise minutes
    this.exerciseGoalMin,
    this.exerciseTodayMin,
    this.exerciseLastDate,

    // steps
    this.stepsGoal,
    this.stepsToday,
    this.stepsLastDate,

    // office cues
    this.officeWalkEveryMin,
    this.officeStretchEveryMin,

    // schedule/milestones
    this.exerciseScheduleJson,
    this.exerciseMilestonesJson,
    List<String>? oneTimeReminders,
  }) : oneTimeReminders = oneTimeReminders ?? [];

  // ---- JSON ----
  factory Habit.fromJson(Map<String, dynamic> j) => Habit(
        id: j['id'] as String,
        name: j['name'] as String,
        enabled: j['enabled'] as bool? ?? true,
        reminderHour: j['reminderHour'] as int? ?? 8,
        reminderMinute: j['reminderMinute'] as int? ?? 0,
        reminderTimes: (j['reminderTimes'] as List?)?.cast<String>() ?? const [],
        category: _catFrom(j['category'] as String?),
        streak: j['streak'] as int? ?? 0,
        lastCompleted: j['lastCompleted'] != null
            ? DateTime.tryParse(j['lastCompleted'] as String)
            : null,

        // water
        waterTarget: j['waterTarget'] as int?,
        waterCompleted: j['waterCompleted'] as int?,
        waterLastDate: j['waterLastDate'] as String?,

        // meditation
        meditationGoalMin: j['meditationGoalMin'] as int?,
        meditationTodayMin: j['meditationTodayMin'] as int?,
        meditationLastDate: j['meditationLastDate'] as String?,

        // medicine
        medicineName: j['medicineName'] as String?,
        medicineDose: j['medicineDose'] as String?,
        medicineNotes: j['medicineNotes'] as String?,
        medicineStartDate: j['medicineStartDate'] as String?,
        medicineEndDate: j['medicineEndDate'] as String?,

        // exercise minutes
        exerciseGoalMin: j['exerciseGoalMin'] as int?,
        exerciseTodayMin: j['exerciseTodayMin'] as int?,
        exerciseLastDate: j['exerciseLastDate'] as String?,

        // steps
        stepsGoal: j['stepsGoal'] as int?,
        stepsToday: j['stepsToday'] as int?,
        stepsLastDate: j['stepsLastDate'] as String?,

        // office cues
        officeWalkEveryMin: j['officeWalkEveryMin'] as int?,
        officeStretchEveryMin: j['officeStretchEveryMin'] as int?,

        // schedule/milestones
        exerciseScheduleJson: j['exerciseScheduleJson'] as String?,
        exerciseMilestonesJson: j['exerciseMilestonesJson'] as String?,
        oneTimeReminders:
            (j['oneTimeReminders'] as List?)?.cast<String>().toList() ?? [],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'enabled': enabled,
        'reminderHour': reminderHour,
        'reminderMinute': reminderMinute,
        'reminderTimes': reminderTimes,
        'category': category.name,
        'streak': streak,
        'lastCompleted': lastCompleted?.toIso8601String(),

        // water
        'waterTarget': waterTarget,
        'waterCompleted': waterCompleted,
        'waterLastDate': waterLastDate,

        // meditation
        'meditationGoalMin': meditationGoalMin,
        'meditationTodayMin': meditationTodayMin,
        'meditationLastDate': meditationLastDate,

        // medicine
        'medicineName': medicineName,
        'medicineDose': medicineDose,
        'medicineNotes': medicineNotes,
        'medicineStartDate': medicineStartDate,
        'medicineEndDate': medicineEndDate,

        // exercise minutes
        'exerciseGoalMin': exerciseGoalMin,
        'exerciseTodayMin': exerciseTodayMin,
        'exerciseLastDate': exerciseLastDate,

        // steps
        'stepsGoal': stepsGoal,
        'stepsToday': stepsToday,
        'stepsLastDate': stepsLastDate,

        // office cues
        'officeWalkEveryMin': officeWalkEveryMin,
        'officeStretchEveryMin': officeStretchEveryMin,

        // schedule/milestones
        'exerciseScheduleJson': exerciseScheduleJson,
        'exerciseMilestonesJson': exerciseMilestonesJson,
        'oneTimeReminders': oneTimeReminders,
      };

  // ---- Enum parsing ----
  static HabitCategory _catFrom(String? s) {
    switch (s) {
      case 'medicine':
        return HabitCategory.medicine;
      case 'water':
        return HabitCategory.water;
      case 'meditation':
        return HabitCategory.meditation;
      case 'reading':
        return HabitCategory.reading;
      case 'exercise':
        return HabitCategory.exercise;
      default:
        return HabitCategory.generic;
    }
  }

  // ---- Time helpers ----
  /// Parse "HH:mm" (24h) to TimeOfDay
  static TimeOfDay parseHHmm(String hhmm) {
    final parts = hhmm.split(':');
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    return TimeOfDay(hour: h.clamp(0, 23), minute: m.clamp(0, 59));
  }

  /// Format TimeOfDay as "HH:mm" (24h)
  static String fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  // ---- Day reset helpers (per-module) ----
  /// Ensure daily counters are reset if the stored date != today for
  /// water/meditation/exercise/steps (used by screens on init).
  void ensureTodayResets(DateTime now) {
    final ymd = _ymd(now);

    // Water
    if (waterLastDate != ymd) {
      waterLastDate = ymd;
      waterCompleted = 0;
    }

    // Meditation
    if (meditationLastDate != ymd) {
      meditationLastDate = ymd;
      meditationTodayMin = 0;
    }

    // Exercise minutes
    if (exerciseLastDate != ymd) {
      exerciseLastDate = ymd;
      exerciseTodayMin = 0;
    }

    // Steps
    if (stepsLastDate != ymd) {
      stepsLastDate = ymd;
      stepsToday = 0;
    }
  }

  // ---- Schedule JSON helpers ----
  /// Decode exerciseScheduleJson into:
  /// `Map<String, List<Map<String, String>>>`
  Map<String, List<Map<String, String>>> decodeExerciseScheduleOrEmpty() {
    final raw = exerciseScheduleJson;
    if (raw == null || raw.isEmpty) {
      return {};
    }
    try {
      final decoded = json.decode(raw);
      if (decoded is! Map) return {};
      final Map<String, List<Map<String, String>>> out = {};
      decoded.forEach((key, value) {
        if (value is List) {
          out[key.toString()] =
              value.map<Map<String, String>>((e) => Map<String, String>.from(e as Map)).toList();
        }
      });
      return out;
    } catch (_) {
      return {};
    }
  }

  /// Encode schedule map to exerciseScheduleJson
  void encodeAndSetExerciseSchedule(Map<String, List<Map<String, String>>> schedule) {
    try {
      exerciseScheduleJson = json.encode(schedule);
    } catch (_) {
      exerciseScheduleJson = '{}';
    }
  }

  // ---- Utilities ----
  Habit copyWith({
    String? name,
    bool? enabled,
    int? reminderHour,
    int? reminderMinute,
    List<String>? reminderTimes,
    HabitCategory? category,
    int? streak,
    DateTime? lastCompleted,

    // water
    int? waterTarget,
    int? waterCompleted,
    String? waterLastDate,

    // meditation
    int? meditationGoalMin,
    int? meditationTodayMin,
    String? meditationLastDate,

    // medicine
    String? medicineName,
    String? medicineDose,
    String? medicineNotes,
    String? medicineStartDate,
    String? medicineEndDate,

    // exercise minutes
    int? exerciseGoalMin,
    int? exerciseTodayMin,
    String? exerciseLastDate,

    // steps
    int? stepsGoal,
    int? stepsToday,
    String? stepsLastDate,

    // office cues
    int? officeWalkEveryMin,
    int? officeStretchEveryMin,

    // schedule
    String? exerciseScheduleJson,
    String? exerciseMilestonesJson,
  }) {
    return Habit(
      id: id,
      name: name ?? this.name,
      enabled: enabled ?? this.enabled,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      reminderTimes: reminderTimes ?? List<String>.from(this.reminderTimes),
      category: category ?? this.category,
      streak: streak ?? this.streak,
      lastCompleted: lastCompleted ?? this.lastCompleted,

      // water
      waterTarget: waterTarget ?? this.waterTarget,
      waterCompleted: waterCompleted ?? this.waterCompleted,
      waterLastDate: waterLastDate ?? this.waterLastDate,

      // meditation
      meditationGoalMin: meditationGoalMin ?? this.meditationGoalMin,
      meditationTodayMin: meditationTodayMin ?? this.meditationTodayMin,
      meditationLastDate: meditationLastDate ?? this.meditationLastDate,

      // medicine
      medicineName: medicineName ?? this.medicineName,
      medicineDose: medicineDose ?? this.medicineDose,
      medicineNotes: medicineNotes ?? this.medicineNotes,
      medicineStartDate: medicineStartDate ?? this.medicineStartDate,
      medicineEndDate: medicineEndDate ?? this.medicineEndDate,

      // exercise minutes
      exerciseGoalMin: exerciseGoalMin ?? this.exerciseGoalMin,
      exerciseTodayMin: exerciseTodayMin ?? this.exerciseTodayMin,
      exerciseLastDate: exerciseLastDate ?? this.exerciseLastDate,

      // steps
      stepsGoal: stepsGoal ?? this.stepsGoal,
      stepsToday: stepsToday ?? this.stepsToday,
      stepsLastDate: stepsLastDate ?? this.stepsLastDate,

      // office cues
      officeWalkEveryMin: officeWalkEveryMin ?? this.officeWalkEveryMin,
      officeStretchEveryMin: officeStretchEveryMin ?? this.officeStretchEveryMin,

      // schedule
      exerciseScheduleJson: exerciseScheduleJson ?? this.exerciseScheduleJson,
      exerciseMilestonesJson:
          exerciseMilestonesJson ?? this.exerciseMilestonesJson,
    );
  }

  // ---- Private helpers ----
  static String _ymd(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // (Optional) expose JSON encode/decode for other extensions
  static String jsonEncode(Object? obj) => json.encode(obj);
  static dynamic jsonDecode(String s) => json.decode(s);
}

