import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chai_dhaba_empire/data/progression_config.dart';
import 'package:chai_dhaba_empire/engine/entities.dart';
import 'package:chai_dhaba_empire/engine/game_world.dart';
import 'package:chai_dhaba_empire/engine/staff_ai.dart';
import 'package:chai_dhaba_empire/services/save_service.dart';
import 'package:chai_dhaba_empire/state/game_controller.dart';
import 'package:chai_dhaba_empire/ui/overlays/confetti_overlay.dart';
import 'package:chai_dhaba_empire/ui/overlays/level_complete_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('M8: Store Objectives & Goal Tracking', () {
    test('Store 1 config defines 6 clear comprehensive objectives', () {
      final config = StoreProgressionConfig.store1;
      expect(config.goals.length, 6);

      final goalIds = config.goals.map((g) => g.id).toSet();
      expect(goalIds.contains('hire_cashier'), isTrue);
      expect(goalIds.contains('hire_workers_3'), isTrue);
      expect(goalIds.contains('unlock_tables_2'), isTrue);
      expect(goalIds.contains('unlock_paratha'), isTrue);
      expect(goalIds.contains('upgrade_kettle_5'), isTrue);
      expect(goalIds.contains('reach_reputation_100'), isTrue);
    });

    test('Unlocking Paratha Tawa satisfies unlock_paratha goal', () {
      final world = GameWorld();
      expect(world.completedMissionIds.contains('unlock_paratha'), isFalse);

      world.parathaStation.isUnlocked = true;
      world.checkMissions();

      expect(world.completedMissionIds.contains('unlock_paratha'), isTrue);
    });

    test('Upgrading Kettle to Level 5 satisfies upgrade_kettle_5 goal', () {
      final world = GameWorld();
      expect(world.completedMissionIds.contains('upgrade_kettle_5'), isFalse);

      world.chaiStation.upgradeTo(5);
      world.checkMissions();

      expect(world.completedMissionIds.contains('upgrade_kettle_5'), isTrue);
    });

    test('Reaching 100% reputation satisfies reach_reputation_100 goal', () {
      final world = GameWorld();
      expect(world.completedMissionIds.contains('reach_reputation_100'), isFalse);

      world.reputationPercent = 100.0;
      expect(world.isReputationLocked100, isTrue);
      expect(world.completedMissionIds.contains('reach_reputation_100'), isTrue);
    });
  });

  group('M8: Shop Completion Celebration & Reward Bonus', () {
    test('Mastering all 6 goals triggers onStoreMastered celebration callback', () {
      final world = GameWorld(initialRupees: 50000.0);
      bool celebrationFired = false;
      world.onStoreMastered = () {
        celebrationFired = true;
      };

      expect(world.isStoreMastered, isFalse);
      expect(world.isStoreMasteredCelebrated, isFalse);

      // 1. Hire Cashier
      world.hireCashier();

      // 2. Hire 3 Workers
      world.hireWorker();
      world.hireWorker();
      world.hireWorker();

      // 3. Unlock 2 Dining Tables
      world.diningTables[0].isUnlocked = true;
      world.diningTables[1].isUnlocked = true;

      // 4. Unlock Paratha Tawa
      world.parathaStation.isUnlocked = true;

      // 5. Upgrade Kettle to L5
      world.chaiStation.upgradeTo(5);

      // 6. Reach 100% Reputation
      world.reputationPercent = 100.0;

      world.checkMissions();

      expect(world.completedMissionIds.length, 6);
      expect(world.isStoreMastered, isTrue);
      expect(celebrationFired, isTrue);
      expect(world.isStoreMasteredCelebrated, isTrue);
    });

    test('Claiming victory reward bonus adds ₹1,000 and prevents duplicate claims', () {
      final world = GameWorld(initialRupees: 100.0);

      // Complete all 6 goals
      world.hireCashier(free: true);
      world.staff.addAll([
        StaffEntity(id: 2, name: 'W1', role: StaffRole.helper, startPosition: Vector2()),
        StaffEntity(id: 3, name: 'W2', role: StaffRole.helper, startPosition: Vector2()),
        StaffEntity(id: 4, name: 'W3', role: StaffRole.helper, startPosition: Vector2()),
      ]);
      world.diningTables[0].isUnlocked = true;
      world.diningTables[1].isUnlocked = true;
      world.parathaStation.isUnlocked = true;
      world.chaiStation.upgradeTo(5);
      world.reputationPercent = 100.0;

      world.checkMissions();
      expect(world.isStoreMastered, isTrue);
      expect(world.isMasteryRewardClaimed, isFalse);

      // Claim reward
      final claimedFirstTime = world.claimMasteryReward();
      expect(claimedFirstTime, isTrue);
      expect(world.isMasteryRewardClaimed, isTrue);
      expect(world.rupees, 1100.0); // 100 + 1000

      // Duplicate claim should fail
      final claimedSecondTime = world.claimMasteryReward();
      expect(claimedSecondTime, isFalse);
      expect(world.rupees, 1100.0); // Remains unchanged
    });
  });

  group('M8: SaveService Persistence for Mastery and Rewards', () {
    test('SaveService preserves mastery celebration and reward claim status', () async {
      SharedPreferences.setMockInitialValues({});
      final saveService = SaveService();

      final world1 = GameWorld();
      world1.reputationPercent = 100.0;
      world1.isStoreMasteredCelebrated = true;
      world1.isMasteryRewardClaimed = true;

      await saveService.saveStoreState(world1);

      final world2 = GameWorld();
      expect(world2.isStoreMasteredCelebrated, isFalse);
      expect(world2.isMasteryRewardClaimed, isFalse);

      await saveService.loadStoreState(world2);

      expect(world2.isStoreMasteredCelebrated, isTrue);
      expect(world2.isMasteryRewardClaimed, isTrue);
    });
  });

  group('M8: UI Particle & Dialog Widgets', () {
    testWidgets('ConfettiOverlay renders smoothly without exceptions', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ConfettiOverlay(),
          ),
        ),
      );

      expect(find.byType(ConfettiOverlay), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(ConfettiOverlay), findsOneWidget);
    });

    testWidgets('LevelCompleteDialog displays store victory information and claim button', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final world = GameWorld();
      world.reputationPercent = 100.0;
      for (final g in world.progressionConfig.goals) {
        world.completedMissionIds.add(g.id);
      }
      final controller = GameController(world: world);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LevelCompleteDialog(controller: controller),
          ),
        ),
      );

      // Verify header and congratulatory text
      expect(find.text('STORE 1 MASTERED! 🎉'), findsOneWidget);
      expect(find.text('Highway Kadak Dhaba'), findsOneWidget);
      expect(find.text('⭐⭐⭐⭐⭐'), findsOneWidget);
      expect(find.text('CLAIM REWARD'), findsOneWidget);

      // Tap CLAIM REWARD
      await tester.tap(find.text('CLAIM REWARD'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('REWARD CLAIMED ✅'), findsOneWidget);
      expect(world.isMasteryRewardClaimed, isTrue);
    });
  });
}
