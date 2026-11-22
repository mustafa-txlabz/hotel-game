import 'package:material_ui/material_ui.dart';

import '../../core/number_format.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';

/// Top HUD displaying currency balance, item carrying count, store reputation, and tutorial hints.
class HudOverlay extends StatelessWidget {
  final double rupees;
  final int carriedCount;
  final int carryCapacity;
  final double reputationPercent;
  final int reputationLevel;
  final VoidCallback? onReputationTap;
  final bool showMasteryRewardBar;
  final double masteryRewardBonus;
  final VoidCallback? onClaimMasteryReward;
  final bool showTutorial;

  const HudOverlay({
    super.key,
    required this.rupees,
    required this.carriedCount,
    required this.carryCapacity,
    this.reputationPercent = 0.0,
    this.reputationLevel = 1,
    this.onReputationTap,
    this.showMasteryRewardBar = false,
    this.masteryRewardBonus = 1000.0,
    this.onClaimMasteryReward,
    this.showTutorial = true,
  });

  @override
  Widget build(BuildContext context) {
    final isFull = carriedCount >= carryCapacity;

    return SafeArea(
      child: Stack(
        children: [
          // Top Bar & Reputation Section
          Positioned(
            top: 10,
            left: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Row 1: Header Row (Title, Carry Count, Cash Wallet)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                // Game Title Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.chaiDarkBrown,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.saffronOrange, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: const [
                      Icon(
                        Icons.restaurant_rounded,
                        color: AppTheme.goldYellow,
                        size: 18,
                      ),
                      SizedBox(width: 6),
                      Text(
                        AppStrings.appTitle,
                        style: TextStyle(
                          color: AppTheme.cream,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),

                Row(
                  children: [
                    // Item Carry Capacity Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isFull
                            ? const Color(0xFFD32F2F)
                            : AppTheme.cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isFull ? Colors.white : AppTheme.saffronOrange,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.local_cafe_rounded,
                            color: isFull ? Colors.white : AppTheme.chaiBrown,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$carriedCount/$carryCapacity',
                            style: TextStyle(
                              color: isFull
                                  ? Colors.white
                                  : AppTheme.chaiDarkBrown,
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Cash Wallet Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.truckArtGreen,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: AppTheme.truckArtGreen,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.currency_rupee_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${AppStrings.currencySymbol}${GameNumberFormat.format(rupees)}',
                            style: const TextStyle(
                              color: AppTheme.chaiDarkBrown,
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Row 2: Sleek Store Reputation Bar (Centered with side spacing)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 380),
                  child: _buildReputationBar(context),
                ),
              ),
            ),

            // Row 3: Temporary Store Mastery Reward Claim Bar (shown under reputation bar until claimed)
            if (showMasteryRewardBar) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 380),
                    child: _buildMasteryRewardBar(context),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),

          // Tutorial Hint when idle
          if (showTutorial)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppTheme.goldYellow.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.touch_app_rounded,
                        color: AppTheme.goldYellow,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        AppStrings.dragToMove,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReputationBar(BuildContext context) {
    final clampedPercent = reputationPercent.clamp(0.0, 100.0);
    final isMax = clampedPercent >= 100.0;
    final displayPercent = isMax ? '100%' : '${clampedPercent.toStringAsFixed(1)}%';

    return GestureDetector(
      onTap: onReputationTap,
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFF2C1E14).withValues(alpha: 0.90), // Sleek Dhaba dark glass
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: isMax
                ? AppTheme.goldYellow
                : AppTheme.goldYellow.withValues(alpha: 0.50),
            width: isMax ? 2.0 : 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: isMax
                  ? AppTheme.goldYellow.withValues(alpha: 0.30)
                  : Colors.black.withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Left: Title & Icon (REPUTATION)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(
                  Icons.verified_rounded,
                  color: AppTheme.goldYellow,
                  size: 16,
                ),
                SizedBox(width: 5),
                Text(
                  'REPUTATION',
                  style: TextStyle(
                    color: AppTheme.cream,
                    fontWeight: FontWeight.w900,
                    fontSize: 11.5,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),

            // Center: Smooth Glowing Golden Progress Bar
            Expanded(
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  // Track background
                  Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),

                  // Filling Bar
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final fillWidth =
                          (constraints.maxWidth * (clampedPercent / 100.0))
                              .clamp(0.0, constraints.maxWidth);

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOutCubic,
                        width: fillWidth,
                        height: 10,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              AppTheme.saffronOrange,
                              AppTheme.goldYellow,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(5),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.goldYellow.withValues(alpha: 0.55),
                              blurRadius: 5,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // Right: Single Clean Percentage Display (No Trophy Icon)
            Text(
              displayPercent,
              style: TextStyle(
                color: isMax ? AppTheme.goldYellow : Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 12.5,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Temporary victory reward bar displayed directly beneath the reputation bar until claimed.
  Widget _buildMasteryRewardBar(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF2C1E14).withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: AppTheme.goldYellow,
          width: 1.6,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.goldYellow.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left: Trophy & Reward text
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🏆', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              const Text(
                'VICTORY BONUS: ',
                style: TextStyle(
                  color: AppTheme.cream,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  letterSpacing: 0.4,
                ),
              ),
              Text(
                '₹${masteryRewardBonus.toInt()}',
                style: const TextStyle(
                  color: AppTheme.goldYellow,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const Spacer(),

          // Right: Vibrant Green CLAIM Button
          GestureDetector(
            onTap: onClaimMasteryReward,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00E676), Color(0xFF00C853)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00E676).withValues(alpha: 0.45),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.stars_rounded, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text(
                    'CLAIM',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
