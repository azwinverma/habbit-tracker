// Visual review harness (not part of the normal suite).
//
//   SHOTS=1 flutter test --update-goldens test/design/screenshots_test.dart
//
// Renders key screens with the real brand fonts in light, dark and Nepali
// and writes PNGs to test/design/screenshots/ (git-ignored).
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker_nepali/core/db/app_database.dart';
import 'package:habit_tracker_nepali/core/reminders/reminder_service.dart';
import 'package:habit_tracker_nepali/features/habits/data/habit_repository.dart';
import 'package:habit_tracker_nepali/features/habits/data/legacy_habit_migrator.dart';
import 'package:habit_tracker_nepali/features/content/data/content_repository.dart';
import 'package:habit_tracker_nepali/features/content/domain/content_item.dart';
import 'package:habit_tracker_nepali/features/content/presentation/discover_screen.dart';
import 'package:habit_tracker_nepali/features/insights/insights_screen.dart';
import 'package:habit_tracker_nepali/features/plan/plan_screen.dart';
import 'package:habit_tracker_nepali/features/profile/profile_screen.dart';
import 'package:habit_tracker_nepali/app/providers.dart';
import 'package:habit_tracker_nepali/screens/home_screen.dart';
import 'package:habit_tracker_nepali/screens/medicine_screen.dart';
import 'package:habit_tracker_nepali/screens/exercise_screen.dart';
import 'package:habit_tracker_nepali/features/content/presentation/home_workouts_screen.dart';
import 'package:habit_tracker_nepali/models/habit.dart';
import 'package:habit_tracker_nepali/app/theme.dart';
import 'package:habit_tracker_nepali/design/backdrop.dart';
import 'package:habit_tracker_nepali/features/medicine/data/dose_log_repository.dart';
import 'package:habit_tracker_nepali/services/ad_service.dart';
import 'package:habit_tracker_nepali/services/storage_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../reminders/reminder_service_test.dart' show FakeBackend;
import '../widgets/today_screen_test.dart' show sampleHabits, wrap;

Future<void> _loadFonts() async {
  Future<ByteData> f(String p) async => ByteData.view((await File(p).readAsBytes()).buffer);
  final jakarta = FontLoader('PlusJakartaSans');
  for (final w in [400, 500, 600, 700, 800]) {
    jakarta.addFont(f('assets/fonts/PlusJakartaSans-$w.ttf'));
  }
  await jakarta.load();
  final noto = FontLoader('NotoSansDevanagari');
  for (final w in [400, 500, 600, 700]) {
    noto.addFont(f('assets/fonts/NotoSansDevanagari-$w.ttf'));
  }
  await noto.load();
  final flutterRoot = Platform.environment['FLUTTER_ROOT'] ??
      File(Platform.resolvedExecutable).parent.parent.parent.parent.parent.path;
  final icons = FontLoader('MaterialIcons')
    ..addFont(f('$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf'));
  await icons.load();
}

