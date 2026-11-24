/// Google AdMob Configuration & Ad Unit Identifiers.
///
/// NOTE FOR OWNER:
/// When you are ready to publish on Google Play:
/// 1. Set [useTestAds] to `false`.
/// 2. Paste your real AdMob Ad Unit IDs into [realRewardedAdUnitIdAndroid]
///    and [realInterstitialAdUnitIdAndroid].
/// 3. In `android/app/src/main/AndroidManifest.xml`, replace the test Application ID
///    with your real AdMob Application ID: [realAppIdAndroid].
class AdIds {
  AdIds._();

  /// Set to `false` when building for Google Play Store release.
  /// Keep `true` during development and local device testing to avoid AdMob policy violations.
  static const bool useTestAds = true;

  // ===========================================================================
  // GOOGLE OFFICIAL TEST AD UNIT IDENTIFIERS (SAFE FOR DEVELOPMENT)
  // ===========================================================================
  /// Official Google Sample App ID
  static const String testAppIdAndroid =
      'ca-app-pub-3940256099942544~3347511713';

  /// Official Google Sample Banner Ad Unit ID
  static const String testBannerAdUnitIdAndroid =
      'ca-app-pub-3940256099942544/6300978111';

  /// Official Google Sample Rewarded Video Ad Unit ID
  static const String testRewardedAdUnitIdAndroid =
      'ca-app-pub-3940256099942544/5224354917';

  /// Official Google Sample Interstitial Ad Unit ID
  static const String testInterstitialAdUnitIdAndroid =
      'ca-app-pub-3940256099942544/1033173712';

  // ===========================================================================
  // REAL PRODUCTION AD UNIT IDENTIFIERS (REPLACE BEFORE STORE PUBLISH)
  // ===========================================================================
  /// Replace with your actual AdMob Application ID from AdMob Console
  static const String realAppIdAndroid = 'YOUR_REAL_ADMOB_APP_ID_HERE';

  /// Replace with your actual Banner Ad Unit ID from AdMob Console
  static const String realBannerAdUnitIdAndroid =
      'YOUR_REAL_BANNER_AD_UNIT_ID_HERE';

  /// Replace with your actual Rewarded Video Ad Unit ID from AdMob Console
  static const String realRewardedAdUnitIdAndroid =
      'YOUR_REAL_REWARDED_AD_UNIT_ID_HERE';

  /// Replace with your actual Interstitial Ad Unit ID from AdMob Console
  static const String realInterstitialAdUnitIdAndroid =
      'YOUR_REAL_INTERSTITIAL_AD_UNIT_ID_HERE';

  // ===========================================================================
  // ACTIVE GETTERS (AUTOMATICALLY ROUTE TEST VS REAL)
  // ===========================================================================
  /// Active Banner Ad Unit ID
  static String get bannerAdUnitId {
    if (useTestAds) {
      return testBannerAdUnitIdAndroid;
    }
    return realBannerAdUnitIdAndroid;
  }

  /// Active Rewarded Video Ad Unit ID
  static String get rewardedAdUnitId {
    if (useTestAds) {
      return testRewardedAdUnitIdAndroid;
    }
    return realRewardedAdUnitIdAndroid;
  }

  /// Active Interstitial Ad Unit ID
  static String get interstitialAdUnitId {
    if (useTestAds) {
      return testInterstitialAdUnitIdAndroid;
    }
    return realInterstitialAdUnitIdAndroid;
  }

  /// Active Application ID
  static String get appId {
    if (useTestAds) {
      return testAppIdAndroid;
    }
    return realAppIdAndroid;
  }
}
