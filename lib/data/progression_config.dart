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
  final double upgradeReputationDelta; // 0.0 (Reputation is driven 100% by customers)
  final double baseSpawnInterval;
  final double minSpawnInterval;
  final int queueCapacity;
  final List<StoreGoal> goals;

  const StoreProgressionConfig({
    required this.storeId,
    required this.storeName,
    this.customerReputationDelta = 0.2,
    this.sadCustomerReputationDelta = -0.2,
    this.upgradeReputationDelta = 0.0,
    this.baseSpawnInterval = 2.0,
    this.minSpawnInterval = 0.5,
    this.queueCapacity = 8,
    this.goals = const [],
  });

  /// Calculates dynamic customer spawn interval (in seconds) based on store reputation %.
  /// Breakpoints:
  /// - 0% Reputation:  2.0s
  /// - 25% Reputation: 1.5s
  /// - 50% Reputation: 1.0s
  /// - 75%-100% Rep:   0.5s
  double calculateSpawnInterval(double reputationPercent) {
    final r = reputationPercent.clamp(0.0, 100.0);
    if (r <= 75.0) {
      return 2.0 - (r / 75.0) * 1.5; // Linear 2.0s -> 1.5s -> 1.0s -> 0.5s
    } else {
      return 0.5; // 75% to 100% locked at 0.5s (Rush hour!)
    }
  }

  /// Store 1: Highway Kadak Dhaba (Starting Location)
  static const StoreProgressionConfig store1 = StoreProgressionConfig(
    storeId: 'store_1',
    storeName: 'Highway Kadak Dhaba',
    customerReputationDelta: 0.2,
    sadCustomerReputationDelta: -0.2,
    upgradeReputationDelta: 0.0,
    baseSpawnInterval: 2.0,
    minSpawnInterval: 0.5,
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
    upgradeReputationDelta: 0.0,
    baseSpawnInterval: 2.0,
    minSpawnInterval: 0.5,
    queueCapacity: 10,
    goals: [],
  );
}
