// lib/services/ad_service.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static bool _inited = false;
  static Future<void>? _initFuture;

  /// Global switch (false in tests / screenshots; later: remote config and
  /// premium). When false no ad is requested or shown.
  static bool enabled = true;

  /// Whether the user's consent state allows requesting ads (always true
  /// outside the EEA/UK/Switzerland; there it follows the consent form).
  static bool canRequestAds = true;

  /// Whether to show "Ad privacy choices" in You (required by Google's
  /// consent rules where the form applies).
  static bool privacyOptionsRequired = false;

  /// Consent (Google UMP) first, then the Mobile Ads SDK. Safe to call more
  /// than once; never throws (ads are optional).
  static Future<void> init() => _initFuture ??= _init();

  static Future<void> _init() async {
    if (_inited || !enabled) return;
    try {
      await _gatherConsent().timeout(const Duration(seconds: 12), onTimeout: () {});
      canRequestAds = await ConsentInformation.instance.canRequestAds();
    } catch (e) {
      debugPrint('[Ads] consent check failed: $e');
    }
    try {
      await MobileAds.instance.initialize();
      _inited = true;
    } catch (e) {
      debugPrint('[Ads] init failed: $e');
    }
  }

  /// Google UMP: updates consent info and shows the form only if required
  /// (EEA/UK/CH users who haven't chosen yet). Elsewhere it completes at once.
  static Future<void> _gatherConsent() {
    final done = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () async {
        await ConsentForm.loadAndShowConsentFormIfRequired((FormError? e) async {
          if (e != null) debugPrint('[Ads] consent form: ${e.message}');
          privacyOptionsRequired = await ConsentInformation.instance.getPrivacyOptionsRequirementStatus() ==
              PrivacyOptionsRequirementStatus.required;
          if (!done.isCompleted) done.complete();
        });
      },
      (FormError e) {
        debugPrint('[Ads] consent info: ${e.message}');
        if (!done.isCompleted) done.complete();
      },
    );
    return done.future;
  }

  /// Re-opens the consent choices (You → Ad privacy choices).
  static Future<void> showPrivacyOptions() async {
    final done = Completer<void>();
    await ConsentForm.showPrivacyOptionsForm((FormError? e) {
      if (!done.isCompleted) done.complete();
    });
    await done.future;
    canRequestAds = await ConsentInformation.instance.canRequestAds();
  }

  /// Ads may be requested now.
  static bool get ready => enabled && canRequestAds;

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

/// One shared interstitial for the whole app, so the caps below are real
/// (screens used to create their own helper, each with its own counters).
/// Shown only at natural breaks (after saving, after a finished session or
/// a watched video), never over content or reminders.
class InterstitialHelper {
  factory InterstitialHelper() => _shared;
  InterstitialHelper._();
  static final InterstitialHelper _shared = InterstitialHelper._();

  InterstitialAd? _ad;
  bool _loading = false;
  DateTime _lastShown = DateTime.fromMillisecondsSinceEpoch(0);
  int _shownCount = 0;

  static const int _minSecondsBetween = 45;
  static const int _maxPerSession = 6;

  Future<void> load() async {
    if (_ad != null || _loading || !AdService.ready) return;
    _loading = true;
    await AdService.init();
    await InterstitialAd.load(
      adUnitId: AdService.interstitialUnitId,
      request: AdService.request(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _loading = false;
          _ad = ad..setImmersiveMode(true);
        },
        onAdFailedToLoad: (err) {
          _loading = false;
          _ad = null;
          if (kDebugMode) debugPrint('Interstitial failed to load: $err');
        },
      ),
    );
  }

  Future<void> showIfAvailable() async {
    if (!AdService.ready) return;
    final now = DateTime.now();
    if (_ad == null) {
      unawaited(load()); // ready next time; never make the user wait for an ad
      return;
    }
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

  /// No-op: the shared ad lives for the whole session.
  void dispose() {}
}

