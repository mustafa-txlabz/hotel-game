/// Business configuration definition stored as pure constants.
class BusinessConfig {
  final int index;
  final String id;
  final String name;
  final double baseCost;
  final double baseIncome;

  const BusinessConfig({
    required this.index,
    required this.id,
    required this.name,
    required this.baseCost,
    required this.baseIncome,
  });
}

/// Central game economy and balance configuration.
///
/// All tuning numbers, costs, multipliers, and business definitions
/// are stored here as typed constants.
class GameBalance {
  /// Base exponential cost growth rate for all tiers (g = 1.13).
  static const double costGrowthRate = 1.13;

  /// Shohrat income bonus per point (3% additive).
  static const double shohratBonusPercent = 0.03;

  /// Minimum shohrat required to prestige.
  static const int minPrestigeShohrat = 5;

  /// Prestige formula denominator: floor(sqrt(runEarnings / 1e7)).
  static const double prestigeDivisor = 1e7;

  /// Tap base rupees (1.0).
  static const double tapBaseRupees = 1.0;

  /// Tap bonus percentage of income per second (2%).
  static const double tapIncomeMultiplier = 0.02;

  /// Max haptics per second (10 Hz).
  static const int maxHapticsPerSecond = 10;

  /// Game tick rate in Hz.
  static const double tickRateHz = 10.0;

  /// Offline earnings rate (50% of active income).
  static const double offlineEarningsRate = 0.5;

  /// Maximum offline earnings duration in seconds (8 hours).
  static const int maxOfflineSeconds = 8 * 3600;

  /// Minimum away seconds required to show offline earnings popup.
  static const int minOfflineSeconds = 60;

  /// Standard milestone thresholds where income doubles (x2 cumulative).
  static const List<int> standardMilestones = [25, 50, 100, 200, 300, 400, 500];

  /// Calculates total milestone multiplier for a given number of units owned.
  static double getMilestoneMultiplier(int owned) {
    if (owned < 25) return 1.0;
    int count = 0;
    for (final m in standardMilestones) {
      if (owned >= m) count++;
    }
    if (owned > 500) {
      count += (owned - 500) ~/ 100;
    }
    return (1 << count).toDouble();
  }

  /// All 10 tiers of businesses.
  static const List<BusinessConfig> allBusinesses = [
    BusinessConfig(
      index: 1,
      id: 'chai_thela',
      name: 'Chai Thela',
      baseCost: 10.0,
      baseIncome: 0.5,
    ),
    BusinessConfig(
      index: 2,
      id: 'paratha_stall',
      name: 'Paratha Stall',
      baseCost: 120.0,
      baseIncome: 6.0,
    ),
    BusinessConfig(
      index: 3,
      id: 'roadside_dhaba',
      name: 'Roadside Dhaba',
      baseCost: 1500.0,
      baseIncome: 70.0,
    ),
    BusinessConfig(
      index: 4,
      id: 'family_restaurant',
      name: 'Family Restaurant',
      baseCost: 20000.0,
      baseIncome: 900.0,
    ),
    BusinessConfig(
      index: 5,
      id: 'food_street',
      name: 'Food Street Franchise',
      baseCost: 300000.0,
      baseIncome: 12000.0,
    ),
    BusinessConfig(
      index: 6,
      id: 'packaging_factory',
      name: 'Chai Packaging Factory',
      baseCost: 5000000.0,
      baseIncome: 170000.0,
    ),
    BusinessConfig(
      index: 7,
      id: 'highway_hotel',
      name: 'Highway Hotel Chain',
      baseCost: 90000000.0,
      baseIncome: 2500000.0,
    ),
    BusinessConfig(
      index: 8,
      id: 'export_house',
      name: 'Tea Export House',
      baseCost: 1800000000.0,
      baseIncome: 40000000.0,
    ),
    BusinessConfig(
      index: 9,
      id: 'mall_court',
      name: 'Mall Food Court',
      baseCost: 40000000000.0,
      baseIncome: 700000000.0,
    ),
    BusinessConfig(
      index: 10,
      id: 'chai_empire_inc',
      name: 'Chai Empire Inc.',
      baseCost: 1000000000000.0,
      baseIncome: 15000000000.0,
    ),
  ];
}
