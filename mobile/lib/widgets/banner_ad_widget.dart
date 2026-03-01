import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/ad_config.dart';

/// A reusable banner ad widget.
///
/// Loads a banner ad and displays it once ready. While loading or on failure
/// the widget collapses to zero height so it does not affect layout.
///
/// On non-mobile platforms (e.g. web) the widget renders nothing because
/// `google_mobile_ads` only supports Android and iOS.
class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    // google_mobile_ads does not support web or desktop.
    if (kIsWeb) return;

    final adUnitId = AdConfig.bannerAdUnitId;
    if (adUnitId.isEmpty) return;

    try {
      _bannerAd = BannerAd(
        adUnitId: adUnitId,
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            if (mounted) {
              setState(() => _isLoaded = true);
            }
          },
          onAdFailedToLoad: (ad, error) {
            debugPrint('BannerAd failed to load: ${error.message}');
            ad.dispose();
            if (mounted) {
              setState(() {
                _bannerAd = null;
                _isLoaded = false;
              });
            }
          },
        ),
      );
      _bannerAd!.load();
    } catch (e) {
      debugPrint('BannerAd creation error: $e');
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
