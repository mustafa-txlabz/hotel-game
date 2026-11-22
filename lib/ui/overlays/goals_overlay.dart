import 'package:material_ui/material_ui.dart';

import '../../core/number_format.dart';
import '../../core/theme.dart';
import '../../data/progression_config.dart';
import '../../state/game_controller.dart';

/// Modal bottom sheet displaying store objectives, 100% reputation progress bar,
/// and location mastery rewards.
class GoalsOverlay extends StatefulWidget {
  final GameController controller;

  const GoalsOverlay({super.key, required this.controller});

  static Future<void> show(BuildContext context, GameController controller) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GoalsOverlay(controller: controller),
    );
  }

  @override
  State<GoalsOverlay> createState() => _GoalsOverlayState();
}

class _GoalsOverlayState extends State<GoalsOverlay> {
  @override
  Widget build(BuildContext context) {
    final world = widget.controller.world;
    final config = world.progressionConfig;

    return Container(
      margin: const EdgeInsets.only(top: 60),
      decoration: const BoxDecoration(
        color: Color(0xFFFBF8EE), // Warm Dhaba cream sheet
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
                      color: AppTheme.saffronOrange.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.emoji_events_rounded,
                      color: AppTheme.saffronOrange,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          config.storeName.toUpperCase(),
                          style: const TextStyle(
                            color: AppTheme.chaiDarkBrown,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          'Store Objectives & Missions',
                          style: TextStyle(
                            color: AppTheme.chaiDarkBrown.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    color: AppTheme.chaiDarkBrown,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Content scroll area
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Section Header: Store Objectives
                    Row(
                      children: [
                        const Text(
                          'STORE OBJECTIVES',
                          style: TextStyle(
                            color: AppTheme.chaiDarkBrown,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.truckArtGreen.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${world.completedMissionIds.length}/${config.goals.length} DONE',
                            style: const TextStyle(
                              color: AppTheme.truckArtGreen,
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // 2. Goals List
                    ...config.goals.map((goal) => _buildGoalCard(world, goal)),

                    if (world.isStoreMastered) ...[
                      const SizedBox(height: 8),
                      _buildMasteryCelebrationCard(world),
                    ],

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalCard(dynamic world, StoreGoal goal) {
    final isDone = world.completedMissionIds.contains(goal.id);
    final progressString = _getGoalProgress(world, goal);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDone ? const Color(0xFFF1F8E9) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDone
              ? AppTheme.truckArtGreen.withValues(alpha: 0.4)
              : Colors.black12,
        ),
      ),
      child: Row(
        children: [
          // Goal Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDone
                  ? AppTheme.truckArtGreen.withValues(alpha: 0.15)
                  : const Color(0xFFECEFF1),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              goal.icon,
              style: const TextStyle(fontSize: 20),
            ),
          ),
          const SizedBox(width: 12),

          // Title & Description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        goal.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isDone
                              ? AppTheme.truckArtGreen
                              : AppTheme.chaiDarkBrown,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          decoration: isDone ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      progressString,
                      style: TextStyle(
                        color: isDone
                            ? AppTheme.truckArtGreen
                            : AppTheme.chaiDarkBrown.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  goal.description,
                  style: TextStyle(
                    color: AppTheme.chaiDarkBrown.withValues(alpha: 0.65),
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Status Badge
          if (isDone)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: AppTheme.truckArtGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 16,
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'IN PROGRESS',
                style: TextStyle(
                  color: AppTheme.chaiDarkBrown,
                  fontWeight: FontWeight.w800,
                  fontSize: 10,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMasteryCelebrationCard(dynamic world) {
    final isClaimed = world.isMasteryRewardClaimed;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE65100), Color(0xFFFF8F00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE65100).withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            '🎉 STORE MASTERED! 🏆',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 16,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${world.progressionConfig.storeName} has reached 100% 5-Star Glory! All goals complete.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          if (!isClaimed)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.goldYellow,
                foregroundColor: AppTheme.chaiDarkBrown,
                elevation: 4,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () {
                widget.controller.claimMasteryReward();
                setState(() {});
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.stars_rounded, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'CLAIM ₹${world.masteryRewardBonus.toInt()} REWARD BONUS',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 6),
                  Text(
                    '₹1,000 BONUS CLAIMED ✅',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _getGoalProgress(dynamic world, StoreGoal goal) {
    switch (goal.type) {
      case GoalType.hireCashier:
        return world.hasCashier ? '1/1' : '0/1';
      case GoalType.hireWorkers:
        return '${world.workerCount}/${goal.targetValue}';
      case GoalType.unlockTables:
        return '${world.unlockedTableCount}/${goal.targetValue}';
      case GoalType.upgradeKettle:
        return 'Lvl ${world.chaiStation.level}/${goal.targetValue}';
      case GoalType.unlockParatha:
        return world.parathaStation.isUnlocked ? '1/1' : '0/1';
      case GoalType.reachReputation:
        return '${world.reputationPercent.toInt()}%/${goal.targetValue}%';
      case GoalType.earnRevenue:
        return '₹${GameNumberFormat.format(world.lifetimeRupees)}/₹${GameNumberFormat.format(goal.targetValue.toDouble())}';
    }
  }
}
