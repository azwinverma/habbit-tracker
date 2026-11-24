import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ne.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ne')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'DailyMantra'**
  String get appTitle;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Small habits. Better days.'**
  String get tagline;

  /// No description provided for @navToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get navToday;

  /// No description provided for @navPlan.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get navPlan;

  /// No description provided for @navAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get navAdd;

  /// No description provided for @navInsights.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get navInsights;

  /// No description provided for @navYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get navYou;

  /// No description provided for @greetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get greetingMorning;

  /// No description provided for @greetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get greetingEvening;

  /// No description provided for @todayProgress.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} done today'**
  String todayProgress(int done, int total);

  /// No description provided for @todayProgressLabel.
  ///
  /// In en, this message translates to:
  /// **'Today\'s progress'**
  String get todayProgressLabel;

  /// No description provided for @quickAdd.
  ///
  /// In en, this message translates to:
  /// **'Quick Add'**
  String get quickAdd;

  /// No description provided for @yourHabits.
  ///
  /// In en, this message translates to:
  /// **'Your Habits'**
  String get yourHabits;

  /// No description provided for @emptyHabits.
  ///
  /// In en, this message translates to:
  /// **'Start small: tap a tile above to add your first habit.'**
  String get emptyHabits;

  /// No description provided for @addAHabit.
  ///
  /// In en, this message translates to:
  /// **'Add a habit'**
  String get addAHabit;

  /// No description provided for @discover.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get discover;

  /// No description provided for @discoverNew.
  ///
  /// In en, this message translates to:
  /// **'Discover ({count} new)'**
  String discoverNew(int count);

  /// No description provided for @markDone.
  ///
  /// In en, this message translates to:
  /// **'Mark {name} done'**
  String markDone(String name);

  /// No description provided for @markNotDone.
  ///
  /// In en, this message translates to:
  /// **'Mark {name} not done'**
  String markNotDone(String name);

  /// No description provided for @qaMedicine.
  ///
  /// In en, this message translates to:
  /// **'Medicine'**
  String get qaMedicine;

  /// No description provided for @qaWater.
  ///
  /// In en, this message translates to:
  /// **'Water Intake'**
  String get qaWater;

  /// No description provided for @qaMeditation.
  ///
  /// In en, this message translates to:
  /// **'Meditation'**
  String get qaMeditation;

  /// No description provided for @qaReading.
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get qaReading;

  /// No description provided for @qaExercise.
  ///
  /// In en, this message translates to:
  /// **'Exercise'**
  String get qaExercise;

  /// No description provided for @qaCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom habit'**
  String get qaCustom;

  /// No description provided for @qaOthers.
  ///
  /// In en, this message translates to:
  /// **'Others'**
  String get qaOthers;

  /// No description provided for @addSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addSheetTitle;

  /// No description provided for @addBrowseContent.
  ///
  /// In en, this message translates to:
  /// **'Browse free books, sounds & exercises'**
  String get addBrowseContent;

  /// No description provided for @planTitle.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get planTitle;

  /// No description provided for @reminderHealth.
  ///
  /// In en, this message translates to:
  /// **'Reminder health'**
  String get reminderHealth;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @notificationsAllowed.
  ///
  /// In en, this message translates to:
  /// **'Allowed'**
  String get notificationsAllowed;

  /// No description provided for @notificationsOff.
  ///
  /// In en, this message translates to:
  /// **'Turned off — reminders cannot appear'**
  String get notificationsOff;

  /// No description provided for @onTimeDelivery.
  ///
  /// In en, this message translates to:
  /// **'On-time delivery'**
  String get onTimeDelivery;

  /// No description provided for @onTimeOk.
  ///
  /// In en, this message translates to:
  /// **'Reminders are scheduled for the exact minute'**
  String get onTimeOk;

  /// No description provided for @onTimeLate.
  ///
  /// In en, this message translates to:
  /// **'Reminders may arrive a few minutes late'**
  String get onTimeLate;

  /// No description provided for @allow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get allow;

  /// No description provided for @sendTestReminder.
  ///
  /// In en, this message translates to:
  /// **'Send a test reminder'**
  String get sendTestReminder;

  /// No description provided for @testReminderSent.
  ///
  /// In en, this message translates to:
  /// **'A test reminder will arrive in about 10 seconds.'**
  String get testReminderSent;

  /// No description provided for @reminderAidDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'DailyMantra is a reminder aid. Phones can delay notifications in battery-saving modes, so don\'t rely on it as your only safeguard for medicine.'**
  String get reminderAidDisclaimer;

  /// No description provided for @noUpcoming.
  ///
  /// In en, this message translates to:
  /// **'No upcoming reminders.'**
  String get noUpcoming;

  /// No description provided for @noUpcomingHint.
  ///
  /// In en, this message translates to:
  /// **'Add a habit with a reminder time to see your plan here.'**
  String get noUpcomingHint;

  /// No description provided for @upNext.
  ///
  /// In en, this message translates to:
  /// **'Up next'**
  String get upNext;

  /// No description provided for @dayToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get dayToday;

  /// No description provided for @dayTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get dayTomorrow;

  /// No description provided for @reminderDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get reminderDaily;

  /// No description provided for @reminderOnce.
  ///
  /// In en, this message translates to:
  /// **'One-time'**
  String get reminderOnce;

  /// No description provided for @couldNotLoad.
  ///
  /// In en, this message translates to:
  /// **'Could not load. {error}'**
  String couldNotLoad(String error);

  /// No description provided for @insightsTitle.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get insightsTitle;

  /// No description provided for @last7Days.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get last7Days;

  /// No description provided for @basedOnLogged.
  ///
  /// In en, this message translates to:
  /// **'Based on what you logged in DailyMantra.'**
  String get basedOnLogged;

  /// No description provided for @nothingLogged.
  ///
  /// In en, this message translates to:
  /// **'Nothing logged yet this week. Mark a habit done or log water, meditation or exercise, and your week will appear here.'**
  String get nothingLogged;

  /// No description provided for @historyNote.
  ///
  /// In en, this message translates to:
  /// **'History is kept from this version onwards; earlier days were not stored by the previous app.'**
  String get historyNote;

  /// No description provided for @metricCompleted.
  ///
  /// In en, this message translates to:
  /// **'Habits completed'**
  String get metricCompleted;

  /// No description provided for @metricWater.
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get metricWater;

  /// No description provided for @metricMeditation.
  ///
  /// In en, this message translates to:
  /// **'Meditation'**
  String get metricMeditation;

  /// No description provided for @metricExercise.
  ///
  /// In en, this message translates to:
  /// **'Exercise'**
  String get metricExercise;

  /// No description provided for @metricSteps.
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get metricSteps;

  /// No description provided for @unitGlasses.
  ///
  /// In en, this message translates to:
  /// **'glasses'**
  String get unitGlasses;

  /// No description provided for @unitMin.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get unitMin;

  /// No description provided for @unitSteps.
  ///
  /// In en, this message translates to:
  /// **'steps'**
  String get unitSteps;

  /// No description provided for @loggedOnDays.
  ///
  /// In en, this message translates to:
  /// **'Logged on {active} of {total} days'**
  String loggedOnDays(int active, int total);

  /// No description provided for @youTitle.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get youTitle;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'Phone setting'**
  String get languageSystem;

  /// No description provided for @remindersSection.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get remindersSection;

  /// No description provided for @exactPermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Alarms & reminders permission'**
  String get exactPermissionTitle;

  /// No description provided for @exactOff.
  ///
  /// In en, this message translates to:
  /// **'Off — reminders may be a few minutes late'**
  String get exactOff;

  /// No description provided for @exactOn.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get exactOn;

  /// No description provided for @freeContent.
  ///
  /// In en, this message translates to:
  /// **'Free content'**
  String get freeContent;

  /// No description provided for @contentNotLoaded.
  ///
  /// In en, this message translates to:
  /// **'Not loaded yet'**
  String get contentNotLoaded;

  /// No description provided for @contentStatus.
  ///
  /// In en, this message translates to:
  /// **'{count} items · updated {when}'**
  String contentStatus(int count, String when);

  /// No description provided for @contentFailed.
  ///
  /// In en, this message translates to:
  /// **'Last refresh failed · {count} saved · retrying later'**
  String contentFailed(int count);

  /// No description provided for @checkNewContent.
  ///
  /// In en, this message translates to:
  /// **'Check for new content now'**
  String get checkNewContent;

  /// No description provided for @contentUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Could not reach content sources. You can still use what\'s saved.'**
  String get contentUnreachable;

  /// No description provided for @newItemsAdded.
  ///
  /// In en, this message translates to:
  /// **'{count} new items added'**
  String newItemsAdded(int count);

  /// No description provided for @upToDate.
  ///
  /// In en, this message translates to:
  /// **'You\'re up to date'**
  String get upToDate;

  /// No description provided for @sourcesLicences.
  ///
  /// In en, this message translates to:
  /// **'Sources & licences'**
  String get sourcesLicences;

  /// No description provided for @sourcesIntro.
  ///
  /// In en, this message translates to:
  /// **'DailyMantra only uses content that is free to reuse, including in an ad-supported app: public domain, CC0, CC BY and CC BY-SA. Each item shows its author and licence.'**
  String get sourcesIntro;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacy;

  /// No description provided for @privacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your data stays on this device'**
  String get privacyTitle;

  /// No description provided for @privacyBody.
  ///
  /// In en, this message translates to:
  /// **'Habits, medicine schedules and history are stored only on your phone. Optional backup and sync will come later and will always be your choice.'**
  String get privacyBody;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get justNow;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{n} min ago'**
  String minutesAgo(int n);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{n} h ago'**
  String hoursAgo(int n);

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{n} d ago'**
  String daysAgo(int n);

  /// No description provided for @never.
  ///
  /// In en, this message translates to:
  /// **'never'**
  String get never;

  /// No description provided for @obWelcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Plan your day, keep up with water, medicine, movement, reading and calm — one small step at a time.'**
  String get obWelcomeBody;

  /// No description provided for @obChooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose your language'**
  String get obChooseLanguage;

  /// No description provided for @obContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get obContinue;

  /// No description provided for @obSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get obSkip;

  /// No description provided for @obBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get obBack;

  /// No description provided for @obGoalsTitle.
  ///
  /// In en, this message translates to:
  /// **'What would you like help with?'**
  String get obGoalsTitle;

  /// No description provided for @obGoalsBody.
  ///
  /// In en, this message translates to:
  /// **'Pick any. You can change this later.'**
  String get obGoalsBody;

  /// No description provided for @goalHealth.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get goalHealth;

  /// No description provided for @goalFocus.
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get goalFocus;

  /// No description provided for @goalFitness.
  ///
  /// In en, this message translates to:
  /// **'Fitness'**
  String get goalFitness;

  /// No description provided for @goalCalm.
  ///
  /// In en, this message translates to:
  /// **'Calm'**
  String get goalCalm;

  /// No description provided for @goalLearning.
  ///
  /// In en, this message translates to:
  /// **'Learning'**
  String get goalLearning;

  /// No description provided for @goalRoutines.
  ///
  /// In en, this message translates to:
  /// **'Routines'**
  String get goalRoutines;

  /// No description provided for @obStartersTitle.
  ///
  /// In en, this message translates to:
  /// **'Start with one to three habits'**
  String get obStartersTitle;

  /// No description provided for @obStartersBody.
  ///
  /// In en, this message translates to:
  /// **'Small is good. Tap the time to change it.'**
  String get obStartersBody;

  /// No description provided for @starterWater.
  ///
  /// In en, this message translates to:
  /// **'Drink water'**
  String get starterWater;

  /// No description provided for @starterMedicine.
  ///
  /// In en, this message translates to:
  /// **'Take my medicine'**
  String get starterMedicine;

  /// No description provided for @starterMeditate.
  ///
  /// In en, this message translates to:
  /// **'Meditate 10 minutes'**
  String get starterMeditate;

  /// No description provided for @starterRead.
  ///
  /// In en, this message translates to:
  /// **'Read 20 minutes'**
  String get starterRead;

  /// No description provided for @starterMove.
  ///
  /// In en, this message translates to:
  /// **'Move / exercise'**
  String get starterMove;

  /// No description provided for @starterJournal.
  ///
  /// In en, this message translates to:
  /// **'Evening reflection'**
  String get starterJournal;

  /// No description provided for @obMaxThree.
  ///
  /// In en, this message translates to:
  /// **'Pick up to three to start — you can add more any time.'**
  String get obMaxThree;

  /// No description provided for @obPrivacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Private and reminder-ready'**
  String get obPrivacyTitle;

  /// No description provided for @obPrivacyBody.
  ///
  /// In en, this message translates to:
  /// **'Everything stays on your phone. No account needed.'**
  String get obPrivacyBody;

  /// No description provided for @obRemindersNote.
  ///
  /// In en, this message translates to:
  /// **'Next, your phone may ask to allow notifications so DailyMantra can remind you at the times you chose.'**
  String get obRemindersNote;

  /// No description provided for @obStart.
  ///
  /// In en, this message translates to:
  /// **'Start my day'**
  String get obStart;

  /// No description provided for @obMedicineNote.
  ///
  /// In en, this message translates to:
  /// **'Reminders only — DailyMantra never gives dosing advice.'**
  String get obMedicineNote;

  /// No description provided for @medTitle.
  ///
  /// In en, this message translates to:
  /// **'Medicine'**
  String get medTitle;

  /// No description provided for @medSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get medSave;

  /// No description provided for @medSaveSchedule.
  ///
  /// In en, this message translates to:
  /// **'Save & schedule'**
  String get medSaveSchedule;

  /// No description provided for @medName.
  ///
  /// In en, this message translates to:
  /// **'Medicine name'**
  String get medName;

  /// No description provided for @medDose.
  ///
  /// In en, this message translates to:
  /// **'Dose (e.g. 500 mg, 2 tablets)'**
  String get medDose;

  /// No description provided for @medNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes (before/after meal, etc.)'**
  String get medNotes;

  /// No description provided for @medEnable.
  ///
  /// In en, this message translates to:
  /// **'Enable reminders'**
  String get medEnable;

  /// No description provided for @medStart.
  ///
  /// In en, this message translates to:
  /// **'Start date'**
  String get medStart;

  /// No description provided for @medEnd.
  ///
  /// In en, this message translates to:
  /// **'End date'**
  String get medEnd;

  /// No description provided for @medPick.
  ///
  /// In en, this message translates to:
  /// **'Pick'**
  String get medPick;

  /// No description provided for @medNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get medNotSet;

  /// No description provided for @medCourseHint.
  ///
  /// In en, this message translates to:
  /// **'Reminders repeat every day at each dose time, from the start date to the end date.'**
  String get medCourseHint;

  /// No description provided for @medDoseTimes.
  ///
  /// In en, this message translates to:
  /// **'Dose times'**
  String get medDoseTimes;

  /// No description provided for @medAddTime.
  ///
  /// In en, this message translates to:
  /// **'Add dose time'**
  String get medAddTime;

  /// No description provided for @medNoTimes.
  ///
  /// In en, this message translates to:
  /// **'No dose times yet.'**
  String get medNoTimes;

  /// No description provided for @medToday.
  ///
  /// In en, this message translates to:
  /// **'Today\'s doses'**
  String get medToday;

  /// No description provided for @medTaken.
  ///
  /// In en, this message translates to:
  /// **'Taken'**
  String get medTaken;

  /// No description provided for @medSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get medSkip;

  /// No description provided for @medSkipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get medSkipped;

  /// No description provided for @medPending.
  ///
  /// In en, this message translates to:
  /// **'Not yet'**
  String get medPending;

  /// No description provided for @medUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get medUndo;

  /// No description provided for @medNoDosesToday.
  ///
  /// In en, this message translates to:
  /// **'No doses scheduled today.'**
  String get medNoDosesToday;

  /// No description provided for @medAdherence.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days: {taken} of {due} doses taken'**
  String medAdherence(int taken, int due);

  /// No description provided for @medAdherenceNone.
  ///
  /// In en, this message translates to:
  /// **'No doses were due in the last 7 days.'**
  String get medAdherenceNone;

  /// No description provided for @medSaved.
  ///
  /// In en, this message translates to:
  /// **'Medicine reminders saved.'**
  String get medSaved;

  /// No description provided for @medSavedDisabled.
  ///
  /// In en, this message translates to:
  /// **'Saved (reminders are off).'**
  String get medSavedDisabled;

  /// No description provided for @medDefaultName.
  ///
  /// In en, this message translates to:
  /// **'Medicine'**
  String get medDefaultName;

  /// No description provided for @medSaveFirst.
  ///
  /// In en, this message translates to:
  /// **'Save to start tracking doses.'**
  String get medSaveFirst;

  /// No description provided for @medNotificationHint.
  ///
  /// In en, this message translates to:
  /// **'Tip: tap “Taken” on the reminder notification. It is recorded even if the app is closed.'**
  String get medNotificationHint;

  /// No description provided for @medDoseSemantics.
  ///
  /// In en, this message translates to:
  /// **'Dose at {time}: {status}'**
  String medDoseSemantics(String time, String status);

  /// No description provided for @exOfficeTitle.
  ///
  /// In en, this message translates to:
  /// **'Office move breaks'**
  String get exOfficeTitle;

  /// No description provided for @exWalk.
  ///
  /// In en, this message translates to:
  /// **'Walk reminders'**
  String get exWalk;

  /// No description provided for @exStretch.
  ///
  /// In en, this message translates to:
  /// **'Stretch reminders'**
  String get exStretch;

  /// No description provided for @exEvery.
  ///
  /// In en, this message translates to:
  /// **'Every {minutes} min'**
  String exEvery(int minutes);

  /// No description provided for @exOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get exOff;

  /// No description provided for @exOfficeHint.
  ///
  /// In en, this message translates to:
  /// **'Reminders between {start} and {end} every day.'**
  String exOfficeHint(String start, String end);

  /// No description provided for @exWalkEvery.
  ///
  /// In en, this message translates to:
  /// **'Walk every (minutes)'**
  String get exWalkEvery;

  /// No description provided for @exStretchEvery.
  ///
  /// In en, this message translates to:
  /// **'Stretch every (minutes)'**
  String get exStretchEvery;

  /// No description provided for @heroAllDone.
  ///
  /// In en, this message translates to:
  /// **'All done for today. Lovely work.'**
  String get heroAllDone;

  /// No description provided for @heroStart.
  ///
  /// In en, this message translates to:
  /// **'Start small. One habit is enough.'**
  String get heroStart;

  /// No description provided for @heroKeepGoing.
  ///
  /// In en, this message translates to:
  /// **'Keep going — {left} left today'**
  String heroKeepGoing(int left);

  /// No description provided for @streakDays.
  ///
  /// In en, this message translates to:
  /// **'{days}-day streak'**
  String streakDays(int days);

  /// No description provided for @tileWater.
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get tileWater;

  /// No description provided for @tileWaterValue.
  ///
  /// In en, this message translates to:
  /// **'{done} of {target} glasses'**
  String tileWaterValue(int done, int target);

  /// No description provided for @tileAddGlass.
  ///
  /// In en, this message translates to:
  /// **'Add a glass'**
  String get tileAddGlass;

  /// No description provided for @tileMedicine.
  ///
  /// In en, this message translates to:
  /// **'Medicine'**
  String get tileMedicine;

  /// No description provided for @tileNextDose.
  ///
  /// In en, this message translates to:
  /// **'Next dose {time}'**
  String tileNextDose(String time);

  /// No description provided for @tileDosesLogged.
  ///
  /// In en, this message translates to:
  /// **'Today\'s doses logged'**
  String get tileDosesLogged;

  /// No description provided for @tileNoDoseToday.
  ///
  /// In en, this message translates to:
  /// **'No doses today'**
  String get tileNoDoseToday;

  /// No description provided for @tileMovement.
  ///
  /// In en, this message translates to:
  /// **'Movement'**
  String get tileMovement;

  /// No description provided for @tileMinutesValue.
  ///
  /// In en, this message translates to:
  /// **'{done} of {goal} min'**
  String tileMinutesValue(int done, int goal);

  /// No description provided for @tileStepsValue.
  ///
  /// In en, this message translates to:
  /// **'{steps} steps'**
  String tileStepsValue(int steps);

  /// No description provided for @tileMind.
  ///
  /// In en, this message translates to:
  /// **'Mind'**
  String get tileMind;

  /// No description provided for @tileMindValue.
  ///
  /// In en, this message translates to:
  /// **'{done} of {goal} min calm'**
  String tileMindValue(int done, int goal);

  /// No description provided for @tileMindStart.
  ///
  /// In en, this message translates to:
  /// **'Take a calm minute'**
  String get tileMindStart;

  /// No description provided for @tileReading.
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get tileReading;

  /// No description provided for @tileReadingContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue reading'**
  String get tileReadingContinue;

  /// No description provided for @tileFindBook.
  ///
  /// In en, this message translates to:
  /// **'Find a free book'**
  String get tileFindBook;

  /// No description provided for @upNextToday.
  ///
  /// In en, this message translates to:
  /// **'Up next today'**
  String get upNextToday;

  /// No description provided for @nothingLeftToday.
  ///
  /// In en, this message translates to:
  /// **'No more reminders today. Enjoy your evening.'**
  String get nothingLeftToday;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @thoughtForToday.
  ///
  /// In en, this message translates to:
  /// **'Thought for today'**
  String get thoughtForToday;

  /// No description provided for @menuEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get menuEdit;

  /// No description provided for @menuDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get menuDelete;

  /// No description provided for @exactDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'On-time reminders'**
  String get exactDialogTitle;

  /// No description provided for @exactDialogBody.
  ///
  /// In en, this message translates to:
  /// **'To deliver medicine and habit reminders at the exact minute, DailyMantra needs the \"Alarms & reminders\" permission. Without it, reminders may arrive a few minutes late.'**
  String get exactDialogBody;

  /// No description provided for @notNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notNow;

  /// No description provided for @emptyTodayTitle.
  ///
  /// In en, this message translates to:
  /// **'Small habits. Better days.'**
  String get emptyTodayTitle;

  /// No description provided for @emptyTodayBody.
  ///
  /// In en, this message translates to:
  /// **'Add your first habit — a glass of water or a short walk is a great start.'**
  String get emptyTodayBody;

  /// No description provided for @doneTodayCount.
  ///
  /// In en, this message translates to:
  /// **'{done}/{total}'**
  String doneTodayCount(int done, int total);

  /// No description provided for @streakShort.
  ///
  /// In en, this message translates to:
  /// **'{days}d'**
  String streakShort(int days);

  /// No description provided for @addHintMedicine.
  ///
  /// In en, this message translates to:
  /// **'Doses on time, logged'**
  String get addHintMedicine;

  /// No description provided for @addHintWater.
  ///
  /// In en, this message translates to:
  /// **'Glasses through the day'**
  String get addHintWater;

  /// No description provided for @addHintMeditation.
  ///
  /// In en, this message translates to:
  /// **'Calm minutes, gentle sounds'**
  String get addHintMeditation;

  /// No description provided for @addHintReading.
  ///
  /// In en, this message translates to:
  /// **'Free classics, daily pages'**
  String get addHintReading;

  /// No description provided for @addHintExercise.
  ///
  /// In en, this message translates to:
  /// **'Moves, steps, office breaks'**
  String get addHintExercise;

  /// No description provided for @addHintCustom.
  ///
  /// In en, this message translates to:
  /// **'Anything you want to repeat'**
  String get addHintCustom;

  /// No description provided for @copyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get copyLink;

  /// No description provided for @linkCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied {url}'**
  String linkCopied(String url);

  /// No description provided for @licNoteGutenberg.
  ///
  /// In en, this message translates to:
  /// **'public-domain ebooks (US). Copyright may differ in other countries.'**
  String get licNoteGutenberg;

  /// No description provided for @licNoteCommons.
  ///
  /// In en, this message translates to:
  /// **'freely licensed recordings (PD, CC0, CC BY, CC BY-SA); author credited.'**
  String get licNoteCommons;

  /// No description provided for @licNoteWger.
  ///
  /// In en, this message translates to:
  /// **'exercise descriptions CC BY-SA; images credited to their authors.'**
  String get licNoteWger;

  /// No description provided for @openSourceLicences.
  ///
  /// In en, this message translates to:
  /// **'Open-source licences'**
  String get openSourceLicences;

  /// No description provided for @onThisDevice.
  ///
  /// In en, this message translates to:
  /// **'Saved on this device'**
  String get onThisDevice;

  /// No description provided for @profileTagline.
  ///
  /// In en, this message translates to:
  /// **'Small habits. Better days.'**
  String get profileTagline;

  /// No description provided for @splashPreparing.
  ///
  /// In en, this message translates to:
  /// **'Getting your day ready…'**
  String get splashPreparing;

  /// No description provided for @splashError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong while starting.'**
  String get splashError;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'ne'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'ne': return AppLocalizationsNe();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
