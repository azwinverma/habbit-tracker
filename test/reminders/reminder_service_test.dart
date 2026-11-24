import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker_nepali/core/reminders/reminder_service.dart';
import 'package:habit_tracker_nepali/core/reminders/reminder_spec.dart';
import 'package:habit_tracker_nepali/models/habit.dart';
import 'package:habit_tracker_nepali/services/native_alarm.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// In-memory stand-in for the OS AlarmManager.
class FakeBackend implements AlarmBackend {
  final Map<int, String> armed = {}; // id -> title
  int legacyPluginAlarms;
  bool legacyCleanup = false;
  bool failSchedule = false;
  bool failLegacy = false;
  bool exact = true;

  FakeBackend({this.legacyPluginAlarms = 0});

  @override
  Future<void> schedule(ReminderSpec spec) async {
    if (failSchedule) throw Exception('boom');
    armed[spec.id] = spec.title;
  }

  @override
  Future<void> scheduleRaw({required int id, required DateTime at, required String title, required String body}) async {
    armed[id] = title;
  }

  @override
  Future<void> cancel(int id) async => armed.remove(id);

  @override
  Future<void> enableLegacyCleanup() async => legacyCleanup = true;

  @override
  Future<int> cancelLegacyPluginAlarms() async {
    if (failLegacy) throw Exception('channel down');
    final n = legacyPluginAlarms;
    legacyPluginAlarms = 0;
    return n;
  }

  @override
  Future<bool> canScheduleExact() async => exact;

  @override
  Future<void> openExactAlarmSettings() async {}

  List<String> pendingDoseActions = [];
  @override
  Future<List<String>> drainDoseActions() async {
    final out = pendingDoseActions;
    pendingDoseActions = [];
    return out;
  }
}

Habit _h(String id, {List<String> times = const ['08:00'], bool enabled = true, List<String>? once}) => Habit(
      id: id,
      name: id,
      enabled: enabled,
      reminderHour: 8,
      reminderMinute: 0,
      reminderTimes: times,
      oneTimeReminders: once,
    );

void main() {
  final now = DateTime(2026, 11, 24, 10, 0);
  late FakeBackend backend;
  late ReminderService svc;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    backend = FakeBackend(legacyPluginAlarms: 7);
    svc = ReminderService(backend: backend);
  });

  test('syncHabit arms one alarm per time', () async {
    await svc.syncHabit(_h('a', times: ['08:00', '20:00']), now: now);
    expect(backend.armed.length, 2);
  });

  test('re-sync with same data does not duplicate', () async {
    await svc.syncHabit(_h('a', times: ['08:00', '20:00']), now: now);
    await svc.syncHabit(_h('a', times: ['08:00', '20:00']), now: now);
    expect(backend.armed.length, 2);
  });

  test('removing a time cancels exactly that alarm', () async {
    await svc.syncHabit(_h('a', times: ['08:00', '20:00']), now: now);
    await svc.syncHabit(_h('a', times: ['08:00']), now: now);
    expect(backend.armed.length, 1);
  });

  test('disabling cancels all of the habit\'s alarms', () async {
    await svc.syncHabit(_h('a', times: ['08:00', '20:00']), now: now);
    await svc.syncHabit(_h('a', times: ['08:00', '20:00'], enabled: false), now: now);
    expect(backend.armed, isEmpty);
  });

  test('cancelHabit removes reminders and any running session alarm', () async {
    await svc.syncHabit(_h('a', times: ['08:00'], once: ['2026-11-30T07:00:00.000']), now: now);
    await svc.scheduleSessionEnd('a', now.add(const Duration(minutes: 10)), title: 't', body: 'b');
    await svc.syncHabit(_h('b'), now: now);
    expect(backend.armed.length, 4);

    await svc.cancelHabit('a');
    expect(backend.armed.length, 1); // only habit b remains
  });

  test('session alarm: one stable id per habit, cancellable', () async {
    await svc.scheduleSessionEnd('a', now, title: 't', body: 'b');
    await svc.scheduleSessionEnd('a', now.add(const Duration(minutes: 5)), title: 't', body: 'b');
    expect(backend.armed.keys, [ReminderService.sessionAlarmId('a')]);
    await svc.cancelSessionEnd('a');
    expect(backend.armed, isEmpty);
  });

  test('reconcileAll cancels alarms of habits that no longer exist', () async {
    await svc.syncHabit(_h('a'), now: now);
    await svc.syncHabit(_h('deleted', times: ['09:00', '10:00']), now: now);
    expect(backend.armed.length, 3);

    await svc.reconcileAll([_h('a')], now: now);
    expect(backend.armed.length, 1);
  });

  test('startup migrates legacy alarms exactly once, then reconciles', () async {
    await svc.startup([_h('a')], now: now);
    expect(backend.legacyCleanup, isTrue);
    expect(backend.legacyPluginAlarms, 0);
    expect(backend.armed.length, 1);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(ReminderService.migratedKey), isTrue);

    backend.legacyPluginAlarms = 3; // would be cancelled again if migration re-ran
    await svc.startup([_h('a')], now: now);
    expect(backend.legacyPluginAlarms, 3);
  });

  test('failed migration is retried next launch, reminders still armed', () async {
    backend.failLegacy = true;
    await svc.startup([_h('a')], now: now);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(ReminderService.migratedKey), isNot(true));
    expect(backend.armed.length, 1);

    backend.failLegacy = false;
    await svc.startup([_h('a')], now: now);
    expect(prefs.getBool(ReminderService.migratedKey), isTrue);
  });

  test('backend failure does not throw into the UI', () async {
    backend.failSchedule = true;
    await expectLater(svc.syncHabit(_h('a'), now: now), completes);
  });

  test('registry survives a new service instance (app restart)', () async {
    await svc.syncHabit(_h('a', times: ['08:00', '20:00']), now: now);
    final restarted = ReminderService(backend: backend);
    await restarted.cancelHabit('a');
    expect(backend.armed, isEmpty);
  });
}
