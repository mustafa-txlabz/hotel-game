/// Central game economy and balance configuration.
///
/// All tuning numbers, costs, multipliers, and business definitions
/// are stored here as typed constants.
class GameBalance {
  /// Base exponential cost growth rate for all businesses.
  static const double costGrowthRate = 1.13;

  /// Shohrat income bonus per point (3% additive).
  static const double shohratBonusPercent = 0.03;

  /// Minimum shohrat required to prestige.
  static const int minPrestigeShohrat = 5;

  /// Prestige formula denominator: floor(sqrt(runEarnings / 1e7)).
  static const double prestigeDivisor = 1e7;

  /// Tap bonus percentage of income per second.
  static const double tapIncomeMultiplier = 0.02;

  /// Offline earnings rate (50% of active income).
  static const double offlineEarningsRate = 0.5;

  /// Maximum offline earnings duration in seconds (8 hours).
  static const int maxOfflineSeconds = 8 * 3600;

  /// Minimum away seconds required to show offline earnings popup.
  static const int minOfflineSeconds = 60;
}

