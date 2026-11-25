/// Free workout videos on YouTube, played in the app with YouTube's
/// official embedded player (allowed by YouTube's terms; no downloading,
/// views and ads stay with the creator). Curated from well-known channels.
///
/// Every id was checked to exist and allow embedding (oEmbed 200) on
/// 2026-11-25; `LIVE=1 flutter test test/content/live_providers_test.dart`
/// re-checks them. Groups match the Exercise schedule body parts.
///
/// Bodybuilding.com (youtube.com/@bodybuildingcom) videos were picked by
/// searching their channel; their newest uploads also arrive automatically
/// through `YoutubeChannelProvider` (channel RSS feed).
class YoutubeWorkout {
  const YoutubeWorkout(this.id, this.title, this.channel, this.group, this.level, this.seconds, {this.home = true});
  final String id;
  final String title;
  final String channel;
  final String group;
  final String level; // Beginner | Mild | Pro (as in the weekly plan)
  final int seconds; // 0 = unknown (channel feed items)

  /// Doable at home without gym machines (bodyweight, mat, maybe dumbbells).
  final bool home;

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
  YoutubeWorkout('rT7DgCr-3pg', 'How to: barbell bench press', 'ScottHermanFitness', 'Chest', 'Pro', 252, home: false),
  YoutubeWorkout('p1GERX3lf3Y', 'Lower back toning routine', 'FitnessBlender', 'Back', 'Beginner', 481),
  YoutubeWorkout('YMwi_eDYG9U', 'Upper & lower back workout at home', 'FitnessBlender', 'Back', 'Mild', 1517),
  YoutubeWorkout('GZbfZ033f74', 'How to: seated cable row', 'ScottHermanFitness', 'Back', 'Mild', 126, home: false),
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
  // Bodybuilding.com follow-along home workouts
  YoutubeWorkout('dJlFmxiL11s', 'At-home core workout', 'Bodybuilding.com', 'Abdomen', 'Beginner', 616),
  YoutubeWorkout('06msLl_wMtM', '15-min bodyweight strength (no equipment)', 'Bodybuilding.com', 'Full body', 'Mild', 1559),
  YoutubeWorkout('YdB1HMCldJY', '30-min at-home strength workout', 'Bodybuilding.com', 'Full body', 'Mild', 1791),
  YoutubeWorkout('fFTdY8SOZJE', '45-min at-home bodyweight workout', 'Bodybuilding.com', 'Full body', 'Mild', 2702),
  YoutubeWorkout('11WLF24-5iM', 'At-home cardio & core workout', 'Bodybuilding.com', 'Cardio', 'Mild', 3472),
  YoutubeWorkout('RlGS5Yns6MY', 'Non-stop follow-along workout', 'Bodybuilding.com', 'Cardio', 'Mild', 1939),
  YoutubeWorkout('ah_vve9bEBI', 'At-home upper body strength', 'Bodybuilding.com', 'Chest', 'Mild', 922),
  YoutubeWorkout('5A_fOVOXOn4', 'At-home core & upper body', 'Bodybuilding.com', 'Shoulders', 'Mild', 2033),
  YoutubeWorkout('2QfkAsMV4ps', 'Upper body at-home strength', 'Bodybuilding.com', 'Arms', 'Mild', 2284),
  YoutubeWorkout('pQ631odhSNI', 'Six-pack abs workout', 'Bodybuilding.com', 'Abdomen', 'Beginner', 628),
];