void main() {
  final enabled = Platform.environment['SHOTS'] == '1';
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  setUpAll(() async {
    if (enabled) await _loadFonts();
  });

  Future<void> shot(WidgetTester tester, String name, Widget Function(AppDatabase db) screen,
      {Brightness b = Brightness.light, Locale locale = const Locale('en'), double height = 2400,
      Future<void> Function(WidgetTester)? after, List<Override> overrides = const [],
      List<Habit> Function(DateTime)? habitsFor, bool storeContent = false}) async {
    tester.view.physicalSize = Size(1080, height);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    AdService.enabled = false;
    SharedPreferences.setMockInitialValues({});
    LegacyHabitMigrator.resetForTest();
    final db = AppDatabase(NativeDatabase.memory());
    AppDatabase.instance = db;
    ReminderService.instance = ReminderService(backend: FakeBackend());
    final now = DateTime.now();
    await tester.runAsync(() async {
      final habits = (habitsFor ?? sampleHabits)(now);
      final storage = StorageService();
      // A week of history for Insights.
      for (var i = 6; i >= 0; i--) {
        final d = DateTime(now.year, now.month, now.day - i);
        habits[0]
          ..waterLastDate = HabitRepository.ymd(d)
          ..waterCompleted = [5, 7, 4, 8, 6, 8, 3][6 - i];
        habits[2]
          ..exerciseLastDate = HabitRepository.ymd(d)
          ..exerciseTodayMin = [20, 0, 35, 15, 30, 0, 12][6 - i];
        if (storeContent) {
          // A believable week: steady water, walks, reading and meditation.
          habits[2].exerciseTodayMin = [25, 30, 18, 30, 35, 22, 30][6 - i];
          habits[2].stepsToday = [7200, 8400, 5100, 8900, 9300, 6100, 6400][6 - i];
          habits[2].stepsLastDate = HabitRepository.ymd(d);
          habits[3].lastCompleted = i == 3 ? null : d.add(const Duration(hours: 21));
          habits[4].lastCompleted = i.isEven ? d.add(const Duration(hours: 21, minutes: 40)) : null;
          habits[5]
            ..meditationLastDate = HabitRepository.ymd(d)
            ..meditationTodayMin = [10, 12, 5, 10, 15, 10, 10][6 - i];
          habits[0].waterCompleted = [7, 8, 6, 8, 8, 7, 6][6 - i];
        }
        await storage.saveHabits(habits);
      }
      if (storeContent) {
        // Today's state exactly as designed (the loop above wrote history).
        final fresh = storeHabits(now);
        habits[3].lastCompleted = fresh[3].lastCompleted;
        habits[4].lastCompleted = fresh[4].lastCompleted;
        await storage.saveHabits(habits);
        final doses = DoseLogRepository(db);
        for (var i = 6; i >= 1; i--) {
          final day = HabitRepository.ymd(DateTime(now.year, now.month, now.day - i));
          await doses.setStatus('m', day, '08:00', DoseStatus.taken);
          await doses.setStatus('m', day, '20:00', i == 4 ? DoseStatus.skipped : DoseStatus.taken);
        }
        await doses.setStatus('m', HabitRepository.ymd(now), '08:00', DoseStatus.taken);
        await ContentRepository(db).upsert('gutenberg', const [
          ContentItem(id: 'g:1', provider: 'gutenberg', kind: ContentKind.book, title: 'Walden', subtitle: 'Henry David Thoreau', license: 'Public domain (US)', mediaUrl: 'https://x/1.epub', mediaFormat: 'epub'),
          ContentItem(id: 'g:2', provider: 'gutenberg', kind: ContentKind.book, title: 'Siddhartha', subtitle: 'Hermann Hesse', license: 'Public domain (US)', mediaUrl: 'https://x/2.epub', mediaFormat: 'epub'),
          ContentItem(id: 'g:3', provider: 'gutenberg', kind: ContentKind.book, title: 'The Art of War', subtitle: 'Sun Tzu', license: 'Public domain (US)', mediaUrl: 'https://x/3.epub', mediaFormat: 'epub'),
          ContentItem(id: 'g:4', provider: 'gutenberg', kind: ContentKind.book, title: 'Little Women', subtitle: 'Louisa May Alcott', license: 'Public domain (US)', mediaUrl: 'https://x/4.epub', mediaFormat: 'epub'),
          ContentItem(id: 'g:5', provider: 'gutenberg', kind: ContentKind.book, title: 'The Adventures of Sherlock Holmes', subtitle: 'Arthur Conan Doyle', license: 'Public domain (US)', mediaUrl: 'https://x/5.epub', mediaFormat: 'epub'),
        ], now: now, firstSync: true);
        await ContentRepository(db).upsert('gutenberg', const [
          ContentItem(id: 'g:6', provider: 'gutenberg', kind: ContentKind.book, title: 'As a Man Thinketh', subtitle: 'James Allen', license: 'Public domain (US)', mediaUrl: 'https://x/6.epub', mediaFormat: 'epub'),
          ContentItem(id: 'g:7', provider: 'gutenberg', kind: ContentKind.book, title: 'The Science of Getting Rich', subtitle: 'Wallace D. Wattles', license: 'Public domain (US)', mediaUrl: 'https://x/7.epub', mediaFormat: 'epub'),
        ], now: now, firstSync: false);
      }
      final repo = ContentRepository(db);
      await repo.upsert('demo', const [
        ContentItem(id: 'd:v1', provider: 'demo', kind: ContentKind.video, title: 'Surya namaskar', subtitle: 'Yoga',
            license: 'CC BY-SA 3.0', mediaUrl: 'https://x/a.webm', mediaFormat: 'video', durationSeconds: 312),
        ContentItem(id: 'd:v2', provider: 'demo', kind: ContentKind.video, title: 'Kettlebell swing', subtitle: 'Exercise demo',
            license: 'CC BY-SA 4', mediaUrl: 'https://x/b.mov', mediaFormat: 'video', durationSeconds: 14),
        ContentItem(id: 'd:v3', provider: 'demo', kind: ContentKind.video, title: 'Breathing meditation', subtitle: 'Meditation',
            license: 'CC0', mediaUrl: 'https://x/c.webm', mediaFormat: 'video', durationSeconds: 600),
        ContentItem(id: 'd:b1', provider: 'demo', kind: ContentKind.book, title: 'Pride and Prejudice', subtitle: 'Jane Austen',
            license: 'Public domain (US)', mediaUrl: 'https://x/p.epub', mediaFormat: 'epub'),
        ContentItem(id: 'd:b2', provider: 'demo', kind: ContentKind.book, title: 'Meditations', subtitle: 'Marcus Aurelius',
            license: 'Public domain (US)', mediaUrl: 'https://x/m.epub', mediaFormat: 'epub'),
      ], now: now, firstSync: true);
      await repo.upsert('demo', const [
        ContentItem(id: 'd:v4', provider: 'demo', kind: ContentKind.video, title: 'Neck stretch for desk workers',
            subtitle: 'Exercise', license: 'CC BY 4.0', mediaUrl: 'https://x/d.webm', mediaFormat: 'video', durationSeconds: 95),
      ], now: now, firstSync: false);
      if (storeContent) {
        // Free exercise library rows for the Home workouts screenshot.
        const bw = 'Muscles: Full body\nEquipment: none (bodyweight exercise)';
        await repo.upsert('wger', [
          for (final (n, v) in const [
            ('Push-ups', true), ('Plank', true), ('Squats', false), ('Glute Bridge', true),
            ('Lunges', false), ('Burpees', true), ('Mountain Climbers', false), ('Crunches', false),
          ])
            ContentItem(
              id: 'wger:$n', provider: 'wger', kind: ContentKind.exercise, title: n, license: 'CC-BY-SA 4',
              description: 'Steps.\n\n$bw', tags: const ['Full body'],
              mediaUrl: v ? 'https://x/$n.mp4' : null, mediaFormat: v ? 'video' : 'none',
            ),
        ], now: now, firstSync: true);
      }
    });
    await tester.pumpWidget(wrap(db, screen(db), b: b, locale: locale, overrides: overrides));
    for (var i = 0; i < 4; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 150)));
      await tester.pump(const Duration(milliseconds: 600));
    }
    if (after != null) await after(tester);
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('screenshots/$name.png'));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
    await tester.runAsync(() => db.close());
  }

  final skip = !enabled;
  testWidgets('today light', (t) => shot(t, 'today_light', (_) => const HomeScreen(), height: 3000), skip: skip);
  testWidgets('today dark', (t) => shot(t, 'today_dark', (_) => const HomeScreen(), b: Brightness.dark, height: 3000), skip: skip);
  testWidgets('today nepali', (t) => shot(t, 'today_ne', (_) => const HomeScreen(), locale: const Locale('ne'), height: 3000), skip: skip);
  testWidgets('insights', (t) => shot(t, 'insights_light', (_) => const InsightsScreen(), height: 3200), skip: skip);
  testWidgets('insights dark', (t) => shot(t, 'insights_dark', (_) => const InsightsScreen(), b: Brightness.dark, height: 3200), skip: skip);
  // Plan reads platform permission state; pin it for screenshots.
  final pinned = [
    exactAlarmAllowedProvider.overrideWith((ref) async => true),
    notificationsEnabledProvider.overrideWith((ref) async => true),
  ];
  testWidgets('plan', (t) => shot(t, 'plan_light', (_) => const PlanScreen(), overrides: pinned), skip: skip);
  testWidgets('you', (t) => shot(t, 'you_light', (_) => const ProfileScreen(), height: 3600), skip: skip);
  testWidgets('discover videos', (t) => shot(t, 'discover_videos',
      (_) => const DiscoverScreen(initialKind: ContentKind.video), overrides: [
            savedContentIdsProvider.overrideWith((ref) => Stream.value({'d:v1'})),
          ]), skip: skip);
  testWidgets('discover books', (t) => shot(t, 'discover_books',
      (_) => const DiscoverScreen(), overrides: [
            savedContentIdsProvider.overrideWith((ref) => Stream.value({'d:b2'})),
          ]), skip: skip);
  testWidgets('medicine', (t) => shot(t, 'medicine_light',
      (_) => MedicineScreen(habit: sampleHabits(DateTime.now())[1]), height: 3200), skip: skip);

  // ---- Play Store screenshots: 1080×1920 (9:16) with brand caption + phone
  // frame, rendered by Flutter so Nepali captions shape correctly.
  //   SHOTS=1 flutter test --update-goldens test/design/screenshots_test.dart --plain-name store
  // Output: test/design/screenshots/store/{en,ne}/NN_name.png
  final storeOverrides = [
    ...pinned,
    savedContentIdsProvider.overrideWith((ref) => Stream.value({'d:b2'})),
  ];
  final h = storeHabits(DateTime.now());
  final screens = <(String, Widget Function(AppDatabase), Locale, Brightness)>[
    ('01_today', (_) => const HomeScreen(), const Locale('en'), Brightness.light),
    ('02_medicine', (_) => MedicineScreen(habit: h[1]), const Locale('en'), Brightness.light),
    ('03_home_workouts', (_) => const HomeWorkoutsScreen(), const Locale('en'), Brightness.light),
    ('04_exercise', (_) => ExerciseScreen(habit: h[2]), const Locale('en'), Brightness.light),
    ('05_discover', (_) => const DiscoverScreen(), const Locale('en'), Brightness.light),
    ('06_insights', (_) => const InsightsScreen(), const Locale('en'), Brightness.light),
    ('07_nepali', (_) => const HomeScreen(), const Locale('ne'), Brightness.light),
    ('08_dark', (_) => const HomeScreen(), const Locale('en'), Brightness.dark),
  ];
  const captions = {
    'en': [
      ('Build better habits', 'One tap a day. Streaks that keep you going.'),
      ('Never miss a dose', 'Medicine & water reminders, right on time.'),
      ('Workouts at home', 'Follow-along videos and exercise guides.'),
      ('Your workout, your way', 'Workout timer, steps and a weekly plan.'),
      ('Books & audiobooks', 'Free to read and listen, even offline.'),
      ('See your progress', 'Water, meditation and workouts at a glance.'),
      ('Now in नेपाली', 'Use the whole app in Nepali or English.'),
      ('Calm at night too', 'A beautiful dark mode for evening routines.'),
    ],
    'ne': [
      ('राम्रो बानी बसाउनुहोस्', 'दिनमा एक ट्याप। निरन्तरता देखिने स्ट्रिक।'),
      ('औषधि छुटाउनु पर्दैन', 'औषधि र पानीको रिमाइन्डर, ठीक समयमा।'),
      ('घरमै व्यायाम', 'सँगै गर्ने भिडियो र व्यायाम निर्देशन।'),
      ('तपाईंको आफ्नै व्यायाम', 'टाइमर, पाइला र साप्ताहिक योजना।'),
      ('निःशुल्क किताब र अडियोबुक', 'अफलाइन पढ्नुहोस् र सुन्नुहोस्।'),
      ('प्रगति हेर्नुहोस्', 'पानी, ध्यान र व्यायाम एकै ठाउँमा।'),
      ('अंग्रेजीमा पनि', 'एकै ट्यापमा भाषा बदल्नुहोस्।'),
      ('रातिका लागि डार्क मोड', 'साँझको दिनचर्यामा आँखालाई आराम।'),
    ],
  };
  for (final lang in const ['en', 'ne']) {
    for (var i = 0; i < screens.length; i++) {
      final (name, screen, loc, bright) = screens[i];
      final (title, sub) = captions[lang]![i];
      // Nepali listing leads with the Nepali UI; otherwise same screens.
      final locale = lang == 'ne'
          ? (i == 0 || i == 7 ? const Locale('ne') : i == 6 ? const Locale('en') : loc)
          : loc;
      testWidgets('store $lang $name', (t) => shot(t, 'store/$lang/$name',
              (db) => StoreFrame(title: title, subtitle: sub, child: screen(db)),
              height: 1920, habitsFor: storeHabits, storeContent: true, overrides: storeOverrides,
              locale: locale, b: bright),
          skip: skip);
    }
  }
}

