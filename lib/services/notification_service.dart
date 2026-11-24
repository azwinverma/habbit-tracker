// lib/services/notification_service.dart
import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:habit_tracker_nepali/models/habit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import '../core/reminders/reminder_service.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _fgInited = false;
  static bool _bgInited = false;

  // Use this in main() / normal app startup
  static Future<void> initializeForeground() async {
    if (_fgInited) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    const init = InitializationSettings(android: android, iOS: ios);
    await _plugin.initialize(init);

    final androidImpl =
        _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.createNotificationChannel(const AndroidNotificationChannel(
      'habit_channel_v2',
      'Habit Reminders',
      description: 'Daily habit reminder notifications',
      importance: Importance.max,
    ));

    tz.initializeTimeZones();

    // ✅ Only ask for permission in FOREGROUND (Android 13+/iOS)
    await requestPermissions();

    _fgInited = true;
  }

  // Use this ONLY from AlarmManager callback (no permission prompt!)
  static Future<void> initializeBackground() async {
    if (_bgInited) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(); // fine, doesn’t prompt
    const init = InitializationSettings(android: android, iOS: ios);
    await _plugin.initialize(init);

    final androidImpl =
        _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.createNotificationChannel(const AndroidNotificationChannel(
      'habit_channel_v2',
      'Habit Reminders',
      description: 'Daily habit reminder notifications',
      importance: Importance.max,
    ));

    tz.initializeTimeZones();

    // ❌ DO NOT call requestPermissions() here
    _bgInited = true;
  }

  static Future<void> requestPermissions() async {
    if (Platform.isAndroid) {
      // On Android 12 and below this is a no-op; on 13+ it shows runtime prompt.
      final androidImpl =
          _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await androidImpl?.requestNotificationsPermission();
    } else if (Platform.isIOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  static Future<void> showNow(int id, String title, String body) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'habit_channel_v2', 'Habit Reminders',
        importance: Importance.max, priority: Priority.high, playSound: true,
      ),
      iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
    );
    await _plugin.show(id, title, body, details);
  }

  @Deprecated('Use ReminderService (native AlarmScheduler). Kept only for the legacy entry point.')
  static Future<void> scheduleExactWithAlarmManager({
    required int alarmId,
    required DateTime when,
    required String title,
    required String body,
  }) async {
    await AndroidAlarmManager.oneShotAt(
      when,
      alarmId,
      alarmEntryPoint,
      exact: true,
      wakeup: true,
      rescheduleOnReboot: true,
      params: {'title': title, 'body': body},
    );
  }

    // Helper to compute the next occurrence at [hour]:[minute]
  static DateTime nextOccurrence(int hour, int minute) {
    final now = DateTime.now();
    var when = DateTime(now.year, now.month, now.day, hour, minute);
    if (when.isBefore(now)) when = when.add(const Duration(days: 1));
    return when;
  }

  // Schedule multiple alarms for a habit using a base id + index
  @Deprecated('Use ReminderService.syncHabit')
  static Future<void> scheduleMultipleTimes({
    required String habitId,
    required List<String> hhmmList, // ["08:00","13:30",...]
    required String title,
    required String bodyPrefix, // e.g., "Time for: Water"
  }) async {
    final base = habitId.hashCode & 0x7fffffff;
    for (var i = 0; i < hhmmList.length; i++) {
      final id = base + i; // stable unique per time
      final tod = Habit.parseHHmm(hhmmList[i]);
      final when = nextOccurrence(tod.hour, tod.minute);
      await scheduleExactWithAlarmManager(
        alarmId: id,
        when: when,
        title: title,
        body: '$bodyPrefix (${hhmmList[i]})',
      );
    }
  }
}



// import 'dart:io';
// import 'package:flutter/foundation.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
// import 'package:timezone/data/latest.dart' as tz;
// import 'package:timezone/timezone.dart' as tz;

// class NotificationService {
//   // static final _plugin = FlutterLocalNotificationsPlugin();

//   // static Future<void> initialize() async {
//   //   const android = AndroidInitializationSettings('@mipmap/ic_launcher');
//   //   const ios = DarwinInitializationSettings();
//   //   const init = InitializationSettings(android: android, iOS: ios);
//   //   await _plugin.initialize(init);

//   //   // Ensure channel at MAX importance (if previously low, bump id to v2)
//   //   final androidImpl = _plugin
//   //       .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
//   //   await androidImpl?.createNotificationChannel(const AndroidNotificationChannel(
//   //     'habit_channel_v2',
//   //     'Habit Reminders',
//   //     description: 'Daily habit reminder notifications',
//   //     importance: Importance.max,
//   //   ));

