import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker_nepali/core/db/app_database.dart';
import 'package:habit_tracker_nepali/features/content/data/content_repository.dart';
import 'package:habit_tracker_nepali/features/content/data/playback_store.dart';
import 'package:habit_tracker_nepali/features/content/domain/content_item.dart';
import 'package:habit_tracker_nepali/features/content/presentation/exercise_detail_screen.dart';
import 'package:habit_tracker_nepali/l10n/app_localizations.dart';

ContentItemRow row(String id, String title, {String format = 'none', List<String> tags = const [], String? desc}) =>
    ContentItemRow(
      id: id, provider: 'wger', kind: 'exercise', title: title, mediaFormat: format, license: 'CC-BY-SA 4',
      mediaUrl: format == 'video' ? 'https://wger.de/$id.mp4' : null, description: desc,
      tags: tags, popularity: 0, firstSeenAt: DateTime(2026), lastSeenAt: DateTime(2026), seen: true,
    );

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('ResumePoint', () {
    test('only resumes long videos, past the start and before the end', () {
      const min = 60 * 1000;
      expect(ResumePoint.worthResuming(positionMs: 30000, durationMs: 30000 - 1), isFalse); // short loop
      expect(ResumePoint.worthResuming(positionMs: 3000, durationMs: 10 * min), isFalse); // just started
      expect(ResumePoint.worthResuming(positionMs: 5 * min, durationMs: 10 * min), isTrue);
      expect(ResumePoint.worthResuming(positionMs: 10 * min - 5000, durationMs: 10 * min), isFalse); // finished
    });

    test('json round trip and progress', () {
      final p = ResumePoint(
          kind: ContentKind.book, positionMs: 3, durationMs: 12, index: 140, cfi: 'epubcfi(/6/4!/4/2)',
          label: 'Chapter III', updatedAt: DateTime(2026, 11, 25, 9));
      final back = ResumePoint.fromJson('{"k":"book","p":3,"d":12,"i":140,"c":"epubcfi(/6/4!/4/2)","l":"Chapter III","t":${DateTime(2026, 11, 25, 9).millisecondsSinceEpoch}}')!;
      expect(back.toJson(), p.toJson());
      expect(back.progress, 0.25);
      expect(ResumePoint.fromJson('not json'), isNull);
    });
  });

  group('PlaybackStore', () {
    late AppDatabase db;
    late PlaybackStore store;
    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      store = PlaybackStore(db);
      final now = DateTime(2026, 11, 25);
      await ContentRepository(db).upsert('p', const [
        ContentItem(id: 'v1', provider: 'p', kind: ContentKind.video, title: 'Yoga flow', license: 'CC0'),
        ContentItem(id: 'b1', provider: 'p', kind: ContentKind.book, title: 'Walden', license: 'PD'),
        ContentItem(id: 'b2', provider: 'p', kind: ContentKind.book, title: 'Emma', license: 'PD'),
      ], now: now, firstSync: true);
    });
    tearDown(() => db.close());

    test('saves and clears video positions; short or finished ones are not kept', () async {
      await store.saveMedia('v1', ContentKind.video,
          position: const Duration(minutes: 4), duration: const Duration(minutes: 20));
      expect((await store.get('v1'))!.positionMs, const Duration(minutes: 4).inMilliseconds);
      await store.saveMedia('v1', ContentKind.video,
          position: const Duration(minutes: 20), duration: const Duration(minutes: 20)); // watched to the end
      expect(await store.get('v1'), isNull);
      await store.saveMedia('v1', ContentKind.video,
          position: const Duration(seconds: 20), duration: const Duration(seconds: 40)); // exercise loop
      expect(await store.get('v1'), isNull);
    });

    test('continue list joins items, filters by kind, newest first', () async {
      await store.save('b1', ResumePoint(kind: ContentKind.book, label: 'Economy', updatedAt: DateTime(2026, 11, 20)));
      await store.save('b2', ResumePoint(kind: ContentKind.book, updatedAt: DateTime(2026, 11, 24)));
      await store.saveMedia('v1', ContentKind.video,
          position: const Duration(minutes: 4), duration: const Duration(minutes: 20));
      await store.save('gone', ResumePoint(kind: ContentKind.book, updatedAt: DateTime(2026, 11, 25))); // pruned item

      final books = await store.watchContinue(kind: ContentKind.book).first;
      expect(books.map((e) => e.item.id), ['b2', 'b1']);
      expect(books.last.point.label, 'Economy');
      final videos = await store.watchContinue(kind: ContentKind.video).first;
      expect(videos.single.item.title, 'Yoga flow');
      await store.clear('b2');
      expect((await store.watchContinue(kind: ContentKind.book).first).single.item.id, 'b1');
    });
  });

  group('ExerciseText', () {
    test('splits wger text into steps, muscles and equipment', () {
      final p = ExerciseText.split(
          'Stand with feet apart.\n- Lower your hips.\n2) Push back up.\n\nMuscles: Quadriceps, Glutes\nEquipment: none (bodyweight exercise)');
      expect(p.steps, ['Stand with feet apart.', 'Lower your hips.', 'Push back up.']);
      expect(p.muscles, 'Quadriceps, Glutes');
      expect(p.equipment, 'none (bodyweight exercise)');
    });

    test('one long paragraph becomes sentences', () {
      final long = 'Lie on your back with knees bent and feet flat on the floor. '
          'Lift your hips until your body forms a straight line from shoulders to knees. '
          'Hold for a moment, then lower slowly.';
      expect(ExerciseText.split(long).steps.length, 3);
      expect(ExerciseText.split(null).steps, isEmpty);
    });

    test('matches plan names to catalogue exercises, preferring videos', () {
      final items = [
        row('1', 'Push-Ups'),
        row('2', 'Push-Up on Knees', format: 'video'),
        row('3', 'Squats'),
        row('4', 'Barbell Squat', format: 'video'),
        row('5', 'Lat Pull Down (Wide Grip)'),
        row('6', 'Plank'),
      ];
      expect(ExerciseText.bestMatch('Bodyweight squats', items)?.id, '4'); // "squat" + video
      expect(ExerciseText.bestMatch('Plank (short holds)', items)?.id, '6');
      expect(ExerciseText.bestMatch('Lat pulldown', items)?.id, '5'); // spacing differs
      expect(ExerciseText.bestMatch('Push-ups (knee/incline)', items)?.id, anyOf('1', '2'));
      expect(ExerciseText.bestMatch('Dragon flags (advanced)', items), isNull);
    });
  });

  testWidgets('exercise page without video shows picture fallback, steps and muscles', (tester) async {
    final it = row('wger:9', 'Glute Bridge',
        tags: const ['Legs', 'Glutes'],
        desc: 'Lie on your back.\nLift your hips.\n\nMuscles: Glutes\nEquipment: Mat');
    final db = AppDatabase(NativeDatabase.memory());
    AppDatabase.instance = db;
    addTearDown(db.close);
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: ExerciseDetailScreen(item: it),
    ));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump();
    final l = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l.noVideoYet), findsOneWidget);
    expect(find.text(l.howToDoIt), findsOneWidget);
    expect(find.text('Lift your hips.'), findsOneWidget);
    expect(find.text('2'), findsOneWidget); // numbered steps
    expect(find.textContaining('Glutes'), findsWidgets);
  });
}
