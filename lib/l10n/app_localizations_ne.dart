// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Nepali (`ne`).
class AppLocalizationsNe extends AppLocalizations {
  AppLocalizationsNe([String locale = 'ne']) : super(locale);

  @override
  String get appTitle => 'DailyMantra';

  @override
  String get tagline => 'साना बानी, राम्रा दिन।';

  @override
  String get navToday => 'आज';

  @override
  String get navPlan => 'योजना';

  @override
  String get navAdd => 'थप्नुहोस्';

  @override
  String get navInsights => 'प्रगति';

  @override
  String get navYou => 'तपाईं';

  @override
  String get greetingMorning => 'शुभ प्रभात';

  @override
  String get greetingAfternoon => 'शुभ दिउँसो';

  @override
  String get greetingEvening => 'शुभ साँझ';

  @override
  String todayProgress(int done, int total) {
    return 'आज $total मध्ये $done पूरा';
  }

  @override
  String get todayProgressLabel => 'आजको प्रगति';

  @override
  String get quickAdd => 'छिटो थप्नुहोस्';

  @override
  String get yourHabits => 'तपाईंका बानीहरू';

  @override
  String get emptyHabits => 'सानोबाट सुरु गर्नुहोस्: पहिलो बानी थप्न माथिको कुनै टाइल थिच्नुहोस्।';

  @override
  String get addAHabit => 'बानी थप्नुहोस्';

  @override
  String get discover => 'खोज्नुहोस्';

  @override
  String discoverNew(int count) {
    return 'खोज्नुहोस् ($count नयाँ)';
  }

  @override
  String markDone(String name) {
    return '$name पूरा भयो भनी चिन्ह लगाउनुहोस्';
  }

  @override
  String markNotDone(String name) {
    return '$name पूरा भएन भनी चिन्ह लगाउनुहोस्';
  }

  @override
  String get qaMedicine => 'औषधि';

  @override
  String get qaWater => 'पानी';

  @override
  String get qaMeditation => 'ध्यान';

  @override
  String get qaReading => 'पढाइ';

  @override
  String get qaExercise => 'व्यायाम';

  @override
  String get qaCustom => 'आफ्नै बानी';

  @override
  String get qaOthers => 'अन्य';

  @override
  String get addSheetTitle => 'थप्नुहोस्';

  @override
  String get addBrowseContent => 'निःशुल्क किताब, ध्वनि र व्यायाम हेर्नुहोस्';

  @override
  String get planTitle => 'योजना';

  @override
  String get reminderHealth => 'रिमाइन्डरको अवस्था';

  @override
  String get notifications => 'सूचनाहरू';

  @override
  String get notificationsAllowed => 'अनुमति छ';

  @override
  String get notificationsOff => 'बन्द छ — रिमाइन्डर देखिन सक्दैनन्';

  @override
  String get onTimeDelivery => 'समयमै सूचना';

  @override
  String get onTimeOk => 'रिमाइन्डर ठ्याक्कै मिनेटमा तय गरिएका छन्';

  @override
  String get onTimeLate => 'रिमाइन्डर केही मिनेट ढिलो आउन सक्छन्';

  @override
  String get allow => 'अनुमति दिनुहोस्';

  @override
  String get sendTestReminder => 'परीक्षण रिमाइन्डर पठाउनुहोस्';

  @override
  String get testReminderSent => 'करिब १० सेकेन्डमा परीक्षण रिमाइन्डर आउनेछ।';

  @override
  String get reminderAidDisclaimer => 'DailyMantra सम्झाउने सहायक मात्र हो। ब्याट्री बचत मोडमा फोनले सूचना ढिलो गर्न सक्छ, त्यसैले औषधिका लागि यसमा मात्र भर नपर्नुहोस्।';

  @override
  String get noUpcoming => 'आउँदै गरेका रिमाइन्डर छैनन्।';

  @override
  String get noUpcomingHint => 'यहाँ योजना हेर्न रिमाइन्डर समयसहित बानी थप्नुहोस्।';

  @override
  String get upNext => 'अब आउने';

  @override
  String get dayToday => 'आज';

