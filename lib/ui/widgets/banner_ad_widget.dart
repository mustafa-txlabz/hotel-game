import 'dart:async';
import 'package:material_ui/material_ui.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../app.dart';
import '../../core/theme.dart';
import '../../services/ad_ids.dart';

/// Production-ready AdMob Banner Ad Widget.
///
/// Features:
/// - Screen-wide full adaptive banner width based on the device display.
/// - Clean screen guarantee: If the ad fails to load (offline, ad blocker, no fill),
///   it collapses completely ([SizedBox.shrink]) with zero placeholder or border.
/// - Auto-refresh every [refreshInterval] (default 45s).
/// - Instant refresh on route return: Refreshes whenever the user navigates back
///   from the game viewport, city map, or settings.
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
  State<BannerAdWidget> createState() => BannerAdWidgetState();
}

class BannerAdWidgetState extends State<BannerAdWidget>
    with WidgetsBindingObserver, RouteAware {
  BannerAd? _currentAd;
  BannerAd? _loadingAd;
  bool _isAdLoaded = false;
  Timer? _refreshTimer;
  bool _isAppActive = true;
  bool _initialLoadRequested = false;

  /// Public getter to check if banner is currently showing.
  bool get isAdLoaded => _isAdLoaded;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    if (BannerAdWidget.testMode) {
      _isAdLoaded = BannerAdWidget.testMockLoaded;
      return;
    }

    if (widget.autoRefresh) {
      _startRefreshTimer();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe to navigation events so returning to this screen triggers a refresh
    final modalRoute = ModalRoute.of(context);
    if (modalRoute != null) {
      appRouteObserver.subscribe(this, modalRoute);
    }

    if (!_initialLoadRequested && !BannerAdWidget.testMode) {
      _initialLoadRequested = true;
      _loadAd();
    }
  }

  @override
  void didPopNext() {
    // Called when the top route has been popped and this screen is visible again!
    debugPrint('[BannerAdWidget] Returned to screen via pop. Triggering banner refresh...');
    refreshAd();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _isAppActive = true;
      if (widget.autoRefresh && (_refreshTimer == null || !_refreshTimer!.isActive)) {
        _startRefreshTimer();
      }
      refreshAd();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.inactive) {
      _isAppActive = false;
      _refreshTimer?.cancel();
    }
  }

  void _startRefreshTimer() {
    if (BannerAdWidget.testMode) return;
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(widget.refreshInterval, (_) {
      if (_isAppActive && mounted) {
        refreshAd();
      }
    });
  }

  /// Refreshes the banner ad on demand (e.g. on navigation return or timer).
  void refreshAd() {
    if (!mounted) return;
    if (BannerAdWidget.testMode) {
      setState(() {
        _isAdLoaded = BannerAdWidget.testMockLoaded;
      });
      return;
    }
    _loadAd();
  }

  Future<void> _loadAd() async {
    if (BannerAdWidget.testMode) return;

    try {
      int screenWidth = 320;
      if (mounted) {
        final queryWidth = MediaQuery.sizeOf(context).width.truncate();
        if (queryWidth > 0) screenWidth = queryWidth;
      }

      // 1. Calculate device screen adaptive banner size
      AdSize targetSize = AdSize.banner;
      try {
        final adaptiveSize =
            await AdSize.getLargeAnchoredAdaptiveBannerAdSize(screenWidth);
        if (adaptiveSize != null) {
          targetSize = adaptiveSize;
        }
      } catch (e) {
        debugPrint('[BannerAdWidget] Adaptive size query error, using standard banner: $e');
      }

      if (!mounted) return;

      // 2. Create and load the full-width adaptive banner ad
      final banner = BannerAd(
        adUnitId: AdIds.bannerAdUnitId,
        size: targetSize,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            final bannerAd = ad as BannerAd;
            if (!mounted) {
              bannerAd.dispose();
              return;
            }
            debugPrint(
              '[BannerAdWidget] Full-width banner loaded successfully (${bannerAd.size.width}x${bannerAd.size.height}).',
            );
            setState(() {
              _currentAd?.dispose();
              _currentAd = bannerAd;
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
              // Clean screen guarantee: If ad fails, remove ad so screen stays clean
              _currentAd?.dispose();
              _currentAd = null;
              _isAdLoaded = false;
            });
            widget.onAdFailedToLoad?.call(error);
          },
        ),
      );

      _loadingAd?.dispose();
      _loadingAd = banner;
      await banner.load();
    } catch (e) {
      debugPrint('[BannerAdWidget] Error in _loadAd: $e');
      if (mounted) {
        setState(() {
          _loadingAd?.dispose();
          _loadingAd = null;
          _currentAd?.dispose();
          _currentAd = null;
          _isAdLoaded = false;
        });
      }
    }
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    _currentAd?.dispose();
    _loadingAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (BannerAdWidget.testMode) {
      if (BannerAdWidget.testMockLoaded) {
        return Container(
          width: double.infinity,
          height: 50.0,
          alignment: Alignment.center,
          color: const Color(0xFF2C1409),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.ad_units_rounded, size: 16, color: AppTheme.goldYellow),
              SizedBox(width: 8),
              Text(
                'TEST AD • FULL-WIDTH BANNER',
                style: TextStyle(
                  color: AppTheme.goldYellow,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        );
      }
      // Clean screen rule: completely collapsed if no ad
      return const SizedBox.shrink();
    }

    // STRICT CLEAN SCREEN RULE:
    // If ad is not loaded (offline, ad blocker, load failure, initial state),
    // return SizedBox.shrink() so screen remains 100% clean with NO placeholder!
    if (!_isAdLoaded || _currentAd == null) {
      return const SizedBox.shrink();
    }

    // Full mobile screen width container
    return Container(
      width: double.infinity,
      height: _currentAd!.size.height.toDouble(),
      alignment: Alignment.center,
      child: SizedBox(
        width: _currentAd!.size.width.toDouble(),
        height: _currentAd!.size.height.toDouble(),
        child: AdWidget(ad: _currentAd!),
      ),
    );
  }
}
