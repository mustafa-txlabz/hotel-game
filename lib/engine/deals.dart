/// Types of special Dhaba rewarded ad power-up deals.
enum DealType {
  /// 2x Movement speed for Owner and all workers for 90 seconds.
  staffTurbo,

  /// 2x Brewing & cooking rate for Chai Kettle and Paratha Tawa for 90 seconds.
  kitchenBoost,

  /// Customer arrival frequency doubled for 90 seconds.
  customerRush,

  /// Instant cash bonus deposited directly into wallet.
  instantCash,

  /// Autonomous Golden VIP Helper assisting for 120 seconds (2 minutes).
  vipHelper,
}

/// Represents a special Dhaba power-up deal granted via rewarded ad.
class DhabaDeal {
  final DealType type;
  final String title;
  final String description;
  final String iconEmoji;
  final int durationSeconds;
  final double cashReward;

  const DhabaDeal({
    required this.type,
    required this.title,
    required this.description,
    required this.iconEmoji,
    this.durationSeconds = 90,
    this.cashReward = 0.0,
  });

  /// Pool of random Dhaba deals offered to the player.
  static const List<DhabaDeal> defaultPool = [
    DhabaDeal(
      type: DealType.staffTurbo,
      title: '2X STAFF TURBO SPEED',
      description: 'Owner & helpers run 2x faster for 90 seconds!',
      iconEmoji: '⚡',
      durationSeconds: 90,
    ),
    DhabaDeal(
      type: DealType.kitchenBoost,
      title: '2X KITCHEN BOOST',
      description: 'Kettle & Tawa brew and cook at double speed for 90 seconds!',
      iconEmoji: '🔥',
      durationSeconds: 90,
    ),
    DhabaDeal(
      type: DealType.customerRush,
      title: 'CUSTOMER RUSH HOUR',
      description: 'Hungry customers arrive 2x faster for 90 seconds!',
      iconEmoji: '👥',
      durationSeconds: 90,
    ),
    DhabaDeal(
      type: DealType.instantCash,
      title: 'INSTANT CASH DROP',
      description: 'Direct ₹600 cash bonus straight into your wallet!',
      iconEmoji: '💰',
      durationSeconds: 0,
      cashReward: 600.0,
    ),
    DhabaDeal(
      type: DealType.vipHelper,
      title: 'GOLDEN VIP HELPER',
      description: 'Summons an autonomous elite turbo helper for 2 minutes!',
      iconEmoji: '👷',
      durationSeconds: 120,
    ),
  ];
}
