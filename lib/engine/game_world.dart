import 'dart:math' as math;

import 'customer_ai.dart';
import 'entities.dart';
import 'ground_pad.dart';
import 'stations.dart';

/// Pure Dart world simulation managing physical bounds, entities, stations, and collisions.
class GameWorld {
  // World arena dimensions in virtual points
  final double worldWidth;
  final double worldHeight;
  final double wallThickness;

  // Entities & Stations
  final PlayerEntity player;
  final ChaiStation chaiStation;
  final ServingCounter counter;
  final TrashBin trashBin;

  // Customer AI & Queue System (M3)
  final CustomerSystem customerSystem;

  // In-Place Machine Upgrade & Floor Unlock Pads (M4)
  final List<GroundPad> groundPads;
  final List<DiningTable> diningTables;

  // Flying cash bundles and floating text popups
  final List<CashBundleEntity> cashBundles;
  final List<FloatingTextEntity> floatingTexts;

  // Economy & currency (soft currency)
  double rupees;
  double lifetimeRupees;

  // Callbacks for sound & haptics
  void Function(ItemType item)? onItemPickedUp;
  void Function(ItemType item)? onItemDeposited;
  void Function(ItemType item)? onItemServed;
  void Function(double amount)? onCashCollected;
  void Function(double amount)? onCashPoured;
  void Function()? onItemDiscarded;

  GameWorld({
    this.worldWidth = 900.0,
    this.worldHeight = 1200.0,
    this.wallThickness = 32.0,
    double initialRupees = 0.0,
    ChaiStation? station,
    ServingCounter? servingCounter,
    TrashBin? trash,
    CustomerSystem? customers,
    List<GroundPad>? pads,
    List<DiningTable>? tables,
  }) : player = PlayerEntity(startPosition: Vector2(450.0, 600.0)),
       chaiStation = station ?? ChaiStation(position: Vector2(260.0, 260.0)),
       counter =
           servingCounter ?? ServingCounter(position: Vector2(450.0, 720.0)),
       trashBin = trash ?? TrashBin(position: Vector2(100.0, 460.0)),
       customerSystem =
           customers ??
           CustomerSystem(
             queue: CustomerQueue(headPosition: Vector2(450.0, 782.0)),
             entrancePosition: Vector2(450.0, 1165.0),
           ),
       cashBundles = [],
       floatingTexts = [],
       rupees = initialRupees,
       lifetimeRupees = initialRupees,
       diningTables =
           tables ??
           [
             DiningTable(
               id: 1,
               position: Vector2(200.0, 950.0),
               isUnlocked: false,
             ),
             DiningTable(
               id: 2,
               position: Vector2(700.0, 950.0),
               isUnlocked: false,
             ),
           ],
       groundPads = pads ?? [] {
    // Bind tables to customer system for dine-in seating
    customerSystem.diningTables = diningTables;

    // Forward customer served events to sound/haptic callback
    customerSystem.onCustomerServed = (customer, item) {
      onItemServed?.call(item);
    };

    // Initialize default ground pads if not supplied
    if (groundPads.isEmpty) {
      final kettlePad = GroundPad(
        id: 'kettle_upgrade',
        type: PadType.machineUpgrade,
        position: Vector2(375.0, 260.0),
        title: 'UPGRADE L2',
        totalCost: 50.0,
        currentLevel: 1,
        maxLevel: 5,
        costForLevel: (targetLevel) {
          switch (targetLevel) {
            case 2:
              return 50.0;
            case 3:
              return 100.0;
            case 4:
              return 180.0;
            case 5:
              return 300.0;
            default:
              return 50.0;
          }
        },
        titleForLevel: (targetLevel) => 'UPGRADE L$targetLevel',
        onLevelUp: (newLevel) {
          chaiStation.upgradeTo(newLevel);
        },
      );

      final table1Pad = GroundPad(
        id: 'table_1_unlock',
        type: PadType.floorUnlock,
        position: Vector2(200.0, 950.0),
        title: 'TABLE 1',
        totalCost: 80.0,
        onUnlocked: () {
          diningTables[0].isUnlocked = true;
        },
      );

      final table2Pad = GroundPad(
        id: 'table_2_unlock',
        type: PadType.floorUnlock,
        position: Vector2(700.0, 950.0),
        title: 'TABLE 2',
        totalCost: 120.0,
        onUnlocked: () {
          if (diningTables.length > 1) {
            diningTables[1].isUnlocked = true;
          }
        },
      );

      groundPads.addAll([kettlePad, table1Pad, table2Pad]);
    }
  }

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

    // 4. Solid collisions (kitchen kettle, serving counter, unlocked dining tables)
    _resolveBoxCollision(
      chaiStation.position,
      chaiStation.width,
      chaiStation.height,
    );
    _resolveBoxCollision(counter.position, counter.width, counter.height);
    for (final table in diningTables) {
      if (table.isUnlocked) {
        _resolveBoxCollision(table.position, table.width, table.height);
      }
    }

    // 5. Kitchen Pickup Zone detection (Chai Kettle)
    _checkKettlePickup();

