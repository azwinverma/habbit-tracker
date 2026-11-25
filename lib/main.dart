import 'dart:async';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/reminders/reminder_service.dart';
import 'features/content/data/background_sync.dart';
import 'firebase_options.dart';
import 'services/ad_service.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Font licences show up under You → Licences.
  LicenseRegistry.addLicense(() async* {
    for (final f in const ['PlusJakartaSans', 'NotoSansDevanagari']) {
      yield LicenseEntryWithLineBreaks([f], await rootBundle.loadString('assets/fonts/OFL-$f.txt'));
    }
  });
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

  // Ads: consent (EEA/UK) then the SDK, without blocking app start.
  unawaited(AdService.init());
  await NotificationService.initializeForeground();
  await NotificationService.initializeBackground();
  await AndroidAlarmManager.initialize();

  ReminderService.permissionRequester = NotificationService.requestPermissions;
  // Keep the free-content catalogue fresh even if the app isn't opened.
  unawaited(BackgroundSync.schedule());

  runApp(const ProviderScope(child: HabitApp()));
}
