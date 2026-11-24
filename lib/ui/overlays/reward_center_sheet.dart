import 'dart:async';
import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';
import '../../data/deals_catalog.dart';
import '../../services/ads_service.dart';
import '../../state/game_controller.dart';

/// Modal bottom sheet for the Dhaba Reward Center / Shop.
///
/// Features:
/// - Prominently displays store Gems balance (💎 X GEMS).
/// - Shows utility deals from [DealsCatalog.rewardStoreDeals].
/// - Offers two purchase routes for every deal:
///     1. Buy instantly with Store Gems (💎).
///     2. Watch a Rewarded Ad (🎬 FREE).
/// - Live ticking timer badges for currently active boosts.
class RewardCenterSheet extends StatefulWidget {
  final GameController controller;

  const RewardCenterSheet({super.key, required this.controller});

  static Future<void> show(BuildContext context, GameController controller) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RewardCenterSheet(controller: controller),
    );
  }

  @override
  State<RewardCenterSheet> createState() => _RewardCenterSheetState();
}

class _RewardCenterSheetState extends State<RewardCenterSheet> {
  bool _isWatchingAd = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerUpdate);
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerUpdate);
    super.dispose();
  }

  void _buyWithGems(CatalogDealItem deal) {
    final world = widget.controller.world;
    if (world.gems < deal.gemsCost) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Need ${deal.gemsCost} 💎! Serve VVIP cars to earn more Gems.',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: AppTheme.chaiDarkBrown,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final success = widget.controller.buyStoreDealWithGems(deal);
    if (success && mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '🎉 ${deal.title} Activated with ${deal.gemsCost} 💎!',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF00C853),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _watchAdForDeal(CatalogDealItem deal) {
    if (_isWatchingAd) return;
    setState(() => _isWatchingAd = true);

    AdsService.instance.showRewardedAd(
      onUserEarnedReward: () {
        if (!mounted) return;
        widget.controller.claimStoreDealWithAd(deal);
        setState(() => _isWatchingAd = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '🎬 FREE REWARD CLAIMED: ${deal.title}!',
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
    final deals = DealsCatalog.rewardStoreDeals;

    return Container(
      margin: const EdgeInsets.only(top: 60),
      decoration: const BoxDecoration(
        color: Color(0xFFFBF8EE), // Dhaba warm cream
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            const SizedBox(height: 12),
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 12),

            // Header Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFB300).withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.storefront_rounded,
                      color: Color(0xFFFF8F00),
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'DHABA REWARD CENTER',
                          style: TextStyle(
                            color: AppTheme.chaiDarkBrown,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            letterSpacing: 0.5,
                          ),
                        ),
                        // Gems balance badge
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00E5FF)
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(0xFF00B0FF)
                                      .withValues(alpha: 0.4),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    '💎',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${world.gems} GEMS',
                                    style: const TextStyle(
                                      color: Color(0xFF0277BD),
                                      fontWeight: FontWeight.w900,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
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
            ),
            const Divider(height: 20, thickness: 1.5, color: Color(0xFFE8DFCE)),

            // Banner Tip
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFFFD54F).withValues(alpha: 0.6),
                  ),
                ),
                child: const Row(
                  children: [
                    Text('💡', style: TextStyle(fontSize: 18)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Boost your dhaba anytime! Buy with Gems or watch a quick Ad for FREE!',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF5D4037),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Deals List
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                itemCount: deals.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final deal = deals[index];
                  return _buildDealCard(deal, world);
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildDealCard(CatalogDealItem deal, dynamic world) {
    // Check active status
    bool isActive = false;
    int remainingSecs = 0;

    if (deal.id == 'store_staff_speed') {
      isActive = world.isStoreStaffSpeedActive;
      remainingSecs = world.storeStaffSpeedRemainingSeconds.ceil();
    } else if (deal.id == 'store_double_earnings') {
      isActive = world.isStoreEarningsActive;
      remainingSecs = world.storeEarningsRemainingSeconds.ceil();
    } else if (deal.id == 'store_worker_capacity') {
      isActive = world.isStoreCapacityActive;
      remainingSecs = world.storeCapacityRemainingSeconds.ceil();
    }

    final canAffordWithGems = world.gems >= deal.gemsCost;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? const Color(0xFF00C853)
              : const Color(0xFFE8DFCE),
          width: isActive ? 1.8 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isActive
                ? const Color(0xFF00C853).withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Emoji, Title, and Active Badge
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFFBF8EE),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE0D7C6)),
                ),
                child: Text(
                  deal.emoji,
                  style: const TextStyle(fontSize: 22),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deal.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: AppTheme.chaiDarkBrown,
                      ),
                    ),
                    if (deal.id == 'store_permanent_worker')
                      Text(
                        'Current Helpers: ${world.helperCount}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0277BD),
                        ),
                      ),
                  ],
                ),
              ),
              if (isActive)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF00C853),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '⏱️',
                        style: TextStyle(fontSize: 10),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${remainingSecs}s',
                        style: const TextStyle(
                          color: Color(0xFF2E7D32),
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Description
          Text(
            deal.description,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6D4C41),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),

          // Action Buttons: Gems (💎) OR Ad (🎬 FREE)
          Row(
            children: [
              // 1. Buy with Gems
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: ElevatedButton(
                    onPressed: canAffordWithGems
                        ? () => _buyWithGems(deal)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canAffordWithGems
                          ? const Color(0xFF0091EA)
                          : const Color(0xFFCFD8DC),
                      foregroundColor: Colors.white,
                      elevation: canAffordWithGems ? 2 : 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        canAffordWithGems
                            ? '💎 ${deal.gemsCost} GEMS'
                            : 'Need ${deal.gemsCost} 💎',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          color: canAffordWithGems
                              ? Colors.white
                              : const Color(0xFF78909C),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // 2. Watch Ad (FREE)
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: ElevatedButton(
                    onPressed: _isWatchingAd
                        ? null
                        : () => _watchAdForDeal(deal),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6D00),
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _isWatchingAd ? 'LOADING...' : '🎬 FREE (AD)',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
