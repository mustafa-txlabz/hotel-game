import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad_ids.dart';

/// Service managing AdMob Rewarded and Interstitial ads.
///
/// Features:
/// - Pre-caches rewarded ads for instant presentation.
/// - Safe test mode & offline fallback (never blocks player).
/// - Clean callbacks for reward grant and ad dismissal.
class AdsService {
  static final AdsService instance = AdsService._internal();
  AdsService._internal();

  bool _isInitialized = false;
  RewardedAd? _rewardedAd;
  bool _isRewardedAdLoading = false;

  /// Whether ads SDK is initialized.
  bool get isInitialized => _isInitialized;

  /// Whether a rewarded ad is currently cached and ready to show.
  bool get isRewardedAdReady => _rewardedAd != null;

  /// Initializes Google Mobile Ads SDK and pre-loads the first rewarded ad.
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
      debugPrint('[AdsService] Google Mobile Ads initialized successfully.');
      loadRewardedAd();
    } catch (e) {
      debugPrint('[AdsService] Initialization error (test/offline mode): $e');
    }
  }

  /// Pre-loads a Rewarded Ad into memory.
  void loadRewardedAd() {
    if (_rewardedAd != null || _isRewardedAdLoading) return;

    _isRewardedAdLoading = true;
    final adUnitId = AdIds.rewardedAdUnitId;

    RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          debugPrint('[AdsService] Rewarded ad loaded successfully.');
          _rewardedAd = ad;
          _isRewardedAdLoading = false;
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('[AdsService] Rewarded ad failed to load: $error');
          _rewardedAd = null;
          _isRewardedAdLoading = false;
        },
      ),
    );
  }

  /// When true, simulates a successful rewarded ad watch (used ONLY in automated unit tests).
  bool testMockReward = false;

  /// Shows a cached Rewarded Ad.
  ///
  /// - [onUserEarnedReward]: Called strictly when the player completes watching the ad.
  /// - [onAdDismissed]: Called when the ad is closed.
  /// - [onAdFailed]: Called when no ad is available (offline, ad blocker, or failed to show).
  void showRewardedAd({
    required VoidCallback onUserEarnedReward,
    VoidCallback? onAdDismissed,
    VoidCallback? onAdFailed,
  }) {
    // 1. Test environment mock (only during automated tests)
    if (testMockReward) {
      onUserEarnedReward();
      onAdDismissed?.call();
      return;
    }

    // 2. Real / Test device execution
    if (_rewardedAd != null) {
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _rewardedAd = null;
          loadRewardedAd();
          onAdDismissed?.call();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          debugPrint('[AdsService] Failed to show ad: $error');
          ad.dispose();
          _rewardedAd = null;
          loadRewardedAd();
          // STRICT RULE: No reward on failed display!
          onAdFailed?.call();
          onAdDismissed?.call();
        },
      );

      _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          debugPrint(
            '[AdsService] User earned reward: ${reward.amount} ${reward.type}',
          );
          onUserEarnedReward();
        },
      );
    } else {
      // STRICT RULE: If ad is not ready (offline, ad blocker, no fill),
      // DO NOT give reward! Notify caller via onAdFailed.
      debugPrint('[AdsService] No rewarded ad ready to display. Requesting new load.');
      loadRewardedAd();
      onAdFailed?.call();
      onAdDismissed?.call();
    }
  }
}
