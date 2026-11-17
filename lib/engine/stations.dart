import 'dart:math' as math;

import 'entities.dart';

enum ItemType { chai, burger, samosa, dirtyTray }

/// Kitchen Chai Brewing Kettle station producing hot chai cups onto an output shelf.
class ChaiStation {
  final Vector2 position;
  final double width;
  final double height;

  // Pickup zone around the station (accessible from front, behind, left, or right)
  final Vector2 pickupZoneCenter;
  final double pickupZoneRadius;
  final double pickupReach;

  // Brewing properties
  double brewTime; // Seconds per cup
  double brewTimer;
  int shelfCapacity;
  int shelfCount;
  int level;
  final int maxLevel;

  // Transfer cooldown to make picking up items feel tactile (pop-pop-pop)
  double pickupInterval;
  double pickupTimer;

  ChaiStation({
    Vector2? position,
    this.width = 130.0,
    this.height = 70.0,
    this.brewTime = 1.0,
    this.shelfCapacity = 8,
    this.pickupInterval = 0.14,
    this.pickupReach = 55.0,
    this.level = 1,
    this.maxLevel = 5,
  }) : position = position ?? Vector2(240.0, 240.0),
       pickupZoneCenter = Vector2(
         (position?.x ?? 240.0),
         (position?.y ?? 240.0) + 60.0,
       ),
       pickupZoneRadius = 55.0,
       brewTimer = 0.0,
       shelfCount = 3, // Start with a few cups ready
       pickupTimer = 0.0;

  /// Upgrades brewing kettle capacity and preparation speed.
  void upgradeTo(int newLevel) {
    level = newLevel;
    shelfCapacity = 8 + (newLevel - 1) * 2; // 8, 10, 12, 14, 16
    brewTime = math.max(
      0.40,
      1.0 - (newLevel - 1) * 0.15,
    ); // 1.0s, 0.85s, 0.70s, 0.55s, 0.40s
  }

  double get brewProgress => (brewTimer / brewTime).clamp(0.0, 1.0);

  /// Progresses brewing timer and shelf inventory.
  void update(double dt) {
    if (dt <= 0.0) return;

    if (pickupTimer > 0.0) {
      pickupTimer -= dt;
    }

    if (shelfCount < shelfCapacity) {
      brewTimer += dt;
      while (brewTimer >= brewTime && shelfCount < shelfCapacity) {
        brewTimer -= brewTime;
        shelfCount++;
      }
      if (shelfCount >= shelfCapacity) {
        brewTimer = 0.0;
      }
    } else {
      brewTimer = 0.0; // Shelf is full
    }
  }

  /// Checks if character position is within pickup range anywhere around the machine
  /// (front, behind, left side, or right side).
  bool isInsidePickupZone(Vector2 characterPos) {
    final halfW = width / 2;
    final halfH = height / 2;
    final left = position.x - halfW;
    final right = position.x + halfW;
    final top = position.y - halfH;
    final bottom = position.y + halfH;

    final dx = math.max(
      0.0,
      math.max(left - characterPos.x, characterPos.x - right),
    );
    final dy = math.max(
      0.0,
      math.max(top - characterPos.y, characterPos.y - bottom),
    );
    final dist = math.sqrt(dx * dx + dy * dy);

    return dist <= pickupReach;
  }

  /// Attempts to take one chai cup from the shelf.
  bool tryTakeCup() {
    if (shelfCount > 0 && pickupTimer <= 0.0) {
      shelfCount--;
      pickupTimer = pickupInterval;
      return true;
    }
    return false;
  }
}

/// A single item tower on the counter holding only one type of item.
class CounterItemTower {
  final ItemType itemType;
  int count;
  final int maxPerTower;

  CounterItemTower({
    required this.itemType,
    this.count = 0,
    this.maxPerTower = 10,
  });

  bool get isFull => count >= maxPerTower;
  bool get isEmpty => count <= 0;
}

/// Enhanced Three-Part Front Serving Counter:
/// - Left Section: Food deposit zone & single-item towers (behind and left flank)
/// - Center Section: Cashier station (green zone) where Owner/Cashier must stand to serve
/// - Right Section: Money tower grid & collection zone (behind and right flank)
class ServingCounter {
  final Vector2 position;
  final double width;
  final double height;

