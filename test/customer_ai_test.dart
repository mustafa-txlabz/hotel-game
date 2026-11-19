import 'package:flutter_test/flutter_test.dart';
import 'package:chai_dhaba_empire/engine/customer_ai.dart';
import 'package:chai_dhaba_empire/engine/entities.dart';
import 'package:chai_dhaba_empire/engine/game_world.dart';
import 'package:chai_dhaba_empire/engine/stations.dart';

void main() {
  group('Customer AI & Queue System (M3)', () {
    test('Customer enqueues into slot positions up to max capacity', () {
      final queue = CustomerQueue(
        headPosition: Vector2(450.0, 782.0),
        spacing: 46.0,
        maxCapacity: 3,
      );

      expect(queue.isEmpty, isTrue);
      expect(queue.isFull, isFalse);

      final c1 = CustomerEntity(
        id: 1,
        startPosition: Vector2(450.0, 1165.0),
        targetPosition: Vector2(0, 0),
      );
      final c2 = CustomerEntity(
        id: 2,
        startPosition: Vector2(450.0, 1165.0),
        targetPosition: Vector2(0, 0),
      );
      final c3 = CustomerEntity(
        id: 3,
        startPosition: Vector2(450.0, 1165.0),
        targetPosition: Vector2(0, 0),
      );
      final c4 = CustomerEntity(
        id: 4,
        startPosition: Vector2(450.0, 1165.0),
        targetPosition: Vector2(0, 0),
      );

      expect(queue.enqueue(c1), isTrue);
      expect(c1.targetPosition.x, 450.0);
      expect(c1.targetPosition.y, 782.0); // Slot 0

      expect(queue.enqueue(c2), isTrue);
      expect(c2.targetPosition.y, 782.0 + 46.0); // Slot 1

      expect(queue.enqueue(c3), isTrue);
      expect(c3.targetPosition.y, 782.0 + 46.0 * 2); // Slot 2
      expect(queue.isFull, isTrue);

      // 4th customer cannot enter full queue
      expect(queue.enqueue(c4), isFalse);
    });

    test(
      'Customer walks towards target slot and faces counter upon arrival',
      () {
        final customer = CustomerEntity(
          id: 1,
          startPosition: Vector2(450.0, 800.0),
          targetPosition: Vector2(450.0, 782.0),
          speed: 100.0,
        );

        expect(customer.isMoving, isFalse);
        customer.update(0.1); // Moves 10px towards 782
        expect(customer.isMoving, isTrue);
        expect(customer.position.y, closeTo(790.0, 0.1));

        customer.update(0.2); // Reaches 782.0
        expect(customer.position.y, 782.0);
        expect(customer.isMoving, isFalse);
      },
    );

    test(
      'Transaction rule: NO sales occur if Cashier green zone is unoccupied',
      () {
        final counter = ServingCounter();
        counter.addFoodItem(ItemType.chai);
        expect(counter.totalFoodCount, 1);
        expect(counter.cashBundleCount, 0);

        final system = CustomerSystem();
        final customer = system.spawnCustomer(item: ItemType.chai, count: 1)!;
        // Instantly position customer at slot 0
        customer.position.x = system.queue.getSlotPosition(0).x;
        customer.position.y = system.queue.getSlotPosition(0).y;
        customer.targetPosition = system.queue.getSlotPosition(0);

        // Cashier is NOT present
        counter.isCashierPresent = false;

        // Update system
        system.update(1.0, counter);

        // Food remains on counter, no cash earned, customer still waiting
        expect(counter.totalFoodCount, 1);
        expect(counter.cashBundleCount, 0);
        expect(customer.receivedCount, 0);
        expect(customer.patienceTimer, closeTo(1.0, 0.01));
        expect(customer.state, CustomerState.waitingInQueue);
      },
    );

    test('Patience expiration: Unattended customer leaves disappointed and queue advances', () {
      final counter = ServingCounter();
      final system = CustomerSystem();

      final c1 = system.spawnCustomer(item: ItemType.chai, count: 1)!;
      c1.position.x = system.queue.getSlotPosition(0).x;
      c1.position.y = system.queue.getSlotPosition(0).y;

      final c2 = system.spawnCustomer(item: ItemType.chai, count: 1)!;
      c2.position.x = system.queue.getSlotPosition(1).x;
      c2.position.y = system.queue.getSlotPosition(1).y;

      counter.isCashierPresent = false;

      // Elapse patience time (e.g. 23 seconds)
      for (int i = 0; i < 46; i++) {
        system.update(0.5, counter);
      }

      // c1 leaves unhappy
      expect(c1.state, CustomerState.leavingUnhappy);
      expect(c1.targetPosition.y, system.entrancePosition.y);

      // Queue advanced: c2 is now at head of queue
      expect(system.queue.head, c2);
      expect(c2.targetPosition.y, system.queue.getSlotPosition(0).y);
      expect(c2.patienceTimer, lessThan(c2.patienceTime));
    });

    test('Patience expiration when cashier is present but counter has no items', () {
      final counter = ServingCounter();
      final system = CustomerSystem();

      final c1 = system.spawnCustomer(item: ItemType.chai, count: 1)!;
      c1.position.x = system.queue.getSlotPosition(0).x;
      c1.position.y = system.queue.getSlotPosition(0).y;

      // Cashier is present, but NO items are available on the counter
      counter.isCashierPresent = true;
      expect(counter.totalFoodCount, 0);

      // Elapse patience time (23 seconds)
      for (int i = 0; i < 46; i++) {
        system.update(0.5, counter);
      }

      // Customer leaves disappointed because item was not served
      expect(c1.state, CustomerState.leavingUnhappy);
      expect(c1.targetPosition.y, system.entrancePosition.y);
    });

    test('Successful service: Cashier present + food available = sale and cash drop', () {
      final counter = ServingCounter();
      counter.addFoodItem(ItemType.chai);
      expect(counter.totalFoodCount, 1);
      expect(counter.cashBundleCount, 0);

      final system = CustomerSystem();
      final customer = system.spawnCustomer(item: ItemType.chai, count: 1)!;
      customer.position.x = system.queue.getSlotPosition(0).x;
      customer.position.y = system.queue.getSlotPosition(0).y;

      // Cashier is PRESENT!
      counter.isCashierPresent = true;

      // System update triggers service
      system.update(0.05, counter);

      // Chai taken from food tower
      expect(counter.totalFoodCount, 0);
      // Cash bundle dropped onto right cash tray
      expect(counter.cashBundleCount, 1);
      // Customer received item and departs happy
      expect(customer.receivedCount, 1);
      expect(customer.state, CustomerState.leavingHappy);
      expect(customer.targetPosition.y, system.entrancePosition.y);
      // Queue is now empty
      expect(system.queue.isEmpty, isTrue);
    });

    test('Despawning: Leaving customer despawns upon reaching entrance', () {
      final counter = ServingCounter();
      final system = CustomerSystem();
      final customer = system.spawnCustomer()!;

      customer.state = CustomerState.leavingHappy;
      customer.position.x = system.entrancePosition.x;
      customer.position.y = system.entrancePosition.y - 10.0;
      customer.targetPosition = system.entrancePosition;

      expect(system.activeCustomers.contains(customer), isTrue);

      system.update(0.1, counter);

      // Customer reached entrance and was removed
      expect(customer.state, CustomerState.despawned);
      expect(system.activeCustomers.contains(customer), isFalse);
    });
  });

  group('Full Customer Flow in GameWorld (M3)', () {
    test('End-to-end customer order, cashier check, cash vacuum loop', () {
      final world = GameWorld(initialRupees: 0.0);

      // 1. Owner deposits 1 chai into counter food towers
      world.chaiStation.shelfCount = 1;
      world.player.addItem(ItemType.chai);
      world.player.position.x = world.counter.foodDepositZoneCenter.x;
      world.player.position.y = world.counter.foodDepositZoneCenter.y;
      world.tick(0.05);

      expect(world.counter.totalFoodCount, 1);
      expect(world.counter.cashBundleCount, 0);

      // 2. Spawn customer and place at counter
      final customer = world.customerSystem.spawnCustomer(
        item: ItemType.chai,
        count: 1,
      )!;
      customer.position.x = world.customerSystem.queue.getSlotPosition(0).x;
      customer.position.y = world.customerSystem.queue.getSlotPosition(0).y;

      // 3. Owner walks to center green Cashier zone to attend customer
      world.player.position.x = world.counter.cashierZoneCenter.x;
      world.player.position.y = world.counter.cashierZoneCenter.y;

      world.tick(0.05);

      // Sale happens!
      expect(world.counter.isCashierPresent, isTrue);
      expect(world.counter.totalFoodCount, 0);
      expect(world.counter.cashBundleCount, 1);
      expect(customer.state, CustomerState.leavingHappy);

      // 4. Owner walks to right side of counter to vacuum up cash
      world.player.position.x = world.counter.cashCollectionZoneCenter.x;
      world.player.position.y = world.counter.cashCollectionZoneCenter.y;

      world.tick(0.05);
      expect(world.counter.cashBundleCount, 0);
      expect(world.cashBundles.length, 1);

      // Vacuum cash into wallet
      for (int i = 0; i < 20; i++) {
        world.tick(0.05);
      }

      expect(world.rupees, 10.0);
      expect(world.floatingTexts.isNotEmpty, isTrue);
      expect(world.floatingTexts.first.text, '+Rs 10');
    });
  });
}
