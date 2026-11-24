import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';
import '../../data/deals_catalog.dart';
import '../../state/game_controller.dart';
import 'insufficient_gems_dialog.dart';

/// Modal bottom sheet for the Dhaba Reward Center / Shop.
///
/// Designed in the clean, horizontal HR-Desk card style:
/// - Header with live Gems balance.
/// - Each offer has:
///     - Left: 44x44 emoji icon container.
///     - Middle: Deal title, active timer badge, and description.
///     - Right: Single action button showing Gems price (`💎 X`).
/// - Direct purchase if player has sufficient Gems -> starts 2-minute cooldown, closes sheet, and shows confirmation!
/// - If Gems are insufficient -> opens [InsufficientGemsDialog] to watch an ad and activate for FREE!
/// - If on 2-minute cooldown -> displays live countdown (`⏳ MM:SS`).
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

  void _onTapDeal(CatalogDealItem deal) {
    final world = widget.controller.world;

    // 1. Check if offer is on 2-minute cooldown
    if (world.isDealOnCooldown(deal.id)) {
      final remaining = world.getDealCooldown(deal.id).ceil();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '⏳ ${deal.title} is on cooldown! Ready in ${remaining}s.',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: AppTheme.chaiDarkBrown,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    // 2. If player has enough gems, purchase immediately!
    if (world.gems >= deal.gemsCost) {
      final success = widget.controller.buyStoreDealWithGems(deal);
      if (success) {
        // Close modal sheet
        Navigator.of(context).pop();

        // Show confirmation message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '🎉 ${deal.title} Activated for ${deal.gemsCost} 💎!',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: const Color(0xFF00C853),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    // 3. Insufficient gems -> Open InsufficientGemsDialog to watch Ad for FREE!
    InsufficientGemsDialog.show(
      context,
      widget.controller,
      deal,
      onRewardClaimed: () {
        if (mounted) {
          Navigator.of(context).pop(); // Close the sheet as well
        }
      },
    );
  }

  String _formatCooldown(double seconds) {
    final s = seconds.ceil().clamp(0, 9999);
    final mins = s ~/ 60;
    final secs = s % 60;
    return '⏳ ${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final world = widget.controller.world;
    final deals = DealsCatalog.rewardStoreDeals;

    return Container(
      margin: const EdgeInsets.only(top: 60),
      decoration: const BoxDecoration(
        color: Color(0xFFFBF8EE), // Dhaba warm cream card
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

            // Header Row: Storefront Icon, Title, Gems Badge, Close Button
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
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
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
                    Text('⚡', style: TextStyle(fontSize: 18)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Buy boosts with Gems, or watch an Ad if you run out of Gems!',
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

            // Deals List (HR Desk Layout)
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                itemCount: deals.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final deal = deals[index];
                  return _buildHrStyleDealCard(deal, world);
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildHrStyleDealCard(CatalogDealItem deal, dynamic world) {
    // 1. Boost active state
    bool isBoostActive = false;
    int remainingBoostSecs = 0;

    if (deal.id == 'store_staff_speed') {
      isBoostActive = world.isStoreStaffSpeedActive;
      remainingBoostSecs = world.storeStaffSpeedRemainingSeconds.ceil();
    } else if (deal.id == 'store_double_earnings') {
      isBoostActive = world.isStoreEarningsActive;
      remainingBoostSecs = world.storeEarningsRemainingSeconds.ceil();
    } else if (deal.id == 'store_worker_capacity') {
      isBoostActive = world.isStoreCapacityActive;
      remainingBoostSecs = world.storeCapacityRemainingSeconds.ceil();
    }

    // 2. Cooldown state (2 minutes / 120s)
    final isOnCooldown = world.isDealOnCooldown(deal.id);
    final cooldownRemaining = world.getDealCooldown(deal.id);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isBoostActive
              ? const Color(0xFF00C853)
              : const Color(0xFFE5DAC7),
          width: isBoostActive ? 1.8 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isBoostActive
                ? const Color(0xFF00C853).withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left: 44x44 Emoji Icon Container (HR Style)
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFFBF8EE),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE0D7C6)),
            ),
            alignment: Alignment.center,
            child: Text(
              deal.emoji,
              style: const TextStyle(fontSize: 22),
            ),
          ),
          const SizedBox(width: 12),

          // Middle: Title, Badges & Description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        deal.title,
                        style: const TextStyle(
                          color: AppTheme.chaiDarkBrown,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isBoostActive) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFF00C853)),
                        ),
                        child: Text(
                          '⏱️ ${remainingBoostSecs}s',
                          style: const TextStyle(
                            color: Color(0xFF2E7D32),
                            fontWeight: FontWeight.w900,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                if (deal.id == 'store_permanent_worker')
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      'Helpers: ${world.helperCount} / 6',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0277BD),
                      ),
                    ),
                  ),
                Text(
                  deal.description,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Right: Single Action Button (HR Style: Price or Cooldown)
          SizedBox(
            height: 38,
            child: ElevatedButton(
              onPressed: () => _onTapDeal(deal),
              style: ElevatedButton.styleFrom(
                backgroundColor: isOnCooldown
                    ? const Color(0xFFCFD8DC)
                    : const Color(0xFF0091EA),
                foregroundColor: Colors.white,
                elevation: isOnCooldown ? 0 : 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
              child: Text(
                isOnCooldown
                    ? _formatCooldown(cooldownRemaining)
                    : '💎 ${deal.gemsCost}',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  color: isOnCooldown
                      ? const Color(0xFF546E7A)
                      : Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
