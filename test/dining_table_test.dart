import 'dart:math' as math;

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

      // All seats occupied makes table unavailable
      table.isOccupied = true;
      expect(table.isAvailable, isFalse);

      table.isOccupied = false;
      expect(table.isAvailable, isTrue);

      // Dirty table is not available
      table.hasDirtyTray = true;
      expect(table.isAvailable, isFalse);
    });

    test('4-Seat positions and clean zone reach', () {
      final table = DiningTable(
        id: 1,
        position: Vector2(200.0, 950.0),
        width: 130.0,
        height: 68.0,
        isUnlocked: true,
      );

      expect(table.seats.length, 4);

      // Top seats face South (math.pi / 2)
      expect(table.seats[0].facingAngle, math.pi / 2);
      expect(table.seats[0].position.x, 170.0);
      expect(table.seats[0].position.y, 950.0 - 34.0 - 14.0);

      expect(table.seats[1].facingAngle, math.pi / 2);
      expect(table.seats[1].position.x, 230.0);

      // Bottom seats face North (-math.pi / 2)
      expect(table.seats[2].facingAngle, -math.pi / 2);
      expect(table.seats[2].position.x, 170.0);
      expect(table.seats[2].position.y, 950.0 + 34.0 + 14.0);

      expect(table.seats[3].facingAngle, -math.pi / 2);
      expect(table.seats[3].position.x, 230.0);

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
      customer.position.x = 450.0;
      customer.position.y = 782.0;

      expect(table.isAvailable, isTrue);

      system.update(0.1, counter);

      expect(customer.isOrderComplete, isTrue);
      expect(customer.state, CustomerState.walkingToTable);
      expect(customer.assignedTable, table);
      expect(customer.assignedSeat, isNotNull);
      expect(customer.assignedSeat!.isOccupied, isTrue);
      expect(table.occupiedCount, 1);
      expect(table.isAvailable, isTrue); // Other 3 seats are still open!
      expect(table.isFullyOccupied, isFalse);
      expect(system.queue.isEmpty, isTrue);
    });

    test('Served customer takes takeaway if order is > 3 items', () {
      final counter = ServingCounter(position: Vector2(450.0, 720.0));
      counter.isCashierPresent = true;
      counter.foodTowers.first.count = 4; // 4 cups ready

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

      final customer = system.spawnCustomer(item: ItemType.chai, count: 4)!;
      customer.position.x = 450.0;
      customer.position.y = 782.0;

      for (int i = 0; i < 4; i++) {
        counter.serviceTimer = 0.0;
        system.update(0.1, counter);
      }

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

      final seat = table.seats.first;
      final customer = CustomerEntity(
        id: 1,
        startPosition: Vector2(450.0, 782.0),
        targetPosition: seat.position.copy(),
        eatDuration: 4.0,
      );
      customer.state = CustomerState.walkingToTable;
      customer.assignedTable = table;
      customer.assignedSeat = seat;
      seat.isOccupied = true;
      system.activeCustomers.add(customer);

      // Walk to table seat
      customer.update(2.0);
      expect(customer.isMoving, isTrue);
      expect(customer.state, CustomerState.walkingToTable);
      expect(seat.isOccupied, isTrue);
      expect(seat.isSeated, isFalse); // Item not shown on table while customer is walking!

      // Arrive at stool seat
      customer.position.x = seat.position.x;
      customer.position.y = seat.position.y;
      customer.update(0.1);

      expect(customer.state, CustomerState.eating);
      expect(customer.isMoving, isFalse);
      expect(customer.eatTimer, 0.0);
      expect(customer.angle, seat.facingAngle); // Faces table!
      expect(seat.isSeated, isTrue); // Item now appears on table once customer is seated!

      // Simulate eating for 3 seconds
      system.update(3.0, ServingCounter());
      expect(customer.state, CustomerState.eating);
      expect(seat.hasDirtyTray, isFalse);
      expect(seat.cashTip, 0.0);
      expect(seat.isSeated, isTrue);

      // Finish eating
      system.update(1.5, ServingCounter());

      expect(customer.state, CustomerState.leavingHappy);
      expect(customer.hasDinedIn, isTrue);
      expect(customer.assignedTable, isNull);
      expect(customer.assignedSeat, isNull);
      expect(seat.isOccupied, isFalse);
      expect(seat.isSeated, isFalse);
      expect(seat.hasDirtyTray, isTrue);
      expect(seat.cashTip, GameBalance.dineInTip); // Rs 25 tip!
      expect(seat.isAvailable, isFalse);
    });

    test('4 customers can dine in at the same table simultaneously (2 top, 2 bottom)', () {
      final counter = ServingCounter(position: Vector2(450.0, 720.0));
      counter.isCashierPresent = true;
      counter.foodTowers.first.count = 5;

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

      // Spawn and serve 4 customers in succession
      final customers = <CustomerEntity>[];
      for (int i = 0; i < 4; i++) {
        counter.serviceTimer = 0.0; // Ready to serve immediately
        final c = system.spawnCustomer(item: ItemType.chai, count: 1)!;
        c.position.x = 450.0;
        c.position.y = 782.0;
        system.update(0.1, counter);
        customers.add(c);
      }

      // Verify all 4 customers got unique seats at the table!
      expect(table.occupiedCount, 4);
      expect(table.isFullyOccupied, isTrue);
      expect(table.isAvailable, isFalse); // All 4 seats are full!

      final assignedSeatIndices = customers.map((c) => c.assignedSeat!.index).toSet();
      expect(assignedSeatIndices, {0, 1, 2, 3}); // Top-left, top-right, bottom-left, bottom-right!

      // 5th customer arrives when table is fully occupied
      counter.serviceTimer = 0.0;
      final fifthCustomer = system.spawnCustomer(item: ItemType.chai, count: 1)!;
      fifthCustomer.position.x = 450.0;
      fifthCustomer.position.y = 782.0;
      system.update(0.1, counter);

      // 5th customer waits near tables for 2.5s!
      expect(fifthCustomer.state, CustomerState.waitingForTable);
      expect(fifthCustomer.assignedTable, isNull);
    });

    test('Customer waiting for table gives up after 2.5s, refunds Rs 10 per cup and loses reputation', () {
      final world = GameWorld(initialRupees: 100.0, initialReputationPercent: 10.0);
      world.hireCashier(free: true);
      final initialRep = world.reputationPercent;

      // Table 1 is unlocked but fully occupied
      world.diningTables[0].isUnlocked = true;
      for (final s in world.diningTables[0].seats) {
        s.isOccupied = true;
      }
      world.diningTables[1].isUnlocked = false;

      world.counter.foodTowers.first.count = 5;
      world.counter.serviceTimer = 0.0;

      final customer = world.customerSystem.spawnCustomer(item: ItemType.chai, count: 1)!;
      customer.position.x = 450.0;
      customer.position.y = 782.0;

      for (int i = 0; i < 20; i++) {
        world.tick(0.05);
      }
      expect(customer.state, CustomerState.waitingForTable);
      expect(world.reputationPercent, closeTo(initialRep + 0.2, 0.001)); // Served +0.2%
      expect(world.rupees, 100.0); // No refund yet, waiting for table

      // Wait 1.5s (total 1.6s) -> still waiting
      world.tick(1.5);
      expect(customer.state, CustomerState.waitingForTable);
      expect(world.rupees, 100.0);

      // Wait another 1.0s (total 2.6s >= 2.5s timeout)
      world.tick(1.0);
      expect(customer.state, CustomerState.leavingUnhappy);
      expect(world.rupees, 90.0); // Rs 10 refunded!
      expect(world.reputationPercent, closeTo(initialRep, 0.001)); // Penalty deducted -0.2%!
    });

    test('Customer waiting for table takes seat if table becomes free before 2.5s', () {
      final table = DiningTable(
        id: 1,
        position: Vector2(200.0, 950.0),
        isUnlocked: true,
      );
      // Occupy all seats
      for (final s in table.seats) {
        s.isOccupied = true;
      }
      expect(table.isAvailable, isFalse);

      final counter = ServingCounter(position: Vector2(450.0, 720.0));
      counter.isCashierPresent = true;
      counter.addFoodItem(ItemType.chai);

      final system = CustomerSystem(
        queue: CustomerQueue(headPosition: Vector2(450.0, 782.0)),
        entrancePosition: Vector2(450.0, 1165.0),
        tables: [table],
      );

      final customer = system.spawnCustomer(item: ItemType.chai, count: 1)!;
      customer.position.x = 450.0;
      customer.position.y = 782.0;
      system.update(0.1, counter);
      expect(customer.state, CustomerState.waitingForTable);

      // Wait 1.0s
      system.update(1.0, counter);
      expect(customer.state, CustomerState.waitingForTable);

      // Free a seat!
      table.seats.first.isOccupied = false;
      table.seats.first.isSeated = false;
      table.seats.first.hasDirtyTray = false;
      expect(table.isAvailable, isTrue);

      // Next tick: customer claims seat!
      system.update(0.1, counter);
      expect(customer.state, CustomerState.walkingToTable);
      expect(customer.assignedSeat, table.seats.first);
      expect(table.seats.first.isOccupied, isTrue);
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
      expect(world.cashBundles.isNotEmpty, isTrue);

      // 2. Tray picked up into player stack
      expect(table.hasDirtyTray, isFalse);
      expect(table.isAvailable, isTrue);
      expect(world.player.carriedCount, 1);
      expect(world.player.carriedItems.last, ItemType.dirtyTray);

      // 3. Cash bundle absorbs into wallet
      world.tick(1.0);
      expect(world.rupees, greaterThanOrEqualTo(25.0));
    });

    test('Owner dumps carried dirty tray at Trash Bin', () {
      final world = GameWorld();
      world.player.addItem(ItemType.dirtyTray);
      expect(world.player.carriedCount, 1);

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

      customer.position.x = 450.0;
      customer.position.y = 782.0;

      // 3. Owner stands at cashier
      world.player.position.x = world.counter.cashierZoneCenter.x;
      world.player.position.y = world.counter.cashierZoneCenter.y;

      for (int i = 0; i < 20; i++) {
        world.tick(0.05);
      }

      // Customer served and heads to Table 1 seat
      expect(customer.state, CustomerState.walkingToTable);
      expect(customer.assignedTable, table);
      expect(customer.assignedSeat, isNotNull);

      // 4. Customer arrives at assigned seat and eats
      customer.position.x = customer.assignedSeat!.position.x;
      customer.position.y = customer.assignedSeat!.position.y;
      world.tick(0.1);
      expect(customer.state, CustomerState.eating);

      // Finish eating
      world.tick(GameBalance.customerEatDuration + 0.5);

      expect(customer.state, CustomerState.leavingHappy);
      expect(table.hasDirtyTray, isTrue);
      expect(table.cashTip, 25.0);

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
