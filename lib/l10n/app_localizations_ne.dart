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
}