    // 6. Food Deposit Zone detection (Left Section of Counter)
    _checkFoodDeposit();

    // 7. Cashier Presence check (Center Section of Counter)
    _checkCashierPresence();

    // 8. Customer AI, queue, patience, and cashier service transactions (M3)
    customerSystem.update(dt, counter);

    // 9. Cash Collection detection (Right Section of Counter)
    _checkCashCollection();

    // 10. Trash bin discard detection
    _checkTrashDiscard();

    // 11. Table Tip Collection & Dirty Tray Cleaning (M5)
    _checkTableCleaning();

    // 12. Ground Upgrade & Unlock Pads (M4)
    _checkGroundPads(dt);

    // 12. Flying cash bundles & absorption
    _updateCashBundles(dt);

    // 13. Floating text popups
    _updateFloatingTexts(dt);
  }

  void _checkGroundPads(double dt) {
    for (final pad in groundPads) {
      if (pad.isInside(player.position) && !pad.isCompleted) {
        final poured = pad.pourCash(rupees, dt);
        if (poured > 0.0) {
          rupees -= poured;
          onCashPoured?.call(poured);
        }
      }
    }
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

  void _checkKettlePickup() {
    if (player.isFull) return;

    if (chaiStation.isInsidePickupZone(player.position)) {
      if (chaiStation.tryTakeCup()) {
        player.addItem(ItemType.chai);
        onItemPickedUp?.call(ItemType.chai);
      }
    }
  }

  void _checkFoodDeposit() {
    if (player.carriedCount == 0) return;

    if (counter.isInsideFoodDepositZone(player.position) &&
        counter.canDepositFood()) {
      // Only deposit edible food items onto counter (never dirty trays!)
      final foodIndex = player.carriedItems.lastIndexWhere(
        (item) => item != ItemType.dirtyTray,
      );
      if (foodIndex != -1) {
        final foodItem = player.carriedItems[foodIndex];
        if (counter.addFoodItem(foodItem)) {
          player.carriedItems.removeAt(foodIndex);
          onItemDeposited?.call(foodItem);
        }
      }
    }
  }

  void _checkCashierPresence() {
    // Cashier presence check (Owner standing in center green circle)
    final isOwnerAtCashier = counter.isInsideCashierZone(player.position);
    counter.isCashierPresent = isOwnerAtCashier;
  }

  void _checkCashCollection() {
    if (counter.isInsideCashCollectionZone(player.position) &&
        counter.canCollectCash()) {
      counter.cashBundleCount--;
      counter.triggerCashCollect();

      // Launch a flying cash bundle from the right counter surface towards player
      final spawnX = counter.position.x + 85.0;
      final spawnY = counter.position.y;
      final bundle = CashBundleEntity(
        position: Vector2(spawnX, spawnY),
        value: 10.0,
      );
      bundle.isFlying = true;
      bundle.spawnBounceTimer = 0.0;
      cashBundles.add(bundle);
    }
  }

  void _checkTrashDiscard() {
    if (player.carriedCount == 0) return;

    if (trashBin.isInsideZone(player.position) && trashBin.canDiscard()) {
      // Prioritize discarding dirty trays first, then other items
      int discardIndex = player.carriedItems.lastIndexWhere(
        (item) => item == ItemType.dirtyTray,
      );
      if (discardIndex == -1) {
        discardIndex = player.carriedItems.length - 1;
      }

      final discarded = player.carriedItems.removeAt(discardIndex);
      trashBin.triggerDiscarded();
      onItemDiscarded?.call();

      floatingTexts.add(
        FloatingTextEntity(
          position: Vector2(trashBin.position.x, trashBin.position.y - 25.0),
          text: discarded == ItemType.dirtyTray ? 'TRASHED 🗑️' : 'DISCARDED',
        ),
      );
    }
  }

  void _checkTableCleaning() {
    for (final table in diningTables) {
      if (!table.isUnlocked) continue;

      if (table.isInsideCleanZone(player.position)) {
        // 1. Vacuum cash tips from any seats that have tips
        for (final seat in table.seats) {
          if (seat.cashTip > 0.0) {
            final tipValue = seat.cashTip;
            seat.cashTip = 0.0;

            final spawnPos = Vector2(seat.position.x, table.position.y);
            final bundle = CashBundleEntity(
              position: spawnPos,
              value: tipValue,
            );
            bundle.isFlying = true;
            bundle.spawnBounceTimer = 0.0;
            cashBundles.add(bundle);
          }
        }

        // 2. Pick up dirty trays from seats as long as player has room in carry stack
        for (final seat in table.seats) {
          if (seat.hasDirtyTray && !player.isFull) {
            player.addItem(ItemType.dirtyTray);
            seat.hasDirtyTray = false;
            onItemPickedUp?.call(ItemType.dirtyTray);

            floatingTexts.add(
              FloatingTextEntity(
                position: Vector2(seat.position.x, table.position.y - 20.0),
                text: 'CLEANED! ✨',
              ),
            );
          }
        }
      }
    }
  }

  void _updateCashBundles(double dt) {
    final collected = <CashBundleEntity>[];

    for (final bundle in cashBundles) {
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
