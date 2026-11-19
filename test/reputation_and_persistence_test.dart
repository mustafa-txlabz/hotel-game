import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chai_dhaba_empire/engine/customer_ai.dart';
import 'package:chai_dhaba_empire/engine/entities.dart';
import 'package:chai_dhaba_empire/engine/game_world.dart';
import 'package:chai_dhaba_empire/engine/stations.dart';
import 'package:chai_dhaba_empire/services/save_service.dart';

void main() {
  group('Per-Store Reputation System (M6.1)', () {
    test('Reputation XP increases with Takeaway customer and Dine-In customer', () {
      final world = GameWorld();
      expect(world.reputationXP, 0);
      expect(world.reputationPercent, 0.0);

      // Takeaway (+2 XP)
      world.addReputationXP(world.progressionConfig.happyTakeawayXP);
      expect(world.reputationXP, 2);
      expect(world.reputationPercent, 0.2);

      // Dine-in (+4 XP)
      world.addReputationXP(world.progressionConfig.happyDineInXP);
      expect(world.reputationXP, 6);
      expect(world.reputationPercent, 0.6);
    });

    test('Sad customer deducts XP down to minimum 0', () {
      final world = GameWorld(initialReputationXP: 5);
      expect(world.reputationXP, 5);

      // -3 XP
      world.addReputationXP(world.progressionConfig.sadCustomerXP);
      expect(world.reputationXP, 2);

      // -3 XP again (cannot drop below 0)
      world.addReputationXP(world.progressionConfig.sadCustomerXP);
      expect(world.reputationXP, 0);
    });

    test('100% Lock Rule: Once 100% is reached, it locks permanently and never drops', () {
      final world = GameWorld(initialReputationXP: 998);
      expect(world.isReputationLocked100, isFalse);

      // Push to 1000 XP (100%)
      world.addReputationXP(10);
      expect(world.reputationXP, 1000);
      expect(world.reputationPercent, 100.0);
      expect(world.isReputationLocked100, isTrue);

      // Sad customers arrive: deduction must be completely blocked!
      world.addReputationXP(-3);
      world.addReputationXP(-50);
      expect(world.reputationXP, 1000);
      expect(world.reputationPercent, 100.0);
      expect(world.isReputationLocked100, isTrue);
    });

    test('Customer spawn rate dynamically speeds up with higher reputation', () {
      final world = GameWorld(initialReputationXP: 0);
      expect(world.customerSystem.spawnInterval, closeTo(4.0, 0.01));

      // At 50% reputation (500 XP)
      world.addReputationXP(500);
      expect(world.reputationPercent, 50.0);
      expect(world.customerSystem.spawnInterval, closeTo(2.9, 0.05));

      // At 100% reputation (1000 XP)
      world.addReputationXP(500);
      expect(world.reputationPercent, 100.0);
      expect(world.customerSystem.spawnInterval, closeTo(1.8, 0.01));
    });

    test('Equipment and Staff upgrades reward bonus reputation XP', () {
      final world = GameWorld(initialRupees: 5000.0);
      final initialXP = world.reputationXP;

      // Hiring Cashier gives upgrade XP (+20) + 'hire_cashier' mission reward (+60) = +80
      world.hireCashier();
      expect(world.reputationXP, initialXP + world.progressionConfig.upgradeXP + 60);

      // Hiring 1st Worker gives upgrade XP (+20) (mission requires 3 workers)
      final afterCashierXP = world.reputationXP;
      world.hireWorker();
      expect(world.reputationXP, afterCashierXP + world.progressionConfig.upgradeXP);
    });

    test('Goal completion awards XP and marks mission completed', () {
      final world = GameWorld(initialRupees: 5000.0);
      expect(world.completedMissionIds, isEmpty);

      // Hire Cashier completes 'hire_cashier' goal
      world.hireCashier();
      expect(world.completedMissionIds.contains('hire_cashier'), isTrue);
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
      world.reputationXP = 340;
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
      expect(freshWorld.reputationXP, 0);
      expect(freshWorld.hasCashier, isFalse);
      expect(freshWorld.workerCount, 0);
      expect(freshWorld.diningTables[0].isUnlocked, isFalse);

      // Load into fresh world
      final loadSuccess = await saveService.loadStoreState(freshWorld);
      expect(loadSuccess, isTrue);

      // Verify exact restoration
      expect(freshWorld.rupees, world.rupees);
      expect(freshWorld.reputationXP, world.reputationXP);
      expect(freshWorld.hasCashier, isTrue);
      expect(freshWorld.workerCount, 1);
      expect(freshWorld.diningTables[0].isUnlocked, isTrue);
      expect(freshWorld.completedMissionIds.contains('hire_cashier'), isTrue);
      expect(freshWorld.customerSystem.spawnInterval, closeTo(world.customerSystem.spawnInterval, 0.05));
    });
  });
}
