/// Free workout videos on YouTube, played in the app with YouTube's
/// official embedded player (allowed by YouTube's terms; no downloading,
/// views and ads stay with the creator). Curated from well-known channels.
///
/// Every id was checked to exist and allow embedding (oEmbed 200) on
/// 2026-11-25; `LIVE=1 flutter test test/content/live_providers_test.dart`
/// re-checks them. Groups match the Exercise schedule body parts.
class YoutubeWorkout {
  const YoutubeWorkout(this.id, this.title, this.channel, this.group, this.level, this.seconds);
  final String id;
  final String title;
  final String channel;
  final String group;
  final String level; // Beginner | Mild | Pro (as in the weekly plan)
  final int seconds;

  String get thumbnail => 'https://i.ytimg.com/vi/$id/hqdefault.jpg';
  String get watchUrl => 'https://www.youtube.com/watch?v=$id';
  String get resumeKey => 'yt:$id';
}

const youtubeWorkoutGroups = [
  'Full body', 'Chest', 'Back', 'Legs', 'Shoulders', 'Arms', 'Abdomen', 'Cardio', 'Yoga', 'Walking', 'Office',
];

const youtubeWorkouts = <YoutubeWorkout>[
  YoutubeWorkout('FGFfqCjtmS8', '10-min full body (beginner, with breaks)', 'Pamela Reif', 'Full body', 'Beginner', 630),
  YoutubeWorkout('KrmYjcQzSsQ', '10-min full body workout', 'The Body Coach TV by Joe Wicks', 'Full body', 'Beginner', 702),
  YoutubeWorkout('UoC_O3HzsH0', '10-min bodyweight workout (no equipment)', 'Fraser Wilson', 'Full body', 'Mild', 655),
  YoutubeWorkout('Gze8oMuj4as', 'Total body strength & core for beginners', 'FitnessBlender', 'Full body', 'Beginner', 1725),
  YoutubeWorkout('Bi1IRzJIoAo', '10-min chest workout without weights', 'FitnessBlender', 'Chest', 'Mild', 643),
  YoutubeWorkout('MrpGbulGprA', 'Bodyweight upper body for beginners', 'FitnessBlender', 'Chest', 'Beginner', 550),
  YoutubeWorkout('IODxDxX7oi4', 'The perfect push-up (form guide)', 'Calisthenicmovement', 'Chest', 'Beginner', 217),
  YoutubeWorkout('rT7DgCr-3pg', 'How to: barbell bench press', 'ScottHermanFitness', 'Chest', 'Pro', 252),
  YoutubeWorkout('p1GERX3lf3Y', 'Lower back toning routine', 'FitnessBlender', 'Back', 'Beginner', 481),
  YoutubeWorkout('YMwi_eDYG9U', 'Upper & lower back workout at home', 'FitnessBlender', 'Back', 'Mild', 1517),
  YoutubeWorkout('GZbfZ033f74', 'How to: seated cable row', 'ScottHermanFitness', 'Back', 'Mild', 126),
  YoutubeWorkout('YyBcMVQylas', '10-min lower body (no equipment)', 'FitnessBlender', 'Legs', 'Beginner', 673),
  YoutubeWorkout('Hp39axsuFs8', 'Bodyweight lower body workout', 'FitnessBlender', 'Legs', 'Mild', 1233),
  YoutubeWorkout('X0qC1k0Zi6k', 'The perfect squat (form guide)', 'Calisthenicmovement', 'Legs', 'Beginner', 480),
  YoutubeWorkout('oUychjqfO8I', 'Shoulders, arms & upper back', 'FitnessBlender', 'Shoulders', 'Beginner', 549),
  YoutubeWorkout('EkeWuJE3aW8', 'Shoulders, back, chest & arms', 'FitnessBlender', 'Shoulders', 'Mild', 998),
  YoutubeWorkout('XsVjeEx2RNI', 'Arms & shoulders toning workout', 'FitnessBlender', 'Arms', 'Mild', 1531),
  YoutubeWorkout('1f8yoFFdkcY', '10-min beginner ab workout', 'Pamela Reif', 'Abdomen', 'Beginner', 630),
  YoutubeWorkout('AnYl6Nk9GOA', '10-min ab workout', 'Pamela Reif', 'Abdomen', 'Mild', 626),
  YoutubeWorkout('1919eTCoESo', '10-min abs & obliques', 'FitnessBlender', 'Abdomen', 'Beginner', 612),
  YoutubeWorkout('2pLT-olgUJs', 'Abs challenge workout', 'Chloe Ting', 'Abdomen', 'Pro', 664),
  YoutubeWorkout('6LqqeBtFn9M', 'The perfect plank (form guide)', 'Get Exercise Confident', 'Abdomen', 'Beginner', 165),
  YoutubeWorkout('5vMYLB-cWhk', '10-min beginner HIIT', 'The Body Coach TV by Joe Wicks', 'Cardio', 'Beginner', 664),
  YoutubeWorkout('8A6Uai5sQVw', 'Low-impact cardio for beginners', 'FitnessBlender', 'Cardio', 'Beginner', 1647),
  YoutubeWorkout('uzxGKGoqAzA', '30-min HIIT cardio', 'FitnessBlender', 'Cardio', 'Pro', 1791),
  YoutubeWorkout('v7AYKMP6rOE', 'Yoga for complete beginners', 'Yoga With Adriene', 'Yoga', 'Beginner', 1425),
  YoutubeWorkout('UEEsdXn8oG8', '11-min wake-up yoga', 'Yoga With Adriene', 'Yoga', 'Beginner', 693),
  YoutubeWorkout('XeXz8fIZDCE', 'Yoga for lower back pain', 'Yoga With Adriene', 'Yoga', 'Beginner', 947),
  YoutubeWorkout('C_rKOIJTB6A', '15-min walk at home', 'Walk at Home', 'Walking', 'Beginner', 837),
  YoutubeWorkout('Xaf143DBdqo', '15-min walking workout at home', 'Lucy Wyndham-Read', 'Walking', 'Beginner', 1057),
  YoutubeWorkout('LYf1Z99vel4', '12-min office desk stretch', 'MadFit', 'Office', 'Beginner', 805),
  YoutubeWorkout('XZM1xiY9jOw', '10-min office stretch (sitting a lot)', 'Pamela Reif', 'Office', 'Mild', 617),
];
