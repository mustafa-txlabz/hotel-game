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
import 'package:chai_dhaba_empire/ui/overlays/insufficient_gems_dialog.dart';
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

    test('Purchasing an offer triggers a 2-minute (120s) cooldown and blocks repeat purchase', () {
      final deal = DealsCatalog.rewardStoreDeals.firstWhere((d) => d.id == 'store_staff_speed');
      expect(world.isDealOnCooldown(deal.id), isFalse);

      final success = world.buyCatalogDealWithGems(deal);
      expect(success, isTrue);
      expect(world.isDealOnCooldown(deal.id), isTrue);
      expect(world.getDealCooldown(deal.id), DealsCatalog.storeDealCooldownSeconds);

      // Attempt repeat purchase during cooldown
      final repeat = world.buyCatalogDealWithGems(deal);
      expect(repeat, isFalse); // Blocked by cooldown!

      // Fast forward past cooldown (120.1s)
      world.tick(120.1);
      expect(world.isDealOnCooldown(deal.id), isFalse);

      // Can now purchase again
      final canBuyAgain = world.buyCatalogDealWithGems(deal);
      expect(canBuyAgain, isTrue);
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

    test('Claiming deal via Ad activates deal without deducting gems and starts cooldown', () {
      world.gems = 2;
      final deal = DealsCatalog.rewardStoreDeals.firstWhere((d) => d.id == 'store_double_earnings');
      final success = world.claimCatalogDealWithAd(deal);
      expect(success, isTrue);
      expect(world.gems, 2); // Untouched!
      expect(world.isStoreEarningsActive, isTrue);
      expect(world.isDealOnCooldown(deal.id), isTrue);
    });
  });

  group('RewardCenterSheet HR-Style Widget Tests', () {
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

    testWidgets('RewardCenterSheet renders header, gems counter, and HR-style cards with price buttons', (tester) async {
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

      // Right-side HR-style price buttons
      expect(find.widgetWithText(ElevatedButton, '💎 2'), findsNWidgets(2)); // Staff speed & worker capacity
      expect(find.widgetWithText(ElevatedButton, '💎 3'), findsOneWidget); // 2X earnings
      expect(find.widgetWithText(ElevatedButton, '💎 5'), findsOneWidget); // Permanent worker
    });

    testWidgets('Tapping price button with sufficient gems buys, starts cooldown, and closes sheet', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => RewardCenterSheet.show(ctx, controller),
                child: const Text('OPEN STORE'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open store sheet
      await tester.tap(find.text('OPEN STORE'));
      await tester.pumpAndSettle();

      expect(find.byType(RewardCenterSheet), findsOneWidget);

      // Tap "💎 2" button (first deal)
      final priceButtons = find.widgetWithText(ElevatedButton, '💎 2');
      await tester.tap(priceButtons.first);
      await tester.pumpAndSettle();

      // Modal sheet should be closed
      expect(find.byType(RewardCenterSheet), findsNothing);

      // Gems deducted
      expect(world.gems, 2); // 4 - 2
      expect(world.isStoreStaffSpeedActive, isTrue);

      // Deal is now on 2-minute cooldown
      expect(world.isDealOnCooldown('store_staff_speed'), isTrue);
    });

    testWidgets('Tapping price button with insufficient gems opens InsufficientGemsDialog', (tester) async {
      world.gems = 1; // Can't afford 2 gems deal

      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => RewardCenterSheet.show(ctx, controller),
                child: const Text('OPEN STORE'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open store sheet
      await tester.tap(find.text('OPEN STORE'));
      await tester.pumpAndSettle();

      // Tap "💎 2"
      final priceButtons = find.widgetWithText(ElevatedButton, '💎 2');
      await tester.tap(priceButtons.first);
      await tester.pumpAndSettle();

      // InsufficientGemsDialog is displayed!
      expect(find.byType(InsufficientGemsDialog), findsOneWidget);
      expect(find.text('NOT ENOUGH GEMS!'), findsOneWidget);
      expect(find.text('🎬 WATCH AD & ACTIVATE'), findsOneWidget);

      // Tap "WATCH AD & ACTIVATE"
      await tester.tap(find.text('🎬 WATCH AD & ACTIVATE'));
      await tester.pumpAndSettle();

      // Deal is activated for free via ad!
      expect(world.isStoreStaffSpeedActive, isTrue);
      expect(world.gems, 1); // Gems not deducted!
      expect(world.isDealOnCooldown('store_staff_speed'), isTrue); // Cooldown started!

      // Dialog is dismissed
      expect(find.byType(InsufficientGemsDialog), findsNothing);
    });

    testWidgets('Deal on cooldown displays countdown timer on button', (tester) async {
      // Put deal on cooldown
      world.storeDealCooldowns['store_staff_speed'] = 110.0;

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

      // Button should display countdown (110s = 01:50)
      expect(find.text('⏳ 01:50'), findsOneWidget);
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

    testWidgets('GameViewport displays storefront icon without Home button', (tester) async {
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
      // Home and Settings icons are NOT on GameViewport action bar
      expect(find.byIcon(Icons.home_rounded), findsNothing);
      expect(find.byIcon(Icons.settings_rounded), findsNothing);

      // Tapping storefront icon opens RewardCenterSheet
      await tester.tap(find.byIcon(Icons.storefront_rounded));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(RewardCenterSheet), findsOneWidget);
      expect(find.text('DHABA REWARD CENTER'), findsOneWidget);
    });
  });
}