  // 1. Left Section: Food Deposit
  final Vector2 foodDepositZoneCenter;
  final double foodDepositZoneRadius;
  final List<CounterItemTower> foodTowers;
  double depositTimer;
  final double depositInterval;

  // 2. Center Section: Cashier
  final Vector2 cashierZoneCenter;
  final double cashierZoneRadius;
  bool isCashierPresent;
  double serviceTimer;
  final double serviceInterval;

  // 3. Right Section: Money Towers & Cash Collection
  final Vector2 cashCollectionZoneCenter;
  final double cashCollectionZoneRadius;
  int cashBundleCount; // Number of cash bundles on counter
  double cashCollectTimer;
  final double cashCollectInterval;

  ServingCounter({
    Vector2? position,
    this.width = 300.0,
    this.height = 56.0,
    this.depositInterval = 0.14,
    this.serviceInterval = 0.32,
    this.cashCollectInterval = 0.08,
  }) : position = position ?? Vector2(450.0, 720.0),
       // Food deposit is behind the left portion of the counter
       foodDepositZoneCenter = Vector2(
         (position?.x ?? 450.0) - 90.0,
         (position?.y ?? 720.0) - 52.0,
       ),
       foodDepositZoneRadius = 46.0,
       foodTowers = [CounterItemTower(itemType: ItemType.chai, count: 0)],
       depositTimer = 0.0,

       // Cashier station is strictly behind the center of the counter
       cashierZoneCenter = Vector2(
         (position?.x ?? 450.0),
         (position?.y ?? 720.0) - 52.0,
       ),
       cashierZoneRadius = 44.0,
       isCashierPresent = false,
       serviceTimer = 0.0,

       // Cash collection is behind the right portion of the counter
       cashCollectionZoneCenter = Vector2(
         (position?.x ?? 450.0) + 90.0,
         (position?.y ?? 720.0) - 52.0,
       ),
       cashCollectionZoneRadius = 44.0,
       cashBundleCount = 0,
       cashCollectTimer = 0.0;

  int get totalFoodCount {
    int sum = 0;
    for (final tower in foodTowers) {
      sum += tower.count;
    }
    return sum;
  }

  void update(double dt) {
    if (depositTimer > 0.0) depositTimer -= dt;
    if (serviceTimer > 0.0) serviceTimer -= dt;
    if (cashCollectTimer > 0.0) cashCollectTimer -= dt;
  }

  // --- Strictly Non-Overlapping Zone Checks ---

  /// Food deposit: compact wrap around the left section of counter on top (behind),
  /// left flank, and bottom (front), stopping strictly before the center cashier zone.
  /// Hard partition: pos.x <= 396.0 (Cashier starts at >= 406.0)
  bool isInsideFoodDepositZone(Vector2 pos) {
    if (pos.x > 396.0) return false;

    final counterLeft = position.x - width / 2; // 300.0
    final leftBound = counterLeft - 35.0; // 265.0
    final rightBound = position.x - 54.0; // 396.0
    final topBound = position.y - height / 2 - 32.0; // 660.0
    final bottomBound = position.y + height / 2 + 32.0; // 780.0

    return pos.x >= leftBound &&
        pos.x <= rightBound &&
        pos.y >= topBound &&
        pos.y <= bottomBound;
  }

  /// Cashier station: comfortable enlarged circle strictly centered behind the counter.
  /// Radius 44px from (450, 668) covers x in [406, 494].
  bool isInsideCashierZone(Vector2 pos) {
    return pos.distanceTo(cashierZoneCenter) <= cashierZoneRadius;
  }

  /// Cash collection: compact wrap around the right section of counter on top (behind),
  /// right flank, and bottom (front), stopping strictly before the center cashier zone.
  /// Hard partition: pos.x >= 504.0 (Cashier ends at <= 494.0)
  bool isInsideCashCollectionZone(Vector2 pos) {
    if (pos.x < 504.0) return false;

    final counterRight = position.x + width / 2; // 600.0
    final leftBound = position.x + 54.0; // 504.0
    final rightBound = counterRight + 35.0; // 635.0
    final topBound = position.y - height / 2 - 32.0; // 660.0
    final bottomBound = position.y + height / 2 + 32.0; // 780.0

    return pos.x >= leftBound &&
        pos.x <= rightBound &&
        pos.y >= topBound &&
        pos.y <= bottomBound;
  }

