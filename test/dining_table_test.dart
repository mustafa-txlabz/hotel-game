import 'package:flutter_test/flutter_test.dart';
import 'package:chai_dhaba_empire/data/balance.dart';
import 'package:chai_dhaba_empire/engine/customer_ai.dart';
import 'package:chai_dhaba_empire/engine/entities.dart';
import 'package:chai_dhaba_empire/engine/game_world.dart';
import 'package:chai_dhaba_empire/engine/stations.dart';

void main() {
  group('DiningTable Specifications (M5)', () {
    test('Initial locked and availability state', () {
      final table = DiningTable(
        id: 1,
        position: Vector2(200.0, 950.0),
        isUnlocked: false,
      );

      expect(table.isUnlocked, isFalse);
      expect(table.isOccupied, isFalse);
      expect(table.hasDirtyTray, isFalse);
      expect(table.cashTip, 0.0);
      expect(table.isAvailable, isFalse); // Locked table cannot be used

      // Unlock table
      table.isUnlocked = true;
      expect(table.isAvailable, isTrue);

      // Occupied table is not available
      table.isOccupied = true;
      expect(table.isAvailable, isFalse);

      table.isOccupied = false;
      expect(table.isAvailable, isTrue);

      // Dirty table is not available
      table.hasDirtyTray = true;
      expect(table.isAvailable, isFalse);
    });

    test('Seat position and clean zone reach', () {
      final table = DiningTable(
        id: 1,
        position: Vector2(200.0, 950.0),
        width: 90.0,
        height: 64.0,
        isUnlocked: true,
      );

      expect(table.seatPosition.x, 200.0);
      expect(table.seatPosition.y, 950.0 + 32.0 + 12.0);

      // Clean zone detection
      expect(table.isInsideCleanZone(Vector2(200.0, 950.0)), isTrue);
      expect(table.isInsideCleanZone(Vector2(200.0, 990.0)), isTrue);
      expect(table.isInsideCleanZone(Vector2(200.0, 1100.0)), isFalse);
    });
  });

  group('Customer Dine-In & Eating Behavior (M5)', () {
    test('Served customer chooses dine-in when table is available', () {
      final counter = ServingCounter(position: Vector2(450.0, 720.0));
      counter.isCashierPresent = true;
      counter.addFoodItem(ItemType.chai);

      final table = DiningTable(
        id: 1,
        position: Vector2(200.0, 950.0),
        isUnlocked: true,
      );

      final system = CustomerSystem(
        queue: CustomerQueue(headPosition: Vector2(450.0, 782.0)),
        entrancePosition: Vector2(450.0, 1165.0),
        tables: [table],
      );

      final customer = system.spawnCustomer(item: ItemType.chai, count: 1)!;
      // Snap customer to front of queue
      customer.position.x = 450.0;
      customer.position.y = 782.0;

      expect(table.isAvailable, isTrue);

      // Update system to execute transaction
      system.update(0.1, counter);

      expect(customer.isOrderComplete, isTrue);
      expect(customer.state, CustomerState.walkingToTable);
      expect(customer.assignedTable, table);
      expect(table.isOccupied, isTrue);
      expect(table.isAvailable, isFalse); // Now occupied
      expect(system.queue.isEmpty, isTrue); // Queue advanced
    });

    test('Served customer takes takeaway if no table is unlocked/available', () {
      final counter = ServingCounter(position: Vector2(450.0, 720.0));
      counter.isCashierPresent = true;
      counter.addFoodItem(ItemType.chai);

      final table = DiningTable(
        id: 1,
        position: Vector2(200.0, 950.0),
        isUnlocked: false, // Locked table!
      );

      final system = CustomerSystem(
        queue: CustomerQueue(headPosition: Vector2(450.0, 782.0)),
        entrancePosition: Vector2(450.0, 1165.0),
        tables: [table],
      );

      final customer = system.spawnCustomer(item: ItemType.chai, count: 1)!;
      customer.position.x = 450.0;
      customer.position.y = 782.0;

      system.update(0.1, counter);

      expect(customer.isOrderComplete, isTrue);
      expect(customer.state, CustomerState.leavingHappy); // Takeaway!
      expect(customer.assignedTable, isNull);
      expect(table.isOccupied, isFalse);
    });

    test('Customer walks to stool, sits down to eat, leaves tip and dirty tray', () {
      final table = DiningTable(
        id: 1,
        position: Vector2(200.0, 950.0),
        isUnlocked: true,
      );

      final system = CustomerSystem(
        queue: CustomerQueue(headPosition: Vector2(450.0, 782.0)),
        entrancePosition: Vector2(450.0, 1165.0),
        tables: [table],
      );

      final customer = CustomerEntity(
        id: 1,
        startPosition: Vector2(450.0, 782.0),
        targetPosition: table.seatPosition.copy(),
        eatDuration: 4.0,
      );
      customer.state = CustomerState.walkingToTable;
      customer.assignedTable = table;
      table.isOccupied = true;
      system.activeCustomers.add(customer);

      // Walk to table seat
      customer.update(2.0); // Step towards stool
      expect(customer.isMoving, isTrue);
      expect(customer.state, CustomerState.walkingToTable);

      // Arrive at stool seat
      customer.position.x = table.seatPosition.x;
      customer.position.y = table.seatPosition.y;
      customer.update(0.1);

      expect(customer.state, CustomerState.eating);
      expect(customer.isMoving, isFalse);
      expect(customer.eatTimer, 0.0);

      // Simulate eating for 3 seconds (not done yet)
      system.update(3.0, ServingCounter());
      expect(customer.state, CustomerState.eating);
      expect(table.hasDirtyTray, isFalse);
      expect(table.cashTip, 0.0);

      // Finish eating (total 4+ seconds)
      system.update(1.5, ServingCounter());

      expect(customer.state, CustomerState.leavingHappy);
      expect(customer.assignedTable, isNull);
      expect(table.isOccupied, isFalse);
      expect(table.hasDirtyTray, isTrue); // Dirty tray left on table!
      expect(table.cashTip, GameBalance.dineInTip); // Rs 25 tip on table!
      expect(table.isAvailable, isFalse); // Blocked until cleaned!
    });
  });

  group('Table Cleaning & Trash Discard Loop in GameWorld (M5)', () {
    test('Owner vacuums cash tip and picks up dirty tray to clean table', () {
      final world = GameWorld(initialRupees: 0.0);
      final table = world.diningTables.first;
      table.isUnlocked = true;
      table.hasDirtyTray = true;
      table.cashTip = 25.0;

      expect(table.isAvailable, isFalse);
      expect(world.player.carriedCount, 0);

      // Move player into table clean zone
      world.player.position.x = table.position.x;
      world.player.position.y = table.position.y + 40.0;

      world.tick(0.1);

      // 1. Tip vacuum started
      expect(table.cashTip, 0.0);
      expect(world.cashBundles.length, 1);
      expect(world.cashBundles.first.value, 25.0);

      // 2. Tray picked up into player stack
      expect(table.hasDirtyTray, isFalse);
      expect(table.isAvailable, isTrue); // Table is now freed for next customer!
      expect(world.player.carriedCount, 1);
      expect(world.player.carriedItems.last, ItemType.dirtyTray);

      // 3. Cash bundle absorbs into wallet
      world.tick(1.0);
      expect(world.rupees, 25.0);
    });

    test('Owner dumps carried dirty tray at Trash Bin', () {
      final world = GameWorld();
      world.player.addItem(ItemType.dirtyTray);
      expect(world.player.carriedCount, 1);

      // Move player to trash bin zone
      world.player.position.x = world.trashBin.position.x;
      world.player.position.y = world.trashBin.position.y;

      world.tick(0.1);

      expect(world.player.carriedCount, 0); // Discarded!
      expect(
        world.floatingTexts.any((ft) => ft.text.contains('TRASHED')),
        isTrue,
      );
    });

    test('Full End-to-End Dine-In, Tip, and Clean Loop', () {
      final world = GameWorld(initialRupees: 0.0);
      final table = world.diningTables.first;
      table.isUnlocked = true;

      // 1. Brew chai and place on counter
      world.counter.addFoodItem(ItemType.chai);
      expect(world.counter.foodTowers.first.count, 1);

      // 2. Customer spawns at entrance
      final customer = world.customerSystem.spawnCustomer(
        item: ItemType.chai,
        count: 1,
      )!;

      // Snap customer to front of counter queue
      customer.position.x = 450.0;
      customer.position.y = 782.0;

      // 3. Owner stands at cashier
      world.player.position.x = world.counter.cashierZoneCenter.x;
      world.player.position.y = world.counter.cashierZoneCenter.y;

      world.tick(0.1);

      // Customer served and heads to Table 1
      expect(customer.state, CustomerState.walkingToTable);
      expect(customer.assignedTable, table);
      expect(table.isOccupied, isTrue);

      // 4. Customer arrives at table and eats
      customer.position.x = table.seatPosition.x;
      customer.position.y = table.seatPosition.y;
      world.tick(0.1);
      expect(customer.state, CustomerState.eating);

      // Finish eating
      world.tick(GameBalance.customerEatDuration + 0.5);

      expect(customer.state, CustomerState.leavingHappy);
      expect(table.hasDirtyTray, isTrue);
      expect(table.cashTip, 25.0);
      expect(table.isAvailable, isFalse);

      // 5. Owner walks to table: collects tip & cleans tray
      world.player.position.x = table.position.x;
      world.player.position.y = table.position.y + 40.0;
      world.tick(0.1);

      expect(table.hasDirtyTray, isFalse);
      expect(table.isAvailable, isTrue);
      expect(world.player.carriedItems.contains(ItemType.dirtyTray), isTrue);

      // Absorb flying cash tip at table
      world.tick(0.6);
      expect(world.rupees, greaterThanOrEqualTo(25.0));

      // 6. Owner walks to trash bin and discards tray
      world.player.position.x = world.trashBin.position.x;
      world.player.position.y = world.trashBin.position.y;
      world.tick(0.1);

      expect(world.player.carriedCount, 0);
    });

    test('Dirty trays are strictly forbidden from depositing onto counter', () {
      final world = GameWorld();
      final counter = world.counter;

      // 1. Direct counter check
      expect(counter.addFoodItem(ItemType.dirtyTray), isFalse);
      expect(counter.foodTowers.any((t) => t.itemType == ItemType.dirtyTray), isFalse);

      // 2. Player carrying only dirty tray standing in food deposit zone
      world.player.addItem(ItemType.dirtyTray);
      expect(world.player.carriedCount, 1);

      world.player.position.x = 350.0;
      world.player.position.y = 700.0; // In food deposit zone
      expect(counter.isInsideFoodDepositZone(world.player.position), isTrue);

      world.tick(0.5);

      // Tray must remain in player's stack and NOT deposit onto counter
      expect(world.player.carriedCount, 1);
      expect(world.player.carriedItems.first, ItemType.dirtyTray);
      expect(counter.foodTowers.first.count, 0);

      // 3. Player carrying mixed items [dirtyTray, chai]
      world.player.addItem(ItemType.chai);
      expect(world.player.carriedCount, 2);

      world.tick(0.5);

      // Chai deposits onto counter, dirty tray remains in stack
      expect(counter.foodTowers.first.count, 1);
      expect(world.player.carriedCount, 1);
      expect(world.player.carriedItems.first, ItemType.dirtyTray);
    });
  });
}
