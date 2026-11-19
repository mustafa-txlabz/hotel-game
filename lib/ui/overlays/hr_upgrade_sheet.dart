import 'package:material_ui/material_ui.dart';

import '../../core/number_format.dart';
import '../../core/theme.dart';
import '../../data/balance.dart';
import '../../state/game_controller.dart';

/// Clipboard-style modal bottom sheet for Dhaba HR management and upgrades.
class HrUpgradeSheet extends StatefulWidget {
  final GameController controller;

  const HrUpgradeSheet({super.key, required this.controller});

  static Future<void> show(BuildContext context, GameController controller) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => HrUpgradeSheet(controller: controller),
    );
  }

  @override
  State<HrUpgradeSheet> createState() => _HrUpgradeSheetState();
}

class _HrUpgradeSheetState extends State<HrUpgradeSheet> {
  @override
  Widget build(BuildContext context) {
    final world = widget.controller.world;

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
                      Icons.assignment_ind_rounded,
                      color: AppTheme.saffronOrange,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'HR & UPGRADES',
                          style: TextStyle(
                            color: AppTheme.chaiDarkBrown,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          'Wallet: ₹${GameNumberFormat.format(world.rupees)}',
                          style: const TextStyle(
                            color: AppTheme.truckArtGreen,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
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
            const Divider(height: 24, thickness: 1.5, color: Color(0xFFE8DFCE)),

            // Upgrades List
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                children: [
                  // --- SECTION 1: OWNER UPGRADES ---
                  _buildSectionHeader('OWNER UPGRADES', Icons.person_rounded),
                  const SizedBox(height: 10),

                  // Move Speed
                  _buildUpgradeCard(
                    title: 'Move Speed',
                    icon: Icons.bolt_rounded,
                    iconColor: Colors.amber.shade700,
                    levelText: 'Lvl ${world.playerSpeedLevel}/${GameBalance.playerSpeedLevels.length}',
                    description: '${world.player.speed.toInt()} px/s speed',
                    cost: world.playerSpeedUpgradeCost,
                    canAfford: world.canUpgradePlayerSpeed,
                    isMax: world.playerSpeedLevel >= GameBalance.playerSpeedLevels.length,
                    onUpgrade: () {
                      if (world.upgradePlayerSpeed()) {
                        widget.controller.tick(0.0);
                        setState(() {});
                      }
                    },
                  ),
                  const SizedBox(height: 10),

                  // Carry Capacity
                  _buildUpgradeCard(
                    title: 'Carry Capacity',
                    icon: Icons.backpack_rounded,
                    iconColor: AppTheme.saffronOrange,
                    levelText: 'Lvl ${world.playerCapacityLevel}/${GameBalance.playerCapacityLevels.length}',
                    description: '${world.player.carryCapacity} items max stack',
                    cost: world.playerCapacityUpgradeCost,
                    canAfford: world.canUpgradePlayerCapacity,
                    isMax: world.playerCapacityLevel >= GameBalance.playerCapacityLevels.length,
                    onUpgrade: () {
                      if (world.upgradePlayerCapacity()) {
                        widget.controller.tick(0.0);
                        setState(() {});
                      }
                    },
                  ),
                  const SizedBox(height: 20),

                  // --- SECTION 2: STAFF & FACULTY ---
                  _buildSectionHeader('STAFF & FACULTY', Icons.groups_rounded),
                  const SizedBox(height: 10),

                  // Cashier Card
                  _buildStaffCard(
                    title: 'Cashier',
                    subtitle: 'Permanently attends counter register',
                    icon: Icons.point_of_sale_rounded,
                    iconColor: AppTheme.truckArtGreen,
                    isHired: world.hasCashier,
                    hiredLabel: 'ON DUTY ✅',
                    cost: GameBalance.hireCashierCost,
                    canAfford: world.rupees >= GameBalance.hireCashierCost,
                    onHire: () {
                      if (world.hireCashier()) {
                        widget.controller.tick(0.0);
                        setState(() {});
                      }
                    },
                  ),
                  const SizedBox(height: 10),

                  // Worker Card
                  _buildStaffCard(
                    title: 'Worker',
                    subtitle: 'Carries chai & cleans dirty tables',
                    icon: Icons.directions_run_rounded,
                    iconColor: Colors.deepOrange,
                    isHired: false,
                    isMax: !world.canHireWorker,
                    hiredLabel: '${world.workerCount}/${world.maxWorkers}',
                    cost: world.nextWorkerCost,
                    canAfford: world.canHireWorker && world.rupees >= world.nextWorkerCost,
                    badge: '${world.workerCount}/${world.maxWorkers}',
                    onHire: () {
                      if (world.hireWorker()) {
                        widget.controller.tick(0.0);
                        setState(() {});
                      }
                    },
                  ),
                  const SizedBox(height: 10),

                  // Worker Speed
                  _buildUpgradeCard(
                    title: 'Worker Speed',
                    icon: Icons.speed_rounded,
                    iconColor: Colors.blue.shade700,
                    levelText: 'Lvl ${world.workerSpeedLevel}/${GameBalance.workerSpeedLevels.length}',
                    description: '${world.currentWorkerSpeed.toInt()} px/s helper speed',
                    cost: world.workerSpeedUpgradeCost,
                    canAfford: world.canUpgradeWorkerSpeed,
                    isMax: world.workerSpeedLevel >= GameBalance.workerSpeedLevels.length,
                    onUpgrade: () {
                      if (world.upgradeWorkerSpeed()) {
                        widget.controller.tick(0.0);
                        setState(() {});
                      }
                    },
                  ),
                  const SizedBox(height: 10),

                  // Worker Capacity
                  _buildUpgradeCard(
                    title: 'Worker Capacity',
                    icon: Icons.local_cafe_rounded,
                    iconColor: AppTheme.chaiBrown,
                    levelText: 'Lvl ${world.workerCapacityLevel}/${GameBalance.workerCapacityLevels.length}',
                    description: '${world.currentWorkerCapacity} items carry capacity',
                    cost: world.workerCapacityUpgradeCost,
                    canAfford: world.canUpgradeWorkerCapacity,
                    isMax: world.workerCapacityLevel >= GameBalance.workerCapacityLevels.length,
                    onUpgrade: () {
                      if (world.upgradeWorkerCapacity()) {
                        widget.controller.tick(0.0);
                        setState(() {});
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.chaiDarkBrown),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: AppTheme.chaiDarkBrown,
            fontWeight: FontWeight.w900,
            fontSize: 13,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  Widget _buildUpgradeCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required String levelText,
    required String description,
    required double? cost,
    required bool canAfford,
    required bool isMax,
    required VoidCallback onUpgrade,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5DAC7), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppTheme.chaiDarkBrown,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3ECE0),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        levelText,
                        style: const TextStyle(
                          color: AppTheme.chaiDarkBrown,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (isMax)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'MAX',
                style: TextStyle(
                  color: Colors.black45,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            )
          else
            ElevatedButton(
              onPressed: canAfford ? onUpgrade : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.truckArtGreen,
                disabledBackgroundColor: Colors.grey.shade300,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: canAfford ? 2 : 0,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.currency_rupee_rounded, size: 14, color: Colors.white),
                  Text(
                    GameNumberFormat.format(cost ?? 0.0),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStaffCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool isHired,
    required String hiredLabel,
    required double cost,
    required bool canAfford,
    required VoidCallback onHire,
    String? badge,
    bool isMax = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5DAC7), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppTheme.chaiDarkBrown,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    if (badge != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.truckArtGreen.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badge,
                          style: const TextStyle(
                            color: AppTheme.truckArtGreen,
                            fontWeight: FontWeight.w800,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (isMax)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade400, width: 1.5),
              ),
              child: const Text(
                'MAX',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 1,
                ),
              ),
            )
          else if (isHired)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.truckArtGreen.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.truckArtGreen, width: 1.5),
              ),
              child: Text(
                hiredLabel,
                style: const TextStyle(
                  color: AppTheme.truckArtGreen,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                ),
              ),
            )
          else
            ElevatedButton(
              onPressed: canAfford ? onHire : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.saffronOrange,
                disabledBackgroundColor: Colors.grey.shade300,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: canAfford ? 2 : 0,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.currency_rupee_rounded, size: 14, color: Colors.white),
                  Text(
                    GameNumberFormat.format(cost),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