//   //   tz.initializeTimeZones();

//   //   // Runtime permission (Android 13+), iOS alerts
//   //   await requestPermissions();
//   // }

//   // static Future<void> requestPermissions() async {
//   //   if (Platform.isAndroid) {
//   //     final androidImpl = _plugin
//   //         .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
//   //     await androidImpl?.requestNotificationsPermission();
//   //   } else if (Platform.isIOS) {
//   //     await _plugin
//   //         .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
//   //         ?.requestPermissions(alert: true, badge: true, sound: true);
//   //   }
//   // }

//     static final _plugin = FlutterLocalNotificationsPlugin();

//   static Future<void> initialize({bool inBackground = false}) async {
//     const android = AndroidInitializationSettings('@mipmap/ic_launcher');
//     const ios = DarwinInitializationSettings();
//     const init = InitializationSettings(android: android, iOS: ios);
//     await _plugin.initialize(init);

//     // Ensure channel exists (OK in bg)
//     final androidImpl =
//         _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
//     await androidImpl?.createNotificationChannel(const AndroidNotificationChannel(
//       'habit_channel_v2',
//       'Habit Reminders',
//       description: 'Daily habit reminder notifications',
//       importance: Importance.max,
//     ));

//     // Timezone DB (safe in bg)
//     tz.initializeTimeZones();

//     // ❌ Do NOT prompt for permission in background isolate
//     if (!inBackground) {
//       await requestPermissions();
//     }
//   }

//   static Future<void> requestPermissions() async {
//     if (Platform.isAndroid) {
//       final androidImpl =
//           _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
//       await androidImpl?.requestNotificationsPermission();
//     } else if (Platform.isIOS) {
//       await _plugin
//           .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
//           ?.requestPermissions(alert: true, badge: true, sound: true);
//     }
//   }

//   // Show immediately (used by AlarmManager callback)
//   static Future<void> showNow(int id, String title, String body) async {
//     const details = NotificationDetails(
//       android: AndroidNotificationDetails(
//         'habit_channel_v2', 'Habit Reminders',
//         importance: Importance.max, priority: Priority.high, playSound: true,
//       ),
//       iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
//     );
//     await _plugin.show(id, title, body, details);
//   }

//   // Schedule next fire exactly at [when] using AlarmManager (Android-only; no-op on iOS)
//   static Future<void> scheduleExactWithAlarmManager({
//     required int alarmId,
//     required DateTime when,
//     required String title,
//     required String body,
//   }) async {
//     await AndroidAlarmManager.oneShotAt(
//       when,
//       alarmId,
//       alarmEntryPoint,
//       exact: true,
//       wakeup: true,
//       rescheduleOnReboot: true,
//       params: {'id': alarmId, 'title': title, 'body': body},
//       // allowWhileIdle: true is implied by exact+wakeup behavior
//     );
//   }

//   // Helper to compute the next occurrence at [hour]:[minute]
//   static DateTime nextOccurrence(int hour, int minute) {
//     final now = DateTime.now();
//     var when = DateTime(now.year, now.month, now.day, hour, minute);
//     if (when.isBefore(now)) when = when.add(const Duration(days: 1));
//     return when;
//   }
// }

// // === AlarmManager entry points (MUST be top-level) ===
// @pragma('vm:entry-point')
// void alarmEntryPoint(Map<String, dynamic> params) {
//   final int id = params['id'] as int;
//   final String title = params['title'] as String;
//   final String body = params['body'] as String;
//   dailyAlarmCallback(id, title, body);
// }

// @pragma('vm:entry-point')
// Future<void> dailyAlarmCallback(int id, String title, String body) async {
//   // Initialize in background isolate
//   await NotificationService.initialize();
//   // Show the notification now
//   await NotificationService.showNow(id, title, body);
//   // Schedule the next one at the same time tomorrow (24h later is fine for daily use)
//   final next = DateTime.now().add(const Duration(days: 1));
//   await NotificationService.scheduleExactWithAlarmManager(
//     alarmId: id,
//     when: next,
//     title: title,
//     body: body,
//   );
// }

// MUST be top-level and use a supported signature
@pragma('vm:entry-point')
void alarmEntryPoint(int id, Map<String, dynamic> params) {
  final String title = params['title'] as String;
  final String body  = params['body'] as String;
  dailyAlarmCallback(id, title, body);
}

