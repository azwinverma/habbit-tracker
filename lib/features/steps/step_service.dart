import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/db/app_database.dart';
import '../../models/habit.dart';
import '../../services/storage_service.dart';

/// Automatic step counting with the phone's built-in step sensor.
///
/// How it works
/// - The hardware step counter (Android `TYPE_STEP_COUNTER`, iPhone motion
///   coprocessor via Core Motion) counts all the time at almost no battery
///   cost and reports a running total since the phone was switched on.
/// - We keep the last total we saw; each new reading adds the difference
///   to *today's* count. A reading lower than the last one means the phone
///   restarted (Android), so the new total is all new steps.
/// - Readings happen when the app opens / returns to the foreground, live
///   while the Exercise screen is open, and every ~15 min in the background
///   on Android (WorkManager), so steps land on the right day even if the
///   app isn't opened.
/// - Daily totals (14 days) live on the phone only (AppMeta `steps:state`)
///   and are written into the exercise habit (Today, Insights, history).
/// - Manual "+50 / +100 / +500" stays for walks without the phone; those are
///   kept separately so sensor updates never overwrite them.
///
/// Limits: steps taken while the phone is switched off are not counted;
/// counting starts when the user turns it on (the sensor has no history on
/// Android).
class StepService {
  StepService(this._db, {Stream<int> Function()? sensor, bool? isAndroid, DateTime Function()? clock})
      : _sensor = sensor ?? (() => Pedometer.stepCountStream.map((e) => e.steps)),
        _isAndroid = isAndroid ?? (!kIsWeb && Platform.isAndroid),
        _clock = clock ?? DateTime.now;

  static StepService? _instance;
  static StepService get instance => _instance ??= StepService(AppDatabase.instance);
  static set instance(StepService s) => _instance = s;

  final AppDatabase _db;
  final Stream<int> Function() _sensor;
  final bool _isAndroid;
  final DateTime Function() _clock;

  static const _stateKey = 'steps:state';
  static const _enabledKey = 'steps:enabled';

  /// Today's total (sensor + manual), for live UI.
  final ValueNotifier<int?> today = ValueNotifier<int?>(null);

  // ---------------------------------------------------------------- enable

  Future<bool> isEnabled() async => (await _db.getMeta(_enabledKey)) == '1';

  /// Asks for the activity permission (Android 10+; iPhone shows its motion
  /// prompt on first use), checks the phone has a step sensor, and starts
  /// counting from now.
  Future<StepEnableResult> enable() async {
    if (_isAndroid) {
      final status = await Permission.activityRecognition.request();
      if (status.isPermanentlyDenied) return StepEnableResult.permanentlyDenied;
      if (!status.isGranted) return StepEnableResult.denied;
    }
    final raw = await _readOnce(timeout: const Duration(seconds: 8));
    if (raw == null) return StepEnableResult.noSensor;
    await _db.setMeta(_enabledKey, '1');
    await _record(raw);
    await applyToHabits();
    return StepEnableResult.enabled;
  }

  Future<void> disable() async {
    await _db.setMeta(_enabledKey, '0');
    await _stopLive();
  }

  static Future<void> openSettings() => openAppSettings();

  // ---------------------------------------------------------------- sampling

  /// One reading → state → habits. Safe to call often (app open/resume,
  /// background task). Never throws.
  Future<void> sync({bool writeHabits = true}) async {
    try {
      if (!await isEnabled()) return;
      if (_isAndroid && !await Permission.activityRecognition.isGranted) return;
      final raw = await _readOnce(timeout: const Duration(seconds: 6));
      if (raw != null) await _record(raw);
      if (writeHabits) await applyToHabits();
    } catch (e) {
      debugPrint('[Steps] sync failed: $e');
    }
  }

  StreamSubscription<int>? _live;
  Timer? _applyDebounce;

  /// Live updates while a steps screen is visible.
  Future<void> startLive() async {
    if (_live != null || !await isEnabled()) return;
    _live = _sensor().listen((raw) async {
      await _record(raw);
      _applyDebounce?.cancel();
      _applyDebounce = Timer(const Duration(seconds: 3), applyToHabits);
    }, onError: (Object e) => debugPrint('[Steps] live: $e'));
  }

  Future<void> stopLive() => _stopLive();

  Future<void> _stopLive() async {
    _applyDebounce?.cancel();
    await _live?.cancel();
    _live = null;
  }

  Future<int?> _readOnce({required Duration timeout}) async {
    try {
      return await _sensor().first.timeout(timeout);
    } catch (e) {
      debugPrint('[Steps] no reading: $e');
      return null;
    }
  }

  Future<void> _record(int raw) async {
    final s = await loadState();
    final next = StepState.apply(s, raw, _clock(), rebootResets: _isAndroid);
    await _saveState(next);
    today.value = next.totalFor(ymd(_clock()));
  }

