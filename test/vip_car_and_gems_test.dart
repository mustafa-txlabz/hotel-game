import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chai_dhaba_empire/engine/entities.dart';
import 'package:chai_dhaba_empire/engine/game_world.dart';
import 'package:chai_dhaba_empire/engine/stations.dart';
import 'package:chai_dhaba_empire/engine/vip_car.dart';
import 'package:chai_dhaba_empire/services/save_service.dart';
import 'package:chai_dhaba_empire/ui/overlays/hud_overlay.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VipCar Entity & Physics Tests', () {
    test('VipCar initializes with correct attributes, dimensions and solid box', () {
      final car = VipCar(
        id: 1,
        model: CarModel.sedan,
        direction: CarDirection.eastBound,
        color: const Color(0xFFE53935),
        startPosition: Vector2(-150, 1360),
        targetParkPosition: Vector2(450, 1360),
        desiredChai: 15,
        desiredParatha: 15,
        patienceTime: 15.0,
      );

      expect(car.id, 1);
      expect(car.state, CarState.drivingIn);
      expect(car.totalDesired, 30);
      expect(car.remainingChai, 15);
      expect(car.remainingParatha, 15);
      expect(car.progress, 0.0);
      expect(car.collisionBox.width, car.width);
      expect(car.collisionBox.height, car.height);
      expect(car.curbsideDropZone.center.dy, 1260.0);
    });

    test('VipCar drives in, parks at curb, and resets patience upon loading', () {
      final car = VipCar(
        id: 2,
        model: CarModel.suv,
        direction: CarDirection.eastBound,
        color: const Color(0xFF1E88E5),
        startPosition: Vector2(440, 1360),
        targetParkPosition: Vector2(450, 1360),
        desiredChai: 2,
        desiredParatha: 2,
        patienceTime: 15.0,
      );

      // 1. Step physics until parked
      car.update(0.1);
      expect(car.state, CarState.parkedWaitingOrder);
      expect(car.position.x, 450.0);

      // 2. Patience timer advances while waiting
      car.update(5.0);
      expect(car.patienceTimer, 5.0);

      // 3. Receiving item loads car and RESETS patience timer to 0!
      final loadedChai = car.receiveItem(ItemType.chai);
      expect(loadedChai, isTrue);
      expect(car.receivedChai, 1);
      expect(car.remainingChai, 1);
      expect(car.patienceTimer, 0.0); // Reset!

      // 4. Loading paratha also resets patience
      car.update(3.0);
      expect(car.patienceTimer, 3.0);
      final loadedParatha = car.receiveItem(ItemType.paratha);
      expect(loadedParatha, isTrue);
      expect(car.receivedParatha, 1);
      expect(car.patienceTimer, 0.0); // Reset!
    });

    test('VipCar two-way travel: West-bound car drives from right to left', () {
      final car = VipCar(
        id: 3,
        model: CarModel.vintage,
        direction: CarDirection.westBound,
        color: const Color(0xFFFFB300),
        startPosition: Vector2(460, 1360),
        targetParkPosition: Vector2(450, 1360),
        desiredChai: 1,
        desiredParatha: 1,
      );

      car.update(0.1);
      expect(car.state, CarState.parkedWaitingOrder);
      expect(car.position.x, 450.0);

      // Complete order & drive out west
      car.receiveItem(ItemType.chai);
      car.receiveItem(ItemType.paratha);
      expect(car.isOrderComplete, isTrue);

      car.state = CarState.drivingOut;
      car.update(1.0);
      // Westbound driving out moves left (x decreases)
      expect(car.position.x, lessThan(450.0));
    });

    test('Random generator creates valid models, colors, and bulk orders', () {
      final car = VipCar.createRandom(id: 10);
      expect(car.id, 10);
      expect(car.totalDesired, greaterThanOrEqualTo(24));
      expect(car.gemsReward, 3);
      expect(car.cashTip, 1000.0);
      expect(car.patienceTime, 15.0);
    });
  });

  group('GameWorld VVIP Curbside Loading & Gems Economy Tests', () {
    test('Spawning VVIP car initializes car and cinematic camera glance', () {
      final world = GameWorld();
      expect(world.activeVipCar, isNull);
      expect(world.gems, 0);

      world.spawnVipCar();
      expect(world.activeVipCar, isNotNull);
      expect(world.cinematicCameraTarget, isNotNull);
      expect(world.cinematicCameraTimer, 1.8);

      // Advance world simulation past cinematic timer
      world.tick(2.0);
      expect(world.cinematicCameraTarget, isNull);
      expect(world.cinematicCameraTimer, isNull);
    });

    test('Solid collision stops player from phasing through parked VVIP car', () {
      final world = GameWorld();
      world.spawnVipCar();
      final car = world.activeVipCar!;
      car.position.x = 450.0;
      car.position.y = 1360.0;
      car.state = CarState.parkedWaitingOrder;

      // Position player just above the car and push down into it
      world.player.position.x = 450.0;
      world.player.position.y = 1300.0;
      world.player.velocity.x = 0.0;
      world.player.velocity.y = 200.0;

      world.tick(0.05);

      // Player must be blocked by car collision box
      expect(world.player.position.y, lessThan(1325.0));
    });

    test('Player at curbside unloads bulk order, granting 3 GEMS and ₹1,000 cash tip', () {
      final world = GameWorld();
      world.spawnVipCar();
      final car = world.activeVipCar!;
      car.position.x = 450.0;
      car.state = CarState.parkedWaitingOrder;

      // Give player exact carried items matching car requirements
      world.player.carriedItems
        ..clear()
        ..addAll(List.generate(car.desiredChai, (_) => ItemType.chai))
        ..addAll(List.generate(car.desiredParatha, (_) => ItemType.paratha));
      world.player.carryCapacity = 50;

      // Position player inside curbside drop zone on sidewalk (y = 1260)
      world.player.position.x = 450.0;
      world.player.position.y = 1260.0;

      expect(car.isInsideDropZone(world.player.position), isTrue);

      final initialRupees = world.rupees;
      final initialGems = world.gems;

      // Tick world to trigger curbside drop transfer
      world.tick(0.05);

      // Car should be complete, transition to drivingOut, and grant rewards
      expect(car.isOrderComplete, isTrue);
      expect(car.state, CarState.drivingOut);
      expect(world.gems, initialGems + 3);
      expect(world.rupees, initialRupees + 1000.0);
      expect(world.player.carriedItems.isEmpty, isTrue);
    });
  });

  group('SaveService Gems Persistence Tests', () {
    test('Gems are persisted and restored across game sessions', () async {
      SharedPreferences.setMockInitialValues({});
      final saveService = SaveService();
      await saveService.init();

      final world1 = GameWorld();
      world1.gems = 18;
      world1.rupees = 5000.0;

      final saved = await saveService.saveStoreState(world1);
      expect(saved, isTrue);

      final world2 = GameWorld();
      expect(world2.gems, 0);

      final loaded = await saveService.loadStoreState(world2);
      expect(loaded, isTrue);
      expect(world2.gems, 18);
      expect(world2.rupees, 5000.0);
    });
  });

  group('HUD Overlay Gems Badge Test', () {
    testWidgets('Renders Gems counter badge alongside cash and carry counter', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HudOverlay(
              rupees: 2500,
              gems: 15,
              carriedCount: 3,
              carryCapacity: 8,
              reputationPercent: 45.0,
              reputationLevel: 2,
            ),
          ),
        ),
      );

      // Verify diamond icon and gems count 15 are rendered
      expect(find.byIcon(Icons.diamond_rounded), findsOneWidget);
      expect(find.text('15'), findsOneWidget);
      expect(find.byIcon(Icons.currency_rupee_rounded), findsOneWidget);
      expect(find.text('Rs 2.50K'), findsOneWidget);
    });
  });
}