  @override
  String get dayTomorrow => 'भोलि';

  @override
  String get reminderDaily => 'दैनिक';

  @override
  String get reminderOnce => 'एक पटक';

  @override
  String couldNotLoad(String error) {
    return 'लोड गर्न सकिएन। $error';
  }

  @override
  String get insightsTitle => 'प्रगति';

  @override
  String get last7Days => 'पछिल्ला ७ दिन';

  @override
  String get basedOnLogged => 'तपाईंले DailyMantra मा राखेको विवरणअनुसार।';

  @override
  String get nothingLogged => 'यस हप्ता अहिलेसम्म केही राखिएको छैन। बानी पूरा गर्नुहोस् वा पानी, ध्यान वा व्यायाम राख्नुहोस्, अनि तपाईंको हप्ता यहाँ देखिनेछ।';

  @override
  String get historyNote => 'इतिहास यही संस्करणदेखि राखिन्छ; अघिल्लो एपले पुराना दिनहरू राखेको थिएन।';

  @override
  String get metricCompleted => 'पूरा भएका बानी';

  @override
  String get metricWater => 'पानी';

  @override
  String get metricMeditation => 'ध्यान';

  @override
  String get metricExercise => 'व्यायाम';

  @override
  String get metricSteps => 'पाइला';

  @override
  String get unitGlasses => 'गिलास';

  @override
  String get unitMin => 'मिनेट';

  @override
  String get unitSteps => 'पाइला';

  @override
  String loggedOnDays(int active, int total) {
    return '$total मध्ये $active दिन राखियो';
  }

  @override
  String get youTitle => 'तपाईं';

  @override
  String get appearance => 'रूप';

  @override
  String get themeSystem => 'प्रणाली';

  @override
  String get themeLight => 'उज्यालो';

  @override
  String get themeDark => 'अँध्यारो';

  @override
  String get language => 'भाषा';

  @override
  String get languageSystem => 'फोनको सेटिङ';

  @override
  String get remindersSection => 'रिमाइन्डर';

  @override
  String get exactPermissionTitle => 'अलार्म र रिमाइन्डर अनुमति';

  @override
  String get exactOff => 'बन्द — रिमाइन्डर केही मिनेट ढिलो आउन सक्छन्';

  @override
  String get exactOn => 'खुला';

  @override
  String get freeContent => 'निःशुल्क सामग्री';

  @override
  String get contentNotLoaded => 'अझै लोड भएको छैन';

  @override
  String contentStatus(int count, String when) {
    return '$count वटा · $when अद्यावधिक';
  }

  @override
  String contentFailed(int count) {
    return 'पछिल्लो पटक अद्यावधिक असफल · $count वटा सुरक्षित · पछि फेरि प्रयास हुन्छ';
  }

  @override
  String get checkNewContent => 'अहिले नयाँ सामग्री जाँच्नुहोस्';

  @override
  String get contentUnreachable => 'सामग्री स्रोतमा पुग्न सकिएन। सुरक्षित गरिएका सामग्री भने चल्छन्।';

  @override
  String newItemsAdded(int count) {
    return '$count नयाँ सामग्री थपियो';
  }

  @override
  String get upToDate => 'सबै अद्यावधिक छ';

  @override
  String get sourcesLicences => 'स्रोत र इजाजतपत्र';

  @override
  String get sourcesIntro => 'DailyMantra ले विज्ञापनसहितको एपमा पनि पुनः प्रयोग गर्न मिल्ने निःशुल्क सामग्री मात्र प्रयोग गर्छ: सार्वजनिक (public domain), CC0, CC BY र CC BY-SA। हरेक सामग्रीमा लेखक र इजाजतपत्र देखाइन्छ।';

  @override
  String get privacy => 'गोपनीयता';

  @override
  String get privacyTitle => 'तपाईंको डेटा यही फोनमा रहन्छ';

  @override
  String get privacyBody => 'बानी, औषधिको तालिका र इतिहास तपाईंको फोनमा मात्र राखिन्छ। ब्याकअप र सिंक पछि आउनेछ, र त्यो सधैँ तपाईंको इच्छामा हुनेछ।';

