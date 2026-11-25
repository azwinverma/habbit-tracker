import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker_nepali/core/db/app_database.dart';
import 'package:habit_tracker_nepali/features/content/data/providers/youtube_channel_provider.dart';
import 'package:habit_tracker_nepali/features/content/data/youtube_workouts.dart';
import 'package:habit_tracker_nepali/features/content/domain/content_item.dart';
import 'package:habit_tracker_nepali/features/content/presentation/exercise_detail_screen.dart';
import 'package:habit_tracker_nepali/features/content/presentation/home_workouts_screen.dart';
import 'package:habit_tracker_nepali/services/ad_service.dart';
import 'package:habit_tracker_nepali/services/review_prompt.dart';

const _feed = '''<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns:yt="http://www.youtube.com/xml/schemas/2015" xmlns:media="http://search.yahoo.com/mrss/" xmlns="http://www.w3.org/2005/Atom">
 <title>Bodybuilding.com</title>
 <entry>
  <yt:videoId>6smqlrDLIco</yt:videoId>
  <title>How To Do A Seated Cable Row with Neutral V Handle</title>
  <published>2026-11-23T16:00:00+00:00</published>
  <media:group>
   <media:description>Keep your chest up.
https://bodybuilding.com/shop</media:description>
   <media:community><media:statistics views="12345"/></media:community>
  </media:group>
 </entry>
 <entry>
  <yt:videoId>LM5tVVkQqF4</yt:videoId>
  <title>EDGE × Bodybuilding.com.</title>
 </entry>
 <entry>
  <yt:videoId>sGlPvYY0MFo</yt:videoId>
  <title>Exciting news coming from Bodybuilding.com</title>
 </entry>
 <entry>
  <yt:videoId>MyhWzQBnXHM</yt:videoId>
  <title>Full Ab Workout with Captains Chair &amp; More</title>
 </entry>
</feed>''';

