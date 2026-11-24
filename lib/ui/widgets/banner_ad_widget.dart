import 'dart:async';
import 'package:material_ui/material_ui.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../core/theme.dart';
import '../../services/ad_ids.dart';

/// Production-ready AdMob Banner Ad Widget.
///
/// Features:
/// - Fixed height (50dp) to prevent layout shifting.
/// - Seamless auto-refresh every [refreshInterval] (default 45s).
/// - Graceful lifecycle handling (pauses refresh when app is in background).
/// - Non-flickering ad swap (loads replacement ad before disposing previous ad).
/// - Safe test mode for automated unit and widget testing.
class BannerAdWidget extends StatefulWidget {
  final Duration refreshInterval;
  final bool autoRefresh;
  final VoidCallback? onAdLoaded;
  final ValueChanged<LoadAdError>? onAdFailedToLoad;

  const BannerAdWidget({
    super.key,
    this.refreshInterval = const Duration(seconds: 45),
    this.autoRefresh = true,
    this.onAdLoaded,
    this.onAdFailedToLoad,
  });

  /// Set to `true` during widget testing to simulate banner ad loading
  /// without triggering platform channels.
  static bool testMode = false;

  /// Whether simulated test banner is considered loaded in tests.
  static bool testMockLoaded = false;

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget>
    with WidgetsBindingObserver {
  BannerAd? _currentAd;
  BannerAd? _loadingAd;
  bool _isAdLoaded = false;
  Timer? _refreshTimer;
  bool _isAppActive = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    if (BannerAdWidget.testMode) {
      _isAdLoaded = BannerAdWidget.testMockLoaded;
      return;
    }

    _loadAd();
    if (widget.autoRefresh) {
      _startRefreshTimer();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _isAppActive = true;
      if (widget.autoRefresh && (_refreshTimer == null || !_refreshTimer!.isActive)) {
        _startRefreshTimer();
      }
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.inactive) {
      _isAppActive = false;
      _refreshTimer?.cancel();
    }
  }

  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(widget.refreshInterval, (_) {
      if (_isAppActive && mounted) {
        _refreshAd();
      }
    });
  }

  void _loadAd() {
    if (BannerAdWidget.testMode) return;

    try {
      final banner = BannerAd(
        adUnitId: AdIds.bannerAdUnitId,
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            if (!mounted) {
              ad.dispose();
              return;
            }
            debugPrint('[BannerAdWidget] Banner ad loaded successfully.');
            setState(() {
              _currentAd?.dispose();
              _currentAd = ad as BannerAd;
              _loadingAd = null;
              _isAdLoaded = true;
            });
            widget.onAdLoaded?.call();
          },
          onAdFailedToLoad: (ad, error) {
            debugPrint('[BannerAdWidget] Banner ad failed to load: $error');
            ad.dispose();
            if (!mounted) return;
            setState(() {
              _loadingAd = null;
              // If we already have a currently active ad, keep it rather than showing blank
              if (_currentAd == null) {
                _isAdLoaded = false;
              }
            });
            widget.onAdFailedToLoad?.call(error);
          },
        ),
      );

      _loadingAd?.dispose();
      _loadingAd = banner;
      banner.load();
    } catch (e) {
      debugPrint('[BannerAdWidget] Error loading banner ad: $e');
    }
  }

  void _refreshAd() {
    if (!_isAppActive || !mounted) return;
    _loadAd();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    _currentAd?.dispose();
    _loadingAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Standard AdMob Banner dimensions: 320 x 50
    const double bannerWidth = 320.0;
    const double bannerHeight = 50.0;

    return Center(
      child: Container(
        width: bannerWidth,
        height: bannerHeight,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF1A0A04),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppTheme.saffronOrange.withValues(alpha: 0.25),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: _buildBannerContent(),
        ),
      ),
    );
  }

  Widget _buildBannerContent() {
    if (BannerAdWidget.testMode) {
      if (BannerAdWidget.testMockLoaded) {
        return Container(
          color: const Color(0xFF2C1409),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.ad_units_rounded, size: 16, color: AppTheme.goldYellow),
                SizedBox(width: 6),
                Text(
                  'TEST AD • BANNER (320x50)',
                  style: TextStyle(
                    color: AppTheme.goldYellow,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        );
      }
      return _buildPlaceholder();
    }

    if (_isAdLoaded && _currentAd != null) {
      return SizedBox(
        width: _currentAd!.size.width.toDouble(),
        height: _currentAd!.size.height.toDouble(),
        child: AdWidget(ad: _currentAd!),
      );
    }

    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      color: const Color(0xFF180803),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_cafe_rounded,
              size: 14,
              color: AppTheme.saffronOrange.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 6),
            Text(
              'DHABA TYCOON • AD BANNER',
              style: TextStyle(
                color: AppTheme.cream.withValues(alpha: 0.4),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
