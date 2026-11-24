/// Catalog of Dhaba Deals and Power-Ups.
///
/// NOTE:
/// This file holds the catalog specifications for:
/// 1. Ground Deal Pad (Special / Surprise Events)
/// 2. Reward Center Store (On-Demand Utility Deals via 1 Rewarded Ad OR Gems)
/// 3. VVIP Customer Economy (Gems reward and bulk orders)
///
/// DO NOT integrate into active gameplay until VVIP Customer mechanics are completed.
library;

enum DealAccessType {
  /// Appears only on the interactive Ground Deal Pad (Surprise Event)
  groundPadOnly,

  /// Available on-demand in the Reward Center via 1 Rewarded Ad OR Gems
  rewardCenterStore,
}

class CatalogDealItem {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final DealAccessType accessType;
  final int durationSeconds;
  final int gemsCost;
  final double speedMultiplier;
  final double earningMultiplier;
  final int extraCapacity;

  const CatalogDealItem({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.accessType,
    this.durationSeconds = 60,
    this.gemsCost = 2,
    this.speedMultiplier = 1.0,
    this.earningMultiplier = 1.0,
    this.extraCapacity = 0,
  });
}

class DealsCatalog {
  DealsCatalog._();

  // ===========================================================================
  // 1. GROUND DEAL PAD (SPECIAL / RARE SURPRISE DEALS)
  // ===========================================================================
  static const List<CatalogDealItem> groundPadDeals = [
    CatalogDealItem(
      id: 'ultra_dhaba_rush',
      title: 'ULTRA DHABA RUSH',
      description:
          'Everything 2x for 90s: 2x kitchen cooking, 2x staff speed & 2x customer flow!',
      emoji: '🚀',
      accessType: DealAccessType.groundPadOnly,
      durationSeconds: 90,
      speedMultiplier: 2.0,
      earningMultiplier: 1.0,
    ),
    CatalogDealItem(
      id: 'extreme_customer_rush',
      title: 'EXTREME CUSTOMER RUSH',
      description:
          'Hungry customer storm! Rapid customer arrivals every ~0.5s for 90s!',
      emoji: '👥',
      accessType: DealAccessType.groundPadOnly,
      durationSeconds: 90,
    ),
    CatalogDealItem(
      id: 'vip_customer_convoy',
      title: 'VVIP CONVOY INCOMING',
      description:
          'Guaranteed VVIP luxury car arrival with massive bulk order for huge Gems!',
      emoji: '🚗',
      accessType: DealAccessType.groundPadOnly,
      durationSeconds: 0,
    ),
  ];

  // ===========================================================================
  // 2. REWARD CENTER / STORE DEALS (ON-DEMAND: 1 AD OR GEMS)
  // ===========================================================================
  /// Default cooldown in seconds after any store deal is purchased (2 minutes).
  static const double storeDealCooldownSeconds = 120.0;

  static const List<CatalogDealItem> rewardStoreDeals = [
    CatalogDealItem(
      id: 'store_staff_speed',
      title: '1.5X STAFF SPEED',
      description: 'Owner and all helpers run 1.5x faster for 60 seconds.',
      emoji: '⚡',
      accessType: DealAccessType.rewardCenterStore,
      durationSeconds: 60,
      gemsCost: 2,
      speedMultiplier: 1.5,
    ),
    CatalogDealItem(
      id: 'store_double_earnings',
      title: '2X EARNINGS BOOST',
      description:
          'Double revenue! Every single rupee earned is doubled (2x) for 60 seconds.',
      emoji: '💰',
      accessType: DealAccessType.rewardCenterStore,
      durationSeconds: 60,
      gemsCost: 3,
      earningMultiplier: 2.0,
    ),
    CatalogDealItem(
      id: 'store_permanent_worker',
      title: 'EXTRA WORKER CONTRACT',
      description:
          'Hire an extra permanent helper crew member via 1 Ad or Gems.',
      emoji: '👷',
      accessType: DealAccessType.rewardCenterStore,
      durationSeconds: 0,
      gemsCost: 5,
    ),
    CatalogDealItem(
      id: 'store_worker_capacity',
      title: '+2 WORKER CAPACITY',
      description:
          'All workers can carry +2 extra items above their head for 60 seconds.',
      emoji: '📦',
      accessType: DealAccessType.rewardCenterStore,
      durationSeconds: 60,
      gemsCost: 2,
      extraCapacity: 2,
    ),
  ];
}
