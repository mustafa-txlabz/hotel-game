import 'package:flutter_test/flutter_test.dart';
import 'package:chai_dhaba_empire/engine/customer_ai.dart';
import 'package:chai_dhaba_empire/engine/game_world.dart';

void main() {
  group('Automatic Sliding Doors & Exterior Road (UI Polish)', () {
    test('Doors start closed and open when player approaches entrance', () {
      final world = GameWorld();
      world.customerSystem.spawnInterval = 999.0;
      expect(world.doorOpenFactor, 0.0);

      // Player starts at center (450, 600) -> far from entrance (450, 1184)
      world.tick(0.1);
      expect(world.doorOpenFactor, 0.0);

      // Move player near the door (e.g. 450, 1140 -> distance ~44 < 110.0)
      world.player.position.x = 450.0;
      world.player.position.y = 1140.0;

      // Tick world to open doors
      for (int i = 0; i < 15; i++) {
        world.tick(0.05);
      }
      expect(world.doorOpenFactor, greaterThan(0.8));

      // Move player away back into the dhaba
      world.player.position.y = 600.0;
      for (int i = 0; i < 30; i++) {
        world.tick(0.05);
      }
      expect(world.doorOpenFactor, lessThan(0.1));
    });

    test('Doors open automatically when a customer approaches entrance', () {
      final world = GameWorld();
      world.customerSystem.spawnInterval = 999.0;
      expect(world.doorOpenFactor, 0.0);

      // Place customer near the door (450, 1200)
      final customer = world.customerSystem.spawnCustomer()!;
      customer.position.x = 450.0;
      customer.position.y = 1200.0;

      // Doors detect customer and open
      for (int i = 0; i < 15; i++) {
        world.tick(0.05);
      }
      expect(world.doorOpenFactor, greaterThan(0.8));
    });

    test('Doors open automatically when a staff member approaches entrance', () {
      final world = GameWorld(initialRupees: 500.0);
      world.customerSystem.spawnInterval = 999.0;
      final hired = world.hireHelper();
      expect(hired, isTrue);
      final helper = world.staff.last;

      for (int i = 0; i < 15; i++) {
        helper.position.x = 450.0;
        helper.position.y = 1170.0;
        world.tick(0.05);
      }
      expect(world.doorOpenFactor, greaterThan(0.8));
    });

    test('Player can step out onto porch through open doors but blocked by solid walls elsewhere', () {
      final world = GameWorld();

      // Open doors
      world.player.position.x = 450.0;
      world.player.position.y = 1140.0;
      for (int i = 0; i < 15; i++) {
        world.tick(0.05);
      }
      expect(world.doorOpenFactor, greaterThan(0.5));

      // Walk South through the open doorway onto sidewalk
      world.player.position.y = 1240.0;
      world.tick(0.05);
      // Allowed on the sidewalk!
      expect(world.player.position.y, 1240.0);
      expect(world.player.isOutside, isTrue);

      // Walk inside the shop into the solid south wall away from the door (x: 200, y: 1180)
      final freshWorld = GameWorld();
      freshWorld.player.position.x = 200.0;
      freshWorld.player.position.y = 1180.0;
      freshWorld.tick(0.05);
      // Blocked by south wall at maxY (1200 - 32 - 18 = 1150.0)
      final maxY = freshWorld.worldHeight - freshWorld.wallThickness - freshWorld.player.radius;
      expect(freshWorld.player.position.y, closeTo(maxY, 0.01));
    });

    test('Customers spawn on sidewalk footpath (left/right) and path to door', () {
      final system = CustomerSystem();

      // Entrance threshold on sidewalk is (450, 1245)
      expect(system.entrancePosition.y, 1245.0);

      // Customer 1 spawns on sidewalk (left or right side)
      final c1 = system.spawnCustomer()!;
      expect(c1.position.y, 1245.0);
      expect(c1.targetPosition.y, lessThan(1200.0)); // Target is inside queue slot

      // Customer 2 spawns on opposite side of sidewalk
      final c2 = system.spawnCustomer()!;
      expect(c2.position.y, 1245.0);
      expect(c2.position.x != c1.position.x, isTrue);
    });

    test('Owner pushing down against the curb does NOT snap back inside the shop', () {
      final world = GameWorld();
      world.customerSystem.spawnInterval = 999.0;
      world.doorOpenFactor = 1.0;
      world.player.isOutside = true;

      // Owner is outside on sidewalk (y: 1240.0)
      world.player.position.x = 450.0;
      world.player.position.y = 1240.0;
      world.tick(0.05);
      expect(world.player.position.y, 1240.0);

      // Owner tries to push further down past curb (y: 1300.0)
      world.player.position.y = 1300.0;
      world.tick(0.05);
      // Cleanly held at the curb on the sidewalk without jumping inside!
      final curbY = 1275.0 - world.player.radius;
      expect(world.player.position.y, closeTo(curbY, 0.01));
      expect(world.player.position.y, greaterThan(world.worldHeight));
    });
  });
}