/// Bodybuilding.com exercise guides (how to do one exercise, ~1 min).
/// Shown at the top of the matching exercise page and as "coach videos".
/// [YoutubeWorkout.title] is the exercise name, used for matching.
const youtubeHowTos = <YoutubeWorkout>[
  YoutubeWorkout('t2b8UdqmlFs', 'Barbell Squat', 'Bodybuilding.com', 'Legs', 'Exercise guide', 1013, home: false),
  YoutubeWorkout('v_c67Omje48', 'Dumbbell Squat', 'Bodybuilding.com', 'Legs', 'Exercise guide', 95, home: false),
  YoutubeWorkout('0tn5K9NlCfo', 'Hack Squat', 'Bodybuilding.com', 'Legs', 'Exercise guide', 83, home: false),
  YoutubeWorkout('XIHO5t_VBPQ', 'Push-Up', 'Bodybuilding.com', 'Chest', 'Exercise guide', 41, home: true),
  YoutubeWorkout('kfnMuP5JgIw', 'Hand-Release Push-Up', 'Bodybuilding.com', 'Chest', 'Exercise guide', 62, home: true),
  YoutubeWorkout('mvNcSF-nXg4', 'Dive Bomber Push-Up', 'Bodybuilding.com', 'Chest', 'Exercise guide', 69, home: true),
  YoutubeWorkout('lxBwW6xAQ10', 'Decline Explosive Push-Up', 'Bodybuilding.com', 'Chest', 'Exercise guide', 44, home: true),
  YoutubeWorkout('d5eGGZXb0Is', 'Deadlift', 'Bodybuilding.com', 'Back', 'Exercise guide', 744, home: false),
  YoutubeWorkout('ecuZtKTNI9U', 'Romanian Deadlift', 'Bodybuilding.com', 'Legs', 'Exercise guide', 35, home: false),
  YoutubeWorkout('tgbrMdfuGJA', 'Plank', 'Bodybuilding.com', 'Abdomen', 'Exercise guide', 37, home: true),
  YoutubeWorkout('9p5e2BSvoLs', 'Bulgarian Split Squat', 'Bodybuilding.com', 'Legs', 'Exercise guide', 52, home: true),
  YoutubeWorkout('MqQlfjQOmHA', 'Glute Bridge', 'Bodybuilding.com', 'Legs', 'Exercise guide', 42, home: true),
  YoutubeWorkout('Fk1OfkMmVt4', 'Barbell Hip Thrust', 'Bodybuilding.com', 'Legs', 'Exercise guide', 45, home: false),
  YoutubeWorkout('ukDEXCXJxdM', 'Barbell Bench Press', 'Bodybuilding.com', 'Chest', 'Exercise guide', 77, home: false),
  YoutubeWorkout('8bfJ3sfUTos', 'Incline Dumbbell Press', 'Bodybuilding.com', 'Chest', 'Exercise guide', 17, home: false),
  YoutubeWorkout('Vc63DPUoA40', 'Dumbbell Bench Press', 'Bodybuilding.com', 'Chest', 'Exercise guide', 78, home: false),
  YoutubeWorkout('QwuUZ5wgQOk', 'Dumbbell Flyes', 'Bodybuilding.com', 'Chest', 'Exercise guide', 55, home: false),
  YoutubeWorkout('OQQnB0vbxbI', 'Cable Fly', 'Bodybuilding.com', 'Chest', 'Exercise guide', 17, home: false),
  YoutubeWorkout('oGxc2ph8Fnw', 'Butterfly (Pec Deck)', 'Bodybuilding.com', 'Chest', 'Exercise guide', 47, home: false),
  YoutubeWorkout('4la6BkUBLgo', 'Chest Dips', 'Bodybuilding.com', 'Chest', 'Exercise guide', 38, home: false),
  YoutubeWorkout('gbPURTSxQLY', 'Negative Pull-Up', 'Bodybuilding.com', 'Back', 'Exercise guide', 62, home: false),
  YoutubeWorkout('jVzrLDIRqnE', 'Burpee Pull-Up', 'Bodybuilding.com', 'Back', 'Exercise guide', 68, home: false),
  YoutubeWorkout('lueEJGjTuPQ', 'Wide-Grip Lat Pulldown', 'Bodybuilding.com', 'Back', 'Exercise guide', 65, home: false),
  YoutubeWorkout('xQNrFHEMhI4', 'Seated Cable Row', 'Bodybuilding.com', 'Back', 'Exercise guide', 93, home: false),
  YoutubeWorkout('--gDUDFKx6Q', 'Bent Over Dumbbell Row', 'Bodybuilding.com', 'Back', 'Exercise guide', 66, home: false),
  YoutubeWorkout('KDEl3AmZbVE', 'T-Bar Row', 'Bodybuilding.com', 'Back', 'Exercise guide', 59, home: false),
  YoutubeWorkout('hhq86gJvrvo', 'Superman', 'Bodybuilding.com', 'Back', 'Exercise guide', 43, home: true),
  YoutubeWorkout('i2uc4oyLbYw', 'Good Morning', 'Bodybuilding.com', 'Back', 'Exercise guide', 33, home: false),
  YoutubeWorkout('tkLTR4b6cAk', 'Face Pull', 'Bodybuilding.com', 'Shoulders', 'Exercise guide', 30, home: false),
  YoutubeWorkout('lPFwcHl0a2c', 'Barbell Shoulder Press', 'Bodybuilding.com', 'Shoulders', 'Exercise guide', 49, home: false),
  YoutubeWorkout('0JfYxMRsUCQ', 'Dumbbell Shoulder Press', 'Bodybuilding.com', 'Shoulders', 'Exercise guide', 62, home: false),
  YoutubeWorkout('X60-yTMOJfw', 'Arnold Press', 'Bodybuilding.com', 'Shoulders', 'Exercise guide', 50, home: false),
  YoutubeWorkout('E3abEP8SIh0', 'Side Lateral Raise', 'Bodybuilding.com', 'Shoulders', 'Exercise guide', 62, home: false),
  YoutubeWorkout('8RL1wbAS5v4', 'Front Raise (Towel)', 'Bodybuilding.com', 'Shoulders', 'Exercise guide', 50, home: true),
  YoutubeWorkout('HN4Ahp3Q9C0', 'Rear Delt Fly', 'Bodybuilding.com', 'Shoulders', 'Exercise guide', 19, home: false),
  YoutubeWorkout('9xGqgGFAtiM', 'Barbell Shrug', 'Bodybuilding.com', 'Shoulders', 'Exercise guide', 39, home: false),
  YoutubeWorkout('3OZ2MT_5r3Q', 'Dumbbell Bicep Curl', 'Bodybuilding.com', 'Arms', 'Exercise guide', 52, home: false),
  YoutubeWorkout('0IAM2YtviQY', 'Hammer Curl', 'Bodybuilding.com', 'Arms', 'Exercise guide', 55, home: false),
  YoutubeWorkout('RgN216Cumtw', 'Preacher Curl', 'Bodybuilding.com', 'Arms', 'Exercise guide', 63, home: false),
  YoutubeWorkout('HIKzvHkibWc', 'Triceps Pushdown', 'Bodybuilding.com', 'Arms', 'Exercise guide', 53, home: false),
  YoutubeWorkout('mRozZKkGIfg', 'Overhead Triceps Extension', 'Bodybuilding.com', 'Arms', 'Exercise guide', 52, home: false),
  YoutubeWorkout('4re6CJ0XNF8', 'Lying Triceps Extension (Skull Crusher)', 'Bodybuilding.com', 'Arms', 'Exercise guide', 153, home: false),
  YoutubeWorkout('OYoc93qAAEY', 'Close-Grip Bench Press', 'Bodybuilding.com', 'Arms', 'Exercise guide', 49, home: false),
  YoutubeWorkout('hJW-Xc8TvU8', 'Farmer\'s Walk', 'Bodybuilding.com', 'Arms', 'Exercise guide', 47, home: false),
  YoutubeWorkout('3R0SOJ3alTA', 'Leg Press', 'Bodybuilding.com', 'Legs', 'Exercise guide', 49, home: false),
  YoutubeWorkout('yR_LqZYSIgM', 'Leg Extension', 'Bodybuilding.com', 'Legs', 'Exercise guide', 51, home: false),
  YoutubeWorkout('jxctD6fL_FQ', 'Lying Leg Curl', 'Bodybuilding.com', 'Legs', 'Exercise guide', 51, home: false),
  YoutubeWorkout('MAMzF7iZNkc', 'Standing Calf Raise', 'Bodybuilding.com', 'Legs', 'Exercise guide', 63, home: false),
  YoutubeWorkout('7AtIjR-QqVA', 'Dumbbell Step-Up', 'Bodybuilding.com', 'Legs', 'Exercise guide', 48, home: false),
  YoutubeWorkout('MJao9o7ROs0', 'Dumbbell Front Squat', 'Bodybuilding.com', 'Legs', 'Exercise guide', 65, home: false),
  YoutubeWorkout('XOTO2qWRy9U', 'Dumbbell Jump Squat', 'Bodybuilding.com', 'Legs', 'Exercise guide', 65, home: false),
  YoutubeWorkout('R-g5yPNYv2k', 'Barbell Reverse Lunge', 'Bodybuilding.com', 'Legs', 'Exercise guide', 83, home: false),
  YoutubeWorkout('Wb8Yr3Nx7dE', 'Lunges', 'Bodybuilding.com', 'Legs', 'Exercise guide', 57, home: true),
  YoutubeWorkout('OmjKyr_Q7fE', 'Walking Lunge (Weight Overhead)', 'Bodybuilding.com', 'Legs', 'Exercise guide', 65, home: false),
  YoutubeWorkout('3h1A9GfB07w', 'Kettlebell Sumo Squat', 'Bodybuilding.com', 'Legs', 'Exercise guide', 62, home: false),
  YoutubeWorkout('JOoc07_Xkls', 'Kettlebell One-Legged Deadlift', 'Bodybuilding.com', 'Legs', 'Exercise guide', 45, home: false),
  YoutubeWorkout('YdZakh0Pkwc', 'Crunches', 'Bodybuilding.com', 'Abdomen', 'Exercise guide', 55, home: true),
  YoutubeWorkout('i6mPCVUrtNk', 'Air Bike (Bicycle Crunch)', 'Bodybuilding.com', 'Abdomen', 'Exercise guide', 54, home: true),
  YoutubeWorkout('3qjoXDTuyOE', 'Cable Crunch', 'Bodybuilding.com', 'Abdomen', 'Exercise guide', 50, home: false),
  YoutubeWorkout('Nw0LOKe3_l8', 'Hanging Leg Raise', 'Bodybuilding.com', 'Abdomen', 'Exercise guide', 46, home: false),
  YoutubeWorkout('Nl-txzo-7WQ', 'Russian Twist', 'Bodybuilding.com', 'Abdomen', 'Exercise guide', 49, home: true),
  YoutubeWorkout('Q5MT5omGNJI', 'Ab Roller', 'Bodybuilding.com', 'Abdomen', 'Exercise guide', 44, home: false),
  YoutubeWorkout('JVm-y2uY9I0', 'Ab Walk-Out', 'Bodybuilding.com', 'Abdomen', 'Exercise guide', 117, home: true),
  YoutubeWorkout('4XLEnwUr1d8', 'Dead Bug', 'Bodybuilding.com', 'Abdomen', 'Exercise guide', 73, home: true),
  YoutubeWorkout('10mp1wusuzM', 'Sit-Up', 'Bodybuilding.com', 'Abdomen', 'Exercise guide', 41, home: true),
  YoutubeWorkout('GEZ8NLbtc8Q', 'Jackknife Sit-Up', 'Bodybuilding.com', 'Abdomen', 'Exercise guide', 51, home: true),
];
