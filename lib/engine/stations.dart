import 'entities.dart';

enum ItemType { chai, burger, samosa }

/// Kitchen Chai Brewing Kettle station producing hot chai cups onto an output shelf.
class ChaiStation {
  final Vector2 position;
  final double width;
  final double height;

  // Pickup zone in front of the counter
  final Vector2 pickupZoneCenter;
  final double pickupZoneRadius;

  // Brewing properties
  double brewTime; // Seconds per cup
  double brewTimer;
  int shelfCapacity;
  int shelfCount;

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
  }) : position = position ?? Vector2(240.0, 240.0),
       pickupZoneCenter = Vector2(
         (position?.x ?? 240.0),
         (position?.y ?? 240.0) + 72.0,
       ),
       pickupZoneRadius = 45.0,
       brewTimer = 0.0,
       shelfCount = 3, // Start with a few cups ready
       pickupTimer = 0.0;

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

  /// Checks if character position is within the pickup zone.
  bool isInsidePickupZone(Vector2 characterPos) {
    return characterPos.distanceTo(pickupZoneCenter) <= pickupZoneRadius;
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
/// - Left Section: Food deposit zone & single-item towers
/// - Center Section: Cashier station (green zone) where Owner/Cashier must stand to serve
/// - Right Section: Money tower grid & collection zone
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
         (position?.x ?? 450.0) - 85.0,
         (position?.y ?? 720.0) - 52.0,
       ),
       foodDepositZoneRadius = 40.0,
       foodTowers = [CounterItemTower(itemType: ItemType.chai, count: 0)],
       depositTimer = 0.0,

       // Cashier station is behind the center of the counter
       cashierZoneCenter = Vector2(
         (position?.x ?? 450.0),
         (position?.y ?? 720.0) - 52.0,
       ),
       cashierZoneRadius = 36.0,
       isCashierPresent = false,
       serviceTimer = 0.0,

       // Cash collection is behind/around the right portion of the counter
       cashCollectionZoneCenter = Vector2(
         (position?.x ?? 450.0) + 85.0,
         (position?.y ?? 720.0) - 52.0,
       ),
       cashCollectionZoneRadius = 42.0,
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

  // --- Zone checks ---
  bool isInsideFoodDepositZone(Vector2 pos) {
    return pos.distanceTo(foodDepositZoneCenter) <= foodDepositZoneRadius;
  }

  bool isInsideCashierZone(Vector2 pos) {
    return pos.distanceTo(cashierZoneCenter) <= cashierZoneRadius;
  }

  bool isInsideCashCollectionZone(Vector2 pos) {
    return pos.distanceTo(cashCollectionZoneCenter) <= cashCollectionZoneRadius;
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
