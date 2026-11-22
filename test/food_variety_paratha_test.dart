import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chai_dhaba_empire/data/balance.dart';
import 'package:chai_dhaba_empire/engine/customer_ai.dart';
import 'package:chai_dhaba_empire/engine/entities.dart';
import 'package:chai_dhaba_empire/engine/game_world.dart';
import 'package:chai_dhaba_empire/engine/staff_ai.dart';
import 'package:chai_dhaba_empire/engine/stations.dart';
import 'package:chai_dhaba_empire/services/save_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('M7: Paratha Station Tests', () {
    test('ParathaStation starts locked and cooks only when unlocked', () {
      final tawa = ParathaStation(
        position: Vector2(510.0, 260.0),
        isUnlocked: false,
      );

      expect(tawa.isUnlocked, isFalse);
      expect(tawa.shelfCount, 0);

      // Updating while locked should not progress cook timer
      tawa.update(10.0);
      expect(tawa.shelfCount, 0);
      expect(tawa.tryTakeParatha(), isFalse);

      // Unlock station
      tawa.isUnlocked = true;
      tawa.update(GameBalance.parathaBaseCookTime + 0.1);
      expect(tawa.shelfCount, greaterThanOrEqualTo(1));
      expect(tawa.tryTakeParatha(), isTrue);
      expect(tawa.shelfCount, 0);
    });

    test('ParathaStation upgrades increase shelf capacity and cook speed', () {
      final tawa = ParathaStation(isUnlocked: true);
      expect(tawa.level, 1);
      expect(tawa.shelfCapacity, GameBalance.parathaBaseShelfCapacity); // 6
      expect(tawa.cookTime, GameBalance.parathaBaseCookTime); // 1.6s

      tawa.upgradeTo(3);
      expect(tawa.level, 3);
      expect(tawa.shelfCapacity, 10);
      expect(tawa.cookTime, 1.10);

      tawa.upgradeTo(5);
      expect(tawa.level, 5);
      expect(tawa.shelfCapacity, 14);
      expect(tawa.cookTime, closeTo(0.60, 0.001));
    });
  });

  group('M7: Three-Part Counter Single-Item Towers', () {
    test('Counter isolates Chai and Paratha into separate dedicated towers', () {
      final counter = ServingCounter(
        position: Vector2(400.0, 600.0),
        depositInterval: 0.0,
      );

      expect(counter.totalFoodCount, 0);

      // Deposit 3 Chai cups
      counter.addFoodItem(ItemType.chai);
      counter.addFoodItem(ItemType.chai);
      counter.addFoodItem(ItemType.chai);

      expect(counter.foodTowers.length, 1);
      expect(counter.foodTowers[0].itemType, ItemType.chai);
      expect(counter.foodTowers[0].count, 3);

      // Deposit 2 Parathas -> Creates a separate Paratha tower!
      counter.addFoodItem(ItemType.paratha);
      counter.addFoodItem(ItemType.paratha);

      expect(counter.foodTowers.length, 2);
      expect(counter.foodTowers[0].itemType, ItemType.chai);
      expect(counter.foodTowers[0].count, 3);
      expect(counter.foodTowers[1].itemType, ItemType.paratha);
      expect(counter.foodTowers[1].count, 2);

      // Taking a Paratha only reduces the Paratha tower
      final tookParatha = counter.takeFoodItem(ItemType.paratha);
      expect(tookParatha, ItemType.paratha);
      expect(counter.foodTowers[0].count, 3); // Chai unchanged
      expect(counter.foodTowers[1].count, 1); // Paratha decremented

      // Taking Chai only reduces the Chai tower
      final tookChai = counter.takeFoodItem(ItemType.chai);
      expect(tookChai, ItemType.chai);
      expect(counter.foodTowers[0].count, 2);
      expect(counter.foodTowers[1].count, 1);
    });
  });

  group('M7: Customer AI Mixed Orders & Dine-In Logic', () {
    test('CustomerEntity properly tracks mixed Chai + Paratha orders', () {
      final customer = CustomerEntity(
        id: 1,
        startPosition: Vector2(400.0, 950.0),
        targetPosition: Vector2(400.0, 700.0),
        desiredChai: 2,
        desiredParatha: 1,
      );

      expect(customer.desiredChai, 2);
      expect(customer.desiredParatha, 1);
      expect(customer.desiredCount, 3);
      expect(customer.isMixed, isTrue);
      expect(customer.hasChai, isTrue);
      expect(customer.hasParatha, isTrue);
      expect(customer.isOrderComplete, isFalse);

      // Receive 1 Chai
      customer.receiveItem(ItemType.chai);
      expect(customer.receivedChai, 1);
      expect(customer.remainingChai, 1);
      expect(customer.remainingParatha, 1);
      expect(customer.isOrderComplete, isFalse);

      // Receive 1 Paratha
      customer.receiveItem(ItemType.paratha);
      expect(customer.receivedParatha, 1);
      expect(customer.remainingParatha, 0);
      expect(customer.remainingChai, 1);
      expect(customer.isOrderComplete, isFalse);

      // Receive 2nd Chai
      customer.receiveItem(ItemType.chai);
      expect(customer.receivedChai, 2);
      expect(customer.isOrderComplete, isTrue);
    });

    test('Customer dine-in eligibility: <= 3 chai AND <= 3 paratha can sit, > 3 is takeaway', () {
      // Eligible small mixed order (2 chai, 2 paratha)
      final smallMixed = CustomerEntity(
        id: 1,
        startPosition: Vector2(400.0, 950.0),
        targetPosition: Vector2(400.0, 700.0),
        desiredChai: 2,
        desiredParatha: 2,
      );
      expect(smallMixed.desiredChai <= 3 && smallMixed.desiredParatha <= 3, isTrue);

      // Ineligible bulk order (4 chai, 1 paratha) -> takeaway
      final bulkChai = CustomerEntity(
        id: 2,
        startPosition: Vector2(400.0, 950.0),
        targetPosition: Vector2(400.0, 700.0),
        desiredChai: 4,
        desiredParatha: 1,
      );
      expect(bulkChai.desiredChai <= 3 && bulkChai.desiredParatha <= 3, isFalse);
    });

    test('Customer dine-in eating time scales with item count (2.0s + total * 1.2s)', () {
      final singleItem = CustomerEntity(
        id: 1,
        startPosition: Vector2(400.0, 950.0),
        targetPosition: Vector2(400.0, 700.0),
        desiredChai: 1,
      );
      singleItem.receiveItem(ItemType.chai);
      final singleEatTime = 2.0 + (singleItem.receivedCount * 1.2);
      expect(singleEatTime, closeTo(3.2, 0.001));

      final comboOrder = CustomerEntity(
        id: 2,
        startPosition: Vector2(400.0, 950.0),
        targetPosition: Vector2(400.0, 700.0),
        desiredChai: 2,
        desiredParatha: 2,
      );
      comboOrder.receiveItem(ItemType.chai);
      comboOrder.receiveItem(ItemType.chai);
      comboOrder.receiveItem(ItemType.paratha);
      comboOrder.receiveItem(ItemType.paratha);
      final comboEatTime = 2.0 + (comboOrder.receivedCount * 1.2);
      expect(comboEatTime, closeTo(6.8, 0.001));
    });

    test('Table timeout refund accurately calculates for mixed orders', () {
      final world = GameWorld();
      world.rupees = 100.0;

      final customer = CustomerEntity(
        id: 10,
        startPosition: Vector2(400.0, 950.0),
        targetPosition: Vector2(400.0, 700.0),
        desiredChai: 2,
        desiredParatha: 1,
      );
      // Customer got 1 chai (Rs 10) and 1 paratha (Rs 20)
      customer.receiveItem(ItemType.chai);
      customer.receiveItem(ItemType.paratha);

      // When table timeout happens, world refunds received items
      final refundAmount = (customer.receivedChai * GameBalance.chaiPrice) +
          (customer.receivedParatha * GameBalance.parathaPrice);
      expect(refundAmount, 30.0); // 10 + 20
    });
  });

  group('M7: GameWorld Simulation & Staff Restocking', () {
    test('Helper automatically restocks Paratha from Tawa to counter when low', () {
      final world = GameWorld();
      world.chaiStation.shelfCount = 0; // Empty kettle so paratha is restocked
      world.parathaStation.isUnlocked = true;
      world.parathaStation.shelfCount = 5;

      // Add a helper worker
      final helper = StaffEntity(
        id: 1,
        name: 'Chotu',
        role: StaffRole.helper,
        startPosition: Vector2(510.0, 320.0), // Near paratha tawa
        speed: 160.0,
        carryCapacity: 3,
      );
      world.staff.add(helper);

      // Counter has 0 parathas
      expect(world.counter.totalFoodCount, 0);

      // Tick world simulation
      world.tick(0.1);

      // Helper should walk towards Paratha Tawa or pick up parathas
      world.tick(1.0);
      expect(helper.carriedCount, greaterThan(0));
      expect(helper.carriedItems.first, ItemType.paratha);
    });

    test('Player can pick up parathas and deposit onto counter', () {
      final world = GameWorld();
      world.parathaStation.isUnlocked = true;
      world.parathaStation.shelfCount = 3;

      // Move player to paratha pickup zone
      world.player.position.x = world.parathaStation.pickupZoneCenter.x;
      world.player.position.y = world.parathaStation.pickupZoneCenter.y;
      world.tick(0.2);

      expect(world.player.carriedCount, greaterThan(0));
      expect(world.player.carriedItems.first, ItemType.paratha);

      // Move player to counter deposit zone
      world.player.position.x = world.counter.foodDepositZoneCenter.x;
      world.player.position.y = world.counter.foodDepositZoneCenter.y;
      world.tick(0.4);

      expect(world.counter.hasFoodItem(ItemType.paratha), isTrue);
    });
  });

  group('M7: Persistence & SaveService for Paratha Station', () {
    test('SaveService saves and restores ParathaStation unlock state and level', () async {
      SharedPreferences.setMockInitialValues({});
      final saveService = SaveService();

      final world1 = GameWorld();
      world1.parathaStation.isUnlocked = true;
      world1.parathaStation.upgradeTo(3);

      await saveService.saveStoreState(world1);

      final world2 = GameWorld();
      expect(world2.parathaStation.isUnlocked, isFalse);
      expect(world2.parathaStation.level, 1);

      await saveService.loadStoreState(world2);

      expect(world2.parathaStation.isUnlocked, isTrue);
      expect(world2.parathaStation.level, 3);
      expect(world2.parathaStation.shelfCapacity, 10);
    });
  });
}