  @override
  String get justNow => 'भर्खरै';

  @override
  String minutesAgo(int n) {
    return '$n मिनेटअघि';
  }

  @override
  String hoursAgo(int n) {
    return '$n घण्टाअघि';
  }

  @override
  String daysAgo(int n) {
    return '$n दिनअघि';
  }

  @override
  String get never => 'कहिल्यै होइन';

  @override
  String get obWelcomeBody => 'दिनको योजना बनाउनुहोस्; पानी, औषधि, हिँडडुल, पढाइ र शान्तिलाई एक-एक सानो कदममा निरन्तर राख्नुहोस्।';

  @override
  String get obChooseLanguage => 'भाषा छान्नुहोस्';

  @override
  String get obContinue => 'अगाडि बढ्नुहोस्';

  @override
  String get obSkip => 'छोड्नुहोस्';

  @override
  String get obBack => 'पछाडि';

  @override
  String get obGoalsTitle => 'तपाईंलाई केमा सहयोग चाहिन्छ?';

  @override
  String get obGoalsBody => 'जति पनि छान्नुहोस्। पछि परिवर्तन गर्न सकिन्छ।';

  @override
  String get goalHealth => 'स्वास्थ्य';

  @override
  String get goalFocus => 'ध्यान केन्द्रित';

  @override
  String get goalFitness => 'तन्दुरुस्ती';

  @override
  String get goalCalm => 'शान्ति';

  @override
  String get goalLearning => 'सिकाइ';

  @override
  String get goalRoutines => 'दिनचर्या';

  @override
  String get obStartersTitle => 'एकदेखि तीनवटा बानीबाट सुरु गर्नुहोस्';

  @override
  String get obStartersBody => 'सानो नै राम्रो। समय बदल्न समयमा थिच्नुहोस्।';

  @override
  String get starterWater => 'पानी पिउने';

  @override
  String get starterMedicine => 'औषधि खाने';

  @override
  String get starterMeditate => '१० मिनेट ध्यान';

  @override
  String get starterRead => '२० मिनेट पढ्ने';

  @override
  String get starterMove => 'हिँडडुल / व्यायाम';

  @override
  String get starterJournal => 'साँझको समीक्षा';

  @override
  String get obMaxThree => 'सुरुमा बढीमा तीनवटा छान्नुहोस् — पछि जतिबेला पनि थप्न सकिन्छ।';

  @override
  String get obPrivacyTitle => 'गोप्य र रिमाइन्डरका लागि तयार';

  @override
  String get obPrivacyBody => 'सबै कुरा तपाईंको फोनमै रहन्छ। खाता चाहिँदैन।';

  @override
  String get obRemindersNote => 'अब, तपाईंले छानेको समयमा सम्झाउन फोनले सूचनाको अनुमति माग्न सक्छ।';

  @override
  String get obStart => 'मेरो दिन सुरु गर्नुहोस्';

  @override
  String get obMedicineNote => 'रिमाइन्डर मात्र — DailyMantra ले औषधिको मात्राबारे सल्लाह दिँदैन।';

  @override
  String get medTitle => 'औषधि';

  @override
  String get medSave => 'सेभ';

  @override
  String get medSaveSchedule => 'सेभ र तालिका बनाउनुहोस्';

  @override
  String get medName => 'औषधिको नाम';

  @override
  String get medDose => 'मात्रा (जस्तै ५०० मि.ग्रा., २ चक्की)';

  @override
  String get medNotes => 'टिप्पणी (खाना अघि/पछि, आदि)';

  @override
  String get medEnable => 'रिमाइन्डर सक्रिय गर्नुहोस्';

  @override
  String get medStart => 'सुरु मिति';

  @override
  String get medEnd => 'अन्त्य मिति';

  @override
  String get medPick => 'छान्नुहोस्';

  @override
  String get medNotSet => 'सेट गरिएको छैन';

  @override
  String get medCourseHint => 'सुरु मितिदेखि अन्त्य मितिसम्म हरेक दिन प्रत्येक मात्राको समयमा रिमाइन्डर आउँछ।';