  // ---------------------------------------------------------------- manual

  /// Steps walked without the phone (kept apart from sensor counts).
  Future<void> addManual(int steps) async {
    final s = await loadState();
    final d = ymd(_clock());
    s.manual[d] = (s.manual[d] ?? 0) + steps;
    await _saveState(s);
    today.value = s.totalFor(d);
    await applyToHabits();
  }

  /// Clears today's manual additions (sensor steps stay).
  Future<void> resetManual() async {
    final s = await loadState();
    final d = ymd(_clock());
    s.manual.remove(d);
    await _saveState(s);
    today.value = s.totalFor(d);
    await applyToHabits();
  }

  // ---------------------------------------------------------------- habits

  /// Writes today's total into every exercise habit and fills step history
  /// for recent days the app wasn't opened.
  Future<void> applyToHabits() async {
    final s = await loadState();
    final now = _clock();
    final todayKey = ymd(now);
    final storage = StorageService();
    final habits = await storage.loadHabits();
    final exercise = habits.where((h) => h.category == HabitCategory.exercise).toList();
    if (exercise.isEmpty) return;
    for (final h in exercise) {
      h.stepsToday = s.totalFor(todayKey);
      h.stepsLastDate = todayKey;
    }
    await storage.saveHabits(habits);
    // Past days (history rows only).
    for (final day in s.allDays.where((d) => d != todayKey)) {
      for (final h in exercise) {
        await _db.into(_db.habitLogs).insertOnConflictUpdate(HabitLogsCompanion.insert(
              habitId: h.id,
              day: day,
              metric: HabitMetric.steps,
              value: Value(s.totalFor(day)),
              updatedAt: now,
            ));
      }
    }
    today.value = s.totalFor(todayKey);
  }

  // ---------------------------------------------------------------- state

  Future<StepState> loadState() async {
    final raw = await _db.getMeta(_stateKey);
    return raw == null ? StepState() : StepState.fromJson(raw);
  }

  Future<void> _saveState(StepState s) => _db.setMeta(_stateKey, s.toJson());

  static String ymd(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

enum StepEnableResult { enabled, denied, permanentlyDenied, noSensor }

/// Pure step bookkeeping (unit-tested).
class StepState {
  StepState({this.lastRaw, this.lastDay, Map<String, int>? days, Map<String, int>? manual})
      : days = days ?? {},
        manual = manual ?? {};

  /// Last sensor total seen (steps since the phone was switched on).
  int? lastRaw;
  String? lastDay;

  /// Sensor steps per day (yyyy-MM-dd).
  final Map<String, int> days;

  /// Manually added steps per day.
  final Map<String, int> manual;

  /// More than this between two readings is a sensor glitch, not walking.
  static const maxDelta = 60000;
  static const keepDays = 14;

  int totalFor(String day) => (days[day] ?? 0) + (manual[day] ?? 0);

  Iterable<String> get allDays => {...days.keys, ...manual.keys};

  /// Adds a new sensor reading taken at [now].
  /// [rebootResets]: on Android the total restarts at 0 after a reboot, so a
  /// lower reading means "all new steps". (On iPhone the plugin's total can
  /// shrink as Core Motion's 7-day window moves, so we just re-baseline.)
  static StepState apply(StepState s, int raw, DateTime now, {bool rebootResets = true}) {
    final today = StepService.ymd(now);
    if (s.lastRaw == null) {
      // First reading: counting starts now.
      s.days[today] ??= 0;
    } else {
      var delta = raw >= s.lastRaw! ? raw - s.lastRaw! : (rebootResets ? raw : 0);
      if (delta < 0 || delta > maxDelta) delta = 0;
      // Steps since the last reading go to today (readings are ≤ 15 min apart
      // in the background, so little lands on the wrong side of midnight).
      s.days[today] = (s.days[today] ?? 0) + delta;
    }
    s.lastRaw = raw;
    s.lastDay = today;
    _prune(s, now);
    return s;
  }

  static void _prune(StepState s, DateTime now) {
    final cutoff = StepService.ymd(now.subtract(const Duration(days: keepDays)));
    s.days.removeWhere((d, _) => d.compareTo(cutoff) < 0);
    s.manual.removeWhere((d, _) => d.compareTo(cutoff) < 0);
  }

  String toJson() => jsonEncode({'r': lastRaw, 'l': lastDay, 'd': days, 'm': manual});

  factory StepState.fromJson(String raw) {
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      return StepState(
        lastRaw: j['r'] as int?,
        lastDay: j['l'] as String?,
        days: (j['d'] as Map?)?.map((k, v) => MapEntry('$k', (v as num).toInt())),
        manual: (j['m'] as Map?)?.map((k, v) => MapEntry('$k', (v as num).toInt())),
      );
    } catch (_) {
      return StepState();
    }
  }
}
