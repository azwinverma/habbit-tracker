import 'package:flutter/material.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:habit_tracker_nepali/screens/splash_screen.dart';
import 'services/ad_service.dart';
import 'services/notification_service.dart';


Future<void> main() async {
WidgetsFlutterBinding.ensureInitialized();
  // Lock the app to portrait mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
await MobileAds.instance.initialize();
await AdService.init();
await NotificationService.initializeForeground();
await NotificationService.initializeBackground();
await AndroidAlarmManager.initialize();
  // await JustAudioBackground.init(
  //   androidNotificationChannelId: 'meditation_audio',
  //   androidNotificationChannelName: 'Meditation Audio',
  //   androidNotificationOngoing: true,
  // );
runApp(const HabitApp());
}


class HabitApp extends StatelessWidget {
const HabitApp({super.key});


@override
Widget build(BuildContext context) {
return MaterialApp(
              debugShowCheckedModeBanner: false,

title: 'DailyMantra',
theme: ThemeData(
colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
useMaterial3: true,
),
home: const SplashScreen(),
// routes: {
// '/': (_) => const HomeScreen(),
// '/add': (_) => const AddEditHabitScreen(),
// '/edit': (ctx) {
// final habit = ModalRoute.of(ctx)!.settings.arguments as Habit;
// return AddEditHabitScreen(habit: habit);
// },
// },
);
}
}

// import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
// import 'package:flutter/material.dart';
// import 'screens/home_screen.dart';
// import 'screens/add_edit_habit_screen.dart';
// import 'models/habit.dart';
// import 'services/ad_service.dart';
// import 'services/notification_service.dart';


// Future<void> main() async {
// WidgetsFlutterBinding.ensureInitialized();
// await AdService.initialize();
// await NotificationService.initialize();
// await AndroidAlarmManager.initialize();
// runApp(const HabitApp());
// }


// class HabitApp extends StatelessWidget {
// const HabitApp({super.key});


// @override
// Widget build(BuildContext context) {
// return MaterialApp(
// title: 'Habit Tracker NP',
// theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)), useMaterial3: true),
// routes: {
// '/': (_) => const HomeScreen(),
// '/add': (_) => const AddEditHabitScreen(),
// '/edit': (ctx) {
// final habit = ModalRoute.of(ctx)!.settings.arguments as Habit;
// return AddEditHabitScreen(habit: habit);
// },
// },
// );
// }
// }