  @override
  String get medDoseTimes => 'मात्राको समय';

  @override
  String get medAddTime => 'मात्राको समय थप्नुहोस्';

  @override
  String get medNoTimes => 'अहिलेसम्म कुनै समय छैन।';

  @override
  String get medToday => 'आजका मात्राहरू';

  @override
  String get medTaken => 'खाएँ';

  @override
  String get medSkip => 'छोड्नुहोस्';

  @override
  String get medSkipped => 'छोडियो';

  @override
  String get medPending => 'बाँकी';

  @override
  String get medUndo => 'पूर्ववत्';

  @override
  String get medNoDosesToday => 'आज कुनै मात्रा तालिकामा छैन।';

  @override
  String medAdherence(int taken, int due) {
    return 'पछिल्लो ७ दिन: $due मध्ये $taken मात्रा खाइयो';
  }

  @override
  String get medAdherenceNone => 'पछिल्लो ७ दिनमा कुनै मात्रा बाँकी थिएन।';

  @override
  String get medSaved => 'औषधि रिमाइन्डर सेभ भयो।';

  @override
  String get medSavedDisabled => 'सेभ भयो (रिमाइन्डर बन्द छ)।';

  @override
  String get medDefaultName => 'औषधि';

  @override
  String get medSaveFirst => 'मात्रा ट्र्याक गर्न पहिले सेभ गर्नुहोस्।';

  @override
  String get medNotificationHint => 'सुझाव: रिमाइन्डर सूचनामा “Taken” थिच्नुहोस्। एप बन्द भए पनि यो रेकर्ड हुन्छ।';

  @override
  String medDoseSemantics(String time, String status) {
    return '$time को मात्रा: $status';
  }

  @override
  String get exOfficeTitle => 'अफिसमा हिँड्ने/तन्किने ब्रेक';

  @override
  String get exWalk => 'हिँड्ने रिमाइन्डर';

  @override
  String get exStretch => 'तन्किने रिमाइन्डर';

  @override
  String exEvery(int minutes) {
    return 'हरेक $minutes मिनेट';
  }

  @override
  String get exOff => 'बन्द';

  @override
  String exOfficeHint(String start, String end) {
    return 'हरेक दिन $start देखि $end सम्म रिमाइन्डर आउँछ।';
  }

  @override
  String get exWalkEvery => 'हरेक कति मिनेटमा हिँड्ने';

  @override
  String get exStretchEvery => 'हरेक कति मिनेटमा तन्किने';

  @override
  String get heroAllDone => 'आजका सबै काम सकियो। राम्रो गर्नुभयो।';

  @override
  String get heroStart => 'सानोबाट सुरु गर्नुहोस्। एउटा बानी नै पर्याप्त छ।';

  @override
  String heroKeepGoing(int left) {
    return 'जारी राख्नुहोस् — आज $left बाँकी';
  }

  @override
  String streakDays(int days) {
    return '$days दिनको निरन्तरता';
  }

  @override
  String get tileWater => 'पानी';

  @override
  String tileWaterValue(int done, int target) {
    return '$target मध्ये $done गिलास';
  }

  @override
  String get tileAddGlass => 'एक गिलास थप्नुहोस्';

  @override
  String get tileMedicine => 'औषधि';

  @override
  String tileNextDose(String time) {
    return 'अर्को मात्रा $time';
  }

  @override
  String get tileDosesLogged => 'आजका मात्रा रेकर्ड भए';

  @override
  String get tileNoDoseToday => 'आज कुनै मात्रा छैन';

  @override
  String get tileMovement => 'शारीरिक गतिविधि';

  @override
  String tileMinutesValue(int done, int goal) {
    return '$goal मध्ये $done मिनेट';
  }

  @override
  String tileStepsValue(int steps) {
    return '$steps पाइला';
  }

  @override
  String get tileMind => 'मन';

  @override
  String tileMindValue(int done, int goal) {
    return '$goal मध्ये $done मिनेट शान्त';
  }

  @override
  String get tileMindStart => 'एक मिनेट शान्त हुनुहोस्';

