import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:chai_dhaba_empire/engine/entities.dart';
import 'package:chai_dhaba_empire/engine/game_world.dart';
import 'package:chai_dhaba_empire/engine/stations.dart';

void main() {
  group('Arcade Engine - Movement & Physics (M0)', () {
    test('Player starts at center of dhaba floor with zero velocity', () {
      final world = GameWorld();
      expect(world.player.position.x, 450.0);
      expect(world.player.position.y, 600.0);
      expect(world.player.velocity.x, 0.0);
      expect(world.player.velocity.y, 0.0);
      expect(world.player.isMoving, isFalse);
    });

    test('Joystick input correctly calculates velocity in 360 degrees', () {
      final world = GameWorld();
      world.setJoystickInput(1.0, 0.0);
      expect(world.player.velocity.x, world.player.speed);
      expect(world.player.velocity.y, 0.0);

      world.setJoystickInput(1.0, 1.0);
      final expectedComponent = world.player.speed / math.sqrt(2);
      expect(world.player.velocity.x, closeTo(expectedComponent, 0.1));
      expect(world.player.velocity.y, closeTo(expectedComponent, 0.1));

      world.setJoystickInput(0.0, 0.0);
      expect(world.player.velocity.x, 0.0);
      expect(world.player.velocity.y, 0.0);
    });

    test('Player smoothly collides with and clamps to boundary walls', () {
      final world = GameWorld(
        worldWidth: 900.0,
        worldHeight: 1200.0,
        wallThickness: 30.0,
      );
      world.setJoystickInput(-1.0, 0.0);
      for (int i = 0; i < 100; i++) {
        world.tick(0.1);
      }

      final minX = world.wallThickness + world.player.radius;
      expect(world.player.position.x, closeTo(minX, 0.01));
      expect(world.player.position.x >= minX, isTrue);
    });
  });

  group('Arcade Engine - Kitchen Station & Stacking Physics (M1)', () {
    test('Chai station brews cups up to shelf capacity', () {
      final station = ChaiStation(brewTime: 1.0, shelfCapacity: 5);
      station.shelfCount = 0;

      station.update(0.5);
      expect(station.shelfCount, 0);
      expect(station.brewProgress, closeTo(0.5, 0.01));

      station.update(0.5);
      expect(station.shelfCount, 1);
      expect(station.brewProgress, 0.0);

      station.update(10.0);
      expect(station.shelfCount, 5);
    });

    test('Player picking up cups from station into head stack', () {
      final world = GameWorld();
      world.chaiStation.shelfCount = 5;

      world.player.position.x = world.chaiStation.pickupZoneCenter.x;
      world.player.position.y = world.chaiStation.pickupZoneCenter.y;

      expect(world.player.carriedCount, 0);
      world.tick(0.05);
      expect(world.player.carriedCount, 1);
      expect(world.chaiStation.shelfCount, 4);

      world.tick(0.2);
      expect(world.player.carriedCount, 2);

      world.tick(0.2);
      expect(world.player.carriedCount, 3);
      expect(world.player.isFull, isTrue);

      world.tick(0.5);
      expect(world.player.carriedCount, 3);
    });

    test('Player can pick up cups from all sides of kettle (front, behind, left, right)', () {
      final station = ChaiStation(
        position: Vector2(240.0, 240.0),
        width: 130.0,
        height: 70.0,
      );

      // In front (y = 240 + 35 + 25 = 300)
      expect(station.isInsidePickupZone(Vector2(240.0, 300.0)), isTrue);

      // Behind (y = 240 - 35 - 25 = 180)
      expect(station.isInsidePickupZone(Vector2(240.0, 180.0)), isTrue);

      // Left flank (x = 240 - 65 - 25 = 150)
      expect(station.isInsidePickupZone(Vector2(150.0, 240.0)), isTrue);

      // Right flank (x = 240 + 65 + 25 = 330)
      expect(station.isInsidePickupZone(Vector2(330.0, 240.0)), isTrue);

      // Far away outside zone
      expect(station.isInsidePickupZone(Vector2(500.0, 500.0)), isFalse);
    });

    test(
      'Stack wobble angle activates when moving and damps when stopping',
      () {
        final player = PlayerEntity();
        player.velocity.x = 200.0;
        player.update(0.1);

        expect(player.isMoving, isTrue);
        expect(player.wobbleAngle.abs(), greaterThan(0.0));

        player.velocity.x = 0.0;
        for (int i = 0; i < 20; i++) {
          player.update(0.1);
        }
        expect(player.isMoving, isFalse);
        expect(player.wobbleAngle.abs(), closeTo(0.0, 0.01));
      },
    );
  });

  group(
    'Arcade Engine - Three-Part Counter, Food Towers & Cash Towers (M2)',
    () {
      test('Player deposits carried food into left counter food towers', () {
        final world = GameWorld();
        world.player.addItem(ItemType.chai);
        world.player.addItem(ItemType.chai);
        expect(world.player.carriedCount, 2);
        expect(world.counter.totalFoodCount, 0);

        // Stand in food deposit zone (left side behind counter)
        world.player.position.x = world.counter.foodDepositZoneCenter.x;
        world.player.position.y = world.counter.foodDepositZoneCenter.y;

        world.tick(0.05);
        expect(world.player.carriedCount, 1);
        expect(world.counter.totalFoodCount, 1);
        expect(world.counter.foodTowers.first.itemType, ItemType.chai);
        expect(world.counter.foodTowers.first.count, 1);

        // After deposit interval, second item deposits
        world.tick(0.2);
        expect(world.player.carriedCount, 0);
        expect(world.counter.totalFoodCount, 2);
        expect(world.counter.foodTowers.first.count, 2);
      });

      test('Strict single-item tower logic with max tower height', () {
        final counter = ServingCounter();
        // Initially 0 items
        expect(counter.totalFoodCount, 0);

        // Add 10 chai items to fill first tower
        for (int i = 0; i < 10; i++) {
          counter.depositTimer = 0.0;
          final success = counter.addFoodItem(ItemType.chai);
          expect(success, isTrue);
        }
        expect(counter.foodTowers.length, 1);
        expect(counter.foodTowers.first.isFull, isTrue);
        expect(counter.foodTowers.first.count, 10);

        // 11th chai creates a second tower
        counter.depositTimer = 0.0;
        final added11th = counter.addFoodItem(ItemType.chai);
        expect(added11th, isTrue);
        expect(counter.foodTowers.length, 2);
        expect(counter.foodTowers[1].count, 1);
        expect(counter.totalFoodCount, 11);
      });

      test('Cashier presence requirement: no service unless someone is in green zone', () {
        final world = GameWorld();
        world.counter.addFoodItem(ItemType.chai);
        expect(world.counter.totalFoodCount, 1);
        expect(world.counter.cashBundleCount, 0);

        // Player is NOT at cashier station (e.g. at 450, 500)
        world.player.position.x = 450.0;
        world.player.position.y = 500.0;

        world.tick(0.5);
        // No service occurred because cashier green zone is empty
        expect(world.counter.isCashierPresent, isFalse);
        expect(world.counter.totalFoodCount, 1);
        expect(world.counter.cashBundleCount, 0);

        // Player steps into center green cashier zone
        world.player.position.x = world.counter.cashierZoneCenter.x;
        world.player.position.y = world.counter.cashierZoneCenter.y;

        world.tick(0.05);
        // Service triggered! Food converted to cash tower on right
        expect(world.counter.isCashierPresent, isTrue);
        expect(world.counter.totalFoodCount, 0);
        expect(world.counter.cashBundleCount, 1);
      });

      test(
        'Collecting cash from right-side cash towers vacuums into wallet',
        () {
          final world = GameWorld(initialRupees: 0.0);
          world.counter.cashBundleCount = 2;

          // Stand in cash collection zone (right side behind counter)
          world.player.position.x = world.counter.cashCollectionZoneCenter.x;
          world.player.position.y = world.counter.cashCollectionZoneCenter.y;

          world.tick(0.05);
          // 1 cash bundle launched as flying bundle
          expect(world.counter.cashBundleCount, 1);
          expect(world.cashBundles.length, 1);

          // Tick world until cash reaches player and gets absorbed into wallet
          for (int i = 0; i < 20; i++) {
            world.tick(0.05);
          }
          // Both bundles vacuumed into wallet
          expect(world.rupees, 20.0);
          expect(world.counter.cashBundleCount, 0);
          expect(world.floatingTexts.isNotEmpty, isTrue);
          expect(world.floatingTexts.first.text, '+Rs 10');
        },
      );

      test('Player can deposit food from the left flank of the counter', () {
        final world = GameWorld();
        world.player.addItem(ItemType.chai);
        expect(world.player.carriedCount, 1);
        expect(world.counter.totalFoodCount, 0);

        // Stand at the left side (flank) of the counter
        world.player.position.x = 270.0;
        world.player.position.y = 720.0;

        expect(
          world.counter.isInsideFoodDepositZone(world.player.position),
          isTrue,
        );
        expect(
          world.counter.isInsideCashierZone(world.player.position),
          isFalse,
        );
        expect(
          world.counter.isInsideCashCollectionZone(world.player.position),
          isFalse,
        );

        world.tick(0.05);
        expect(world.player.carriedCount, 0);
        expect(world.counter.totalFoodCount, 1);
      });

      test('Player can collect cash from the right flank of the counter', () {
        final world = GameWorld(initialRupees: 0.0);
        world.counter.cashBundleCount = 1;

        // Stand at the right side (flank) of the counter
        world.player.position.x = 630.0;
        world.player.position.y = 720.0;

        expect(
          world.counter.isInsideCashCollectionZone(world.player.position),
          isTrue,
        );
        expect(
          world.counter.isInsideCashierZone(world.player.position),
          isFalse,
        );
        expect(
          world.counter.isInsideFoodDepositZone(world.player.position),
          isFalse,
        );

        world.tick(0.05);
        expect(world.counter.cashBundleCount, 0);
        expect(world.cashBundles.length, 1);
      });

      test(
        'Left Food Zone covers top (behind), left flank, and bottom (front)',
        () {
          final counter = ServingCounter();
          // Top (behind left counter: x=340, y=665)
          expect(
            counter.isInsideFoodDepositZone(Vector2(340.0, 665.0)),
            isTrue,
          );
          // Left flank (x=270, y=720)
          expect(
            counter.isInsideFoodDepositZone(Vector2(270.0, 720.0)),
            isTrue,
          );
          // Bottom (in front of left counter: x=340, y=775)
          expect(
            counter.isInsideFoodDepositZone(Vector2(340.0, 775.0)),
            isTrue,
          );
          // Right of left counter (x=410 towards cashier) -> False!
          expect(
            counter.isInsideFoodDepositZone(Vector2(410.0, 720.0)),
            isFalse,
          );
        },
      );

      test(
        'Right Cash Zone covers top (behind), right flank, and bottom (front)',
        () {
          final counter = ServingCounter();
          // Top (behind right counter: x=560, y=665)
          expect(
            counter.isInsideCashCollectionZone(Vector2(560.0, 665.0)),
            isTrue,
          );
          // Right flank (x=630, y=720)
          expect(
            counter.isInsideCashCollectionZone(Vector2(630.0, 720.0)),
            isTrue,
          );
          // Bottom (in front of right counter: x=560, y=775)
          expect(
            counter.isInsideCashCollectionZone(Vector2(560.0, 775.0)),
            isTrue,
          );
          // Left of right counter (x=490 towards cashier) -> False!
          expect(
            counter.isInsideCashCollectionZone(Vector2(490.0, 720.0)),
            isFalse,
          );
        },
      );

      test(
        'Counter zones are strictly non-overlapping across the entire map',
        () {
          final counter = ServingCounter();
          // Check a 10px grid spanning across and behind the counter
          for (double x = 200.0; x <= 700.0; x += 10.0) {
            for (double y = 600.0; y <= 800.0; y += 10.0) {
              final pt = Vector2(x, y);
              int activeZones = 0;
              if (counter.isInsideFoodDepositZone(pt)) activeZones++;
              if (counter.isInsideCashierZone(pt)) activeZones++;
              if (counter.isInsideCashCollectionZone(pt)) activeZones++;

              expect(
                activeZones,
                lessThanOrEqualTo(1),
                reason: 'Point ($x, $y) overlapped multiple zones!',
              );
            }
          }
        },
      );

      test('Trash bin discards unwanted items from player stack', () {
        final world = GameWorld();
        world.player.addItem(ItemType.chai);
        expect(world.player.carriedCount, 1);

        // Walk to trash bin
        world.player.position.x = world.trashBin.position.x;
        world.player.position.y = world.trashBin.position.y;

        world.tick(0.05);
        expect(world.player.carriedCount, 0);
      });

      test('Counter collision stops player from passing through', () {
        final world = GameWorld();
        final counterCenter = world.counter.position;

        // Try placing player at center of serving counter
        world.player.position.x = counterCenter.x;
        world.player.position.y = counterCenter.y;

        world.tick(0.01);

        final halfW = world.counter.width / 2;
        final halfH = world.counter.height / 2;
        final isOutside =
            (world.player.position.x < counterCenter.x - halfW) ||
            (world.player.position.x > counterCenter.x + halfW) ||
            (world.player.position.y < counterCenter.y - halfH) ||
            (world.player.position.y > counterCenter.y + halfH);

        expect(isOutside, isTrue);
      });
    },
  );
}
