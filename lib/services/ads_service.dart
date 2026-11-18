import 'dart:async';

/// AdMob advertising service managing rewarded and interstitial ad flows.
/// (Full AdMob ads integration scheduled for Milestone M9).
class AdsService {
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  bool get isRewardedLoaded => false;
  bool get isInterstitialLoaded => false;

  /// Initializes MobileAds SDK.
  Future<void> init() async {
    _isInitialized = true;
  }

  Future<bool> showRewarded() async {
    return false;
  }

  Future<void> maybeShowInterstitial(String reason) async {
  }
}
