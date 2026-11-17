import 'package:flutter_test/flutter_test.dart';
import 'package:chai_dhaba_empire/engine/entities.dart';
import 'package:chai_dhaba_empire/engine/game_world.dart';
import 'package:chai_dhaba_empire/engine/ground_pad.dart';
import 'package:chai_dhaba_empire/engine/stations.dart';

void main() {
  group('In-Place Machine Upgrade & Floor Unlock Pads (M4)', () {
    test(
      'Cash pouring smoothly deducts money and preserves partial progress',
      () {
        final pad = GroundPad(
          id: 'test_pad',
          type: PadType.floorUnlock,
          position: Vector2(300.0, 300.0),
          title: 'UNLOCK',
          totalCost: 100.0,
          pourRate: 50.0, // 50 Rs / sec
        );

        expect(pad.remainingCost, 100.0);
        expect(pad.progress, 0.0);

        // Player stands on pad with 30 Rs
        final poured1 = pad.pourCash(
          30.0,
          0.5,
        ); // wants to pour 25.0 Rs (50 * 0.5)
        expect(poured1, 25.0);
        expect(pad.remainingCost, 75.0);
        expect(pad.progress, closeTo(0.25, 0.01));

        // Player steps off pad or has 0 Rs -> no pouring occurs, partial progress preserved
        final poured2 = pad.pourCash(0.0, 0.5);
        expect(poured2, 0.0);
        expect(pad.remainingCost, 75.0); // Exact memory preserved!

        // Player returns with remaining 75 Rs and pours until 0
        final poured3 = pad.pourCash(
          100.0,
          2.0,
        ); // wants to pour up to 100, capped at remaining 75
        expect(poured3, 75.0);
        expect(pad.remainingCost, 0.0);
        expect(pad.isCompleted, isTrue);
        expect(pad.progress, 1.0);
      },
    );

    test('In-place machine upgrade upgrades kettle capacity and brew speed up to MAX', () {
      final kettle = ChaiStation(
        position: Vector2(260.0, 260.0),
        shelfCapacity: 8,
        brewTime: 1.0,
      );

      final pad = GroundPad(
        id: 'kettle_upgrade',
        type: PadType.machineUpgrade,
        position: Vector2(375.0, 260.0),
        title: 'UPGRADE L2',
        totalCost: 50.0,
        currentLevel: 1,
        maxLevel: 3,
        costForLevel: (lvl) => lvl == 2 ? 50.0 : 100.0,
        titleForLevel: (lvl) => 'UPGRADE L$lvl',
        onLevelUp: (newLevel) {
          kettle.upgradeTo(newLevel);
        },
      );

      expect(kettle.level, 1);
      expect(kettle.shelfCapacity, 8);
      expect(kettle.brewTime, 1.0);

      // Pour to Level 2
      pad.pourCash(50.0, 2.0);
      expect(pad.currentLevel, 2);
      expect(kettle.level, 2);
      expect(kettle.shelfCapacity, 10);
      expect(kettle.brewTime, 0.85);
      expect(pad.title, 'UPGRADE L3');
      expect(pad.totalCost, 100.0);
      expect(pad.remainingCost, 100.0);
      expect(pad.isCompleted, isFalse);

      // Pour to Level 3 (Max level)
      pad.pourCash(100.0, 3.0);
      expect(pad.currentLevel, 3);
      expect(kettle.level, 3);
      expect(kettle.shelfCapacity, 12);
      expect(kettle.brewTime, 0.70);
      expect(pad.isCompleted, isTrue);
      expect(pad.title, 'MAX');
    });

    test('Floor unlock pad pops dining table into existence', () {
      final table = DiningTable(
        id: 1,
        position: Vector2(200.0, 950.0),
        isUnlocked: false,
      );

      final pad = GroundPad(
        id: 'table_1_unlock',
        type: PadType.floorUnlock,
        position: Vector2(200.0, 950.0),
        title: 'TABLE 1',
        totalCost: 80.0,
        onUnlocked: () {
          table.isUnlocked = true;
        },
      );

      expect(table.isUnlocked, isFalse);

      // Player stands on pad with 80 Rs
      pad.pourCash(80.0, 2.0);

      expect(pad.isCompleted, isTrue);
      expect(table.isUnlocked, isTrue);
    });
  });

  group('Ground Pads Integration in GameWorld (M4)', () {
    test('Player walking onto Kettle Upgrade pad smoothly pours cash and upgrades kettle', () {
      final world = GameWorld(initialRupees: 50.0);
      final pad = world.groundPads.firstWhere((p) => p.id == 'kettle_upgrade');

      expect(world.chaiStation.level, 1);
      expect(pad.remainingCost, 50.0);

      // Move player onto kettle upgrade pad
      world.player.position.x = pad.position.x;
      world.player.position.y = pad.position.y;

      // Tick world to pour cash
      for (int i = 0; i < 20; i++) {
        world.tick(0.05); // 1.0 second total pour
      }

      // 50 Rs poured into pad, kettle upgraded to Level 2!
      expect(world.chaiStation.level, 2);
      expect(world.chaiStation.shelfCapacity, 10);
      expect(world.rupees, closeTo(0.0, 0.1));
      // Pad transitions to Level 3 cost
      expect(pad.currentLevel, 2);
      expect(pad.totalCost, 100.0);
    });

    test('Player walking onto Table Unlock pad unlocks dining table', () {
      final world = GameWorld(initialRupees: 100.0);
      final pad = world.groundPads.firstWhere((p) => p.id == 'table_1_unlock');
      final table = world.diningTables.first;

      expect(table.isUnlocked, isFalse);

      // Move player onto table unlock pad
      world.player.position.x = pad.position.x;
      world.player.position.y = pad.position.y;

      // Tick world to pour cash
      for (int i = 0; i < 30; i++) {
        world.tick(0.05); // 1.5 seconds pour
      }

      expect(table.isUnlocked, isTrue);
      expect(pad.isCompleted, isTrue);
      expect(world.rupees, closeTo(20.0, 0.1));
    });

    test('Unlocked table creates physical solid collision stopping player', () {
      final world = GameWorld(initialRupees: 100.0);
      final table = world.diningTables.first;
      table.isUnlocked = true;

      // Try placing player at center of table
      world.player.position.x = table.position.x;
      world.player.position.y = table.position.y;

      world.tick(0.01);

      final halfW = table.width / 2;
      final halfH = table.height / 2;
      final isOutside =
          (world.player.position.x < table.position.x - halfW) ||
          (world.player.position.x > table.position.x + halfW) ||
          (world.player.position.y < table.position.y - halfH) ||
          (world.player.position.y > table.position.y + halfH);

      expect(isOutside, isTrue);
    });
  });
}
