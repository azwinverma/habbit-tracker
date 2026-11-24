// lib/widgets/ad_banner.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ad_service.dart';

/// Adaptive anchored banner that only inserts AdWidget after onAdLoaded.
/// Safe for release: no AdWidget before loaded; retries on failure.
class AdBanner extends StatefulWidget {
  final String placement; // optional tag for analytics
  final EdgeInsetsGeometry padding;

  const AdBanner({
    super.key,
    this.placement = 'default',
    this.padding = EdgeInsets.zero,
  });

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> with WidgetsBindingObserver {
  BannerAd? _banner;
  AdSize? _size;

  bool _isLoaded = false;
  bool _started = false; // prevent duplicate loads
  int _retries = 0;
  AppLifecycleState _lifecycle = AppLifecycleState.resumed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _load();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycle = state;
    if (!mounted) return;

    // If we returned to foreground and don't have a loaded banner, try again.
    if (state == AppLifecycleState.resumed && !_isLoaded && _banner == null) {
      _retries = 0;
      _load();
    }
  }

  Future<void> _load() async {
    // Resolve adaptive size first (needs a valid context)
    final widthPx = MediaQuery.sizeOf(context).width.truncate();
    final anchorSize =
        await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(widthPx);

    if (!mounted) return;

    if (anchorSize == null) {
      // No size available (rare on very small widths); show nothing.
      setState(() {
        _size = null;
        _isLoaded = false;
      });
      return;
    }

    setState(() {
      _size = anchorSize;
      _isLoaded = false;
    });

    // Dispose any previous instance before creating a new one
    _disposeBanner();

    final banner = BannerAd(
      size: anchorSize,
      adUnitId: AdService.bannerUnitId, // your test/prod id logic in AdService
      request: AdService.request(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) return;
          setState(() {
            _banner = ad as BannerAd; // keep the loaded instance
            _isLoaded = true;         // <-- gate for rendering AdWidget
            _retries = 0;
          });
        },
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
          if (!mounted) return;
          _banner = null;
          _isLoaded = false;

          // Retry with capped exponential backoff, only when foregrounded
          _retries++;
          final delay = Duration(seconds: min(2 << _retries, 30));
          if (_lifecycle == AppLifecycleState.resumed) {
            Future.delayed(delay, () {
              if (mounted && !_isLoaded && _banner == null) {
                _load();
              }
            });
          }
        },
      ),
    );

    // Start async loading. Do NOT await this to assume it's loaded.
    // AdWidget must not be shown until onAdLoaded toggles _isLoaded.
    try {
      banner.load();
    } catch (_) {
      banner.dispose();
    }
  }

  void _disposeBanner() {
    try {
      _banner?.dispose();
    } catch (_) {}
    _banner = null;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposeBanner();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Hide when backgrounded or not loaded yet (prevents AdWidget crash).
    if (_lifecycle != AppLifecycleState.resumed || !_isLoaded || _banner == null || _size == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: widget.padding,
      child: SizedBox(
        width: _size!.width.toDouble(),
        height: _size!.height.toDouble(),
        child: AdWidget(ad: _banner!),
      ),
    );
  }
}



// // lib/widgets/ad_banner.dart
// import 'package:flutter/material.dart';
// import 'package:google_mobile_ads/google_mobile_ads.dart';
// import '../services/ad_service.dart';

// /// Adaptive anchored banner that auto-sizes to screen width.
// /// Place it in `bottomNavigationBar` or inside a SliverToBoxAdapter, etc.
// class AdBanner extends StatefulWidget {
//   final String placement; // optional tag for analytics
//   final EdgeInsetsGeometry padding;
//   const AdBanner({super.key, this.placement = 'default', this.padding = EdgeInsets.zero});

//   @override
//   State<AdBanner> createState() => _AdBannerState();
// }

// class _AdBannerState extends State<AdBanner> {
//   BannerAd? _banner;
//   AdSize? _size;
//   bool _loading = true;

//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     _load();
//   }

//   Future<void> _load() async {
//     if (_banner != null) return;
//     final anchorSize = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
//       MediaQuery.sizeOf(context).width.truncate(),
//     );
//     if (!mounted) return;
//     setState(() => _size = anchorSize);

//     if (anchorSize == null) {
//       setState(() => _loading = false);
//       return;
//     }

//     final banner = BannerAd(
//       size: anchorSize,
//       adUnitId: AdService.bannerUnitId,
//       request: AdService.request(),
//       listener: BannerAdListener(
//         onAdLoaded: (ad) => setState(() => _loading = false),
//         onAdFailedToLoad: (ad, err) {
//           ad.dispose();
//           if (mounted) setState(() => _loading = false);
//         },
//       ),
//     );
//     await banner.load();
//     if (!mounted) {
//       banner.dispose();
//       return;
//     }
//     setState(() => _banner = banner);
//   }

//   @override
//   void dispose() {
//     _banner?.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_loading) {
//       return const SizedBox(height: 0);
//     }
//     if (_banner == null || _size == null) {
//       return const SizedBox(height: 0);
//     }
//     return Padding(
//       padding: widget.padding,
//       child: SizedBox(
//         width: _size!.width.toDouble(),
//         height: _size!.height.toDouble(),
//         child: AdWidget(ad: _banner!),
//       ),
//     );
//   }
// }