  // --- Food Operations ---
  bool canDepositFood() => depositTimer <= 0.0;

  bool addFoodItem(ItemType item) {
    if (!canDepositFood()) return false;

    // Find existing non-full tower of the SAME item type
    for (final tower in foodTowers) {
      if (tower.itemType == item && !tower.isFull) {
        tower.count++;
        depositTimer = depositInterval;
        return true;
      }
    }

    // Otherwise create a new tower for this item type (up to max 4 towers on counter)
    if (foodTowers.length < 4) {
      foodTowers.add(CounterItemTower(itemType: item, count: 1));
      depositTimer = depositInterval;
      return true;
    }

    return false;
  }

  ItemType? takeFoodItem(ItemType desiredType) {
    for (int i = foodTowers.length - 1; i >= 0; i--) {
      final tower = foodTowers[i];
      if (tower.itemType == desiredType && tower.count > 0) {
        tower.count--;
        if (tower.count == 0 && foodTowers.length > 1) {
          foodTowers.removeAt(i);
        }
        return desiredType;
      }
    }
    return null;
  }

  bool canServe() =>
      isCashierPresent && serviceTimer <= 0.0 && totalFoodCount > 0;

  void triggerService() {
    serviceTimer = serviceInterval;
  }

  // --- Cash Operations ---
  void addCashBundle() {
    cashBundleCount++;
  }

  bool canCollectCash() => cashCollectTimer <= 0.0 && cashBundleCount > 0;

  void triggerCashCollect() {
    cashCollectTimer = cashCollectInterval;
  }
}

/// Trash Bin allowing player to discard unwanted carried items.
class TrashBin {
  final Vector2 position;
  final double radius;
  final double zoneRadius;
  double discardInterval;
  double discardTimer;

  TrashBin({
    Vector2? position,
    this.radius = 20.0,
    this.zoneRadius = 38.0,
    this.discardInterval = 0.12,
  }) : position = position ?? Vector2(100.0, 460.0),
       discardTimer = 0.0;

  void update(double dt) {
    if (discardTimer > 0.0) {
      discardTimer -= dt;
    }
  }

  bool isInsideZone(Vector2 pos) {
    return pos.distanceTo(position) <= zoneRadius;
  }

  bool canDiscard() => discardTimer <= 0.0;

  void triggerDiscarded() {
    discardTimer = discardInterval;
  }
}

/// A dining table where customers sit down to eat, leave tips, and leave dirty trays.
class DiningTable {
  final int id;
  final Vector2 position;
  final double width;
  final double height;
  bool isUnlocked;
  bool isOccupied;
  bool hasDirtyTray;
  double cashTip;

  DiningTable({
    required this.id,
    required this.position,
    this.width = 90.0,
    this.height = 64.0,
    this.isUnlocked = false,
    this.isOccupied = false,
    this.hasDirtyTray = false,
    this.cashTip = 0.0,
  });

  /// Table is available for a customer to sit and dine in.
  bool get isAvailable => isUnlocked && !isOccupied && !hasDirtyTray;

  /// Stool seat position where customer sits while dining (facing North towards table).
  Vector2 get seatPosition => Vector2(position.x, position.y + (height / 2) + 12.0);

  /// Checks if player is within reach to clean dirty trays or collect cash tip.
  bool isInsideCleanZone(Vector2 pos) {
    final halfW = width / 2;
    final halfH = height / 2;
    final left = position.x - halfW;
    final right = position.x + halfW;
    final top = position.y - halfH;
    final bottom = position.y + halfH;

    final dx = math.max(0.0, math.max(left - pos.x, pos.x - right));
    final dy = math.max(0.0, math.max(top - pos.y, pos.y - bottom));
    return math.sqrt(dx * dx + dy * dy) <= 45.0;
  }
}
