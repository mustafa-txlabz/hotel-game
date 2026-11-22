import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';
import '../../state/game_controller.dart';
import 'confetti_overlay.dart';

/// Modal dialog celebrating 100% completion / mastery of a dhaba location (M8).
class LevelCompleteDialog extends StatefulWidget {
  final GameController controller;

  const LevelCompleteDialog({super.key, required this.controller});

  static Future<void> show(BuildContext context, GameController controller) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (_) => LevelCompleteDialog(controller: controller),
    );
  }

  @override
  State<LevelCompleteDialog> createState() => _LevelCompleteDialogState();
}

class _LevelCompleteDialogState extends State<LevelCompleteDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final world = widget.controller.world;
    final config = world.progressionConfig;
    final isClaimed = world.isMasteryRewardClaimed;

    return Stack(
      children: [
        // 1. Confetti & Fireworks Particle Rain in Background
        const Positioned.fill(child: ConfettiOverlay()),

        // 2. Main Victory Card
        Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
            decoration: BoxDecoration(
              color: const Color(0xFFFBF8EE), // Warm Dhaba cream
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppTheme.goldYellow, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.goldYellow.withValues(alpha: 0.4),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
                const BoxShadow(
                  color: Colors.black54,
                  blurRadius: 16,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                  // Animated Pulsing Trophy
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      final scale = 1.0 + _pulseController.value * 0.12;
                      return Transform.scale(
                        scale: scale,
                        child: child,
                      );
                    },
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.goldYellow, AppTheme.saffronOrange],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.saffronOrange.withValues(alpha: 0.45),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          '🏆',
                          style: TextStyle(fontSize: 42),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title: STORE MASTERED!
                  const Text(
                    'STORE 1 MASTERED! 🎉',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.chaiDarkBrown,
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Subtitle & Stars
                  Text(
                    config.storeName,
                    style: TextStyle(
                      color: AppTheme.chaiDarkBrown.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '⭐⭐⭐⭐⭐',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 10),

                  // Congratulatory message
                  Text(
                    'Congratulations! You have completed all store objectives and earned 100% 5-Star reputation on the Grand Trunk Highway!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.chaiDarkBrown.withValues(alpha: 0.75),
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Objectives Completed Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.truckArtGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          color: AppTheme.truckArtGreen,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${world.completedMissionIds.length}/${config.goals.length} Objectives Completed',
                          style: const TextStyle(
                            color: AppTheme.truckArtGreen,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Victory Reward Box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.goldYellow.withValues(alpha: 0.6),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'VICTORY REWARD BONUS',
                          style: TextStyle(
                            color: AppTheme.saffronOrange,
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              '💰',
                              style: TextStyle(fontSize: 22),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '₹${world.masteryRewardBonus.toInt()}',
                              style: const TextStyle(
                                color: AppTheme.chaiDarkBrown,
                                fontWeight: FontWeight.w900,
                                fontSize: 26,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (!isClaimed)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.goldYellow,
                                foregroundColor: AppTheme.chaiDarkBrown,
                                elevation: 3,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {
                                widget.controller.claimMasteryReward();
                                setState(() {});
                              },
                              child: const Text(
                                'CLAIM REWARD',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.truckArtGreen.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.verified_rounded,
                                  color: AppTheme.truckArtGreen,
                                  size: 18,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'REWARD CLAIMED ✅',
                                  style: TextStyle(
                                    color: AppTheme.truckArtGreen,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Continue Playing / Next Location Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.chaiDarkBrown,
                        side: const BorderSide(
                          color: AppTheme.chaiDarkBrown,
                          width: 1.5,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        'CONTINUE PLAYING',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      ],
    );
  }
}
