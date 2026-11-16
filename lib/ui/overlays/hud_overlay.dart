import 'package:material_ui/material_ui.dart';

import '../../core/number_format.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';

/// Top HUD displaying currency balance, item carrying count, and tutorial hints.
class HudOverlay extends StatelessWidget {
  final double rupees;
  final int carriedCount;
  final int carryCapacity;
  final bool showTutorial;

  const HudOverlay({
    super.key,
    required this.rupees,
    required this.carriedCount,
    required this.carryCapacity,
    this.showTutorial = true,
  });

  @override
  Widget build(BuildContext context) {
    final isFull = carriedCount >= carryCapacity;

    return SafeArea(
      child: Stack(
        children: [
          // Top Bar
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Row(
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
}
