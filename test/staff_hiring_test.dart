import 'package:flutter_test/flutter_test.dart';
import 'package:chai_dhaba_empire/data/balance.dart';
import 'package:chai_dhaba_empire/engine/game_world.dart';
import 'package:chai_dhaba_empire/engine/staff_ai.dart';
import 'package:chai_dhaba_empire/engine/stations.dart';

void main() {
  group('Staff Hiring & Cashier Faculty Specifications (M6)', () {
    test('Initial staff and upgrade levels state', () {
      final world = GameWorld();
      expect(world.hasCashier, isFalse);
      expect(world.chotuCount, 0);
      expect(world.playerSpeedLevel, 1);
      expect(world.playerCapacityLevel, 1);
      expect(world.workerSpeedLevel, 1);
      expect(world.workerCapacityLevel, 1);
      expect(world.counter.isCashierPresent, isFalse);
    });

    test('Hiring Cashier permanently keeps cashier present at counter', () {
      final world = GameWorld(initialRupees: 200.0);
      expect(world.hasCashier, isFalse);

      final success = world.hireCashier();
      expect(success, isTrue);
      expect(world.hasCashier, isTrue);
      expect(world.staff.length, 1);
      expect(world.staff.first.role, StaffRole.cashier);
      expect(world.counter.isCashierPresent, isTrue);
      expect(world.rupees, 200.0 - GameBalance.hireCashierCost);

      // Even if player moves far away to top-left corner
      world.player.position.x = 50.0;
      world.player.position.y = 50.0;
      world.tick(0.1);

      // Cashier is STILL present!
      expect(world.counter.isCashierPresent, isTrue);
    });

    test('Customer is served automatically by hired Cashier without Owner', () {
      final world = GameWorld(initialRupees: 200.0);
      world.hireCashier();

      // Put Owner far away from counter
      world.player.position.x = 100.0;
      world.player.position.y = 100.0;

      // Add chai cups to counter food towers
      world.counter.foodTowers.first.count = 4;
      world.counter.serviceTimer = 0.0;

      // Spawn a customer at counter slot 0
      final customer = world.customerSystem.spawnCustomer(
        item: ItemType.chai,
        count: 1,
      )!;
      customer.position.x = 450.0;
      customer.position.y = 782.0;

      // Update simulation
      world.tick(0.1);

      // Customer should have been served by hired cashier!
      expect(customer.receivedCount, 1);
      expect(world.counter.foodTowers.first.count, 3);
      expect(world.counter.cashBundleCount, 1); // Customer paid cash!
    });

    test('Cashier floor unlock pad smoothly pours cash and hires Cashier', () {
      final world = GameWorld(initialRupees: 200.0);
      final pad = world.groundPads.firstWhere((p) => p.id == 'hire_cashier');
      expect(pad.isCompleted, isFalse);
      expect(world.hasCashier, isFalse);

      // Walk Owner onto the pad
      world.player.position.x = pad.position.x;
      world.player.position.y = pad.position.y;

      // Tick world to pour cash until completed
      for (int i = 0; i < 60; i++) {
        world.tick(0.05);
      }

      expect(pad.isCompleted, isTrue);
      expect(world.hasCashier, isTrue);
      expect(world.counter.isCashierPresent, isTrue);
      expect(world.rupees, closeTo(200.0 - GameBalance.hireCashierCost, 0.5));
    });
  });

  group('Autonomous Chotu AI & Task Execution (M6)', () {
    test('Store 1 limits workers to maximum 3 and disables further hiring', () {
      final world = GameWorld(initialRupees: 5000.0);
      expect(world.canHireWorker, isTrue);
      expect(world.maxWorkers, 3);
      expect(world.workerCount, 0);

      expect(world.hireWorker(), isTrue); // Worker 1 (1/3)
      expect(world.workerCount, 1);
      expect(world.canHireWorker, isTrue);

      expect(world.hireWorker(), isTrue); // Worker 2 (2/3)
      expect(world.workerCount, 2);
      expect(world.canHireWorker, isTrue);

      expect(world.hireWorker(), isTrue); // Worker 3 (3/3)
      expect(world.workerCount, 3);
      expect(world.canHireWorker, isFalse); // 3/3 reached!

      // Attempting to hire 4th worker fails!
      expect(world.hireWorker(), isFalse);
      expect(world.workerCount, 3);
    });

    test('Hiring Chotu spawns autonomous worker with correct stats', () {
      final world = GameWorld(initialRupees: 300.0);
      expect(world.chotuCount, 0);

      final success = world.hireChotu();
      expect(success, isTrue);
      expect(world.chotuCount, 1);
      final chotu = world.staff.firstWhere((s) => s.role == StaffRole.helper);
      expect(chotu.speed, GameBalance.workerBaseSpeed);
      expect(chotu.carryCapacity, GameBalance.workerBaseCapacity);
      expect(world.rupees, 300.0 - GameBalance.hireChotuBaseCost);
    });

    test('Chotu automatically fetches chai from kettle and delivers to counter', () {
      final world = GameWorld(initialRupees: 0.0);
      world.hireChotu(free: true);
      final chotu = world.staff.firstWhere((s) => s.role == StaffRole.helper);

      // Kettle has brewed cups
      world.chaiStation.shelfCount = 4;
      // Counter is empty
      world.counter.foodTowers.first.count = 0;

      // Position Chotu near kettle to pick up
      chotu.position.x = world.chaiStation.pickupZoneCenter.x;
      chotu.position.y = world.chaiStation.pickupZoneCenter.y;

      // Tick world
      world.tick(0.1);

      // Chotu picked up chai cup
      expect(chotu.carriedCount, greaterThan(0));
      expect(chotu.carriedItems.first, ItemType.chai);
      expect(chotu.taskState, ChotuTaskState.deliveringChai);

      // Teleport Chotu to counter food deposit zone
      chotu.position.x = world.counter.foodDepositZoneCenter.x;
      chotu.position.y = world.counter.foodDepositZoneCenter.y;
      chotu.targetPosition.x = world.counter.foodDepositZoneCenter.x;
      chotu.targetPosition.y = world.counter.foodDepositZoneCenter.y;

      // Tick world until all carried items are deposited
      for (int i = 0; i < 5; i++) {
        world.tick(0.15);
      }

      // Chai delivered onto counter tower!
      expect(world.counter.foodTowers.first.count, greaterThan(0));
      expect(chotu.carriedCount, 0);
    });

    test('Chotu picks up multiple chai cups matching upgraded carry capacity', () {
      final world = GameWorld(initialRupees: 500.0);
      world.hireChotu(free: true);
      final chotu = world.staff.firstWhere((s) => s.role == StaffRole.helper);

      // Upgrade Worker Capacity twice: Lvl 1 (2) -> Lvl 2 (3) -> Lvl 3 (5)
      world.upgradeWorkerCapacity(); // now 3
      world.upgradeWorkerCapacity(); // now 5
      expect(chotu.carryCapacity, 5);

      // Kettle has 6 cups ready
      world.chaiStation.shelfCount = 6;
      world.counter.foodTowers.first.count = 0;

      // Position Chotu at kettle pickup
      chotu.position.x = world.chaiStation.pickupZoneCenter.x;
      chotu.position.y = world.chaiStation.pickupZoneCenter.y;
      chotu.targetPosition.x = world.chaiStation.pickupZoneCenter.x;
      chotu.targetPosition.y = world.chaiStation.pickupZoneCenter.y;

      world.tick(0.1);

      // Chotu must have picked up ALL 5 cups up to full capacity!
      expect(chotu.carriedCount, 5);
      expect(chotu.isFull, isTrue);
      expect(world.chaiStation.shelfCount, 1); // 6 - 5 = 1 left on shelf!
      expect(chotu.taskState, ChotuTaskState.deliveringChai);
    });

    test('Chotu automatically cleans dirty tables and dumps trays in trash bin', () {
      final world = GameWorld(initialRupees: 0.0);
      world.hireChotu(free: true);
      final chotu = world.staff.firstWhere((s) => s.role == StaffRole.helper);

      // Table 1 unlocked with dirty tray and tip on seat 0
      final table = world.diningTables.first;
      table.isUnlocked = true;
      table.seats.first.hasDirtyTray = true;
      table.seats.first.cashTip = 25.0;

      // Position Chotu at table clean zone
      chotu.position.x = table.position.x;
      chotu.position.y = table.position.y + 40.0;
      chotu.targetPosition.x = table.position.x;
      chotu.targetPosition.y = table.position.y + 40.0;

      world.tick(0.1);

      // Chotu cleaned table!
      expect(table.hasDirtyTray, isFalse);
      expect(table.cashTip, 0.0);
      expect(world.rupees, 25.0); // Tip collected to dhaba wallet!
      expect(chotu.carriedCount, 1);
      expect(chotu.carriedItems.first, ItemType.dirtyTray);
      expect(chotu.taskState, ChotuTaskState.dumpingTrash);

      // Teleport Chotu to Trash Bin
      chotu.position.x = world.trashBin.position.x + 20.0;
      chotu.position.y = world.trashBin.position.y;

      world.tick(0.1);

      // Dirty tray dumped in trash!
      expect(chotu.carriedCount, 0);
    });

    test('Chotu Runner waits at Staff Standby area when kettle is brewing and counter is stocked', () {
      final world = GameWorld(initialRupees: 0.0);
      world.hireChotu(free: true);
      final chotu = world.staff.firstWhere((s) => s.role == StaffRole.helper);
      expect(chotu.duty, ChotuDuty.runner);

      // Counter is not full, but kettle has 0 cups ready (currently brewing)
      world.counter.foodTowers.first.count = 2;
      world.chaiStation.shelfCount = 0;

      // Position Chotu near kettle
      chotu.position.x = world.chaiStation.pickupZoneCenter.x;
      chotu.position.y = world.chaiStation.pickupZoneCenter.y;

      world.tick(0.1);

      // Chotu does NOT camp at kettle; instead waits at Staff Standby area (720, 270)!
      expect(chotu.targetPosition.x, closeTo(720.0, 50.0));
      expect(chotu.targetPosition.y, closeTo(270.0, 50.0));
      expect(chotu.taskState, ChotuTaskState.idle);
    });

    test('Multiple Chotus have distinct duties (Runner vs Busboy) and never swarm same table', () {
      final world = GameWorld(initialRupees: 0.0);
      world.hireChotu(free: true); // Chotu 1 -> Runner
      world.hireChotu(free: true); // Chotu 2 -> Busboy

      final chotu1 = world.staff[0];
      final chotu2 = world.staff[1];

      expect(chotu1.duty, ChotuDuty.runner);
      expect(chotu2.duty, ChotuDuty.busboy);

      // Table 1 unlocked with dirty tray
      final table1 = world.diningTables.first;
      table1.isUnlocked = true;
      table1.seats.first.hasDirtyTray = true;

      // Counter has 0 cups, kettle has 2 cups
      world.counter.foodTowers.first.count = 0;
      world.chaiStation.shelfCount = 2;

      world.tick(0.1);

      // Chotu 2 (Busboy) claims and targets Table 1
      expect(chotu2.taskState, ChotuTaskState.cleaningTable);
      expect(chotu2.assignedTableId, table1.id);
      expect(chotu2.targetPosition.x, table1.position.x);

      // Chotu 1 (Runner) does NOT target Table 1; instead focuses on restocking chai!
      expect(chotu1.assignedTableId, isNull);
      expect(
        chotu1.taskState == ChotuTaskState.fetchingChai ||
            chotu1.taskState == ChotuTaskState.deliveringChai,
        isTrue,
      );
    });

    test('Chotu with id=2 delivers chai without getting stuck near cashier boundary', () {
      final world = GameWorld(initialRupees: 0.0);
      world.hireCashier(free: true); // id = 1 (Cashier)
      world.hireChotu(free: true); // id = 2 (Chotu)
      final chotu = world.staff.firstWhere((s) => s.role == StaffRole.helper);
      expect(chotu.id, 2);

      int depositedCount = 0;
      world.onItemDeposited = (item) {
        if (item == ItemType.chai) depositedCount++;
      };

      // Chotu carries 2 cups of chai
      chotu.addItem(ItemType.chai);
      chotu.addItem(ItemType.chai);
      chotu.taskState = ChotuTaskState.deliveringChai;

      // Position Chotu at the food deposit zone
      chotu.position.x = world.counter.foodDepositZoneCenter.x;
      chotu.position.y = world.counter.foodDepositZoneCenter.y;

      // Tick world until deposited
      for (int i = 0; i < 10; i++) {
        world.tick(0.1);
      }

      // Chai deposited onto counter, Chotu NOT stuck!
      expect(depositedCount, 2);
      expect(world.counter.totalFoodCount, 2);
    });

    test('Counter supports 3 columns x 10 items = 30 max items, workers restock past 10', () {
      final world = GameWorld(initialRupees: 0.0);
      expect(world.counter.maxColumns, 3);
      expect(world.counter.maxFoodCapacity, 30);

      // Fill first column completely (10 items)
      world.counter.foodTowers.first.count = 10;
      expect(world.counter.totalFoodCount, 10);
      expect(world.counter.hasFoodRoom, isTrue); // Has room for columns 2 & 3!

      world.hireChotu(free: true);
      final chotu = world.staff.firstWhere((s) => s.role == StaffRole.helper);

      // Kettle has brewed cups
      world.chaiStation.shelfCount = 5;

      // Position Chotu at kettle
      chotu.position.x = world.chaiStation.pickupZoneCenter.x;
      chotu.position.y = world.chaiStation.pickupZoneCenter.y;

      world.tick(0.1);

      // Worker actively picks up chai to fill column 2 (does NOT stop because column 1 was 10!)
      expect(chotu.carriedCount, greaterThan(0));
      expect(chotu.taskState, ChotuTaskState.deliveringChai);

      // Teleport Chotu to counter
      chotu.position.x = world.counter.foodDepositZoneCenter.x;
      chotu.position.y = world.counter.foodDepositZoneCenter.y;

      for (int i = 0; i < 15; i++) {
        world.tick(0.15);
      }

      // Tower 2 is created and contains items! Total food count > 10!
      expect(world.counter.foodTowers.length, 2);
      expect(world.counter.totalFoodCount, greaterThan(10));
    });

    test('Worker with overflow item dumps in trash when counter is 30 items full and becomes free', () {
      final world = GameWorld(initialRupees: 0.0);
      world.hireChotu(free: true);
      final chotu = world.staff.firstWhere((s) => s.role == StaffRole.helper);

      // Fill counter to 29 items (1 item room left to reach 30)
      world.counter.foodTowers.clear();
      world.counter.foodTowers.add(CounterItemTower(itemType: ItemType.chai, count: 10));
      world.counter.foodTowers.add(CounterItemTower(itemType: ItemType.chai, count: 10));
      world.counter.foodTowers.add(CounterItemTower(itemType: ItemType.chai, count: 9));
      expect(world.counter.totalFoodCount, 29);

      // Chotu carries 2 cups
      chotu.addItem(ItemType.chai);
      chotu.addItem(ItemType.chai);
      chotu.taskState = ChotuTaskState.deliveringChai;

      // Position Chotu at food deposit zone
      chotu.position.x = world.counter.foodDepositZoneCenter.x;
      chotu.position.y = world.counter.foodDepositZoneCenter.y;

      world.tick(0.1); // Deposits 1st cup, counter becomes 30/30 (FULL!)

      expect(world.counter.totalFoodCount, 30);
      expect(world.counter.isFoodFull, isTrue);
      expect(chotu.carriedCount, 1); // 1 cup remains in hands!

      // Worker immediately heads to trash bin instead of blocking counter!
      world.tick(0.1);
      expect(chotu.taskState, ChotuTaskState.dumpingTrash);
      expect(chotu.targetPosition.x, closeTo(world.trashBin.position.x + 25.0, 5.0));

      // Teleport worker to trash bin to dump excess item
      chotu.position.x = world.trashBin.position.x + 25.0;
      chotu.position.y = world.trashBin.position.y;
      world.tick(0.1);

      // Carried items are dumped into trash bin! Hands are empty!
      expect(chotu.carriedCount, 0);
      expect(chotu.taskState, ChotuTaskState.idle);

      // Next tick: Idle worker targets Staff Standby area
      world.tick(0.1);
      expect(chotu.targetPosition.x, closeTo(720.0, 50.0));
      expect(chotu.targetPosition.y, closeTo(270.0, 50.0));
    });
  });

  group('HR Upgrades System (M6)', () {
    test('Owner Speed and Capacity upgrades update stats and consume rupees', () {
      final world = GameWorld(initialRupees: 500.0);

      // Initial stats
      expect(world.player.speed, GameBalance.playerSpeedLevels[0]);
      expect(world.player.carryCapacity, GameBalance.playerCapacityLevels[0]);

      // Upgrade Speed
      final speedUp = world.upgradePlayerSpeed();
      expect(speedUp, isTrue);
      expect(world.playerSpeedLevel, 2);
      expect(world.player.speed, GameBalance.playerSpeedLevels[1]);
      expect(world.rupees, 500.0 - GameBalance.playerSpeedUpgradeCosts[0]);

      // Upgrade Capacity
      final capUp = world.upgradePlayerCapacity();
      expect(capUp, isTrue);
      expect(world.playerCapacityLevel, 2);
      expect(world.player.carryCapacity, GameBalance.playerCapacityLevels[1]);
    });

    test('Worker Speed and Capacity upgrades update existing and future Chotus', () {
      final world = GameWorld(initialRupees: 500.0);
      world.hireChotu(free: true);
      final chotu1 = world.staff.firstWhere((s) => s.role == StaffRole.helper);

      expect(chotu1.speed, GameBalance.workerSpeedLevels[0]);
      expect(chotu1.carryCapacity, GameBalance.workerCapacityLevels[0]);

      // Upgrade worker speed & capacity
      world.upgradeWorkerSpeed();
      world.upgradeWorkerCapacity();

      expect(world.workerSpeedLevel, 2);
      expect(world.workerCapacityLevel, 2);
      expect(chotu1.speed, GameBalance.workerSpeedLevels[1]);
      expect(chotu1.carryCapacity, GameBalance.workerCapacityLevels[1]);

      // Spawn a second Chotu, it must also have level 2 stats!
      world.hireChotu(free: true);
      final chotu2 = world.staff.last;
      expect(chotu2.speed, GameBalance.workerSpeedLevels[1]);
      expect(chotu2.carryCapacity, GameBalance.workerCapacityLevels[1]);
    });
  });

  group('Staff Physical Solid Collisions & Navigation (M6 / Local Fix)', () {
    test('Serving counter is solid for workers: worker is pushed outside counter bounds', () {
      final world = GameWorld(initialRupees: 0.0);
      world.hireChotu(free: true);
      final chotu = world.staff.firstWhere((s) => s.role == StaffRole.helper);

      // Force worker position inside the serving counter box (450, 720)
      chotu.position.x = world.counter.position.x;
      chotu.position.y = world.counter.position.y;

      world.tick(0.01);

      // Worker must have been pushed outside the counter rectangle!
      final halfW = world.counter.width / 2;
      final halfH = world.counter.height / 2;
      final left = world.counter.position.x - halfW;
      final right = world.counter.position.x + halfW;
      final top = world.counter.position.y - halfH;
      final bottom = world.counter.position.y + halfH;

      final isInside = chotu.position.x > left &&
          chotu.position.x < right &&
          chotu.position.y > top &&
          chotu.position.y < bottom;

      expect(isInside, isFalse);
    });

    test('Chai Kettle machine is solid for workers: worker cannot penetrate station', () {
      final world = GameWorld(initialRupees: 0.0);
      world.hireChotu(free: true);
      final chotu = world.staff.firstWhere((s) => s.role == StaffRole.helper);

      // Place worker inside kettle box
      chotu.position.x = world.chaiStation.position.x;
      chotu.position.y = world.chaiStation.position.y;

      world.tick(0.01);

      final halfW = world.chaiStation.width / 2;
      final halfH = world.chaiStation.height / 2;
      final left = world.chaiStation.position.x - halfW;
      final right = world.chaiStation.position.x + halfW;
      final top = world.chaiStation.position.y - halfH;
      final bottom = world.chaiStation.position.y + halfH;

      final isInside = chotu.position.x > left &&
          chotu.position.x < right &&
          chotu.position.y > top &&
          chotu.position.y < bottom;

      expect(isInside, isFalse);
    });

    test('Unlocked Dining Tables are solid for workers, locked tables are not', () {
      final world = GameWorld(initialRupees: 0.0);
      world.hireChotu(free: true);
      final chotu = world.staff.firstWhere((s) => s.role == StaffRole.helper);
      final table = world.diningTables.first;
      expect(table.isUnlocked, isFalse);

      // When table is locked: no solid collision
      chotu.position.x = table.position.x;
      chotu.position.y = table.position.y;
      chotu.targetPosition.x = table.position.x;
      chotu.targetPosition.y = table.position.y;
      world.tick(0.01);
      expect(chotu.position.x, table.position.x);
      expect(chotu.position.y, table.position.y);

      // Unlock table
      table.isUnlocked = true;
      world.tick(0.01);

      // Now table is solid: worker is pushed outside!
      final halfW = table.width / 2;
      final halfH = table.height / 2;
      final isInside = chotu.position.x > table.position.x - halfW &&
          chotu.position.x < table.position.x + halfW &&
          chotu.position.y > table.position.y - halfH &&
          chotu.position.y < table.position.y + halfH;

      expect(isInside, isFalse);
    });

    test('Trash Bin is NOT solid for workers (allows easy dumping)', () {
      final world = GameWorld(initialRupees: 0.0);
      world.hireChotu(free: true);
      final chotu = world.staff.firstWhere((s) => s.role == StaffRole.helper);

      chotu.position.x = world.trashBin.position.x;
      chotu.position.y = world.trashBin.position.y;
      chotu.targetPosition.x = world.trashBin.position.x;
      chotu.targetPosition.y = world.trashBin.position.y;

      world.tick(0.01);

      // Worker is allowed inside the trash bin zone without collision ejection
      expect(chotu.position.x, world.trashBin.position.x);
      expect(chotu.position.y, world.trashBin.position.y);
    });

    test('Workers route cleanly around the counter via open corridors without cutting through', () {
      final world = GameWorld(initialRupees: 0.0);
      world.hireChotu(free: true);
      final chotu = world.staff.firstWhere((s) => s.role == StaffRole.helper);

      // Position worker at Table 2 (700, 950) in dining area
      chotu.position.x = 700.0;
      chotu.position.y = 950.0;
      // Target Trash Bin (125, 460) in kitchen area
      chotu.targetPosition.x = world.trashBin.position.x + 25.0;
      chotu.targetPosition.y = world.trashBin.position.y;

      // Simulate movement for 30 seconds
      bool penetratedCounter = false;
      final counterLeft = world.counter.position.x - world.counter.width / 2;
      final counterRight = world.counter.position.x + world.counter.width / 2;
      final counterTop = world.counter.position.y - world.counter.height / 2;
      final counterBottom = world.counter.position.y + world.counter.height / 2;

      for (int i = 0; i < 400; i++) {
        world.tick(0.05);

        if (chotu.position.x > counterLeft &&
            chotu.position.x < counterRight &&
            chotu.position.y > counterTop &&
            chotu.position.y < counterBottom) {
          penetratedCounter = true;
          break;
        }
      }

      // Worker must NEVER have penetrated the counter!
      expect(penetratedCounter, isFalse);
      // Worker should have successfully reached near trash bin!
      expect(chotu.position.y, lessThan(counterTop));
    });
  });
}
