import 'package:flutter_test/flutter_test.dart';
import 'package:chai_dhaba_empire/engine/customer_ai.dart';
import 'package:chai_dhaba_empire/engine/game_world.dart';
import 'package:chai_dhaba_empire/engine/stations.dart';

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

      // Walk South through the open doorway
      world.player.position.y = 1240.0;
      world.tick(0.05);
      // Allowed on the porch!
      expect(world.player.position.y, 1240.0);

      // Walk into the solid south wall away from the door (e.g. x: 200, y: 1240)
      world.player.position.x = 200.0;
      world.player.position.y = 1200.0;
      world.tick(0.05);
      // Blocked by south wall at maxY (1200 - 32 - 18 = 1150.0)
      final maxY = world.worldHeight - world.wallThickness - world.player.radius;
      expect(world.player.position.y, closeTo(maxY, 0.01));
    });

    test('Customers spawn on highway exterior and despawn upon leaving to highway', () {
      final counter = ServingCounter();
      final system = CustomerSystem();

      // Spawns at exterior highway position (450, 1340)
      expect(system.entrancePosition.y, 1340.0);

      final customer = system.spawnCustomer()!;
      expect(customer.position.y, 1340.0);
      expect(customer.position.x, 450.0);

      // Complete customer flow to leavingHappy
      customer.state = CustomerState.leavingHappy;
      customer.position.x = 450.0;
      customer.position.y = 1335.0; // Near highway despawn threshold

      system.update(0.1, counter);
      expect(customer.state, CustomerState.despawned);
      expect(system.activeCustomers.contains(customer), isFalse);
    });
  });
}
