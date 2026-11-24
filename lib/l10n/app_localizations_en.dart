// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'DailyMantra';

  @override
  String get tagline => 'Small habits. Better days.';

  @override
  String get navToday => 'Today';

  @override
  String get navPlan => 'Plan';

  @override
  String get navAdd => 'Add';

  @override
  String get navInsights => 'Insights';

  @override
  String get navYou => 'You';

  @override
  String get greetingMorning => 'Good morning';

  @override
  String get greetingAfternoon => 'Good afternoon';

  @override
  String get greetingEvening => 'Good evening';

  @override
  String todayProgress(int done, int total) {
    return '$done of $total done today';
  }

  @override
  String get todayProgressLabel => 'Today\'s progress';

  @override
  String get quickAdd => 'Quick Add';

  @override
  String get yourHabits => 'Your Habits';

  @override
  String get emptyHabits => 'Start small: tap a tile above to add your first habit.';

  @override
  String get addAHabit => 'Add a habit';

  @override
  String get discover => 'Discover';

  @override
  String discoverNew(int count) {
    return 'Discover ($count new)';
  }

  @override
  String markDone(String name) {
    return 'Mark $name done';
  }

  @override
  String markNotDone(String name) {
    return 'Mark $name not done';
  }

  @override
  String get qaMedicine => 'Medicine';

  @override
  String get qaWater => 'Water Intake';

  @override
  String get qaMeditation => 'Meditation';

  @override
  String get qaReading => 'Reading';

  @override
  String get qaExercise => 'Exercise';

  @override
  String get qaCustom => 'Custom habit';

  @override
  String get qaOthers => 'Others';

  @override
  String get addSheetTitle => 'Add';

  @override
  String get addBrowseContent => 'Browse free books, sounds & exercises';

  @override
  String get planTitle => 'Plan';

  @override
  String get reminderHealth => 'Reminder health';

  @override
  String get notifications => 'Notifications';

  @override
  String get notificationsAllowed => 'Allowed';

  @override
  String get notificationsOff => 'Turned off — reminders cannot appear';

  @override
  String get onTimeDelivery => 'On-time delivery';

  @override
  String get onTimeOk => 'Reminders are scheduled for the exact minute';

  @override
  String get onTimeLate => 'Reminders may arrive a few minutes late';

  @override
  String get allow => 'Allow';

  @override
  String get sendTestReminder => 'Send a test reminder';

  @override
  String get testReminderSent => 'A test reminder will arrive in about 10 seconds.';

  @override
  String get reminderAidDisclaimer => 'DailyMantra is a reminder aid. Phones can delay notifications in battery-saving modes, so don\'t rely on it as your only safeguard for medicine.';

  @override
  String get noUpcoming => 'No upcoming reminders.';

  @override
  String get noUpcomingHint => 'Add a habit with a reminder time to see your plan here.';

  @override
  String get upNext => 'Up next';

  @override
  String get dayToday => 'Today';

  @override
  String get dayTomorrow => 'Tomorrow';

  @override
  String get reminderDaily => 'Daily';

  @override
  String get reminderOnce => 'One-time';

  @override
  String couldNotLoad(String error) {
    return 'Could not load. $error';
  }

  @override
  String get insightsTitle => 'Insights';

  @override
  String get last7Days => 'Last 7 days';

  @override
  String get basedOnLogged => 'Based on what you logged in DailyMantra.';

  @override
  String get nothingLogged => 'Nothing logged yet this week. Mark a habit done or log water, meditation or exercise, and your week will appear here.';

  @override
  String get historyNote => 'History is kept from this version onwards; earlier days were not stored by the previous app.';

  @override
  String get metricCompleted => 'Habits completed';

  @override
  String get metricWater => 'Water';

  @override
  String get metricMeditation => 'Meditation';

  @override
  String get metricExercise => 'Exercise';

  @override
  String get metricSteps => 'Steps';

  @override
  String get unitGlasses => 'glasses';

  @override
  String get unitMin => 'min';

  @override
  String get unitSteps => 'steps';

  @override
  String loggedOnDays(int active, int total) {
    return 'Logged on $active of $total days';
  }

  @override
  String get youTitle => 'You';

  @override
  String get appearance => 'Appearance';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'Phone setting';

  @override
  String get remindersSection => 'Reminders';

  @override
  String get exactPermissionTitle => 'Alarms & reminders permission';

  @override
  String get exactOff => 'Off — reminders may be a few minutes late';

  @override
  String get exactOn => 'On';

  @override
  String get freeContent => 'Free content';

  @override
  String get contentNotLoaded => 'Not loaded yet';

  @override
  String contentStatus(int count, String when) {
    return '$count items · updated $when';
  }

  @override
  String contentFailed(int count) {
    return 'Last refresh failed · $count saved · retrying later';
  }

  @override
  String get checkNewContent => 'Check for new content now';

  @override
  String get contentUnreachable => 'Could not reach content sources. You can still use what\'s saved.';

  @override
  String newItemsAdded(int count) {
    return '$count new items added';
  }

  @override
  String get upToDate => 'You\'re up to date';

  @override
  String get sourcesLicences => 'Sources & licences';

  @override
  String get sourcesIntro => 'DailyMantra only uses content that is free to reuse, including in an ad-supported app: public domain, CC0, CC BY and CC BY-SA. Each item shows its author and licence.';

  @override
  String get privacy => 'Privacy';

  @override
  String get privacyTitle => 'Your data stays on this device';

  @override
  String get privacyBody => 'Habits, medicine schedules and history are stored only on your phone. Optional backup and sync will come later and will always be your choice.';

  @override
  String get justNow => 'just now';

  @override
  String minutesAgo(int n) {
    return '$n min ago';
  }

  @override
  String hoursAgo(int n) {
    return '$n h ago';
  }

  @override
  String daysAgo(int n) {
    return '$n d ago';
  }

  @override
  String get never => 'never';

  @override
  String get obWelcomeBody => 'Plan your day, keep up with water, medicine, movement, reading and calm — one small step at a time.';

  @override
  String get obChooseLanguage => 'Choose your language';

  @override
  String get obContinue => 'Continue';

  @override
  String get obSkip => 'Skip';

  @override
  String get obBack => 'Back';

  @override
  String get obGoalsTitle => 'What would you like help with?';

  @override
  String get obGoalsBody => 'Pick any. You can change this later.';

  @override
  String get goalHealth => 'Health';

  @override
  String get goalFocus => 'Focus';

  @override
  String get goalFitness => 'Fitness';

  @override
  String get goalCalm => 'Calm';

  @override
  String get goalLearning => 'Learning';

  @override
  String get goalRoutines => 'Routines';

  @override
  String get obStartersTitle => 'Start with one to three habits';

  @override
  String get obStartersBody => 'Small is good. Tap the time to change it.';

  @override
  String get starterWater => 'Drink water';

  @override
  String get starterMedicine => 'Take my medicine';

  @override
  String get starterMeditate => 'Meditate 10 minutes';

  @override
  String get starterRead => 'Read 20 minutes';

  @override
  String get starterMove => 'Move / exercise';

  @override
  String get starterJournal => 'Evening reflection';

  @override
  String get obMaxThree => 'Pick up to three to start — you can add more any time.';

  @override
  String get obPrivacyTitle => 'Private and reminder-ready';

  @override
  String get obPrivacyBody => 'Everything stays on your phone. No account needed.';

  @override
  String get obRemindersNote => 'Next, your phone may ask to allow notifications so DailyMantra can remind you at the times you chose.';

  @override
  String get obStart => 'Start my day';

  @override
  String get obMedicineNote => 'Reminders only — DailyMantra never gives dosing advice.';
}
