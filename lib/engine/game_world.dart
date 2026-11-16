import 'dart:math' as math;

import 'entities.dart';
import 'stations.dart';

/// Pure Dart world simulation managing physical bounds, entities, stations, and collisions.
class GameWorld {
  // World arena dimensions in virtual points
  final double worldWidth;
  final double worldHeight;
  final double wallThickness;

  // Magnet suction radius for collecting cash bundles
  final double cashMagnetRadius;

  // Entities & Stations
  final PlayerEntity player;
  final ChaiStation chaiStation;
  final ServingCounter counter;
  final TrashBin trashBin;

  // Active ground cash and floating text popups
  final List<CashBundleEntity> cashBundles;
  final List<FloatingTextEntity> floatingTexts;

  // Economy & currency (soft currency)
  double rupees;
  double lifetimeRupees;

  // Callbacks for sound & haptics
  void Function(ItemType item)? onItemPickedUp;
  void Function(ItemType item)? onItemServed;
  void Function(double amount)? onCashCollected;
  void Function()? onItemDiscarded;

  GameWorld({
    this.worldWidth = 900.0,
    this.worldHeight = 1200.0,
    this.wallThickness = 32.0,
    this.cashMagnetRadius = 85.0,
    double initialRupees = 0.0,
    ChaiStation? station,
    ServingCounter? servingCounter,
    TrashBin? trash,
  }) : player = PlayerEntity(startPosition: Vector2(450.0, 600.0)),
       chaiStation = station ?? ChaiStation(position: Vector2(260.0, 260.0)),
       counter =
           servingCounter ?? ServingCounter(position: Vector2(450.0, 720.0)),
       trashBin = trash ?? TrashBin(position: Vector2(100.0, 460.0)),
       cashBundles = [],
       floatingTexts = [],
       rupees = initialRupees,
       lifetimeRupees = initialRupees;

  /// Sets joystick input vector normalized (-1.0 to 1.0).
  void setJoystickInput(double dx, double dy) {
    final length = math.sqrt(dx * dx + dy * dy);
    if (length > 0.1) {
      final normX = dx / (length > 1.0 ? length : 1.0);
      final normY = dy / (length > 1.0 ? length : 1.0);
      player.velocity.x = normX * player.speed;
      player.velocity.y = normY * player.speed;
    } else {
      player.velocity.x = 0.0;
      player.velocity.y = 0.0;
    }
  }

  /// Progresses the world simulation by [dt] seconds.
  void tick(double dt) {
    if (dt <= 0.0) return;

    // 1. Update stations
    chaiStation.update(dt);
    counter.update(dt);
    trashBin.update(dt);

    // 2. Update player physics
    player.update(dt);

    // 3. Collision against perimeter boundary walls
    _clampPlayerToWorldBounds();

    // 4. Solid counter collisions (kitchen counter and serving counter)
    _resolveBoxCollision(
      chaiStation.position,
      chaiStation.width,
      chaiStation.height,
    );
    _resolveBoxCollision(counter.position, counter.width, counter.height);

    // 5. Item pickup zone detection (Chai Kettle)
    _checkItemPickup();

    // 6. Item serving delivery detection (Serving Counter)
    _checkItemServing();

    // 7. Trash bin discard detection
    _checkTrashDiscard();

    // 8. Cash magnet vacuum & collection
    _updateCashBundles(dt);

    // 9. Floating text popups
    _updateFloatingTexts(dt);
  }

  void _clampPlayerToWorldBounds() {
    final minX = wallThickness + player.radius;
    final maxX = worldWidth - wallThickness - player.radius;
    final minY = wallThickness + player.radius;
    final maxY = worldHeight - wallThickness - player.radius;

    if (player.position.x < minX) player.position.x = minX;
    if (player.position.x > maxX) player.position.x = maxX;
    if (player.position.y < minY) player.position.y = minY;
    if (player.position.y > maxY) player.position.y = maxY;
  }

  void _resolveBoxCollision(Vector2 boxCenter, double width, double height) {
    final halfW = width / 2;
    final halfH = height / 2;
    final left = boxCenter.x - halfW;
    final right = boxCenter.x + halfW;
    final top = boxCenter.y - halfH;
    final bottom = boxCenter.y + halfH;

    final closestX = player.position.x.clamp(left, right);
    final closestY = player.position.y.clamp(top, bottom);

    final dx = player.position.x - closestX;
    final dy = player.position.y - closestY;
    final distance = math.sqrt(dx * dx + dy * dy);

    if (distance < player.radius) {
      if (distance > 0.0001) {
        final push = player.radius - distance;
        player.position.x += (dx / distance) * push;
        player.position.y += (dy / distance) * push;
      } else {
        final distLeft = (player.position.x - left).abs();
        final distRight = (right - player.position.x).abs();
        final distTop = (player.position.y - top).abs();
        final distBottom = (bottom - player.position.y).abs();
        final minDist = math.min(
          math.min(distLeft, distRight),
          math.min(distTop, distBottom),
        );

        if (minDist == distBottom) {
          player.position.y = bottom + player.radius;
        } else if (minDist == distTop) {
          player.position.y = top - player.radius;
        } else if (minDist == distRight) {
          player.position.x = right + player.radius;
        } else {
          player.position.x = left - player.radius;
        }
      }
    }
  }

  void _checkItemPickup() {
    if (player.isFull) return;

    if (chaiStation.isInsidePickupZone(player.position)) {
      if (chaiStation.tryTakeCup()) {
        player.addItem(ItemType.chai);
        onItemPickedUp?.call(ItemType.chai);
      }
    }
  }

  void _checkItemServing() {
    if (player.carriedCount == 0) return;

    if (counter.isInsideStaffZone(player.position) && counter.canServe()) {
      final item = player.removeItem();
      if (item != null) {
        counter.triggerServed();

        // Spawn a cash bundle on the counter
        final scatterX = (cashBundles.length % 4) * 16.0 - 24.0;
        final scatterY = (cashBundles.length ~/ 4) * 12.0 - 10.0;
        final dropPos = Vector2(
          counter.cashDropPosition.x + scatterX,
          counter.cashDropPosition.y + scatterY,
        );

        cashBundles.add(CashBundleEntity(position: dropPos, value: 10.0));
        onItemServed?.call(item);
      }
    }
  }

  void _checkTrashDiscard() {
    if (player.carriedCount == 0) return;

    if (trashBin.isInsideZone(player.position) && trashBin.canDiscard()) {
      final discarded = player.removeItem();
      if (discarded != null) {
        trashBin.triggerDiscarded();
        onItemDiscarded?.call();
      }
    }
  }

  void _updateCashBundles(double dt) {
    final collected = <CashBundleEntity>[];

    for (final bundle in cashBundles) {
      // Activate vacuum magnet when near player
      final dist = bundle.position.distanceTo(player.position);
      if (dist <= cashMagnetRadius) {
        bundle.isFlying = true;
      }

      if (bundle.updateTowards(player.position, dt)) {
        collected.add(bundle);
        rupees += bundle.value;
        lifetimeRupees += bundle.value;

        // Spawn floating +Rs popup
        floatingTexts.add(
          FloatingTextEntity(
            position: Vector2(player.position.x, player.position.y - 25.0),
            text: '+Rs ${bundle.value.toInt()}',
          ),
        );

        onCashCollected?.call(bundle.value);
      }
    }

    cashBundles.removeWhere((b) => collected.contains(b));
  }

  void _updateFloatingTexts(double dt) {
    for (final ft in floatingTexts) {
      ft.update(dt);
    }
    floatingTexts.removeWhere((ft) => ft.isExpired);
  }
}
