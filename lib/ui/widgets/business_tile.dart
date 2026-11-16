import 'package:material_ui/material_ui.dart';

import '../../core/number_format.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../data/balance.dart';
import '../../state/game_controller.dart';

/// Business list tile displaying business status, income, milestone progress,
/// and purchase button.
class BusinessTile extends StatelessWidget {
  final BusinessConfig config;
  final GameController controller;

  const BusinessTile({
    super.key,
    required this.config,
    required this.controller,
  });

  IconData _getBusinessIcon(String id) {
    switch (id) {
      case 'chai_thela':
        return Icons.emoji_food_beverage_rounded;
      case 'paratha_stall':
        return Icons.breakfast_dining_rounded;
      case 'roadside_dhaba':
        return Icons.storefront_rounded;
      default:
        return Icons.business_center_rounded;
    }
  }

  int _getNextMilestone(int owned) {
    for (final m in GameBalance.standardMilestones) {
      if (owned < m) return m;
    }
    return ((owned ~/ 100) + 1) * 100;
  }

  @override
  Widget build(BuildContext context) {
    final isUnlocked = controller.engine.isBusinessUnlocked(config.id);
    final owned = controller.state.getBusiness(config.id).owned;
    final income = controller.engine.businessIncomePerSecond(config.id);
    final cost = controller.engine.getCost(config.id, 1);
    final canAfford = controller.engine.canAfford(config.id, 1);

    if (!isUnlocked) {
      return _buildLockedTile(context, cost);
    }

    final nextMilestone = _getNextMilestone(owned);
    final milestoneProgress = (owned / nextMilestone).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: canAfford ? AppTheme.saffronOrange : Colors.brown.shade200,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.chaiDarkBrown.withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // Business Icon
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: AppTheme.cream,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.chaiBrown, width: 2),
              ),
              child: Icon(
                _getBusinessIcon(config.id),
                color: AppTheme.chaiBrown,
                size: 32,
              ),
            ),
            const SizedBox(width: 12),

            // Business Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          config.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.chaiDarkBrown,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.chaiBrown,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'x$owned',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${AppStrings.incomeLabel} ${AppStrings.currencySymbol}${GameNumberFormat.formatRate(income)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.truckArtGreen,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Milestone progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: milestoneProgress,
                      minHeight: 5,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppTheme.saffronOrange,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${AppStrings.milestoneRewardPrefix}$nextMilestone',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            // Buy button
            SizedBox(
              width: 90,
              height: 52,
              child: ElevatedButton(
                onPressed: canAfford
                    ? () => controller.buyBusiness(config.id, 1)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: canAfford
                      ? AppTheme.saffronOrange
                      : Colors.grey.shade300,
                  foregroundColor: canAfford
                      ? Colors.white
                      : Colors.grey.shade600,
                  elevation: canAfford ? 3 : 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 4,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: canAfford
                          ? AppTheme.truckArtRed
                          : Colors.grey.shade400,
                      width: 1.5,
                    ),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      AppStrings.buyButton,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${AppStrings.currencySymbol}${GameNumberFormat.format(cost)}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLockedTile(BuildContext context, double cost) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade400, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.lock_rounded,
                color: Colors.grey.shade600,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    config.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppStrings.unlockRequirement,
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Cost: ${AppStrings.currencySymbol}${GameNumberFormat.format(cost)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
