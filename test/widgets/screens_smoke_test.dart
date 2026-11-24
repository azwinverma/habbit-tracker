import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker_nepali/app/providers.dart';
import 'package:habit_tracker_nepali/app/theme.dart';
import 'package:habit_tracker_nepali/core/db/app_database.dart';
import 'package:habit_tracker_nepali/features/content/data/content_repository.dart';
import 'package:habit_tracker_nepali/features/content/domain/content_item.dart';
import 'package:habit_tracker_nepali/features/content/presentation/discover_screen.dart';
import 'package:habit_tracker_nepali/features/habits/data/habit_repository.dart';
import 'package:habit_tracker_nepali/features/insights/insights_screen.dart';
import 'package:habit_tracker_nepali/features/plan/plan_screen.dart';
import 'package:habit_tracker_nepali/l10n/app_localizations.dart';
import 'package:habit_tracker_nepali/models/habit.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));

  Future<void> pump(WidgetTester tester, Widget screen, {Brightness b = Brightness.light, Locale locale = const Locale('en')}) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        exactAlarmAllowedProvider.overrideWith((ref) async => true),
        notificationsEnabledProvider.overrideWith((ref) async => true),
      ],
      child: MaterialApp(
        theme: buildTheme(b),
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: screen,
      ),
    ));
    // Let drift streams emit (real async), then settle frames.
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump();
    await tester.pump();
  }

  Future<void> tearDownDb(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    // Flush drift's stream-cancellation timers in the fake clock before
    // closing, otherwise close() waits forever.
    await tester.pump(const Duration(seconds: 5));
    await tester.runAsync(() => db.close());
  }

  testWidgets('Insights renders logged history (light + dark)', (tester) async {
    final today = HabitRepository.ymd(DateTime.now());
    await tester.runAsync(() => HabitRepository(db).saveAll([
          Habit(id: 'w', name: 'Water', enabled: true, reminderHour: 8, reminderMinute: 0,
              category: HabitCategory.water, waterTarget: 8, waterCompleted: 5, waterLastDate: today),
        ]));
    for (final b in Brightness.values) {
      await pump(tester, const InsightsScreen(), b: b);
      expect(find.text('Last 7 days'), findsOneWidget);
      expect(find.text('5 glasses'), findsOneWidget);
      expect(find.text('Logged on 1 of 7 days'), findsWidgets);
    }
    await tearDownDb(tester);
  });

  testWidgets('Discover lists cached content with New badge and opens details', (tester) async {
    final repo = ContentRepository(db);
    final now = DateTime.now();
    await tester.runAsync(() async {
      await repo.upsert('gutenberg', const [
        ContentItem(id: 'gutenberg:1', provider: 'gutenberg', kind: ContentKind.book, title: 'Walden',
            subtitle: 'Henry David Thoreau', license: 'Public domain (US)', mediaUrl: 'https://x/1.epub', mediaFormat: 'epub'),
      ], now: now, firstSync: true);
      await repo.upsert('gutenberg', const [
        ContentItem(id: 'gutenberg:2', provider: 'gutenberg', kind: ContentKind.book, title: 'Emma',
            subtitle: 'Jane Austen', license: 'Public domain (US)', mediaUrl: 'https://x/2.epub', mediaFormat: 'epub'),
      ], now: now, firstSync: false);
    });

    await pump(tester, const DiscoverScreen());
    expect(find.text('Walden'), findsOneWidget);
    expect(find.text('Emma'), findsOneWidget);
    expect(find.text('New'), findsOneWidget); // only the item from the later sync

    await tester.tap(find.text('Emma'));
    await tester.pumpAndSettle();
    expect(find.text('Read now'), findsOneWidget);
    expect(find.text('Licence: Public domain (US)'), findsOneWidget);

    await tearDownDb(tester);
  });

  testWidgets('Discover shows an empty state offline', (tester) async {
    await pump(tester, const DiscoverScreen());
    expect(find.textContaining('Nothing here yet'), findsOneWidget);
    await tearDownDb(tester);
  });

  testWidgets('Plan shows upcoming reminders and reminder health', (tester) async {
    await tester.runAsync(() => HabitRepository(db).saveAll([
          Habit(id: 'g', name: 'Journal', enabled: true, reminderHour: 22, reminderMinute: 15),
        ]));
    await pump(tester, const PlanScreen());
    expect(find.text('Reminder health'), findsOneWidget);
    expect(find.text('Journal'), findsOneWidget);
    expect(find.text('22:15'), findsOneWidget);
    expect(find.text('Send a test reminder'), findsOneWidget);
    await tearDownDb(tester);
  });

  testWidgets('Insights renders in Nepali', (tester) async {
    await pump(tester, const InsightsScreen(), locale: const Locale('ne'));
    expect(find.text('पछिल्ला ७ दिन'), findsOneWidget);
    expect(find.text('पानी'), findsOneWidget);
    await tearDownDb(tester);
  });
}
