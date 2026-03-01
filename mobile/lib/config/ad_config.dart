import 'dart:io';

/// Configuration for Google AdMob ads.
///
/// All IDs here are Google's official **test** ad unit IDs.
/// Replace them with real ad unit IDs only via environment configuration
/// for production builds.
class AdConfig {
  AdConfig._();

  // ---------------------------------------------------------------------------
  // Interstitial frequency
  // ---------------------------------------------------------------------------

  /// Show an interstitial ad every Nth message send.
  static const int interstitialFrequency = 3;

  // ---------------------------------------------------------------------------
  // Banner ad unit IDs (test)
  // ---------------------------------------------------------------------------

  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/6300978111';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/2934735716';
    }
    // Fallback — should not be reached on supported platforms.
    return '';
  }

  // ---------------------------------------------------------------------------
  // Interstitial ad unit IDs (test)
  // ---------------------------------------------------------------------------

  static String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/1033173712';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/4411468910';
    }
    return '';
  }
}