ContentItemRow ex(String title, {String? desc, String format = 'none'}) => ContentItemRow(
      id: 'wger:$title', provider: 'wger', kind: 'exercise', title: title, mediaFormat: format, license: 'CC-BY-SA 4',
      description: desc, tags: const ['Legs'], popularity: 0,
      firstSeenAt: DateTime(2026), lastSeenAt: DateTime(2026), seen: true,
    );

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('Bodybuilding.com channel feed', () {
    test('keeps workout videos, skips promos/news, maps to playable YouTube items', () {
      final items = YoutubeChannelProvider.parseFeed(_feed, const YoutubeChannel('UC97k3hlbE-1rVN8y56zyEEA', 'Bodybuilding.com'));
      expect(items.map((i) => i.id), ['yt:6smqlrDLIco', 'yt:MyhWzQBnXHM']);
      final row = items.first;
      expect(row.kind, ContentKind.video);
      expect(row.mediaFormat, 'youtube');
      expect(row.subtitle, 'Bodybuilding.com');
      expect(row.imageUrl, 'https://i.ytimg.com/vi/6smqlrDLIco/hqdefault.jpg');
      expect(row.popularity, 12345);
      expect(row.description, 'Keep your chest up.'); // links dropped
      expect(row.tags, ['Bodybuilding.com', 'Back']);
      expect(items.last.title, 'Full Ab Workout with Captains Chair & More'); // unescaped
      expect(items.last.tags.last, 'Abdomen');
    });

    test('groups titles by body part', () {
      expect(YoutubeChannelProvider.groupFor('How To Use A Standing Calf Raise Machine'), 'Legs');
      expect(YoutubeChannelProvider.groupFor('Cable Triceps Pushdown with a Straight Bar'), 'Arms');
      expect(YoutubeChannelProvider.groupFor('How To Do A Standing Cable Chest Fly'), 'Chest');
      expect(YoutubeChannelProvider.groupFor('The Machine No One Uses'), 'Full body');
    });
  });

  group('coach exercise guides (Bodybuilding.com)', () {
    test('list is well formed and all from Bodybuilding.com', () {
      final ids = [...youtubeWorkouts, ...youtubeHowTos].map((v) => v.id).toList();
      expect(ids.toSet().length, ids.length, reason: 'duplicate video id');
      for (final v in youtubeHowTos) {
        expect(v.channel, 'Bodybuilding.com');
        expect(RegExp(r'^[A-Za-z0-9_-]{11}$').hasMatch(v.id), isTrue, reason: v.id);
        expect(youtubeWorkoutGroups, contains(v.group));
      }
      expect(youtubeHowTos.length, greaterThan(50));
      expect(youtubeWorkouts.where((v) => v.channel == 'Bodybuilding.com').length, greaterThanOrEqualTo(8));
    });

    test('wger exercise names find the right guide', () {
      expect(ExerciseText.howToFor('Bench Press')?.title, 'Barbell Bench Press');
      expect(ExerciseText.howToFor('Plank')?.title, 'Plank');
      expect(ExerciseText.howToFor('Crunches')?.title, 'Crunches');
      expect(ExerciseText.howToFor('Hammer Curls')?.title, 'Hammer Curl');
      expect(ExerciseText.howToFor('Lat Pull Down (Wide Grip)')?.title, 'Wide-Grip Lat Pulldown');
      expect(ExerciseText.howToFor('Squats')?.title, contains('Squat'));
      expect(ExerciseText.howToFor('Underwater basket weaving'), isNull);
    });
  });

  test('home workouts: bodyweight filter', () {
    expect(HomeWorkoutsScreen.isBodyweight(ex('Push-ups', desc: 'Push.\n\nMuscles: Chest\nEquipment: none (bodyweight exercise)')), isTrue);
    expect(HomeWorkoutsScreen.isBodyweight(ex('Plank', desc: 'Hold.\n\nEquipment: Gym mat')), isTrue);
    expect(HomeWorkoutsScreen.isBodyweight(ex('Burpees', desc: 'Jump.')), isTrue); // no equipment listed
    expect(HomeWorkoutsScreen.isBodyweight(ex('Bench Press', desc: 'Press.\n\nEquipment: Barbell, Bench')), isFalse);
  });

  group('rating prompt', () {
    final t0 = DateTime(2026, 11, 1, 9);
    test('asks only engaged users, rarely', () {
      ReviewState st(int c, int d, {DateTime? first, int asks = 0, DateTime? last}) => ReviewState(
          firstSeen: first ?? t0, count: c, days: [for (var i = 0; i < d; i++) 'd$i'], asks: asks, lastAsked: last);
      final now = t0.add(const Duration(days: 10));
      expect(ReviewPrompt.shouldAsk(st(6, 3), now), isTrue);
      expect(ReviewPrompt.shouldAsk(st(5, 3), now), isFalse); // too few completions
      expect(ReviewPrompt.shouldAsk(st(20, 2), now), isFalse); // only 2 days
      expect(ReviewPrompt.shouldAsk(st(20, 5, first: now.subtract(const Duration(days: 2))), now), isFalse); // new install
      expect(ReviewPrompt.shouldAsk(st(20, 5, asks: 1, last: now.subtract(const Duration(days: 30))), now), isFalse); // cooldown
      expect(ReviewPrompt.shouldAsk(st(20, 5, asks: 1, last: now.subtract(const Duration(days: 121))), now), isTrue);
      expect(ReviewPrompt.shouldAsk(st(20, 5, asks: 3), now), isFalse); // max 3 ever
    });

    test('counts completions per day and persists', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      var now = t0;
      final p = ReviewPrompt(db, clock: () => now);
      for (var day = 0; day < 3; day++) {
        now = t0.add(Duration(days: day));
        await p.onHabitCompleted();
        await p.onHabitCompleted();
      }
      final raw = await db.getMeta('review:state');
      expect(raw, contains('"c":6'));
      expect(raw, contains('"d":["2026-11-1","2026-11-2","2026-11-3"]'));
    });
  });

  test('one shared interstitial helper (caps apply app-wide)', () {
    expect(identical(InterstitialHelper(), InterstitialHelper()), isTrue);
  });
}
