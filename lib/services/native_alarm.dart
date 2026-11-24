import 'dart:io' show Platform;

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../core/reminders/reminder_spec.dart';

/// Abstraction over the OS alarm scheduler so the reminder logic can be
/// unit-tested with a fake.
abstract class AlarmBackend {
  Future<void> schedule(ReminderSpec spec);
  Future<void> scheduleRaw({
    required int id,
    required DateTime at,
    required String title,
    required String body,
  });
  Future<void> cancel(int id);

  /// After this is enabled, the native receiver silently drops (and does not
  /// re-arm) any alarm whose id it does not know about. This is how alarms
  /// created by pre-2.0 builds — whose ids cannot be recomputed — are retired.
  Future<void> enableLegacyCleanup();

  /// Cancels every alarm still registered with android_alarm_manager_plus
  /// (the pre-2.0 scheduler for medicine/reading/exercise).
  Future<int> cancelLegacyPluginAlarms();

  Future<bool> canScheduleExact();
  Future<void> openExactAlarmSettings();
}

/// Android implementation backed by the Kotlin `habit_alarms` channel
/// (AlarmScheduler / AlarmReceiver / BootReceiver). No-op on other platforms
/// for now — iOS reminders are tracked as a Phase 3 item.
class NativeAlarmBackend implements AlarmBackend {
  static const _ch = MethodChannel('habit_alarms');

  bool get _supported => !kIsWeb && Platform.isAndroid;

  @override
  Future<void> schedule(ReminderSpec spec) async {
    if (!_supported) return;
    await _ch.invokeMethod('scheduleExact', {
      'id': spec.id,
      'epochMillis': spec.firstAt.millisecondsSinceEpoch,
      'title': spec.title,
      'body': spec.body,
      'daily': spec.kind == ReminderKind.daily,
      'hour': spec.hour,
      'minute': spec.minute,
      'endMillis': spec.endAt?.millisecondsSinceEpoch,
    });
  }

  @override
  Future<void> scheduleRaw({
    required int id,
    required DateTime at,
    required String title,
    required String body,
  }) async {
    if (!_supported) return;
    await _ch.invokeMethod('scheduleExact', {
      'id': id,
      'epochMillis': at.millisecondsSinceEpoch,
      'title': title,
      'body': body,
      'daily': false,
      'hour': at.hour,
      'minute': at.minute,
    });
  }

  @override
  Future<void> cancel(int id) async {
    if (!_supported) return;
    await _ch.invokeMethod('cancel', {'id': id});
  }

  @override
  Future<void> enableLegacyCleanup() async {
    if (!_supported) return;
    await _ch.invokeMethod('enableLegacyCleanup');
  }

  @override
  Future<int> cancelLegacyPluginAlarms() async {
    if (!_supported) return 0;
    final ids = (await _ch.invokeListMethod<int>('legacyPluginAlarmIds')) ?? const [];
    for (final id in ids) {
      await AndroidAlarmManager.cancel(id);
    }
    return ids.length;
  }

  @override
  Future<bool> canScheduleExact() async {
    if (!_supported) return true;
    return (await _ch.invokeMethod<bool>('canScheduleExact')) ?? true;
  }

  @override
  Future<void> openExactAlarmSettings() async {
    if (!_supported) return;
    await _ch.invokeMethod('openExactAlarmSettings');
  }
}