  @override
  String get tileReading => 'पढाइ';

  @override
  String get tileReadingContinue => 'पढ्न जारी राख्नुहोस्';

  @override
  String get tileFindBook => 'निःशुल्क किताब खोज्नुहोस्';

  @override
  String get upNextToday => 'आज अब';

  @override
  String get nothingLeftToday => 'आज अरू रिमाइन्डर छैन। साँझको आनन्द लिनुहोस्।';

  @override
  String get seeAll => 'सबै हेर्नुहोस्';

  @override
  String get thoughtForToday => 'आजको विचार';

  @override
  String get menuEdit => 'सम्पादन';

  @override
  String get menuDelete => 'मेटाउनुहोस्';

  @override
  String get exactDialogTitle => 'समयमै रिमाइन्डर';

  @override
  String get exactDialogBody => 'औषधि र बानीका रिमाइन्डर ठ्याक्कै समयमा पठाउन DailyMantra लाई \"Alarms & reminders\" अनुमति चाहिन्छ। यो नभए रिमाइन्डर केही मिनेट ढिला आउन सक्छ।';

  @override
  String get notNow => 'अहिले होइन';

  @override
  String get emptyTodayTitle => 'साना बानी। राम्रा दिन।';

  @override
  String get emptyTodayBody => 'आफ्नो पहिलो बानी थप्नुहोस् — एक गिलास पानी वा छोटो हिँडाइ राम्रो सुरुवात हो।';

  @override
  String doneTodayCount(int done, int total) {
    return '$done/$total';
  }

  @override
  String streakShort(int days) {
    return '$days दिन';
  }

  @override
  String get addHintMedicine => 'समयमै मात्रा, रेकर्ड सहित';

  @override
  String get addHintWater => 'दिनभरि गिलास गन्नुहोस्';

  @override
  String get addHintMeditation => 'शान्त मिनेट, मधुर आवाज';

  @override
  String get addHintReading => 'निःशुल्क क्लासिक, दैनिक पाना';

  @override
  String get addHintExercise => 'व्यायाम, पाइला, अफिस ब्रेक';

  @override
  String get addHintCustom => 'दोहोर्‍याउन चाहेको जुनसुकै कुरा';

  @override
  String get copyLink => 'लिंक कपी गर्नुहोस्';

  @override
  String linkCopied(String url) {
    return '$url कपी भयो';
  }

  @override
  String get licNoteGutenberg => 'सार्वजनिक डोमेनका ई-पुस्तक (अमेरिका)। अन्य देशमा प्रतिलिपि अधिकार फरक हुन सक्छ।';

  @override
  String get licNoteCommons => 'खुला इजाजतका रेकर्डिङ (PD, CC0, CC BY, CC BY-SA); लेखकलाई श्रेय दिइएको।';

  @override
  String get licNoteWger => 'व्यायाम विवरण CC BY-SA; तस्बिरहरूको श्रेय लेखकलाई।';

  @override
  String get openSourceLicences => 'खुला स्रोत इजाजतपत्र';

  @override
  String get onThisDevice => 'यही फोनमा सुरक्षित';

  @override
  String get profileTagline => 'साना बानी। राम्रा दिन।';

  @override
  String get splashPreparing => 'तपाईंको दिन तयार गर्दै…';

  @override
  String get splashError => 'सुरु गर्दा केही समस्या भयो।';

  @override
  String get retry => 'फेरि प्रयास गर्नुहोस्';

  @override
  String get searchContent => 'शीर्षक, लेखक, विषय खोज्नुहोस्';

  @override
  String get clear => 'हटाउनुहोस्';

  @override
  String get savedFilter => 'सुरक्षित';

  @override
  String get tabBooks => 'किताब';

  @override
  String get tabAudiobooks => 'अडियो किताब';

  @override
  String get tabSounds => 'आवाज';

  @override
  String get tabWorkouts => 'व्यायाम';

  @override
  String get tabVideos => 'भिडियो';

  @override
  String get newBadge => 'नयाँ';

