import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chai_dhaba_empire/data/deals_catalog.dart';
import 'package:chai_dhaba_empire/engine/entities.dart';
import 'package:chai_dhaba_empire/engine/game_world.dart';
import 'package:chai_dhaba_empire/engine/staff_ai.dart';
import 'package:chai_dhaba_empire/services/ads_service.dart';
import 'package:chai_dhaba_empire/state/game_controller.dart';
import 'package:chai_dhaba_empire/ui/game/game_viewport.dart';
import 'package:chai_dhaba_empire/ui/overlays/reward_center_sheet.dart';

void main() {
  group('Reward Center Store Engine & Deals Tests', () {
    late GameWorld world;

    setUp(() {
      world = GameWorld(initialGems: 10, initialRupees: 500);
    });

    test('Store Staff Speed deal activates, deducts gems, and applies 1.5x multiplier', () {
      final deal = DealsCatalog.rewardStoreDeals.firstWhere((d) => d.id == 'store_staff_speed');
      expect(world.gems, 10);
      expect(world.isStoreStaffSpeedActive, isFalse);

      final initialPlayerSpeed = world.player.speed;
      final success = world.buyCatalogDealWithGems(deal);
      expect(success, isTrue);
      expect(world.gems, 8); // 10 - 2
      expect(world.isStoreStaffSpeedActive, isTrue);
      expect(world.storeStaffSpeedRemainingSeconds, 60.0);

      // Speed is updated during world.tick
      world.tick(0.1);
      expect(world.player.speed, greaterThan(initialPlayerSpeed));
      expect(world.player.speed, closeTo(initialPlayerSpeed * 1.5, 0.5));
    });

    test('Store Double Earnings deal doubles collected cash bundle value', () {
      final deal = DealsCatalog.rewardStoreDeals.firstWhere((d) => d.id == 'store_double_earnings');
      world.buyCatalogDealWithGems(deal);
      expect(world.isStoreEarningsActive, isTrue);

      final initialRupees = world.rupees;
      final bundle = CashBundleEntity(
        position: Vector2(world.player.position.x, world.player.position.y),
        value: 50.0,
      )
        ..isFlying = true
        ..spawnBounceTimer = 0.0;
      world.cashBundles.add(bundle);

      world.tick(0.1);
      // bundle was at player position -> collected immediately with 2x multiplier
      expect(world.rupees, initialRupees + (50.0 * 2.0));
    });

    test('Store Permanent Worker deal hires an extra helper even at max HR limit', () {
      final deal = DealsCatalog.rewardStoreDeals.firstWhere((d) => d.id == 'store_permanent_worker');
      // Fill workers to max (3)
      world.hireHelper(free: true);
      world.hireHelper(free: true);
      world.hireHelper(free: true);
      expect(world.canHireWorker, isFalse);
      expect(world.helperCount, 3);

      final success = world.buyCatalogDealWithGems(deal);
      expect(success, isTrue);
      expect(world.helperCount, 4); // Extra worker successfully hired!
      expect(world.gems, 5); // 10 - 5
    });

    test('Store Worker Capacity deal increases both worker and player carry capacity', () {
      final deal = DealsCatalog.rewardStoreDeals.firstWhere((d) => d.id == 'store_worker_capacity');
      world.hireHelper(free: true);
      final helper = world.staff.firstWhere((s) => s.role == StaffRole.helper);
      final initialCapacity = helper.carryCapacity;
      final initialPlayerCapacity = world.player.carryCapacity;

      world.buyCatalogDealWithGems(deal);
      expect(world.isStoreCapacityActive, isTrue);
      expect(world.temporaryWorkerCapacityBoost, 2);
      expect(helper.carryCapacity, initialCapacity + 2);
      expect(world.player.carryCapacity, initialPlayerCapacity + 2);

      // Fast forward past duration
      world.tick(60.1);
      expect(world.isStoreCapacityActive, isFalse);
      expect(world.temporaryWorkerCapacityBoost, 0);
      expect(helper.carryCapacity, initialCapacity);
      expect(world.player.carryCapacity, initialPlayerCapacity);
    });

    test('Fails gracefully when player has insufficient gems', () {
      world.gems = 1;
      final deal = DealsCatalog.rewardStoreDeals.firstWhere((d) => d.id == 'store_staff_speed'); // Cost: 2
      final success = world.buyCatalogDealWithGems(deal);
      expect(success, isFalse);
      expect(world.gems, 1);
      expect(world.isStoreStaffSpeedActive, isFalse);
    });

    test('Claiming deal via Ad activates deal without deducting gems', () {
      world.gems = 2;
      final deal = DealsCatalog.rewardStoreDeals.firstWhere((d) => d.id == 'store_double_earnings');
      final success = world.claimCatalogDealWithAd(deal);
      expect(success, isTrue);
      expect(world.gems, 2); // Untouched!
      expect(world.isStoreEarningsActive, isTrue);
    });
  });

  group('RewardCenterSheet Widget Tests', () {
    late GameWorld world;
    late GameController controller;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      AdsService.instance.testMockReward = true;
      world = GameWorld(initialGems: 4, initialRupees: 500);
      controller = GameController(world: world);
    });

    tearDown(() {
      AdsService.instance.testMockReward = false;
    });

    testWidgets('RewardCenterSheet renders header, gems counter, and all deals', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RewardCenterSheet(controller: controller),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('DHABA REWARD CENTER'), findsOneWidget);
      expect(find.text('4 GEMS'), findsOneWidget);
      expect(find.text('1.5X STAFF SPEED'), findsOneWidget);
      expect(find.text('2X EARNINGS BOOST'), findsOneWidget);
      expect(find.text('EXTRA WORKER CONTRACT'), findsOneWidget);
      expect(find.text('+2 WORKER CAPACITY'), findsOneWidget);
    });

    testWidgets('Can buy affordable deal with Gems and triggers boost', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RewardCenterSheet(controller: controller),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap "💎 2 GEMS" on 1.5x staff speed (first deal)
      final gemButtons = find.widgetWithText(ElevatedButton, '💎 2 GEMS');
      expect(gemButtons, findsAtLeastNWidgets(1));

      await tester.tap(gemButtons.first);
      await tester.pumpAndSettle();

      expect(world.gems, 2); // 4 - 2
      expect(world.isStoreStaffSpeedActive, isTrue);
      expect(find.text('2 GEMS'), findsOneWidget);
    });

    testWidgets('Shows disabled state when Gems are insufficient', (tester) async {
      world.gems = 1;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RewardCenterSheet(controller: controller),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Need 2 💎'), findsAtLeastNWidgets(1));
      expect(find.text('Need 3 💎'), findsOneWidget);
      expect(find.text('Need 5 💎'), findsOneWidget);
    });

    testWidgets('Watch Ad button claims deal for free via Rewarded Ad', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RewardCenterSheet(controller: controller),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final adButtons = find.widgetWithText(ElevatedButton, '🎬 FREE (AD)');
      expect(adButtons, findsNWidgets(4));

      // Tap ad button on 2X earnings
      await tester.tap(adButtons.at(1));
      await tester.pumpAndSettle();

      expect(world.isStoreEarningsActive, isTrue);
      expect(world.gems, 4); // Gems not spent!
    });
  });

  group('GameViewport Reward Center Button Tests', () {
    late GameWorld world;
    late GameController controller;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      AdsService.instance.testMockReward = true;
      world = GameWorld(initialGems: 5, initialRupees: 500);
      controller = GameController(world: world);
    });

    tearDown(() {
      AdsService.instance.testMockReward = false;
    });

    testWidgets('GameViewport displays storefront icon replacing settings icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<GameController>.value(
            value: controller,
            child: const Scaffold(
              body: GameViewport(),
            ),
          ),
        ),
      );
      await tester.pump();

      // Reward Center storefront icon is present
      expect(find.byIcon(Icons.storefront_rounded), findsOneWidget);
      // Settings icon is NOT on GameViewport action bar
      expect(find.byIcon(Icons.settings_rounded), findsNothing);

      // Tapping storefront icon opens RewardCenterSheet
      await tester.tap(find.byIcon(Icons.storefront_rounded));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(RewardCenterSheet), findsOneWidget);
      expect(find.text('DHABA REWARD CENTER'), findsOneWidget);
    });
  });
}