/// Entry point for alarms created by pre-2.0 builds via
/// android_alarm_manager_plus. New reminders go through ReminderService and
/// the native AlarmScheduler instead.
///
/// The old version re-armed EVERY alarm for "now + 1 day", which turned
/// one-time reminders, session-end alarms and dated medicine doses into
/// never-ending daily notifications. Once the 2.0 migration has run (and
/// re-created all live reminders natively), any legacy alarm that still fires
/// is an orphan: drop it without showing or re-arming.
@pragma('vm:entry-point')
Future<void> dailyAlarmCallback(int id, String title, String body) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    if (prefs.getBool(ReminderService.migratedKey) ?? false) {
      await AndroidAlarmManager.cancel(id);
      return;
    }
  } catch (_) {
    // If prefs are unavailable fall through to legacy behaviour.
  }

  // Init inside background isolate
  await NotificationService.initializeBackground();

  // Show the notification
  await NotificationService.showNow(id, title, body);

  // Re-schedule for tomorrow (simple daily)
  final next = DateTime.now().add(const Duration(days: 1));
  await NotificationService.scheduleExactWithAlarmManager(
    alarmId: id,
    when: next,
    title: title,
    body: body,
  );
}


// import 'dart:io';
// import 'package:flutter/foundation.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:timezone/data/latest.dart' as tz;
// import 'package:timezone/timezone.dart' as tz;

// class NotificationService {
//   static final _plugin = FlutterLocalNotificationsPlugin();

// static Future<void> initialize() async {
//   const android = AndroidInitializationSettings('@mipmap/ic_launcher');
//   const ios = DarwinInitializationSettings();
//   const init = InitializationSettings(android: android, iOS: ios);
//   await _plugin.initialize(init);

//   // Make sure the channel exists and is HIGH importance (won’t be suppressed)
//   final androidImpl =
//       _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
//   await androidImpl?.createNotificationChannel(const AndroidNotificationChannel(
//     'habit_channel', // MUST match the channel id you use in NotificationDetails
//     'Habit Reminders',
//     description: 'Daily habit reminder notifications',
//     importance: Importance.max,
//   ));

//   // Timezone DB
//   tz.initializeTimeZones();

//   await requestPermissions();
// }

//   static Future<void> requestPermissions() async {
//     if (Platform.isAndroid) {
//       final androidImpl = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
//       await androidImpl?.requestNotificationsPermission();
//     } else if (Platform.isIOS) {
//       await _plugin
//           .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
//           ?.requestPermissions(alert: true, badge: true, sound: true);
//     }
//   }

//   // Debug helper: one-off notification in [seconds]
//   static Future<void> scheduleInSeconds(int id, String title, String body, int seconds) async {
//     final when = tz.TZDateTime.now(tz.local).add(Duration(seconds: seconds));
//     const details = NotificationDetails(
//       android: AndroidNotificationDetails('habit_channel', 'Habit Reminders', importance: Importance.max, priority: Priority.high, playSound: true),
//       iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
//     );
//     await _plugin.zonedSchedule(
//       id,
//       title,
//       body,
//       when,
//       details,
//       androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
//       uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
//     );
//   }

//   // Debug helper: show immediately
//   static Future<void> showNow(int id, String title, String body) async {
//     const details = NotificationDetails(
//       android: AndroidNotificationDetails('habit_channel', 'Habit Reminders', importance: Importance.max, priority: Priority.high, playSound: true),
//       iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
//     );
//     await _plugin.show(id, title, body, details);
//   }

//   // Daily schedule at [hour]:[minute]
//   static Future<void> scheduleDaily(
//     int id,
//     String title,
//     String body,
//     int hour,
//     int minute,
//   ) async {
//     final now = tz.TZDateTime.now(tz.local);
//     var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
//     if (scheduled.isBefore(now)) scheduled = scheduled.add(const Duration(days: 1));

//     const details = NotificationDetails(
//       android: AndroidNotificationDetails('habit_channel', 'Habit Reminders', importance: Importance.max, priority: Priority.high, playSound: true),
//       iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
//     );

//     try {
//       await _plugin.zonedSchedule(
//         id,
//         title,
//         body,
//         scheduled,
//         details,
//         androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
//         uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
//         matchDateTimeComponents: DateTimeComponents.time,
//       );
//     } catch (e) {
//       if (kDebugMode) print('Exact schedule failed, fallback → $e');
//       await _plugin.zonedSchedule(
//         id,
//         title,
//         body,
//         scheduled,
//         details,
//         androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
//         uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
//         matchDateTimeComponents: DateTimeComponents.time,
//       );
//     }
//   }

//   static Future<void> cancel(int id) => _plugin.cancel(id);
// }