/// Play Store frame: Deep Teal backdrop, caption, phone with the app inside.
class StoreFrame extends StatelessWidget {
  const StoreFrame({super.key, required this.title, required this.subtitle, required this.child});
  final String title;
  final String subtitle;
  final Widget child;

  static const phone = Size(393, 786); // logical phone viewport

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final w = mq.size.width;
    final theme = Theme.of(context);
    final phoneW = w * 0.76;
    return CustomPaint(
      painter: _StorePainter(),
      child: Column(children: [
        SizedBox(height: mq.size.height * 0.055),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(title,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium
                  ?.copyWith(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 30, height: 1.15)),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(color: BrandColors.mint, fontSize: 15.5, height: 1.35)),
        ),
        const SizedBox(height: 22),
        Expanded(
          child: ClipRect(
            child: OverflowBox(
              alignment: Alignment.topCenter,
              maxHeight: double.infinity,
              child: Container(
                width: phoneW,
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B1F1E),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 24, offset: Offset(0, 10))],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(25),
                  child: SizedBox(
                    width: phoneW - 10,
                    height: (phoneW - 10) * phone.height / phone.width,
                    child: FittedBox(
                      fit: BoxFit.fill,
                      child: SizedBox.fromSize(
                        size: phone,
                        child: MediaQuery(
                          data: mq.copyWith(size: phone, padding: const EdgeInsets.only(top: 26), viewPadding: const EdgeInsets.only(top: 26)),
                          child: Stack(children: [
                            Positioned.fill(child: child),
                            const Positioned(top: 0, left: 0, right: 0, height: 26, child: _StatusBar()),
                          ]),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar();
  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme.onSurface;
    final style = Theme.of(context).textTheme.labelMedium?.copyWith(fontSize: 12, fontWeight: FontWeight.w700, color: c);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(children: [
        Text('9:41', style: style),
        const Spacer(),
        Icon(Icons.signal_cellular_alt_rounded, size: 13, color: c),
        const SizedBox(width: 4),
        Icon(Icons.wifi_rounded, size: 13, color: c),
        const SizedBox(width: 4),
        Icon(Icons.battery_full_rounded, size: 13, color: c),
      ]),
    );
  }
}

class _StorePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = Offset.zero & size;
    canvas.drawRect(
        r,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E807A), BrandColors.deepTeal, Color(0xFF0F4A47)],
          ).createShader(r));
    final c = Offset(size.width * 0.9, size.height * 0.05);
    canvas.drawCircle(
        c,
        size.width * 0.8,
        Paint()
          ..shader = RadialGradient(colors: [BrandColors.mint.withValues(alpha: 0.18), BrandColors.mint.withValues(alpha: 0)])
              .createShader(Rect.fromCircle(center: c, radius: size.width * 0.8)));
    paintRidge(canvas, size.width, size.height * 0.30, BrandColors.mint, 0.07, 0.10, height: 0.55);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Store-listing demo data: believable names, times and progress.
List<Habit> storeHabits(DateTime now) {
  final today = HabitRepository.ymd(now);
  String d(int days) => HabitRepository.ymd(DateTime(now.year, now.month, now.day + days));
  return [
    Habit(id: 'w', name: 'Drink water', enabled: true, reminderHour: 8, reminderMinute: 0,
        reminderTimes: ['08:00', '10:00', '12:00', '14:00', '17:00', '20:00'], category: HabitCategory.water,
        waterTarget: 8, waterCompleted: 6, waterLastDate: today, streak: 12),
    Habit(id: 'm', name: 'Vitamin D3', enabled: true, reminderHour: 8, reminderMinute: 0,
        reminderTimes: ['08:00', '20:00'], category: HabitCategory.medicine, medicineName: 'Vitamin D3',
        medicineDose: '1 tablet after breakfast', medicineStartDate: d(-14), medicineEndDate: d(46)),
    Habit(id: 'e', name: 'Morning walk', enabled: true, reminderHour: 6, reminderMinute: 30,
        reminderTimes: ['06:30'], category: HabitCategory.exercise, exerciseGoalMin: 30,
        exerciseTodayMin: 30, exerciseLastDate: today, stepsToday: 6400, stepsGoal: 8000, stepsLastDate: today),
    Habit(id: 'r', name: 'Read 20 pages', enabled: true, reminderHour: 21, reminderMinute: 0,
        reminderTimes: ['21:00'], category: HabitCategory.generic, lastCompleted: now, streak: 9),
    Habit(id: 'j', name: 'Evening journal', enabled: true, reminderHour: 21, reminderMinute: 30,
        reminderTimes: ['21:30'], category: HabitCategory.generic, streak: 6),
    Habit(id: 'z', name: 'Meditate', enabled: true, reminderHour: 6, reminderMinute: 0,
        reminderTimes: ['06:00'], category: HabitCategory.meditation, meditationGoalMin: 10,
        meditationTodayMin: 10, meditationLastDate: today, streak: 21),
  ];
}
