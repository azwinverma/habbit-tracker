// lib/services/ad_service.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static bool _inited = false;

  static Future<void> init() async {
    if (_inited) return;
    await MobileAds.instance.initialize();

    // Optional: mark test devices during development
    // MobileAds.instance.updateRequestConfiguration(
    //   RequestConfiguration(testDeviceIds: const ['YOUR_TEST_DEVICE_ID']),
    // );

    _inited = true;
  }

  /// Use test IDs for debug, your real unit IDs for release.
  /// Your provided production IDs:
  /// App ID (Manifest/Info.plist only):  ca-app-pub-2249746804787716~2324545509
  /// Banner unit:                        ca-app-pub-2249746804787716/3463858047
  /// Interstitial unit:                  ca-app-pub-2249746804787716/6291710676

  static String get bannerUnitId => kDebugMode
      ? (Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/6300978111' // test
          : 'ca-app-pub-3940256099942544/2934735716') // test
      : (Platform.isAndroid
          ? 'ca-app-pub-2249746804787716/3463858047' // YOUR PROD BANNER
          : 'ca-app-pub-2249746804787716/3463858047'); // if iOS same, replace with iOS unit

  static String get interstitialUnitId => kDebugMode
      ? (Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/1033173712' // test
          : 'ca-app-pub-3940256099942544/4411468910') // test
      : (Platform.isAndroid
          ? 'ca-app-pub-2249746804787716/6291710676' // YOUR PROD INTERSTITIAL
          : 'ca-app-pub-2249746804787716/6291710676'); // if iOS same, replace with iOS unit

  // If you plan to show App Open ads, you need a *unit id* like .../xxxxxxx
  // NOT the App ID. Commented out to avoid misuse:
  // static String get appOpenUnitId => kDebugMode
  //     ? (Platform.isAndroid
  //         ? 'ca-app-pub-3940256099942544/9257395921' // test app open
  //         : 'ca-app-pub-3940256099942544/5662855259') // test app open (iOS)
  //     : (Platform.isAndroid
  //         ? 'ca-app-pub-XXXXXXXXXXXXXXX/XXXXXXXXXX' // YOUR PROD APP OPEN UNIT
  //         : 'ca-app-pub-XXXXXXXXXXXXXXX/XXXXXXXXXX');

  static AdRequest request() => const AdRequest(
        nonPersonalizedAds: true, // keep or adjust as needed
      );
}

class InterstitialHelper {
  InterstitialAd? _ad;
  DateTime _lastShown = DateTime.fromMillisecondsSinceEpoch(0);
  int _shownCount = 0;

  static const int _minSecondsBetween = 45;
  static const int _maxPerSession = 6;

  Future<void> load() async {
    if (_ad != null) return;
    await InterstitialAd.load(
      adUnitId: AdService.interstitialUnitId,
      request: AdService.request(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _ad = ad..setImmersiveMode(true),
        onAdFailedToLoad: (err) {
          _ad = null;
          if (kDebugMode) debugPrint('Interstitial failed to load: $err');
        },
      ),
    );
  }

  Future<void> showIfAvailable() async {
    final now = DateTime.now();
    if (_ad == null) await load();
    if (_ad == null) return;
    if (_shownCount >= _maxPerSession) return;
    if (now.difference(_lastShown).inSeconds < _minSecondsBetween) return;

    _ad!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _ad = null;
        _shownCount++;
        _lastShown = DateTime.now();
        load();
      },
      onAdFailedToShowFullScreenContent: (ad, err) {
        ad.dispose();
        _ad = null;
        load();
      },
    );

    await _ad!.show();
  }

  void dispose() {
    _ad?.dispose();
    _ad = null;
  }
}







// // lib/services/ad_service.dart
// import 'dart:io';
// import 'package:flutter/foundation.dart';
// import 'package:google_mobile_ads/google_mobile_ads.dart';

// /// Centralized Ads bootstrap + helpers.
// /// - Call `AdService.init()` once (e.g., in main() or SplashScreen)
// /// - Place banners via AdBanner (see widget below)
// /// - Show interstitials via InterstitialHelper().showIfAvailable()
// class AdService {
//   static bool _inited = false;

//   static Future<void> init() async {
//     if (_inited) return;
//     await MobileAds.instance.initialize();
//     // (Optional) You can configure test device ids here:
//     // RequestConfiguration configuration = RequestConfiguration(
//     //   testDeviceIds: ['TEST_DEVICE_ID'],
//     // );
//     // MobileAds.instance.updateRequestConfiguration(configuration);
//     _inited = true;
//   }

//   /// Change these to your real AdMob Ad Unit IDs when you go live.
//   /// Use test IDs during development:
//   /// https://developers.google.com/admob/android/test-ads
//   static String get appOpenUnitId => kDebugMode
//       ? (Platform.isAndroid
//           ? 'ca-app-pub-3940256099942544/3419835294'
//           : 'ca-app-pub-3940256099942544/5662855259')
//       : (Platform.isAndroid
//           ? 'ca-app-pub-2249746804787716~2324545509'
//           : 'ca-app-pub-2249746804787716~2324545509');

