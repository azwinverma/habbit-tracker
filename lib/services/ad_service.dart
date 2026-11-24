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

