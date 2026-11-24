import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';
import '../../data/deals_catalog.dart';
import '../../services/ads_service.dart';
import '../../state/game_controller.dart';

/// Modal dialog shown when a player taps a store deal but has insufficient Gems.
///
/// Features:
/// - Informs the player of the gem shortage.
/// - Shows offer summary.
/// - Allows instant activation for FREE by watching a Google AdMob Rewarded Ad!
class InsufficientGemsDialog extends StatefulWidget {
  final GameController controller;
  final CatalogDealItem deal;
  final VoidCallback? onRewardClaimed;

  const InsufficientGemsDialog({
    super.key,
    required this.controller,
    required this.deal,
    this.onRewardClaimed,
  });

  /// Displays the insufficient gems dialog.
  static Future<void> show(
    BuildContext context,
    GameController controller,
    CatalogDealItem deal, {
    VoidCallback? onRewardClaimed,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (ctx) => InsufficientGemsDialog(
        controller: controller,
        deal: deal,
        onRewardClaimed: onRewardClaimed,
      ),
    );
  }

  @override
  State<InsufficientGemsDialog> createState() => _InsufficientGemsDialogState();
}

class _InsufficientGemsDialogState extends State<InsufficientGemsDialog> {
  bool _isWatchingAd = false;

  void _onWatchAd() {
    if (_isWatchingAd) return;
    setState(() => _isWatchingAd = true);

    AdsService.instance.showRewardedAd(
      onUserEarnedReward: () {
        if (!mounted) return;
        widget.controller.claimStoreDealWithAd(widget.deal);
        setState(() => _isWatchingAd = false);

        // Close this dialog first
        Navigator.of(context, rootNavigator: true).pop();

        // Trigger callback to close parent sheet & show snackbar
        widget.onRewardClaimed?.call();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '🎬 FREE REWARD CLAIMED: ${widget.deal.title}! 🎉',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: const Color(0xFF00C853),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      },
      onAdDismissed: () {
        if (mounted) {
          setState(() => _isWatchingAd = false);
        }
      },
      onAdFailed: () {
        if (mounted) {
          setState(() => _isWatchingAd = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Video ad not ready. Please check your internet connection! 📶',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              backgroundColor: AppTheme.chaiDarkBrown,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 3),
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final world = widget.controller.world;
    final deal = widget.deal;
    final shortage = deal.gemsCost - world.gems;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 330,
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFFBF8EE), // Dhaba warm cream
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFF00B0FF).withValues(alpha: 0.5),
              width: 2.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Row: Diamond Icon & Close Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF00B0FF).withValues(alpha: 0.4),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const Text('💎', style: TextStyle(fontSize: 22)),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppTheme.chaiDarkBrown,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Title
              const Text(
                'NOT ENOUGH GEMS!',
                style: TextStyle(
                  color: AppTheme.chaiDarkBrown,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),

              // Shortage note
              Text(
                'You need ${deal.gemsCost} 💎 for this boost.\nYour balance: ${world.gems} 💎 (Need $shortage more)',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF5D4037),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),

              // Deal Preview Box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE8DFCE)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFBF8EE),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE0D7C6)),
                      ),
                      alignment: Alignment.center,
                      child: Text(deal.emoji, style: const TextStyle(fontSize: 20)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            deal.title,
                            style: const TextStyle(
                              color: AppTheme.chaiDarkBrown,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            deal.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF757575),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Rewarded Ad Callout
              const Text(
                'Watch a video ad to activate for FREE! 🎁',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFE65100),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),

              // Watch Ad Button
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: _isWatchingAd ? null : _onWatchAd,
                  icon: _isWatchingAd
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.play_circle_fill_rounded, size: 20),
                  label: Text(
                    _isWatchingAd ? 'LOADING AD...' : '🎬 WATCH AD & ACTIVATE',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6D00),
                    foregroundColor: Colors.white,
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Cancel button
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Maybe Later',
                  style: TextStyle(
                    color: Color(0xFF8D6E63),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