//   static String get bannerUnitId => kDebugMode
//       ? (Platform.isAndroid
//           ? 'ca-app-pub-3940256099942544/6300978111'
//           : 'ca-app-pub-3940256099942544/2934735716')
//       : (Platform.isAndroid
//           ? 'ca-app-pub-2249746804787716/3463858047'
//           : 'ca-app-pub-2249746804787716/3463858047');

//   static String get interstitialUnitId => kDebugMode
//       ? (Platform.isAndroid
//           ? 'ca-app-pub-3940256099942544/1033173712'
//           : 'ca-app-pub-3940256099942544/4411468910')
//       : (Platform.isAndroid
//           ? 'ca-app-pub-2249746804787716/6291710676'
//           : 'ca-app-pub-2249746804787716/6291710676');

//   /// Common ad request; add keywords/content URL if you want.
//   static AdRequest request() => const AdRequest(
//         // keywords: ['habit', 'meditation', 'fitness', 'reading'],
//         // contentUrl: 'https://example.com',
//         nonPersonalizedAds: true, // enable if you prefer
//       );
// }

// /// Small helper class that manages one interstitial at a time + throttling.
// /// You can keep a single instance per screen or a global singleton.
// class InterstitialHelper {
//   InterstitialAd? _ad;
//   DateTime _lastShown = DateTime.fromMillisecondsSinceEpoch(0);
//   int _shownCount = 0;

//   /// Frequency control
//   static const int _minSecondsBetween = 45; // don’t spam
//   static const int _maxPerSession = 6;

//   Future<void> load() async {
//     if (_ad != null) return;
//     await InterstitialAd.load(
//       adUnitId: AdService.interstitialUnitId,
//       request: AdService.request(),
//       adLoadCallback: InterstitialAdLoadCallback(
//         onAdLoaded: (ad) => _ad = ad..setImmersiveMode(true),
//         onAdFailedToLoad: (err) {
//           _ad = null;
//           if (kDebugMode) {
//             debugPrint('Interstitial failed to load: $err');
//           }
//         },
//       ),
//     );
//   }

//   Future<void> showIfAvailable() async {
//     final now = DateTime.now();
//     if (_ad == null) {
//       await load();
//     }
//     if (_ad == null) return; // still not loaded
//     if (_shownCount >= _maxPerSession) return;
//     if (now.difference(_lastShown).inSeconds < _minSecondsBetween) return;

//     _ad!.fullScreenContentCallback = FullScreenContentCallback(
//       onAdDismissedFullScreenContent: (ad) {
//         ad.dispose();
//         _ad = null;
//         _shownCount++;
//         _lastShown = DateTime.now();
//         // Preload next
//         load();
//       },
//       onAdFailedToShowFullScreenContent: (ad, err) {
//         ad.dispose();
//         _ad = null;
//         // Preload next
//         load();
//       },
//     );
//     await _ad!.show();
//   }

//   void dispose() {
//     _ad?.dispose();
//     _ad = null;
//   }
// }








// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:google_mobile_ads/google_mobile_ads.dart';

// class AdService {
//   static Future<void> initialize() async {
//     WidgetsFlutterBinding.ensureInitialized();
//     await MobileAds.instance.initialize();
//   }

//   static String get bannerId => Platform.isIOS
//       ? 'ca-app-pub-3940256099942544/2934735716'
//       : 'ca-app-pub-3940256099942544/6300978111';

//   static String get interstitialId => Platform.isIOS
//       ? 'ca-app-pub-3940256099942544/4411468910'
//       : 'ca-app-pub-3940256099942544/1033173712';
// }

// class BannerAdWidget extends StatefulWidget {
//   const BannerAdWidget({super.key});
//   @override
//   State<BannerAdWidget> createState() => _BannerAdWidgetState();
// }

// class _BannerAdWidgetState extends State<BannerAdWidget> {
//   BannerAd? _ad;
//   bool _ready = false;
//   @override
//   void initState() {
//     super.initState();
//     _ad = BannerAd(
//       adUnitId: AdService.bannerId,
//       size: AdSize.banner,
//       request: const AdRequest(),
//       listener: BannerAdListener(onAdLoaded: (_) => setState(() => _ready = true), onAdFailedToLoad: (ad, error) {
//         ad.dispose();
//       }),
//     )..load();
//   }

//   @override
//   void dispose() {
//     _ad?.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (!_ready || _ad == null) return const SizedBox.shrink();
//     return SizedBox(width: _ad!.size.width.toDouble(), height: _ad!.size.height.toDouble(), child: AdWidget(ad: _ad!));
//   }
// }

// class InterstitialHelper {
//   InterstitialAd? _ad;
//   Future<void> load() async {
//     await InterstitialAd.load(
//       adUnitId: AdService.interstitialId,
//       request: const AdRequest(),
//       adLoadCallback: InterstitialAdLoadCallback(
//         onAdLoaded: (ad) => _ad = ad,
//         onAdFailedToLoad: (_) => _ad = null,
//       ),
//     );
//   }
//   Future<void> showIfAvailable() async {
//     if (_ad == null) return;
//     await _ad!.show();
//     _ad!.dispose();
//     _ad = null;
//   }
// }
