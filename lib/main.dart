import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'app/app.dart';
import 'core/reminders/reminder_service.dart';
import 'firebase_options.dart';
import 'services/ad_service.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Firebase is optional for core features: the app must keep working
  // offline / if initialisation fails (no account, no network needed).
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    debugPrint('[Firebase] init failed, continuing without it: $e');
  }

  await MobileAds.instance.initialize();
  await AdService.init();
  await NotificationService.initializeForeground();
  await NotificationService.initializeBackground();
  await AndroidAlarmManager.initialize();

  ReminderService.permissionRequester = NotificationService.requestPermissions;

  runApp(const ProviderScope(child: HabitApp()));
}
