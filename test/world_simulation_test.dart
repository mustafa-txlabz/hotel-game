import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:chai_dhaba_empire/engine/game_world.dart';

void main() {
  group('Arcade Engine - World Simulation & Movement', () {
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
      // Move right (dx = 1.0, dy = 0.0)
      world.setJoystickInput(1.0, 0.0);
      expect(world.player.velocity.x, world.player.speed);
      expect(world.player.velocity.y, 0.0);

      // Move diagonally (dx = 1.0, dy = 1.0) -> should be normalized
      world.setJoystickInput(1.0, 1.0);
      final expectedComponent = world.player.speed / math.sqrt(2);
      expect(world.player.velocity.x, closeTo(expectedComponent, 0.1));
      expect(world.player.velocity.y, closeTo(expectedComponent, 0.1));

      // Releasing joystick stops player
      world.setJoystickInput(0.0, 0.0);
      expect(world.player.velocity.x, 0.0);
      expect(world.player.velocity.y, 0.0);
    });

    test('World tick updates player position and walk cycle animation', () {
      final world = GameWorld();
      world.setJoystickInput(1.0, 0.0);

      world.tick(0.1); // 100ms
      expect(world.player.position.x, closeTo(450.0 + world.player.speed * 0.1, 0.01));
      expect(world.player.isMoving, isTrue);
      expect(world.player.walkCycle, greaterThan(0.0));
      expect(world.player.angle, closeTo(0.0, 0.01)); // Facing right
    });

    test('Player smoothly collides with and clamps to boundary walls', () {
      final world = GameWorld(worldWidth: 900.0, worldHeight: 1200.0, wallThickness: 30.0);
      // Run left at top speed into the wall for 10 seconds
      world.setJoystickInput(-1.0, 0.0);
      for (int i = 0; i < 100; i++) {
        world.tick(0.1);
      }

      final minX = world.wallThickness + world.player.radius;
      expect(world.player.position.x, closeTo(minX, 0.01));
      expect(world.player.position.x >= minX, isTrue);

      // Run up into top wall for 10 seconds
      world.setJoystickInput(0.0, -1.0);
      for (int i = 0; i < 100; i++) {
        world.tick(0.1);
      }

      final minY = world.wallThickness + world.player.radius;
      expect(world.player.position.y, closeTo(minY, 0.01));
      expect(world.player.position.y >= minY, isTrue);
    });
  });
}
