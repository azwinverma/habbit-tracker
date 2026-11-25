import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker_nepali/features/content/data/youtube_workouts.dart';
import 'package:habit_tracker_nepali/features/content/presentation/youtube_workout_screen.dart';

void main() {
  test('curated YouTube list is well formed and covers every plan body part', () {
    final ids = youtubeWorkouts.map((v) => v.id).toList();
    expect(ids.toSet().length, ids.length, reason: 'duplicate video');
    for (final v in youtubeWorkouts) {
      expect(RegExp(r'^[A-Za-z0-9_-]{11}$').hasMatch(v.id), isTrue, reason: v.id);
      expect(youtubeWorkoutGroups, contains(v.group));
      expect(['Beginner', 'Mild', 'Pro'], contains(v.level));
      expect(v.seconds, greaterThan(60));
      expect(v.title, isNotEmpty);
      expect(v.channel, isNotEmpty);
    }
    // Weekly-plan body parts must all have at least one video (fallback for "Watch how").
    for (final part in ['Chest', 'Back', 'Legs', 'Shoulders', 'Arms', 'Abdomen']) {
      expect(youtubeWorkouts.where((v) => v.group == part), isNotEmpty, reason: part);
    }
    for (final g in youtubeWorkoutGroups) {
      expect(youtubeWorkouts.where((v) => v.group == g), isNotEmpty, reason: 'empty group $g');
    }
  });

  test('player page embeds the video with YouTube\'s IFrame player and resume start', () {
    final html = YoutubeWorkoutScreen.playerHtml('v7AYKMP6rOE', startSeconds: 125);
    expect(html, contains('"v7AYKMP6rOE"'));
    expect(html, contains('start:125'));
    expect(html, contains('https://www.youtube.com/iframe_api'));
    expect(html, contains('youtube-nocookie.com'));
    expect(html, contains("send('t:'"));
  });
}
