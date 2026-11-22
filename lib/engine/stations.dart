import 'dart:math' as math;

import '../data/balance.dart';
import 'entities.dart';

enum ItemType { chai, paratha, burger, samosa, dirtyTray }

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

/// Kitchen Tawa Paratha station producing hot crispy lachha parathas onto an output shelf.
class ParathaStation {
  final Vector2 position;
  final double width;
  final double height;
  bool isUnlocked;

  // Pickup zone around the station (accessible from front, behind, left, or right)
  final Vector2 pickupZoneCenter;
  final double pickupZoneRadius;
  final double pickupReach;

  // Cooking properties
  double cookTime;
  double cookTimer;
  int shelfCapacity;
  int shelfCount;
  int level;
  final int maxLevel;

  // Transfer cooldown for snappy tactile pickup
  double pickupInterval;
  double pickupTimer;

  ParathaStation({
    Vector2? position,
    this.width = 120.0,
    this.height = 70.0,
    this.isUnlocked = false,
    this.cookTime = GameBalance.parathaBaseCookTime,
    this.shelfCapacity = GameBalance.parathaBaseShelfCapacity,
    this.pickupInterval = 0.14,
    this.pickupReach = 55.0,
    this.level = 1,
    this.maxLevel = 5,
    int initialShelfCount = 0,
  }) : position = position ?? Vector2(510.0, 260.0),
       pickupZoneCenter = Vector2(
         (position?.x ?? 510.0),
         (position?.y ?? 260.0) + 60.0,
       ),
       pickupZoneRadius = 55.0,
       cookTimer = 0.0,
       shelfCount = initialShelfCount,
       pickupTimer = 0.0;

  /// Upgrades tawa capacity and cooking speed.
  void upgradeTo(int newLevel) {
    level = newLevel;
    shelfCapacity = 6 + (newLevel - 1) * 2; // 6, 8, 10, 12, 14
    cookTime = math.max(
      0.50,
      GameBalance.parathaBaseCookTime - (newLevel - 1) * 0.25,
    ); // 1.6s, 1.35s, 1.10s, 0.85s, 0.60s
  }

  double get cookProgress => (cookTimer / cookTime).clamp(0.0, 1.0);

  /// Progresses tawa cooking timer and shelf inventory.
  void update(double dt) {
    if (dt <= 0.0 || !isUnlocked) return;

    if (pickupTimer > 0.0) {
      pickupTimer -= dt;
    }

    if (shelfCount < shelfCapacity) {
      cookTimer += dt;
      while (cookTimer >= cookTime && shelfCount < shelfCapacity) {
        cookTimer -= cookTime;
        shelfCount++;
      }
      if (shelfCount >= shelfCapacity) {
        cookTimer = 0.0;
      }
    } else {
      cookTimer = 0.0;
    }
  }

