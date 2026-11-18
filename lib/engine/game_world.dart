import 'dart:math' as math;

import '../data/balance.dart';
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
    HRDesk? hr,
    List<StaffEntity>? staffMembers,
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

      final chotuPad = GroundPad(
        id: 'hire_chotu',
        type: PadType.floorUnlock,
        position: Vector2(660.0, 480.0),
        title: 'CHOTU',
        totalCost: GameBalance.hireChotuBaseCost,
        onUnlocked: () {
          hireChotu(free: true);
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

      groundPads.addAll([kettlePad, cashierPad, chotuPad, table1Pad, table2Pad]);
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

    // 4. Solid collisions (kitchen kettle, serving counter, HR desk, unlocked dining tables)
    _resolveBoxCollision(
      chaiStation.position,
      chaiStation.width,
      chaiStation.height,
    );
    _resolveBoxCollision(counter.position, counter.width, counter.height);
    _resolveBoxCollision(hrDesk.position, hrDesk.width, hrDesk.height);
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

    // 8. Staff AI Updates (Cashier & Chotus) (M6)
    for (final member in staff) {
      if (member.role == StaffRole.chotu) {
        _updateChotuAI(member, dt);
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
  int get chotuCount => staff.where((s) => s.role == StaffRole.chotu).length;

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
      name: 'Mian Ji (Cashier)',
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
    return true;
  }

  double get nextChotuCost =>
      GameBalance.hireChotuBaseCost *
      math.pow(GameBalance.hireChotuCostMultiplier, chotuCount);

  bool hireChotu({bool free = false}) {
    final cost = nextChotuCost;
    if (!free && rupees < cost) return false;
    if (!free) rupees -= cost;

    // Alternate duties: 1st is Runner (Chai restock), 2nd is Busboy (table cleaning), etc.
    final duty = (chotuCount % 2 == 0) ? ChotuDuty.runner : ChotuDuty.busboy;
    final startPos = duty == ChotuDuty.runner
        ? Vector2(chaiStation.pickupZoneCenter.x, chaiStation.pickupZoneCenter.y + 12.0)
        : Vector2(450.0, 880.0);

    final chotu = StaffEntity(
      id: nextStaffId++,
      name: 'Chotu ${chotuCount + 1}',
      role: StaffRole.chotu,
      startPosition: startPos,
      speed: currentWorkerSpeed,
      carryCapacity: currentWorkerCapacity,
      duty: duty,
    );
    staff.add(chotu);

    // If first chotu and floor pad exists, complete it
    if (chotuCount == 1) {
      for (final pad in groundPads) {
        if (pad.id == 'hire_chotu' && !pad.isCompleted) {
          pad.remainingCost = 0.0;
          pad.isCompleted = true;
        }
      }
    }

    floatingTexts.add(
      FloatingTextEntity(
        position: Vector2(chotu.position.x, chotu.position.y - 25.0),
        text: 'CHOTU HIRED! 🏃',
      ),
    );
    return true;
  }

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
      if (s.role == StaffRole.chotu) {
        s.speed = newSpeed;
      }
    }
    floatingTexts.add(
      FloatingTextEntity(
        position: Vector2(hrDesk.position.x, hrDesk.position.y - 25.0),
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
      if (s.role == StaffRole.chotu) {
        s.carryCapacity = newCap;
      }
    }
    floatingTexts.add(
      FloatingTextEntity(
        position: Vector2(hrDesk.position.x, hrDesk.position.y - 25.0),
        text: 'WORKER CAPACITY! 🎒',
      ),
    );
    return true;
  }

  bool _isTableClaimedByOther(int tableId, int currentWorkerId) {
    for (final s in staff) {
      if (s.role == StaffRole.chotu &&
          s.id != currentWorkerId &&
          s.assignedTableId == tableId) {
        return true;
      }
    }
    return false;
  }

  // --- Autonomous Chotu AI Logic (M6) ---

  void _updateChotuAI(StaffEntity chotu, double dt) {
    chotu.updateMovement(dt);

    // Natural lane offset based on worker ID so multiple Chotus never overlap on identical tracks
    final laneOffset = ((chotu.id % 3) - 1) * 20.0;

    // 1. If carrying dirty trays, primary objective is to dump them at Trash Bin!
    if (chotu.carriedItems.contains(ItemType.dirtyTray)) {
      chotu.targetPosition.x = trashBin.position.x + 25.0;
      chotu.targetPosition.y = trashBin.position.y + laneOffset * 0.5;
      chotu.taskState = ChotuTaskState.dumpingTrash;
      chotu.assignedTableId = null;

      if (trashBin.isInsideZone(chotu.position) && trashBin.canDiscard()) {
        final idx = chotu.carriedItems.indexOf(ItemType.dirtyTray);
        if (idx != -1) {
          chotu.carriedItems.removeAt(idx);
          trashBin.triggerDiscarded();
          onItemDiscarded?.call();
          floatingTexts.add(
            FloatingTextEntity(
              position: Vector2(trashBin.position.x, trashBin.position.y - 20.0),
              text: 'CLEANED! 🗑️',
            ),
          );
        }
      }
      return;
    }

    // 2. If carrying chai cups, deliver them to the Serving Counter food towers!
    if (chotu.taskState == ChotuTaskState.deliveringChai ||
        chotu.carriedItems.contains(ItemType.chai)) {
      // Target the food deposit zone center (360, 668), safe from cashier boundary (396)
      final depositOffset = (chotu.id % 2 == 0 ? -10.0 : 10.0);
      chotu.targetPosition.x = counter.foodDepositZoneCenter.x + depositOffset;
      chotu.targetPosition.y = counter.foodDepositZoneCenter.y + 4.0;
      chotu.taskState = ChotuTaskState.deliveringChai;
      chotu.assignedTableId = null;

      final isAtDeposit = counter.isInsideFoodDepositZone(chotu.position) ||
          chotu.position.distanceTo(counter.foodDepositZoneCenter) <= 50.0;

      if (isAtDeposit) {
        if (!chotu.isMoving) {
          chotu.angle = math.pi / 2; // Facing down towards counter
        }
        if (counter.canDepositFood()) {
          final idx = chotu.carriedItems.indexOf(ItemType.chai);
          if (idx != -1) {
            if (counter.addFoodItem(ItemType.chai)) {
              chotu.carriedItems.removeAt(idx);
              onItemDeposited?.call(ItemType.chai);
            }
          }
        }
        if (!chotu.carriedItems.contains(ItemType.chai)) {
          chotu.taskState = ChotuTaskState.idle;
        }
      }
      return;
    }

    // 3. Hands are empty: Check for unclaimed dirty dining tables
    DiningTable? unclaimedDirtyTable;
    for (final table in diningTables) {
      if (table.isUnlocked && (table.hasDirtyTray || table.cashTip > 0.0)) {
        if (!_isTableClaimedByOther(table.id, chotu.id)) {
          unclaimedDirtyTable = table;
          break;
        }
      }
    }

    // Busboys prioritize table cleaning. Solo worker balances both. Runners focus on restocking unless counter is full or already in clean zone.
    final isInsideTableZone = unclaimedDirtyTable != null &&
        unclaimedDirtyTable.isInsideCleanZone(chotu.position);

    final wantsToClean = unclaimedDirtyTable != null &&
        !chotu.isFull &&
        (isInsideTableZone ||
            chotu.duty == ChotuDuty.busboy ||
            (chotuCount == 1 &&
                (counter.totalFoodCount >= 2 || chaiStation.shelfCount == 0)) ||
            counter.totalFoodCount >= 10);

    if (wantsToClean) {
      chotu.assignedTableId = unclaimedDirtyTable.id;
      chotu.targetPosition.x = unclaimedDirtyTable.position.x;
      chotu.targetPosition.y = unclaimedDirtyTable.position.y + 40.0;
      chotu.taskState = ChotuTaskState.cleaningTable;

      if (unclaimedDirtyTable.isInsideCleanZone(chotu.position)) {
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
          if (seat.hasDirtyTray && !chotu.isFull) {
            chotu.addItem(ItemType.dirtyTray);
            seat.hasDirtyTray = false;
            onItemPickedUp?.call(ItemType.dirtyTray);
          }
        }
        if (chotu.carriedItems.contains(ItemType.dirtyTray)) {
          chotu.taskState = ChotuTaskState.dumpingTrash;
          chotu.assignedTableId = null;
        }
      }
      return;
    }

    // 4. Counter needs restocking: fetch chai from Chai Kettle!
    final needsRestock = counter.totalFoodCount < 10;
    final canHelpRestock = needsRestock &&
        (chotu.duty == ChotuDuty.runner || chaiStation.shelfCount > 0);

    if (canHelpRestock && !chotu.isFull) {
      chotu.assignedTableId = null;
      chotu.targetPosition.x = chaiStation.pickupZoneCenter.x + laneOffset;
      chotu.targetPosition.y = chaiStation.pickupZoneCenter.y;
      chotu.taskState = ChotuTaskState.fetchingChai;

      if (chaiStation.isInsidePickupZone(chotu.position)) {
        // Pick up chai cups up to Chotu's full upgraded capacity!
        while (!chotu.isFull && chaiStation.shelfCount > 0) {
          chaiStation.shelfCount--;
          chotu.addItem(ItemType.chai);
          onItemPickedUp?.call(ItemType.chai);
        }
        if (chotu.carriedCount > 0) {
          chotu.taskState = ChotuTaskState.deliveringChai;
        } else {
          // Kettle is currently brewing: wait at pickup zone facing the kettle (no sprint to HR desk!)
          chotu.angle = -math.pi / 2;
        }
      }
      return;
    }

    // 5. Idle / Standby at designated staff stations (NOT running to HR desk!)
    chotu.taskState = ChotuTaskState.idle;
    chotu.assignedTableId = null;

    if (chotu.duty == ChotuDuty.runner) {
      // Runner stands near the kitchen prep counter facing the dhaba
      chotu.targetPosition.x = chaiStation.pickupZoneCenter.x + laneOffset;
      chotu.targetPosition.y = chaiStation.pickupZoneCenter.y + 12.0;
      if (!chotu.isMoving) {
        chotu.angle = math.pi / 2; // Facing down towards dhaba
      }
    } else {
      // Busboy stands in dining hall buffer zone ready for customers
      chotu.targetPosition.x = 450.0 + laneOffset;
      chotu.targetPosition.y = 880.0;
      if (!chotu.isMoving) {
        chotu.angle = math.pi / 2; // Facing south towards dining tables
      }
    }
  }
}
