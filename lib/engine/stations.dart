import 'entities.dart';

enum ItemType { chai, burger }

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

/// Front Serving Counter where player/workers deliver food to drop cash bundles.
class ServingCounter {
  final Vector2 position;
  final double width;
  final double height;

  // Delivery drop zone behind counter where staff stands
  final Vector2 staffDropZoneCenter;
  final double staffDropZoneRadius;

  // Location where cash piles drop
  final Vector2 cashDropPosition;

  // Delivery interval cooldown
  double serveInterval;
  double serveTimer;

  ServingCounter({
    Vector2? position,
    this.width = 240.0,
    this.height = 54.0,
    this.serveInterval = 0.16,
  }) : position = position ?? Vector2(450.0, 720.0),
       staffDropZoneCenter = Vector2(
         (position?.x ?? 450.0),
         (position?.y ?? 720.0) - 56.0,
       ),
       staffDropZoneRadius = 46.0,
       cashDropPosition = Vector2(
         (position?.x ?? 450.0) - 70.0,
         (position?.y ?? 720.0) - 56.0,
       ),
       serveTimer = 0.0;

  void update(double dt) {
    if (serveTimer > 0.0) {
      serveTimer -= dt;
    }
  }

  bool isInsideStaffZone(Vector2 pos) {
    return pos.distanceTo(staffDropZoneCenter) <= staffDropZoneRadius;
  }

  bool canServe() => serveTimer <= 0.0;

  void triggerServed() {
    serveTimer = serveInterval;
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