  /// Checks if character position is within pickup range.
  bool isInsidePickupZone(Vector2 characterPos) {
    if (!isUnlocked) return false;
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

  /// Attempts to take one paratha plate from the shelf.
  bool tryTakeParatha() {
    if (isUnlocked && shelfCount > 0 && pickupTimer <= 0.0) {
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
  final int maxColumns;
  final int maxPerTower;
  double depositTimer;
  final double depositInterval;

  // 2. Center Section: Cashier
  final Vector2 cashierZoneCenter;
  final double cashierZoneRadius;
  bool isCashierPresent;
  double serviceTimer;
  double serviceInterval;

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
    this.serviceInterval = 0.0,
    this.cashCollectInterval = 0.08,
    this.maxColumns = 3,
    this.maxPerTower = 10,
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

  int get maxFoodCapacity => maxColumns * maxPerTower;
  bool get isFoodFull => totalFoodCount >= maxFoodCapacity;
  bool get hasFoodRoom => totalFoodCount < maxFoodCapacity;

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
    // Dirty trays must NEVER be deposited on the food counter!
    if (item == ItemType.dirtyTray) return false;
    if (!canDepositFood()) return false;
    if (isFoodFull) return false;

    // Find existing non-full tower of the SAME item type
    for (final tower in foodTowers) {
      if (tower.itemType == item && !tower.isFull) {
        tower.count++;
        depositTimer = depositInterval;
        return true;
      }
    }

    // Otherwise create a new tower for this item type (up to maxColumns)
    if (foodTowers.length < maxColumns) {
      foodTowers.add(
        CounterItemTower(
          itemType: item,
          count: 1,
          maxPerTower: maxPerTower,
        ),
      );
      depositTimer = depositInterval;
      return true;
    }

    return false;
  }

  bool hasFoodItem(ItemType desiredType) {
    for (final tower in foodTowers) {
      if (tower.itemType == desiredType && tower.count > 0) return true;
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

/// Represents an individual stool seat at a dining table.
class TableSeat {
  final int index;
  final Vector2 position;
  final double facingAngle;
  bool isOccupied;
  bool isSeated;
  bool hasDirtyTray;
  double cashTip;
  bool mealHasChai;
  bool mealHasParatha;

  TableSeat({
    required this.index,
    required this.position,
    required this.facingAngle,
    this.isOccupied = false,
    this.isSeated = false,
    this.hasDirtyTray = false,
    this.cashTip = 0.0,
    this.mealHasChai = true,
    this.mealHasParatha = false,
  });

  bool get isAvailable => !isOccupied && !hasDirtyTray;
}

/// A spacious Dhaba dining table accommodating up to 4 customers (2 on top side, 2 on bottom side).
class DiningTable {
  final int id;
  final Vector2 position;
  final double width;
  final double height;
  bool isUnlocked;
  final List<TableSeat> seats;

  DiningTable({
    required this.id,
    required this.position,
    this.width = 130.0,
    this.height = 68.0,
    this.isUnlocked = false,
    bool isOccupied = false,
    bool hasDirtyTray = false,
    double cashTip = 0.0,
  }) : seats = [] {
    final halfH = height / 2;
    // 4 seats: 2 on Top side (facing South math.pi/2), 2 on Bottom side (facing North -math.pi/2)
    seats.addAll([
      // Seat 0: Top-Left
      TableSeat(
        index: 0,
        position: Vector2(position.x - 30.0, position.y - halfH - 14.0),
        facingAngle: math.pi / 2,
      ),
      // Seat 1: Top-Right
      TableSeat(
        index: 1,
        position: Vector2(position.x + 30.0, position.y - halfH - 14.0),
        facingAngle: math.pi / 2,
      ),
      // Seat 2: Bottom-Left
      TableSeat(
        index: 2,
        position: Vector2(position.x - 30.0, position.y + halfH + 14.0),
        facingAngle: -math.pi / 2,
      ),
      // Seat 3: Bottom-Right
      TableSeat(
        index: 3,
        position: Vector2(position.x + 30.0, position.y + halfH + 14.0),
        facingAngle: -math.pi / 2,
      ),
    ]);

    if (isOccupied) {
      seats.first.isOccupied = true;
      seats.first.isSeated = true;
    }
    if (hasDirtyTray) {
      seats.first.hasDirtyTray = true;
    }
    if (cashTip > 0.0) {
      seats.first.cashTip = cashTip;
    }
  }

  int get maxSeats => 4;
  int get occupiedCount => seats.where((s) => s.isOccupied).length;
  int get dirtyCount => seats.where((s) => s.hasDirtyTray).length;

  /// Table is available if it is unlocked, not fully occupied, and has no dirty tray.
  bool get isAvailable => isUnlocked && !isFullyOccupied && !hasDirtyTray;

  /// Table is fully occupied when all seats are taken.
  bool get isFullyOccupied => occupiedCount >= maxSeats;

  /// Returns the first free, clean seat available for a new customer.
  TableSeat? get firstAvailableSeat =>
      isUnlocked ? seats.where((s) => s.isAvailable).firstOrNull : null;

  bool get hasDirtyTray => seats.any((s) => s.hasDirtyTray);
  set hasDirtyTray(bool value) {
    if (!value) {
      for (final s in seats) {
        s.hasDirtyTray = false;
      }
    } else {
      seats.first.hasDirtyTray = true;
    }
  }

  double get cashTip => seats.fold(0.0, (sum, s) => sum + s.cashTip);
  set cashTip(double value) {
    if (value == 0.0) {
      for (final s in seats) {
        s.cashTip = 0.0;
      }
    } else {
      seats.first.cashTip = value;
    }
  }

  bool get isOccupied => occupiedCount > 0;
  set isOccupied(bool value) {
    for (final s in seats) {
      s.isOccupied = value;
      s.isSeated = value;
    }
  }

  /// Default seat position (Bottom-Left seat)
  Vector2 get seatPosition => seats[2].position;

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

/// HR Desk station where Owner manages staff and upgrades (M6).
class HRDesk {
  final Vector2 position;
  final double width;
  final double height;
  final double zoneRadius;

  HRDesk({
    Vector2? position,
    this.width = 90.0,
    this.height = 60.0,
    this.zoneRadius = 60.0,
  }) : position = position ?? Vector2(750.0, 260.0);

  /// Interaction zone in front of the desk where player stands to open HR clipboard
  Vector2 get interactionZoneCenter => Vector2(position.x, position.y + 55.0);

  bool isInsideZone(Vector2 pos) {
    return interactionZoneCenter.distanceTo(pos) <= zoneRadius;
  }
}
