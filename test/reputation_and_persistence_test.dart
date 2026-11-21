import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chai_dhaba_empire/engine/customer_ai.dart';
import 'package:chai_dhaba_empire/engine/entities.dart';
import 'package:chai_dhaba_empire/engine/game_world.dart';
import 'package:chai_dhaba_empire/engine/stations.dart';
import 'package:chai_dhaba_empire/services/save_service.dart';

void main() {
  group('Per-Store Reputation System (M6.1)', () {
    test('Reputation percentage increases with customer served (+0.2%)', () {
      final world = GameWorld();
      expect(world.reputationPercent, 0.0);

      // 1 Customer (+0.2%)
      world.addReputationPercent(world.progressionConfig.customerReputationDelta);
      expect(world.reputationPercent, closeTo(0.2, 0.001));

      // 4 More Customers (+0.8% -> total 1.0%)
      for (int i = 0; i < 4; i++) {
        world.addReputationPercent(world.progressionConfig.customerReputationDelta);
      }
      expect(world.reputationPercent, closeTo(1.0, 0.001));
    });

    test('Sad customer deducts 0.2% down to minimum 0.0%', () {
      final world = GameWorld(initialReputationPercent: 0.5);
      expect(world.reputationPercent, closeTo(0.5, 0.001));

      // -0.2%
      world.addReputationPercent(world.progressionConfig.sadCustomerReputationDelta);
      expect(world.reputationPercent, closeTo(0.3, 0.001));

      // -0.2% again
      world.addReputationPercent(world.progressionConfig.sadCustomerReputationDelta);
      expect(world.reputationPercent, closeTo(0.1, 0.001));

      // -0.2% again (cannot drop below 0.0%)
      world.addReputationPercent(world.progressionConfig.sadCustomerReputationDelta);
      expect(world.reputationPercent, 0.0);
    });

    test('100% Lock Rule: Once 100% is reached, it locks permanently and never drops', () {
      final world = GameWorld(initialReputationPercent: 99.8);
      expect(world.isReputationLocked100, isFalse);

      // Push to 100%
      world.addReputationPercent(0.4);
      expect(world.reputationPercent, 100.0);
      expect(world.isReputationLocked100, isTrue);

      // Sad customers arrive: deduction must be completely blocked!
      world.addReputationPercent(-0.2);
      world.addReputationPercent(-5.0);
      expect(world.reputationPercent, 100.0);
      expect(world.isReputationLocked100, isTrue);
    });

    test('Customer spawn rate dynamically speeds up with higher reputation', () {
      final world = GameWorld(initialReputationPercent: 0.0);
      expect(world.customerSystem.spawnInterval, closeTo(6.0, 0.01));

      // At 25% reputation
      world.addReputationPercent(25.0);
      expect(world.reputationPercent, 25.0);
      expect(world.customerSystem.spawnInterval, closeTo(5.0, 0.01));

      // At 50% reputation
      world.addReputationPercent(25.0);
      expect(world.reputationPercent, 50.0);
      expect(world.customerSystem.spawnInterval, closeTo(4.0, 0.01));

      // At 75% reputation
      world.addReputationPercent(25.0);
      expect(world.reputationPercent, 75.0);
      expect(world.customerSystem.spawnInterval, closeTo(3.5, 0.01));

      // At 100% reputation
      world.addReputationPercent(25.0);
      expect(world.reputationPercent, 100.0);
      expect(world.customerSystem.spawnInterval, closeTo(3.5, 0.01));
    });

    test('Equipment and Staff upgrades do NOT modify reputation (driven 100% by customers)', () {
      final world = GameWorld(initialRupees: 5000.0);
      final initialRep = world.reputationPercent;

      // Hiring Cashier does NOT give reputation
      world.hireCashier();
      expect(world.reputationPercent, initialRep);

      // Hiring 1st Worker does NOT give reputation
      world.hireWorker();
      expect(world.reputationPercent, initialRep);

      // Upgrades do NOT give reputation
      world.upgradePlayerSpeed();
      expect(world.reputationPercent, initialRep);
    });

    test('Goal completion marks mission completed without reputation reward (customer-only)', () {
      final world = GameWorld(initialRupees: 5000.0);
      expect(world.completedMissionIds, isEmpty);

      // Hire Cashier completes 'hire_cashier' goal
      world.hireCashier();
      expect(world.completedMissionIds.contains('hire_cashier'), isTrue);
      // Reputation stays at 0.0% (reputation is driven strictly by served customers)
      expect(world.reputationPercent, 0.0);
    });
  });

  group('Expanded Queue & Crowded-Out Customers (M6.1)', () {
    test('Queue supports 8 customers without overflow', () {
      final queue = CustomerQueue(maxCapacity: 8);
      expect(queue.isFull, isFalse);

      for (int i = 0; i < 8; i++) {
        final customer = CustomerEntity(
          id: i + 1,
          startPosition: Vector2(450.0, 1165.0),
          targetPosition: queue.getSlotPosition(i),
        );
        expect(queue.enqueue(customer), isTrue);
      }

      expect(queue.isFull, isTrue);
      expect(queue.count, 8);
    });

    test('Crowded-out customer walks in, reacts unhappy, and turns back to entrance', () {
      final counter = ServingCounter();
      final system = CustomerSystem(
        queue: CustomerQueue(maxCapacity: 1),
      );

      // Fill queue with 1 customer
      system.spawnCustomer();
      expect(system.queue.isFull, isTrue);

      bool crowdedOutCalled = false;
      system.onCustomerCrowdedOut = (_) {
        crowdedOutCalled = true;
      };

      // Spawning when full creates crowded customer
      final crowded = system.spawnCrowdedCustomer();
      expect(crowded, isNotNull);
      expect(crowdedOutCalled, isTrue);
      expect(system.queue.customers.contains(crowded), isFalse);

      // Simulate arrival at threshold
      crowded!.position.x = crowded.targetPosition.x;
      crowded.position.y = crowded.targetPosition.y;

      system.update(0.1, counter);
      expect(crowded.state, CustomerState.leavingUnhappy);
      expect(crowded.targetPosition.y, closeTo(system.entrancePosition.y, 0.1));
    });
  });

  group('Multi-Store Save & Load Persistence (M6.1)', () {
    test('Saves and restores store state across sessions', () async {
      SharedPreferences.setMockInitialValues({});
      final saveService = SaveService();

      final world = GameWorld(initialRupees: 1250.0);
      world.reputationPercent = 34.0;
      world.hireCashier(free: true);
      world.hireWorker(free: true);
      world.diningTables[0].isUnlocked = true;
      world.completedMissionIds.add('hire_cashier');

      // Save
      final saveSuccess = await saveService.saveStoreState(world);
      expect(saveSuccess, isTrue);

      // Create fresh blank world
      final freshWorld = GameWorld(initialRupees: 0.0);
      expect(freshWorld.rupees, 0.0);
      expect(freshWorld.reputationPercent, 0.0);
      expect(freshWorld.hasCashier, isFalse);
      expect(freshWorld.workerCount, 0);
      expect(freshWorld.diningTables[0].isUnlocked, isFalse);

      // Load into fresh world
      final loadSuccess = await saveService.loadStoreState(freshWorld);
      expect(loadSuccess, isTrue);

      // Verify exact restoration
      expect(freshWorld.rupees, world.rupees);
      expect(freshWorld.reputationPercent, world.reputationPercent);
      expect(freshWorld.hasCashier, isTrue);
      expect(freshWorld.workerCount, 1);
      expect(freshWorld.diningTables[0].isUnlocked, isTrue);
      expect(freshWorld.completedMissionIds.contains('hire_cashier'), isTrue);
      expect(freshWorld.customerSystem.spawnInterval, closeTo(world.customerSystem.spawnInterval, 0.05));
    });
  });
}
