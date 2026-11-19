/// Data models and configurations for per-store progression, reputation XP,
/// and location missions/goals.
library;

enum GoalType {
  hireCashier,
  hireWorkers,
  unlockTables,
  upgradeKettle,
  reachReputation,
  earnRevenue,
}

/// An individual mission/goal for a dhaba location.
class StoreGoal {
  final String id;
  final String title;
  final String description;
  final GoalType type;
  final int targetValue;
  final int rewardXP;
  final String icon;

  const StoreGoal({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.targetValue,
    this.rewardXP = 50,
    this.icon = '🎯',
  });
}

/// Per-store progression configuration allowing unique target XP, customer flow rates,
/// queue capacities, and difficulty curves for every location.
class StoreProgressionConfig {
  final String storeId;
  final String storeName;
  final int targetReputationXP;
  final int happyTakeawayXP;
  final int happyDineInXP;
  final int sadCustomerXP;
  final int upgradeXP;
  final double baseSpawnInterval;
  final double minSpawnInterval;
  final int queueCapacity;
  final List<StoreGoal> goals;

  const StoreProgressionConfig({
    required this.storeId,
    required this.storeName,
    this.targetReputationXP = 1000,
    this.happyTakeawayXP = 2,
    this.happyDineInXP = 4,
    this.sadCustomerXP = -3,
    this.upgradeXP = 20,
    this.baseSpawnInterval = 4.0,
    this.minSpawnInterval = 1.8,
    this.queueCapacity = 8,
    this.goals = const [],
  });

  /// Store 1: Highway Kadak Dhaba (Starting Location)
  static const StoreProgressionConfig store1 = StoreProgressionConfig(
    storeId: 'store_1',
    storeName: 'Highway Kadak Dhaba',
    targetReputationXP: 1000,
    happyTakeawayXP: 2,
    happyDineInXP: 4,
    sadCustomerXP: -3,
    upgradeXP: 20,
    baseSpawnInterval: 4.0,
    minSpawnInterval: 1.8,
    queueCapacity: 8,
    goals: [
      StoreGoal(
        id: 'hire_cashier',
        title: 'Hire Cashier',
        description: 'Automate serving counter transactions',
        type: GoalType.hireCashier,
        targetValue: 1,
        rewardXP: 60,
        icon: '👨‍💼',
      ),
      StoreGoal(
        id: 'hire_workers_3',
        title: 'Hire 3 Workers',
        description: 'Assemble a 3-member runner & busboy crew',
        type: GoalType.hireWorkers,
        targetValue: 3,
        rewardXP: 70,
        icon: '🏃',
      ),
      StoreGoal(
        id: 'unlock_tables_2',
        title: 'Unlock 2 Dining Tables',
        description: 'Expand dine-in seating for bigger tips',
        type: GoalType.unlockTables,
        targetValue: 2,
        rewardXP: 60,
        icon: '🪑',
      ),
      StoreGoal(
        id: 'upgrade_kettle_5',
        title: 'Master Kadak Kettle',
        description: 'Upgrade chai brewing kettle to Level 5 (MAX)',
        type: GoalType.upgradeKettle,
        targetValue: 5,
        rewardXP: 80,
        icon: '☕',
      ),
      StoreGoal(
        id: 'reach_reputation_100',
        title: '100% Dhaba Reputation',
        description: 'Earn 1000 XP and become a 5-Star Dhaba Empire',
        type: GoalType.reachReputation,
        targetValue: 100,
        rewardXP: 100,
        icon: '⭐',
      ),
    ],
  );

  /// Store 2: City Food Street (Future Location - Scaled Difficulty)
  static const StoreProgressionConfig store2 = StoreProgressionConfig(
    storeId: 'store_2',
    storeName: 'City Food Street',
    targetReputationXP: 2500,
    happyTakeawayXP: 2,
    happyDineInXP: 4,
    sadCustomerXP: -4,
    upgradeXP: 30,
    baseSpawnInterval: 3.5,
    minSpawnInterval: 1.5,
    queueCapacity: 10,
    goals: [],
  );
}
