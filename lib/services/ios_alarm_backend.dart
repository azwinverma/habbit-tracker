import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../core/reminders/alarm_id.dart';
import '../core/reminders/reminder_spec.dart';
import 'native_alarm.dart';

/// One pending iOS local notification.
@immutable
class IosPending {
  final int id;
  final DateTime at;

  /// Repeats every day at [at]'s wall-clock time (calendar trigger on
  /// hour+minute). One slot of the 64-notification limit.
  final bool repeatDaily;
  const IosPending(this.id, this.at, {this.repeatDaily = false});

  @override
  String toString() => 'IosPending($id, $at${repeatDaily ? ', daily' : ''})';
}

/// Turns a [ReminderSpec] into iOS pending notifications (pure, testable).
///
/// iOS has no alarm callback to re-arm or stop a reminder, and keeps at most
/// 64 pending notifications per app. So:
///  * a daily reminder with no end that starts within a day becomes one
///    repeating notification (1 slot);
///  * anything bounded (medicine course ending within [window]) or starting
///    later (course not begun) becomes one-shots for each day inside the
///    rolling [window]. The window is refreshed whenever the app opens
///    (`ReminderService.startup` re-plans everything).
abstract final class IosSchedulePlanner {
  static const window = Duration(days: 7);
  static const maxPending = 64;

  /// Ids of the one-shot copies of a daily reminder. Derived from the base id
  /// so that cancelling the base id can cancel them without any bookkeeping.
  static int dayId(int baseId, int dayIndex) => stableAlarmId('$baseId|d$dayIndex');
  static const maxDays = 8; // window days + today

  static List<IosPending> expand(ReminderSpec s, DateTime now) {
    if (s.kind == ReminderKind.once) {
      return s.firstAt.isAfter(now) ? [IosPending(s.id, s.firstAt)] : const [];
    }
    final horizon = now.add(window);
    final startsSoon = !s.firstAt.isAfter(now.add(const Duration(days: 1)));
    final endsLate = s.endAt == null || s.endAt!.isAfter(horizon);
    if (startsSoon && endsLate) return [IosPending(s.id, s.firstAt, repeatDaily: true)];

    final out = <IosPending>[];
    var day = DateTime(s.firstAt.year, s.firstAt.month, s.firstAt.day, s.hour, s.minute);
    for (var i = 0; i < maxDays; i++) {
      if (day.isAfter(horizon)) break;
      if (s.endAt != null && day.isAfter(s.endAt!)) break;
      if (day.isAfter(now)) out.add(IosPending(dayId(s.id, i), day));
      day = DateTime(day.year, day.month, day.day + 1, s.hour, s.minute); // DST-safe
    }
    return out;
  }
}

/// iOS implementation of [AlarmBackend] on `flutter_local_notifications`
/// (UNUserNotificationCenter). Medicine notification buttons are Android-only
/// for now; doses are logged in the app on iOS.
class IosAlarmBackend implements AlarmBackend {
  IosAlarmBackend({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  static Future<void>? _tzReady;

  static const _details = NotificationDetails(
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBanner: true,
      presentList: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    ),
  );

  /// Loads the tz database and sets the device's zone so wall-clock times
  /// (08:00) stay 08:00 locally, including across DST.
  static Future<void> _ensureTz() => _tzReady ??= () async {
        tzdata.initializeTimeZones();
        try {
          final info = await FlutterTimezone.getLocalTimezone();
          tz.setLocalLocation(tz.getLocation(info.identifier));
        } catch (e) {
          debugPrint('[Reminders/iOS] unknown time zone, using UTC: $e');
          tz.setLocalLocation(tz.UTC);
        }
      }();

  @override
  Future<void> schedule(ReminderSpec spec) async {
    await _ensureTz();
    await cancel(spec.id); // drop stale one-shot copies from a previous plan
    for (final p in IosSchedulePlanner.expand(spec, DateTime.now())) {
      await _plugin.zonedSchedule(
        p.id,
        spec.title,
        spec.body,
        tz.TZDateTime.from(p.at, tz.local),
        _details,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: p.repeatDaily ? DateTimeComponents.time : null,
      );
    }
    await _warnIfOverBudget();
  }

  @override
  Future<void> scheduleRaw({
    required int id,
    required DateTime at,
    required String title,
    required String body,
  }) async {
    await _ensureTz();
    if (!at.isAfter(DateTime.now())) return;
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(at, tz.local),
      _details,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  @override
  Future<void> cancel(int id) async {
    await _plugin.cancel(id);
    for (var i = 0; i < IosSchedulePlanner.maxDays; i++) {
      await _plugin.cancel(IosSchedulePlanner.dayId(id, i));
    }
  }

  Future<void> _warnIfOverBudget() async {
    if (!kDebugMode) return;
    final n = (await _plugin.pendingNotificationRequests()).length;
    if (n > IosSchedulePlanner.maxPending) {
      debugPrint('[Reminders/iOS] $n pending > ${IosSchedulePlanner.maxPending}: '
          'iOS keeps only the soonest ${IosSchedulePlanner.maxPending}.');
    }
  }

  // No legacy scheduler, exact-alarm permission or native action queue on iOS.
  @override
  Future<void> enableLegacyCleanup() async {}
  @override
  Future<int> cancelLegacyPluginAlarms() async => 0;
  @override
  Future<bool> canScheduleExact() async => true;
  @override
  Future<void> openExactAlarmSettings() async {}
  @override
  Future<List<String>> drainDoseActions() async => const [];
}
