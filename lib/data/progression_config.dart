/// Data models and configurations for per-store progression, reputation percentage,
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
  final String icon;

  const StoreGoal({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.targetValue,
    this.icon = '🎯',
  });
}

/// Per-store progression configuration allowing unique customer flow rates,
/// queue capacities, and difficulty curves for every location.
class StoreProgressionConfig {
  final String storeId;
  final String storeName;
  final double customerReputationDelta; // e.g. +0.2% per customer
  final double sadCustomerReputationDelta; // e.g. -0.2% per sad customer
  final double upgradeReputationDelta; // e.g. +2.0% per upgrade/unlock
  final double baseSpawnInterval;
  final double minSpawnInterval;
  final int queueCapacity;
  final List<StoreGoal> goals;

  const StoreProgressionConfig({
    required this.storeId,
    required this.storeName,
    this.customerReputationDelta = 0.2,
    this.sadCustomerReputationDelta = -0.2,
    this.upgradeReputationDelta = 2.0,
    this.baseSpawnInterval = 3.0,
    this.minSpawnInterval = 1.0,
    this.queueCapacity = 8,
    this.goals = const [],
  });

  /// Calculates dynamic customer spawn interval (in seconds) based on store reputation %.
  /// Breakpoints:
  /// - 0% Reputation:  3.0s
  /// - 25% Reputation: 2.0s
  /// - 50% Reputation: 1.5s
  /// - 75%-100% Rep:   1.0s
  double calculateSpawnInterval(double reputationPercent) {
    final r = reputationPercent.clamp(0.0, 100.0);
    if (r <= 25.0) {
      final t = r / 25.0;
      return 3.0 - t * (3.0 - 2.0); // 3.0s -> 2.0s
    } else if (r <= 50.0) {
      final t = (r - 25.0) / 25.0;
      return 2.0 - t * (2.0 - 1.5); // 2.0s -> 1.5s
    } else if (r <= 75.0) {
      final t = (r - 50.0) / 25.0;
      return 1.5 - t * (1.5 - 1.0); // 1.5s -> 1.0s
    } else {
      return 1.0; // 75% to 100% -> 1.0s
    }
  }

  /// Store 1: Highway Kadak Dhaba (Starting Location)
  static const StoreProgressionConfig store1 = StoreProgressionConfig(
    storeId: 'store_1',
    storeName: 'Highway Kadak Dhaba',
    customerReputationDelta: 0.2,
    sadCustomerReputationDelta: -0.2,
    upgradeReputationDelta: 2.0,
    baseSpawnInterval: 3.0,
    minSpawnInterval: 1.0,
    queueCapacity: 8,
    goals: [
      StoreGoal(
        id: 'hire_cashier',
        title: 'Hire Cashier',
        description: 'Automate serving counter transactions',
        type: GoalType.hireCashier,
        targetValue: 1,
        icon: '👨‍💼',
      ),
      StoreGoal(
        id: 'hire_workers_3',
        title: 'Hire 3 Workers',
        description: 'Assemble a 3-member runner & busboy crew',
        type: GoalType.hireWorkers,
        targetValue: 3,
        icon: '🏃',
      ),
      StoreGoal(
        id: 'unlock_tables_2',
        title: 'Unlock 2 Dining Tables',
        description: 'Expand dine-in seating for bigger tips',
        type: GoalType.unlockTables,
        targetValue: 2,
        icon: '🪑',
      ),
      StoreGoal(
        id: 'upgrade_kettle_5',
        title: 'Master Kadak Kettle',
        description: 'Upgrade brewing kettle to Level 5 (MAX)',
        type: GoalType.upgradeKettle,
        targetValue: 5,
        icon: '☕',
      ),
      StoreGoal(
        id: 'reach_reputation_100',
        title: '100% Dhaba Reputation',
        description: 'Achieve 100% 5-Star Dhaba Empire status',
        type: GoalType.reachReputation,
        targetValue: 100,
        icon: '⭐',
      ),
    ],
  );

  /// Store 2: City Food Street (Future Location - Scaled Difficulty)
  static const StoreProgressionConfig store2 = StoreProgressionConfig(
    storeId: 'store_2',
    storeName: 'City Food Street',
    customerReputationDelta: 0.1, // Half increment for larger store
    sadCustomerReputationDelta: -0.15,
    upgradeReputationDelta: 1.5,
    baseSpawnInterval: 3.5,
    minSpawnInterval: 1.5,
    queueCapacity: 10,
    goals: [],
  );
}
