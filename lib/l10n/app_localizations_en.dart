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

  @override
  String get medTitle => 'Medicine';

  @override
  String get medSave => 'Save';

  @override
  String get medSaveSchedule => 'Save & schedule';

  @override
  String get medName => 'Medicine name';

  @override
  String get medDose => 'Dose (e.g. 500 mg, 2 tablets)';

  @override
  String get medNotes => 'Notes (before/after meal, etc.)';

  @override
  String get medEnable => 'Enable reminders';

  @override
  String get medStart => 'Start date';

  @override
  String get medEnd => 'End date';

  @override
  String get medPick => 'Pick';

  @override
  String get medNotSet => 'Not set';

  @override
  String get medCourseHint => 'Reminders repeat every day at each dose time, from the start date to the end date.';

  @override
  String get medDoseTimes => 'Dose times';

  @override
  String get medAddTime => 'Add dose time';

  @override
  String get medNoTimes => 'No dose times yet.';

  @override
  String get medToday => 'Today\'s doses';

  @override
  String get medTaken => 'Taken';

  @override
  String get medSkip => 'Skip';

  @override
  String get medSkipped => 'Skipped';

  @override
  String get medPending => 'Not yet';

  @override
  String get medUndo => 'Undo';

  @override
  String get medNoDosesToday => 'No doses scheduled today.';

  @override
  String medAdherence(int taken, int due) {
    return 'Last 7 days: $taken of $due doses taken';
  }

  @override
  String get medAdherenceNone => 'No doses were due in the last 7 days.';

  @override
  String get medSaved => 'Medicine reminders saved.';

  @override
  String get medSavedDisabled => 'Saved (reminders are off).';

  @override
  String get medDefaultName => 'Medicine';

  @override
  String get medSaveFirst => 'Save to start tracking doses.';

  @override
  String get medNotificationHint => 'Tip: tap “Taken” on the reminder notification. It is recorded even if the app is closed.';

  @override
  String medDoseSemantics(String time, String status) {
    return 'Dose at $time: $status';
  }

  @override
  String get exOfficeTitle => 'Office move breaks';

  @override
  String get exWalk => 'Walk reminders';

  @override
  String get exStretch => 'Stretch reminders';

  @override
  String exEvery(int minutes) {
    return 'Every $minutes min';
  }

  @override
  String get exOff => 'Off';

  @override
  String exOfficeHint(String start, String end) {
    return 'Reminders between $start and $end every day.';
  }

  @override
  String get exWalkEvery => 'Walk every (minutes)';

  @override
  String get exStretchEvery => 'Stretch every (minutes)';

  @override
  String get heroAllDone => 'All done for today. Lovely work.';

  @override
  String get heroStart => 'Start small. One habit is enough.';

  @override
  String heroKeepGoing(int left) {
    return 'Keep going — $left left today';
  }

  @override
  String streakDays(int days) {
    return '$days-day streak';
  }

  @override
  String get tileWater => 'Water';

  @override
  String tileWaterValue(int done, int target) {
    return '$done of $target glasses';
  }

  @override
  String get tileAddGlass => 'Add a glass';

  @override
  String get tileMedicine => 'Medicine';

  @override
  String tileNextDose(String time) {
    return 'Next dose $time';
  }

  @override
  String get tileDosesLogged => 'Today\'s doses logged';

  @override
  String get tileNoDoseToday => 'No doses today';

  @override
  String get tileMovement => 'Movement';

  @override
  String tileMinutesValue(int done, int goal) {
    return '$done of $goal min';
  }

  @override
  String tileStepsValue(int steps) {
    return '$steps steps';
  }

  @override
  String get tileMind => 'Mind';

  @override
  String tileMindValue(int done, int goal) {
    return '$done of $goal min calm';
  }

  @override
  String get tileMindStart => 'Take a calm minute';

  @override
  String get tileReading => 'Reading';

  @override
  String get tileReadingContinue => 'Continue reading';

  @override
  String get tileFindBook => 'Find a free book';

  @override
  String get upNextToday => 'Up next today';

  @override
  String get nothingLeftToday => 'No more reminders today. Enjoy your evening.';

  @override
  String get seeAll => 'See all';

  @override
  String get thoughtForToday => 'Thought for today';

  @override
  String get menuEdit => 'Edit';

  @override
  String get menuDelete => 'Delete';

  @override
  String get exactDialogTitle => 'On-time reminders';

  @override
  String get exactDialogBody => 'To deliver medicine and habit reminders at the exact minute, DailyMantra needs the \"Alarms & reminders\" permission. Without it, reminders may arrive a few minutes late.';

  @override
  String get notNow => 'Not now';

  @override
  String get emptyTodayTitle => 'Small habits. Better days.';

  @override
  String get emptyTodayBody => 'Add your first habit — a glass of water or a short walk is a great start.';

  @override
  String doneTodayCount(int done, int total) {
    return '$done/$total';
  }

  @override
  String streakShort(int days) {
    return '${days}d';
  }

  @override
  String get addHintMedicine => 'Doses on time, logged';

  @override
  String get addHintWater => 'Glasses through the day';

  @override
  String get addHintMeditation => 'Calm minutes, gentle sounds';

  @override
  String get addHintReading => 'Free classics, daily pages';

  @override
  String get addHintExercise => 'Moves, steps, office breaks';

  @override
  String get addHintCustom => 'Anything you want to repeat';

  @override
  String get copyLink => 'Copy link';

  @override
  String linkCopied(String url) {
    return 'Copied $url';
  }

  @override
  String get licNoteGutenberg => 'public-domain ebooks (US). Copyright may differ in other countries.';

  @override
  String get licNoteCommons => 'freely licensed recordings (PD, CC0, CC BY, CC BY-SA); author credited.';

  @override
  String get licNoteWger => 'exercise descriptions CC BY-SA; images credited to their authors.';

  @override
  String get openSourceLicences => 'Open-source licences';

  @override
  String get onThisDevice => 'Saved on this device';

  @override
  String get profileTagline => 'Small habits. Better days.';

  @override
  String get splashPreparing => 'Getting your day ready…';

  @override
  String get splashError => 'Something went wrong while starting.';

  @override
  String get retry => 'Try again';

  @override
  String get searchContent => 'Search titles, authors, topics';

  @override
  String get clear => 'Clear';

  @override
  String get savedFilter => 'Saved';

  @override
  String get tabBooks => 'Books';

  @override
  String get tabAudiobooks => 'Audiobooks';

  @override
  String get tabSounds => 'Sounds';

  @override
  String get tabWorkouts => 'Workouts';

  @override
  String get tabVideos => 'Videos';

  @override
  String get newBadge => 'New';

  @override
  String nothingMatches(String query) {
    return 'Nothing matches \"$query\".';
  }

  @override
  String get nothingYet => 'Nothing here yet. Connect to the internet and pull down to load free content.';

  @override
  String get nothingSaved => 'Nothing saved yet. Open an item and tap Download to keep it on your phone.';

  @override
  String get readNow => 'Read now';

  @override
  String get listen => 'Listen';

  @override
  String get playLoops => 'Play (loops)';

  @override
  String get play => 'Play';

  @override
  String get pause => 'Pause';

  @override
  String get loop => 'Loop';

  @override
  String get watchVideo => 'Watch video';

  @override
  String watchVideoSize(String size) {
    return 'Watch video ($size)';
  }

  @override
  String get couldNotPlay => 'Could not play this. Check your connection and try again.';

  @override
  String get videoError => 'This video can\'t be played on this device. Try another one, or check your connection.';

  @override
  String get creditsLicence => 'Credits & licence';

  @override
  String licenceLabel(String licence) {
    return 'Licence: $licence';
  }

  @override
  String get copySourceLink => 'Copy source link';

  @override
  String get sourceCopied => 'Source link copied';

  @override
  String get downloadOffline => 'Download for offline';

  @override
  String downloadOfflineSize(String size) {
    return 'Download for offline ($size)';
  }

  @override
  String get downloaded => 'Saved on this phone';

  @override
  String get removeDownload => 'Remove download';

  @override
  String get downloadFailed => 'Download failed. Check your connection and try again.';

  @override
  String get downloadAll => 'Download all chapters';

  @override
  String get chapters => 'Chapters';

  @override
  String chapterCount(int count) {
    return '$count chapters';
  }

  @override
  String get previousChapter => 'Previous chapter';

  @override
  String get nextChapter => 'Next chapter';

  @override
  String get back30 => 'Back 30 seconds';

  @override
  String get forward30 => 'Forward 30 seconds';

  @override
  String get cancel => 'Cancel';

  @override
  String get remove => 'Remove';

  @override
  String get storageTitle => 'Saved for offline';

  @override
  String storageUsed(String size, int count) {
    return '$size used on this phone · $count files';
  }

  @override
  String get clearDownloads => 'Remove all downloads';

  @override
  String get clearDownloadsConfirm => 'Remove all saved books, audio and videos from this phone? You can download them again later.';

  @override
  String get autoUpdateNote => 'New content is checked every time you open the app, and in the background about twice a day on Wi-Fi or mobile data.';

  @override
  String get licNoteLibrivox => 'public-domain audiobooks read by volunteers.';

  @override
  String get licNoteCommonsVideo => 'freely licensed exercise, yoga and meditation videos (PD, CC0, CC BY, CC BY-SA); author credited.';

  @override
  String get fullscreen => 'Full screen';

  @override
  String get exitFullscreen => 'Exit full screen';

  @override
  String get back10 => 'Back 10 seconds';

  @override
  String get forward10 => 'Forward 10 seconds';

  @override
  String get playbackSpeed => 'Playback speed';

  @override
  String get mute => 'Mute';

  @override
  String get unmute => 'Unmute';

  @override
  String resumedAt(String time) {
    return 'Resumed at $time';
  }

  @override
  String get startOver => 'Start over';

  @override
  String get videoDemo => 'Video demo';

  @override
  String get noVideoYet => 'No video for this exercise yet. Follow the picture and steps below.';

  @override
  String get howToDoIt => 'How to do it';

  @override
  String get musclesLabel => 'Muscles';

  @override
  String get equipmentLabel => 'Equipment';

  @override
  String get moreWithVideo => 'More exercises with video';

  @override
  String get continueTitle => 'Continue where you left off';

  @override
  String timeLeft(String time) {
    return '$time left';
  }

  @override
  String get resumeAction => 'Continue';

  @override
  String get removeFromContinue => 'Remove from Continue';

  @override
  String get openedWhereLeft => 'Opened where you left off';

  @override
  String get continueReading => 'Continue reading';

  @override
  String get exLibraryTitle => 'Exercise library';

  @override
  String get exWithVideo => 'With video';

  @override
  String get exSearchHint => 'Search exercises';

  @override
  String get exWatchHow => 'Watch how';

  @override
  String get exLibraryEmpty => 'Exercises appear here after the first update. Connect to the internet and pull down to refresh.';
}