  @override
  String nothingMatches(String query) {
    return '\"$query\" सँग मिल्ने केही भेटिएन।';
  }

  @override
  String get nothingYet => 'अहिले केही छैन। इन्टरनेट जोडेर तल तान्नुहोस्, निःशुल्क सामग्री आउँछ।';

  @override
  String get nothingSaved => 'अहिलेसम्म केही सुरक्षित छैन। कुनै सामग्री खोलेर डाउनलोड थिच्नुहोस्।';

  @override
  String get readNow => 'अहिले पढ्नुहोस्';

  @override
  String get listen => 'सुन्नुहोस्';

  @override
  String get playLoops => 'बजाउनुहोस् (दोहोरिने)';

  @override
  String get play => 'बजाउनुहोस्';

  @override
  String get pause => 'रोक्नुहोस्';

  @override
  String get loop => 'दोहोर्‍याउनुहोस्';

  @override
  String get watchVideo => 'भिडियो हेर्नुहोस्';

  @override
  String watchVideoSize(String size) {
    return 'भिडियो हेर्नुहोस् ($size)';
  }

  @override
  String get couldNotPlay => 'बजाउन सकिएन। इन्टरनेट जाँचेर फेरि प्रयास गर्नुहोस्।';

  @override
  String get videoError => 'यो भिडियो यो फोनमा चल्न सकेन। अर्को प्रयास गर्नुहोस् वा इन्टरनेट जाँच्नुहोस्।';

  @override
  String get creditsLicence => 'श्रेय र इजाजत';

  @override
  String licenceLabel(String licence) {
    return 'इजाजत: $licence';
  }

  @override
  String get copySourceLink => 'स्रोत लिंक कपी गर्नुहोस्';

  @override
  String get sourceCopied => 'स्रोत लिंक कपी भयो';

  @override
  String get downloadOffline => 'अफलाइनका लागि डाउनलोड';

  @override
  String downloadOfflineSize(String size) {
    return 'अफलाइनका लागि डाउनलोड ($size)';
  }

  @override
  String get downloaded => 'यो फोनमा सुरक्षित';

  @override
  String get removeDownload => 'डाउनलोड हटाउनुहोस्';

  @override
  String get downloadFailed => 'डाउनलोड असफल भयो। इन्टरनेट जाँचेर फेरि प्रयास गर्नुहोस्।';

  @override
  String get downloadAll => 'सबै अध्याय डाउनलोड गर्नुहोस्';

  @override
  String get chapters => 'अध्यायहरू';

  @override
  String chapterCount(int count) {
    return '$count अध्याय';
  }

  @override
  String get previousChapter => 'अघिल्लो अध्याय';

  @override
  String get nextChapter => 'अर्को अध्याय';

  @override
  String get back30 => '३० सेकेन्ड पछाडि';

  @override
  String get forward30 => '३० सेकेन्ड अगाडि';

  @override
  String get cancel => 'रद्द गर्नुहोस्';

  @override
  String get remove => 'हटाउनुहोस्';

  @override
  String get storageTitle => 'अफलाइनका लागि सुरक्षित';

  @override
  String storageUsed(String size, int count) {
    return 'यो फोनमा $size प्रयोग · $count फाइल';
  }

  @override
  String get clearDownloads => 'सबै डाउनलोड हटाउनुहोस्';

  @override
  String get clearDownloadsConfirm => 'यो फोनबाट सबै सुरक्षित किताब, अडियो र भिडियो हटाउने? पछि फेरि डाउनलोड गर्न सकिन्छ।';

  @override
  String get autoUpdateNote => 'हरेक पटक एप खोल्दा नयाँ सामग्री जाँचिन्छ, र दिनमा करिब दुई पटक पृष्ठभूमिमा पनि।';

  @override
  String get licNoteLibrivox => 'स्वयंसेवकले पढेका सार्वजनिक डोमेनका अडियो किताब।';

  @override
  String get licNoteCommonsVideo => 'खुला इजाजतका व्यायाम, योग र ध्यान भिडियो (PD, CC0, CC BY, CC BY-SA); लेखकलाई श्रेय।';
}
