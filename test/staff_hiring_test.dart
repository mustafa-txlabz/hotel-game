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
    test('Hiring Chotu spawns autonomous worker with correct stats', () {
      final world = GameWorld(initialRupees: 300.0);
      expect(world.chotuCount, 0);

      final success = world.hireChotu();
      expect(success, isTrue);
      expect(world.chotuCount, 1);
      final chotu = world.staff.firstWhere((s) => s.role == StaffRole.chotu);
      expect(chotu.speed, GameBalance.workerBaseSpeed);
      expect(chotu.carryCapacity, GameBalance.workerBaseCapacity);
      expect(world.rupees, 300.0 - GameBalance.hireChotuBaseCost);
    });

    test('Chotu automatically fetches chai from kettle and delivers to counter', () {
      final world = GameWorld(initialRupees: 0.0);
      world.hireChotu(free: true);
      final chotu = world.staff.firstWhere((s) => s.role == StaffRole.chotu);

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
      chotu.position.x = world.counter.position.x - 70.0;
      chotu.position.y = world.counter.position.y - 45.0;

      world.tick(0.1);

      // Chai delivered onto counter tower!
      expect(world.counter.foodTowers.first.count, greaterThan(0));
      expect(chotu.carriedCount, 0);
    });

    test('Chotu automatically cleans dirty tables and dumps trays in trash bin', () {
      final world = GameWorld(initialRupees: 0.0);
      world.hireChotu(free: true);
      final chotu = world.staff.firstWhere((s) => s.role == StaffRole.chotu);

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
      final chotu1 = world.staff.firstWhere((s) => s.role == StaffRole.chotu);

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
}
