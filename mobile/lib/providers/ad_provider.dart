import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/ad_config.dart';

/// Tracks message send count and manages interstitial ad lifecycle.
class AdState {
  const AdState({this.sendCount = 0});

  final int sendCount;

  /// Returns `true` when the send count is a non-zero multiple of the
  /// configured [AdConfig.interstitialFrequency].
  bool get shouldShowInterstitial =>
      sendCount > 0 && sendCount % AdConfig.interstitialFrequency == 0;

  AdState copyWith({int? sendCount}) {
    return AdState(sendCount: sendCount ?? this.sendCount);
  }
}

final adProvider = NotifierProvider<AdNotifier, AdState>(
  AdNotifier.new,
);

class AdNotifier extends Notifier<AdState> {
  InterstitialAd? _interstitialAd;

  @override
  AdState build() {
    ref.onDispose(() {
      _interstitialAd?.dispose();
    });
    return const AdState();
  }

  /// Increment the send counter. Call this after every successful message send.
  void incrementSendCount() {
    state = state.copyWith(sendCount: state.sendCount + 1);
  }

  /// Preload an interstitial ad so it is ready to show immediately.
  void preloadInterstitial() {
    // google_mobile_ads does not support web.
    if (kIsWeb) return;

    final adUnitId = AdConfig.interstitialAdUnitId;
    if (adUnitId.isEmpty) return;

    try {
      InterstitialAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _interstitialAd = ad;
            _interstitialAd!.fullScreenContentCallback =
                FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                ad.dispose();
                _interstitialAd = null;
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                debugPrint('Interstitial failed to show: ${error.message}');
                ad.dispose();
                _interstitialAd = null;
              },
            );
          },
          onAdFailedToLoad: (error) {
            debugPrint('Interstitial failed to load: ${error.message}');
            _interstitialAd = null;
          },
        ),
      );
    } catch (e) {
      debugPrint('Interstitial preload error: $e');
    }
  }

  /// Show the preloaded interstitial ad if one is available. Returns `true` if
  /// the ad was shown, `false` otherwise.
  bool showInterstitial() {
    if (_interstitialAd == null) return false;

    try {
      _interstitialAd!.show();
      // After showing, the callback will dispose it. Clear the reference so we
      // don't try to show it again.
      _interstitialAd = null;
      return true;
    } catch (e) {
      debugPrint('Interstitial show error: $e');
      _interstitialAd?.dispose();
      _interstitialAd = null;
      return false;
    }
  }
}
