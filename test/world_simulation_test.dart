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

  group('Arcade Engine - Serving Counter, Cash Drops & Vacuum Magnet (M2)', () {
    test('Serving chai at counter unloads item and drops cash bundle', () {
      final world = GameWorld();
      world.player.addItem(ItemType.chai);
      world.player.addItem(ItemType.chai);
      expect(world.player.carriedCount, 2);
      expect(world.cashBundles.isEmpty, isTrue);

      // Position player in the counter's staff serving zone
      world.player.position.x = world.counter.staffDropZoneCenter.x;
      world.player.position.y = world.counter.staffDropZoneCenter.y;

      world.tick(0.05);

      // One item served, one cash bundle dropped
      expect(world.player.carriedCount, 1);
      expect(world.cashBundles.length, 1);
      expect(world.cashBundles.first.value, 10.0);

      // After cooldown, second item served
      world.tick(0.25);
      expect(world.player.carriedCount, 0);
      expect(world.cashBundles.length, 2);
    });

    test('Magnet vacuum sucks cash bundles into player wallet', () {
      final world = GameWorld(initialRupees: 0.0);
      // Place a cash bundle on the ground
      final bundle = CashBundleEntity(
        position: Vector2(400.0, 600.0),
        value: 10.0,
      );
      world.cashBundles.add(bundle);

      // Player stands within magnet radius (dist = 50px < 85px)
      world.player.position.x = 450.0;
      world.player.position.y = 600.0;

      // Tick world to trigger vacuum suction
      world.tick(0.05);
      expect(bundle.isFlying, isTrue);

      // Tick until cash reaches player and gets absorbed
      for (int i = 0; i < 20; i++) {
        world.tick(0.05);
      }

      // Cash absorbed into wallet
      expect(world.rupees, 10.0);
      expect(world.cashBundles.isEmpty, isTrue);
      // Floating text spawned
      expect(world.floatingTexts.isNotEmpty, isTrue);
      expect(world.floatingTexts.first.text, '+Rs 10');
    });

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
  });
}
