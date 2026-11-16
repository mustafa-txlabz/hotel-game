/// Centralized AdMob configuration and Ad Unit IDs.
///
/// Toggle [useTestAds] to switch between Google's official test ad units
/// and live production ad units before publishing to Google Play.
class AdIds {
  /// Always true during development and testing.
  /// Set to false when deploying with your live AdMob account credentials.
  static const bool useTestAds = true;

  // Test Ad Unit IDs (Google official test IDs)
  static const String testAndroidAppId = 'ca-app-pub-3940256099942544~3347511713';
  static const String testRewarded = 'ca-app-pub-3940256099942544/5224354917';
  static const String testInterstitial = 'ca-app-pub-3940256099942544/1033173712';
  static const String testBanner = 'ca-app-pub-3940256099942544/6300978111';

  // Production Ad Unit IDs (Owner fills these in before Google Play release)
  static const String liveRewarded = 'REPLACE_ME_LIVE_REWARDED_ID';
  static const String liveInterstitial = 'REPLACE_ME_LIVE_INTERSTITIAL_ID';
  static const String liveBanner = 'REPLACE_ME_LIVE_BANNER_ID';

  static String get rewardedUnitId => useTestAds ? testRewarded : liveRewarded;
  static String get interstitialUnitId => useTestAds ? testInterstitial : liveInterstitial;
  static String get bannerUnitId => useTestAds ? testBanner : liveBanner;
}

