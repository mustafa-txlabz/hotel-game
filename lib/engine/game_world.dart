import 'dart:math' as math;

import '../data/balance.dart';
import '../data/progression_config.dart';
import 'customer_ai.dart';
import 'entities.dart';
import 'ground_pad.dart';
import 'staff_ai.dart';
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

  // HR Desk Station & Staff Management (M6)
  final HRDesk hrDesk;
  final List<StaffEntity> staff;
  int nextStaffId;

  // Upgrades Levels
  int playerSpeedLevel;
  int playerCapacityLevel;
  int workerSpeedLevel;
  int workerCapacityLevel;

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

  // Store Progression & Reputation System (M6.1)
  final StoreProgressionConfig progressionConfig;
  double _reputationPercent;
  double get reputationPercent => _reputationPercent;
  set reputationPercent(double value) {
    _reputationPercent = value.clamp(0.0, 100.0);
    if (_reputationPercent >= 100.0) {
      isReputationLocked100 = true;
    }
    _updateSpawnInterval();
    checkMissions();
  }
  bool isReputationLocked100;
  final Set<String> completedMissionIds;

  // Automatic Sliding Double Doors (Physical Animated Entrance)
  double doorOpenFactor = 0.0;

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
    double initialReputationPercent = 0.0,
    bool initialReputationLocked100 = false,
    Set<String>? initialCompletedMissions,
    StoreProgressionConfig? config,
    ChaiStation? station,
    ServingCounter? servingCounter,
    TrashBin? trash,
    CustomerSystem? customers,
    List<GroundPad>? pads,
    List<DiningTable>? tables,
    HRDesk? hr,
    List<StaffEntity>? staffMembers,
  }) : progressionConfig = config ?? StoreProgressionConfig.store1,
       _reputationPercent = initialReputationPercent,
       isReputationLocked100 = initialReputationLocked100,
       completedMissionIds = initialCompletedMissions ?? <String>{},
       player = PlayerEntity(startPosition: Vector2(450.0, 600.0)),
       chaiStation = station ?? ChaiStation(position: Vector2(260.0, 260.0)),
       counter =
           servingCounter ?? ServingCounter(position: Vector2(450.0, 720.0)),
       trashBin = trash ?? TrashBin(position: Vector2(100.0, 460.0)),
       customerSystem =
           customers ??
           CustomerSystem(
             queue: CustomerQueue(
               headPosition: Vector2(450.0, 782.0),
               maxCapacity: (config ?? StoreProgressionConfig.store1).queueCapacity,
             ),
              entrancePosition: Vector2(450.0, 1245.0),
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
       groundPads = pads ?? [],
       hrDesk = hr ?? HRDesk(position: Vector2(750.0, 260.0)),
       staff = staffMembers ?? [],
       nextStaffId = 1,
       playerSpeedLevel = 1,
       playerCapacityLevel = 1,
       workerSpeedLevel = 1,
       workerCapacityLevel = 1 {
    // Apply initial upgrade stats to player
    player.speed = GameBalance.playerSpeedLevels[playerSpeedLevel - 1];
    player.carryCapacity =
        GameBalance.playerCapacityLevels[playerCapacityLevel - 1];

    // Configure initial customer spawn interval based on current reputation
    _updateSpawnInterval();

    // Bind tables to customer system for dine-in seating
    customerSystem.diningTables = diningTables;

    // Forward customer served events to sound/haptic callback and reputation
    customerSystem.onCustomerServed = (customer, item) {
      onItemServed?.call(item);
      addReputationPercent(progressionConfig.customerReputationDelta);
    };

    customerSystem.onCustomerLeftUnhappy = (customer) {
      addReputationPercent(progressionConfig.sadCustomerReputationDelta);
      floatingTexts.add(
        FloatingTextEntity(
          position: Vector2(customer.position.x, customer.position.y - 35.0),
          text: '${progressionConfig.sadCustomerReputationDelta.toStringAsFixed(1)}% 💔',
        ),
      );
    };

    customerSystem.onCustomerTableTimeout = (customer) {
      // Customer waited 2.5s and no table was available: refund money and throw away chai
      final refundAmount = GameBalance.chaiPrice * customer.receivedCount;
      rupees = math.max(0.0, rupees - refundAmount);

      floatingTexts.add(
        FloatingTextEntity(
          position: Vector2(customer.position.x, customer.position.y - 45.0),
          text: '-Rs ${refundAmount.toInt()} 💸',
        ),
      );
      floatingTexts.add(
        FloatingTextEntity(
          position: Vector2(customer.position.x, customer.position.y - 65.0),
          text: 'NO TABLE! ☕💥',
        ),
      );
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
          checkMissions();
        },
      );

      final cashierPad = GroundPad(
        id: 'hire_cashier',
        type: PadType.floorUnlock,
        position: Vector2(560.0, 580.0),
        title: 'CASHIER',
        totalCost: GameBalance.hireCashierCost,
        onUnlocked: () {
          hireCashier(free: true);
        },
      );

      final helperPad = GroundPad(
        id: 'hire_helper',
        type: PadType.floorUnlock,
        position: Vector2(660.0, 480.0),
        title: 'WORKER',
        totalCost: GameBalance.hireHelperBaseCost,
        onUnlocked: () {
          hireHelper(free: true);
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
          checkMissions();
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
          checkMissions();
        },
      );

      groundPads.addAll([kettlePad, cashierPad, helperPad, table1Pad, table2Pad]);
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

    // 2.5 Automatic Sliding Door proximity detection (door center: 450, 1184)
    final doorCenter = Vector2(worldWidth / 2, worldHeight - wallThickness / 2);
    const doorDetectionRadius = 110.0;

    bool isSomeoneNearDoor = false;
    if (player.position.distanceTo(doorCenter) < doorDetectionRadius) {
      isSomeoneNearDoor = true;
    } else if (staff.any((s) => s.position.distanceTo(doorCenter) < doorDetectionRadius)) {
      isSomeoneNearDoor = true;
    } else if (customerSystem.activeCustomers.any(
        (c) => c.position.distanceTo(doorCenter) < doorDetectionRadius)) {
      isSomeoneNearDoor = true;
    }

    final targetDoorFactor = isSomeoneNearDoor ? 1.0 : 0.0;
    final lerpSpeed = isSomeoneNearDoor ? 8.0 : 4.5;
    doorOpenFactor +=
        (targetDoorFactor - doorOpenFactor) * (dt * lerpSpeed).clamp(0.0, 1.0);
    doorOpenFactor = doorOpenFactor.clamp(0.0, 1.0);

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

    // 8. Staff AI Updates (Cashier & Helpers) (M6)
    for (final member in staff) {
      if (member.role == StaffRole.helper || member.role == StaffRole.chotu) {
        _updateHelperAI(member, dt);
        _resolveStaffCollisions(member);
      }
    }

    // 9. Customer AI, queue, patience, and cashier service transactions (M3)
    customerSystem.update(dt, counter);

    // 10. Cash Collection detection (Right Section of Counter)
    _checkCashCollection();

    // 11. Trash bin discard detection
    _checkTrashDiscard();

    // 12. Table Tip Collection & Dirty Tray Cleaning (M5)
    _checkTableCleaning();

    // 13. Ground Upgrade & Unlock Pads (M4 & M6)
    _checkGroundPads(dt);

    // 14. Flying cash bundles & absorption
    _updateCashBundles(dt);

    // 15. Floating text popups
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

    // South doorway opening (x: 360 to 540)
    const doorWidth = 180.0;
    final doorLeft = (worldWidth - doorWidth) / 2;
    final doorRight = doorLeft + doorWidth;
    final isAtDoorway = player.position.x >= doorLeft + player.radius &&
        player.position.x <= doorRight - player.radius;

    // Check outside state transitions
    if (!player.isOutside) {
      if (isAtDoorway && doorOpenFactor > 0.15 && player.position.y >= worldHeight) {
        player.isOutside = true;
      }
    } else {
      if (isAtDoorway && player.position.y <= maxY) {
        player.isOutside = false;
      }
    }

    if (player.isOutside) {
      // OUTSIDE ON SIDEWALK
      // 1. South road curb: stops player from walking onto the road
      const curbLimitY = 1275.0;
      if (player.position.y > curbLimitY - player.radius) {
        player.position.y = curbLimitY - player.radius;
      }

      // 2. North boundary on sidewalk: outside of brick wall blocks player except at doorway
      if (!isAtDoorway) {
        final outerWallY = worldHeight + player.radius;
        if (player.position.y < outerWallY) {
          player.position.y = outerWallY;
        }
      }

      // 3. Horizontal bounds on sidewalk
      final sidewalkMinX = 40.0 + player.radius;
      final sidewalkMaxX = worldWidth - 40.0 - player.radius;
      if (player.position.x < sidewalkMinX) player.position.x = sidewalkMinX;
      if (player.position.x > sidewalkMaxX) player.position.x = sidewalkMaxX;
    } else {
      // INSIDE THE SHOP (y < worldHeight)
      // Top wall
      if (player.position.y < minY) player.position.y = minY;

      // Left and Right walls
      if (player.position.x < minX) player.position.x = minX;
      if (player.position.x > maxX) player.position.x = maxX;

      // South wall: doorway allows passing through when door is open.
      // Brick walls stop player at maxY (1150.0).
      if (!isAtDoorway || doorOpenFactor <= 0.15) {
        if (player.position.y > maxY) player.position.y = maxY;
      }
    }
  }

  void _resolveEntityBoxCollision(
    Vector2 entityPos,
    double entityRadius,
    Vector2 boxCenter,
    double width,
    double height,
  ) {
    final halfW = width / 2;
    final halfH = height / 2;
    final left = boxCenter.x - halfW;
    final right = boxCenter.x + halfW;
    final top = boxCenter.y - halfH;
    final bottom = boxCenter.y + halfH;

    final closestX = entityPos.x.clamp(left, right);
    final closestY = entityPos.y.clamp(top, bottom);

    final dx = entityPos.x - closestX;
    final dy = entityPos.y - closestY;
    final distance = math.sqrt(dx * dx + dy * dy);

    if (distance < entityRadius) {
      if (distance > 0.0001) {
        final push = entityRadius - distance;
        entityPos.x += (dx / distance) * push;
        entityPos.y += (dy / distance) * push;
      } else {
        final distLeft = (entityPos.x - left).abs();
        final distRight = (right - entityPos.x).abs();
        final distTop = (entityPos.y - top).abs();
        final distBottom = (bottom - entityPos.y).abs();
        final minDist = math.min(
          math.min(distLeft, distRight),
          math.min(distTop, distBottom),
        );

        if (minDist == distBottom) {
          entityPos.y = bottom + entityRadius;
        } else if (minDist == distTop) {
          entityPos.y = top - entityRadius;
        } else if (minDist == distRight) {
          entityPos.x = right + entityRadius;
        } else {
          entityPos.x = left - entityRadius;
        }
      }
    }
  }

  void _resolveBoxCollision(Vector2 boxCenter, double width, double height) {
    _resolveEntityBoxCollision(
      player.position,
      player.radius,
      boxCenter,
      width,
      height,
    );
  }

  void _resolveStaffCollisions(StaffEntity staffMember) {
    // 1. Boundary walls
    final minX = wallThickness + staffMember.radius;
    final maxX = worldWidth - wallThickness - staffMember.radius;
    final minY = wallThickness + staffMember.radius;
    final maxY = worldHeight - wallThickness - staffMember.radius;

    if (staffMember.position.x < minX) staffMember.position.x = minX;
    if (staffMember.position.x > maxX) staffMember.position.x = maxX;
    if (staffMember.position.y < minY) staffMember.position.y = minY;
    if (staffMember.position.y > maxY) staffMember.position.y = maxY;

    // 2. Kitchen machines (Chai Kettle)
    _resolveEntityBoxCollision(
      staffMember.position,
      staffMember.radius,
      chaiStation.position,
      chaiStation.width,
      chaiStation.height,
    );

    // 3. Serving Counter (solid for workers)
    _resolveEntityBoxCollision(
      staffMember.position,
      staffMember.radius,
      counter.position,
      counter.width,
      counter.height,
    );

    // 4. Dining Tables (solid for workers when unlocked)
    for (final table in diningTables) {
      if (table.isUnlocked) {
        _resolveEntityBoxCollision(
          staffMember.position,
          staffMember.radius,
          table.position,
          table.width,
          table.height,
        );
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
    // Cashier presence check: Owner standing in center green circle OR hired Cashier on duty
    final isOwnerAtCashier = counter.isInsideCashierZone(player.position);
    counter.isCashierPresent = hasCashier || isOwnerAtCashier;
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
        checkMissions();
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

  // --- Staff & HR Upgrades Methods (M6) ---

  bool get hasCashier => staff.any((s) => s.role == StaffRole.cashier);
  int get helperCount => staff
      .where((s) => s.role == StaffRole.helper || s.role == StaffRole.chotu)
      .length;
  int get workerCount => helperCount;
  int get chotuCount => helperCount;

  double get currentWorkerSpeed =>
      GameBalance.workerSpeedLevels[workerSpeedLevel - 1];
  int get currentWorkerCapacity =>
      GameBalance.workerCapacityLevels[workerCapacityLevel - 1];

  bool hireCashier({bool free = false}) {
    if (hasCashier) return false;
    if (!free && rupees < GameBalance.hireCashierCost) return false;
    if (!free) rupees -= GameBalance.hireCashierCost;

    final cashier = StaffEntity(
      id: nextStaffId++,
      name: 'Cashier',
      role: StaffRole.cashier,
      startPosition: counter.cashierZoneCenter,
    );
    cashier.angle = math.pi / 2; // Facing South towards customers
    staff.add(cashier);
    counter.isCashierPresent = true;

    // Complete cashier ground pad if present
    for (final pad in groundPads) {
      if (pad.id == 'hire_cashier' && !pad.isCompleted) {
        pad.remainingCost = 0.0;
        pad.isCompleted = true;
      }
    }

    floatingTexts.add(
      FloatingTextEntity(
        position: Vector2(
          counter.cashierZoneCenter.x,
          counter.cashierZoneCenter.y - 25.0,
        ),
        text: 'CASHIER HIRED! 👔',
      ),
    );
    checkMissions();
    return true;
  }

  int get maxWorkers => GameBalance.maxWorkersLevel1;
  bool get canHireWorker => workerCount < maxWorkers;
  bool get canHireHelper => canHireWorker;
  bool get canHireChotu => canHireWorker;

  double get nextHelperCost =>
      GameBalance.hireHelperBaseCost *
      math.pow(GameBalance.hireHelperCostMultiplier, helperCount);
  double get nextChotuCost => nextHelperCost;
  double get nextWorkerCost => nextHelperCost;

  bool hireWorker({bool free = false}) => hireHelper(free: free);

  bool hireHelper({bool free = false}) {
    if (!canHireWorker) return false;
    final cost = nextHelperCost;
    if (!free && rupees < cost) return false;
    if (!free) rupees -= cost;

    // Alternate duties: 1st is Runner (Chai restock), 2nd is Busboy (table cleaning), etc.
    final duty = (helperCount % 2 == 0) ? HelperDuty.runner : HelperDuty.busboy;
    final startPos = duty == HelperDuty.runner
        ? Vector2(chaiStation.pickupZoneCenter.x, chaiStation.pickupZoneCenter.y + 12.0)
        : Vector2(450.0, 880.0);

    final helper = StaffEntity(
      id: nextStaffId++,
      name: 'Worker ${helperCount + 1}',
      role: StaffRole.helper,
      startPosition: startPos,
      speed: currentWorkerSpeed,
      carryCapacity: currentWorkerCapacity,
      duty: duty,
    );
    staff.add(helper);

    // If first helper and floor pad exists, complete it
    if (helperCount == 1) {
      for (final pad in groundPads) {
        if ((pad.id == 'hire_helper' || pad.id == 'hire_chotu') && !pad.isCompleted) {
          pad.remainingCost = 0.0;
          pad.isCompleted = true;
        }
      }
    }

    floatingTexts.add(
      FloatingTextEntity(
        position: Vector2(helper.position.x, helper.position.y - 25.0),
        text: 'WORKER HIRED! 🏃',
      ),
    );
    checkMissions();
    return true;
  }

  bool hireChotu({bool free = false}) => hireHelper(free: free);

  bool get canUpgradePlayerSpeed =>
      playerSpeedLevel < GameBalance.playerSpeedLevels.length &&
      rupees >= GameBalance.playerSpeedUpgradeCosts[playerSpeedLevel - 1];

  double? get playerSpeedUpgradeCost =>
      playerSpeedLevel < GameBalance.playerSpeedLevels.length
          ? GameBalance.playerSpeedUpgradeCosts[playerSpeedLevel - 1]
          : null;

  bool upgradePlayerSpeed() {
    final cost = playerSpeedUpgradeCost;
    if (cost == null || rupees < cost) return false;
    rupees -= cost;
    playerSpeedLevel++;
    player.speed = GameBalance.playerSpeedLevels[playerSpeedLevel - 1];
    floatingTexts.add(
      FloatingTextEntity(
        position: Vector2(player.position.x, player.position.y - 25.0),
        text: 'SPEED UP! ⚡',
      ),
    );
    return true;
  }

  bool get canUpgradePlayerCapacity =>
      playerCapacityLevel < GameBalance.playerCapacityLevels.length &&
      rupees >= GameBalance.playerCapacityUpgradeCosts[playerCapacityLevel - 1];

  double? get playerCapacityUpgradeCost =>
      playerCapacityLevel < GameBalance.playerCapacityLevels.length
          ? GameBalance.playerCapacityUpgradeCosts[playerCapacityLevel - 1]
          : null;

  bool upgradePlayerCapacity() {
    final cost = playerCapacityUpgradeCost;
    if (cost == null || rupees < cost) return false;
    rupees -= cost;
    playerCapacityLevel++;
    player.carryCapacity =
        GameBalance.playerCapacityLevels[playerCapacityLevel - 1];
    floatingTexts.add(
      FloatingTextEntity(
        position: Vector2(player.position.x, player.position.y - 25.0),
        text: 'CAPACITY UP! 🎒',
      ),
    );
    return true;
  }

  bool get canUpgradeWorkerSpeed =>
      workerSpeedLevel < GameBalance.workerSpeedLevels.length &&
      rupees >= GameBalance.workerSpeedUpgradeCosts[workerSpeedLevel - 1];

  double? get workerSpeedUpgradeCost =>
      workerSpeedLevel < GameBalance.workerSpeedLevels.length
          ? GameBalance.workerSpeedUpgradeCosts[workerSpeedLevel - 1]
          : null;

  bool upgradeWorkerSpeed() {
    final cost = workerSpeedUpgradeCost;
    if (cost == null || rupees < cost) return false;
    rupees -= cost;
    workerSpeedLevel++;
    final newSpeed = currentWorkerSpeed;
    for (final s in staff) {
      if (s.role == StaffRole.helper || s.role == StaffRole.chotu) {
        s.speed = newSpeed;
      }
    }
    floatingTexts.add(
      FloatingTextEntity(
        position: Vector2(player.position.x, player.position.y - 25.0),
        text: 'WORKER SPEED! ⚡',
      ),
    );
    return true;
  }

  bool get canUpgradeWorkerCapacity =>
      workerCapacityLevel < GameBalance.workerCapacityLevels.length &&
      rupees >= GameBalance.workerCapacityUpgradeCosts[workerCapacityLevel - 1];

  double? get workerCapacityUpgradeCost =>
      workerCapacityLevel < GameBalance.workerCapacityLevels.length
          ? GameBalance.workerCapacityUpgradeCosts[workerCapacityLevel - 1]
          : null;

  bool upgradeWorkerCapacity() {
    final cost = workerCapacityUpgradeCost;
    if (cost == null || rupees < cost) return false;
    rupees -= cost;
    workerCapacityLevel++;
    final newCap = currentWorkerCapacity;
    for (final s in staff) {
      if (s.role == StaffRole.helper || s.role == StaffRole.chotu) {
        s.carryCapacity = newCap;
      }
    }
    floatingTexts.add(
      FloatingTextEntity(
        position: Vector2(player.position.x, player.position.y - 25.0),
        text: 'WORKER CAPACITY! 🎒',
      ),
    );
    return true;
  }

  // --- Reputation & Store Progression (M6.1) ---

  int get reputationLevel {
    if (reputationPercent >= 100.0) return 5;
    if (reputationPercent >= 75.0) return 4;
    if (reputationPercent >= 50.0) return 3;
    if (reputationPercent >= 25.0) return 2;
    return 1;
  }

  int get unlockedTableCount =>
      diningTables.where((t) => t.isUnlocked).length;

  bool get isStoreMastered =>
      isReputationLocked100 &&
      completedMissionIds.length >= progressionConfig.goals.length;

  void _updateSpawnInterval() {
    customerSystem.spawnInterval =
        progressionConfig.calculateSpawnInterval(reputationPercent);
  }

  void addReputationPercent(double delta, {String? reason}) {
    if (delta < 0) {
      if (isReputationLocked100) return; // 100% Lock Rule!
      reputationPercent = math.max(0.0, _reputationPercent + delta);
    } else if (delta > 0) {
      reputationPercent = math.min(100.0, _reputationPercent + delta);
    }
  }

  void checkMissions() {
    for (final goal in progressionConfig.goals) {
      if (completedMissionIds.contains(goal.id)) continue;

      bool isMet = false;
      switch (goal.type) {
        case GoalType.hireCashier:
          isMet = hasCashier;
          break;
        case GoalType.hireWorkers:
          isMet = workerCount >= goal.targetValue;
          break;
        case GoalType.unlockTables:
          isMet = unlockedTableCount >= goal.targetValue;
          break;
        case GoalType.upgradeKettle:
          isMet = chaiStation.level >= goal.targetValue;
          break;
        case GoalType.reachReputation:
          isMet = reputationPercent >= goal.targetValue;
          break;
        case GoalType.earnRevenue:
          isMet = lifetimeRupees >= goal.targetValue;
          break;
      }

      if (isMet) {
        completedMissionIds.add(goal.id);
        floatingTexts.add(
          FloatingTextEntity(
            position: Vector2(player.position.x, player.position.y - 40.0),
            text: 'GOAL DONE: ${goal.title}! 🎯',
          ),
        );
      }
    }
  }

  bool _isTableClaimedByOther(int tableId, int currentWorkerId) {
    for (final s in staff) {
      if ((s.role == StaffRole.helper || s.role == StaffRole.chotu) &&
          s.id != currentWorkerId &&
          s.assignedTableId == tableId) {
        return true;
      }
    }
    return false;
  }

  // --- Autonomous Helper / Waiter AI Logic (M6) ---

  void _updateHelperAI(StaffEntity helper, double dt) {
    helper.updateMovement(dt);

    // Natural lane offset based on worker ID so multiple helpers never overlap on identical tracks
    final laneOffset = ((helper.id % 3) - 1) * 20.0;

    // 1. If dumping trash (dirty trays OR excess food due to full counter), dump at Trash Bin!
    if (helper.taskState == HelperTaskState.dumpingTrash ||
        helper.carriedItems.contains(ItemType.dirtyTray)) {
      helper.targetPosition.x = trashBin.position.x + 25.0;
      helper.targetPosition.y = trashBin.position.y + laneOffset * 0.5;
      helper.taskState = HelperTaskState.dumpingTrash;
      helper.assignedTableId = null;

      if (trashBin.isInsideZone(helper.position) && trashBin.canDiscard()) {
        if (helper.carriedItems.isNotEmpty) {
          final isTray = helper.carriedItems.first == ItemType.dirtyTray;
          helper.carriedItems.removeAt(0);
          trashBin.triggerDiscarded();
          onItemDiscarded?.call();
          floatingTexts.add(
            FloatingTextEntity(
              position: Vector2(trashBin.position.x, trashBin.position.y - 20.0),
              text: isTray ? 'CLEANED! 🗑️' : 'DISCARDED! 🗑️',
            ),
          );
        }
        if (helper.carriedItems.isEmpty) {
          helper.taskState = HelperTaskState.idle;
        }
      }
      return;
    }

    // 2. If carrying chai cups (and not dumping trash), deliver to Serving Counter food towers!
    if (helper.carriedItems.contains(ItemType.chai)) {
      // Target the food deposit zone center (360, 668), safe from cashier boundary (396)
      final depositOffset = (helper.id % 2 == 0 ? -10.0 : 10.0);
      helper.targetPosition.x = counter.foodDepositZoneCenter.x + depositOffset;
      helper.targetPosition.y = counter.foodDepositZoneCenter.y;
      helper.taskState = HelperTaskState.deliveringChai;
      helper.assignedTableId = null;

      final isAtDeposit = counter.isInsideFoodDepositZone(helper.position) ||
          helper.position.distanceTo(counter.foodDepositZoneCenter) <= 50.0;

      if (isAtDeposit) {
        if (!helper.isMoving) {
          helper.angle = math.pi / 2; // Facing down towards counter
        }
        if (counter.isFoodFull || !counter.hasFoodRoom) {
          // Counter is completely full! Worker dumps remaining items in trash bin and becomes free!
          helper.taskState = HelperTaskState.dumpingTrash;
          helper.targetPosition.x = trashBin.position.x + 25.0;
          helper.targetPosition.y = trashBin.position.y + laneOffset * 0.5;
        } else if (counter.canDepositFood()) {
          final idx = helper.carriedItems.indexOf(ItemType.chai);
          if (idx != -1) {
            if (counter.addFoodItem(ItemType.chai)) {
              helper.carriedItems.removeAt(idx);
              onItemDeposited?.call(ItemType.chai);
            }
          }
          if (!helper.carriedItems.contains(ItemType.chai)) {
            helper.taskState = HelperTaskState.idle;
          }
        }
      }
      return;
    }

    // 3. Hands are empty: Check for unclaimed dirty dining tables
    DiningTable? unclaimedDirtyTable;
    for (final table in diningTables) {
      if (table.isUnlocked && (table.hasDirtyTray || table.cashTip > 0.0)) {
        if (!_isTableClaimedByOther(table.id, helper.id)) {
          unclaimedDirtyTable = table;
          break;
        }
      }
    }

    // Busboys prioritize table cleaning. Solo worker balances both. Runners focus on restocking unless counter is full or already in clean zone.
    final isInsideTableZone = unclaimedDirtyTable != null &&
        unclaimedDirtyTable.isInsideCleanZone(helper.position);

    final wantsToClean = unclaimedDirtyTable != null &&
        !helper.isFull &&
        (isInsideTableZone ||
            helper.duty == HelperDuty.busboy ||
            (helperCount == 1 &&
                (counter.totalFoodCount >= 2 || chaiStation.shelfCount == 0)) ||
            counter.totalFoodCount >= 10);

    if (wantsToClean) {
      helper.assignedTableId = unclaimedDirtyTable.id;
      helper.targetPosition.x = unclaimedDirtyTable.position.x;
      final approachFromTop = helper.position.y < unclaimedDirtyTable.position.y;
      helper.targetPosition.y = unclaimedDirtyTable.position.y +
          (approachFromTop ? -52.0 : 52.0);
      helper.taskState = HelperTaskState.cleaningTable;

      if (unclaimedDirtyTable.isInsideCleanZone(helper.position)) {
        // Collect tips
        for (final seat in unclaimedDirtyTable.seats) {
          if (seat.cashTip > 0.0) {
            final tip = seat.cashTip;
            seat.cashTip = 0.0;
            rupees += tip;
            lifetimeRupees += tip;
            floatingTexts.add(
              FloatingTextEntity(
                position: Vector2(seat.position.x, unclaimedDirtyTable.position.y - 20.0),
                text: '+Rs ${tip.toInt()}',
              ),
            );
            onCashCollected?.call(tip);
          }
        }

        // Pick up dirty trays
        for (final seat in unclaimedDirtyTable.seats) {
          if (seat.hasDirtyTray && !helper.isFull) {
            helper.addItem(ItemType.dirtyTray);
            seat.hasDirtyTray = false;
            onItemPickedUp?.call(ItemType.dirtyTray);
          }
        }
        if (helper.carriedItems.contains(ItemType.dirtyTray)) {
          helper.taskState = HelperTaskState.dumpingTrash;
          helper.assignedTableId = null;
        }
      }
      return;
    }

    // 4. Counter needs restocking: fetch chai from Chai Kettle!
    // Restock only when counter has room AND kettle has brewed cups ready!
    final needsRestock = counter.hasFoodRoom && chaiStation.shelfCount > 0;

    if (needsRestock && !helper.isFull) {
      helper.assignedTableId = null;
      helper.targetPosition.x = chaiStation.pickupZoneCenter.x + laneOffset;
      helper.targetPosition.y = chaiStation.pickupZoneCenter.y;
      helper.taskState = HelperTaskState.fetchingChai;

      if (chaiStation.isInsidePickupZone(helper.position)) {
        // Pick up chai cups up to Helper's full upgraded capacity!
        while (!helper.isFull && chaiStation.shelfCount > 0) {
          chaiStation.shelfCount--;
          helper.addItem(ItemType.chai);
          onItemPickedUp?.call(ItemType.chai);
        }
        if (helper.carriedCount > 0) {
          helper.taskState = HelperTaskState.deliveringChai;
        } else {
          helper.taskState = HelperTaskState.idle;
        }
      }
      return;
    }

    // 5. Idle / Standby at dedicated Staff Rest Area (Top-Right open zone, away from counter & machines)
    helper.taskState = HelperTaskState.idle;
    helper.assignedTableId = null;

    final standbyBaseX = 720.0;
    final standbyBaseY = 270.0;
    final slotCol = (helper.id - 1) % 3;
    final slotRow = ((helper.id - 1) ~/ 3) % 2;

    helper.targetPosition.x = standbyBaseX + slotCol * 35.0;
    helper.targetPosition.y = standbyBaseY + slotRow * 35.0;

    if (!helper.isMoving) {
      helper.angle = math.pi / 2; // Facing down towards the shop floor
    }
  }
}
