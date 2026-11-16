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

      // Half brew time: 0.5s -> no new cup
      station.update(0.5);
      expect(station.shelfCount, 0);
      expect(station.brewProgress, closeTo(0.5, 0.01));

      // Reaching 1.0s -> 1 cup brewed
      station.update(0.5);
      expect(station.shelfCount, 1);
      expect(station.brewProgress, 0.0);

      // Advance by 10s -> capped at shelfCapacity (5)
      station.update(10.0);
      expect(station.shelfCount, 5);
    });

    test('Player picking up cups from station into head stack', () {
      final world = GameWorld();
      world.chaiStation.shelfCount = 5;

      // Position player directly inside the pickup zone
      world.player.position.x = world.chaiStation.pickupZoneCenter.x;
      world.player.position.y = world.chaiStation.pickupZoneCenter.y;

      expect(world.player.carriedCount, 0);
      expect(
        world.chaiStation.isInsidePickupZone(world.player.position),
        isTrue,
      );

      // Tick world to trigger pickup
      world.tick(0.05);
      expect(world.player.carriedCount, 1);
      expect(world.chaiStation.shelfCount, 4);

      // Next pickup happens after pickup interval
      world.tick(0.2);
      expect(world.player.carriedCount, 2);

      world.tick(0.2);
      expect(world.player.carriedCount, 3);
      expect(world.player.isFull, isTrue);

      // Further ticks do NOT exceed player capacity
      world.tick(0.5);
      expect(world.player.carriedCount, 3);
      expect(world.player.isFull, isTrue);
    });

    test(
      'Stack wobble angle activates when moving and damps when stopping',
      () {
        final player = PlayerEntity();
        player.velocity.x = 200.0;
        player.update(0.1);

        expect(player.isMoving, isTrue);
        expect(player.wobbleAngle.abs(), greaterThan(0.0));

        // Stop player
        player.velocity.x = 0.0;
        for (int i = 0; i < 20; i++) {
          player.update(0.1);
        }
        expect(player.isMoving, isFalse);
        expect(player.wobbleAngle.abs(), closeTo(0.0, 0.01));
      },
    );

    test(
      'Player cannot walk through solid counter table (sliding collision)',
      () {
        final world = GameWorld();
        final counterCenter = world.chaiStation.position;

        // Try placing player directly at the center of the counter
        world.player.position.x = counterCenter.x;
        world.player.position.y = counterCenter.y;

        world.tick(0.01);

        // Player must be pushed outside the counter bounds
        final halfW = world.chaiStation.width / 2;
        final halfH = world.chaiStation.height / 2;
        final isOutside =
            (world.player.position.x < counterCenter.x - halfW) ||
            (world.player.position.x > counterCenter.x + halfW) ||
            (world.player.position.y < counterCenter.y - halfH) ||
            (world.player.position.y > counterCenter.y + halfH);

        expect(isOutside, isTrue);
      },
    );
  });
}
