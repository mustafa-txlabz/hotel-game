import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_ids.dart';

/// AdMob advertising service managing rewarded and interstitial ad flows.
class AdsService {
  bool _isInitialized = false;
  RewardedAd? _rewardedAd;
  InterstitialAd? _interstitialAd;

  bool get isInitialized => _isInitialized;
  bool get isRewardedLoaded => _rewardedAd != null;
  bool get isInterstitialLoaded => _interstitialAd != null;

  /// Initializes MobileAds SDK.
  Future<void> init() async {
    await MobileAds.instance.initialize();
    _isInitialized = true;
    _loadRewardedAd();
    _loadInterstitialAd();
  }

  void _loadRewardedAd() {
    RewardedAd.load(
      adUnitId: AdIds.rewardedUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => _rewardedAd = ad,
        onAdFailedToLoad: (error) {
          _rewardedAd = null;
        },
      ),
    );
  }

  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: AdIds.interstitialUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitialAd = ad,
        onAdFailedToLoad: (error) {
          _interstitialAd = null;
        },
      ),
    );
  }

  Future<bool> showRewarded() async {
    // Stub for M0/M1/M3, full implementation wired in M5
    return false;
  }

  Future<void> maybeShowInterstitial(String reason) async {
    // Implementation in M5
  }
}
