import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

import 'ios_alarm_backend.dart';
import 'native_alarm.dart';

/// The reminder backend for the current platform: native AlarmManager on
/// Android, UNUserNotificationCenter (via flutter_local_notifications) on iOS.
AlarmBackend defaultAlarmBackend() =>
    (!kIsWeb && Platform.isIOS) ? IosAlarmBackend() : NativeAlarmBackend();
