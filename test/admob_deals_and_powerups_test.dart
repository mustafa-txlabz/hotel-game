import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chai_dhaba_empire/data/balance.dart';
import 'package:chai_dhaba_empire/engine/deals.dart';
import 'package:chai_dhaba_empire/engine/entities.dart';
import 'package:chai_dhaba_empire/engine/game_world.dart';
import 'package:chai_dhaba_empire/engine/staff_ai.dart';
import 'package:chai_dhaba_empire/services/ad_ids.dart';
import 'package:chai_dhaba_empire/state/game_controller.dart';
import 'package:chai_dhaba_empire/ui/overlays/deal_popup.dart';

void main() {
  group('M9: AdIds Configuration & Google Official Test IDs', () {
    test('Default configuration enables safe test ads', () {
      expect(AdIds.useTestAds, isTrue);
    });

    test('AdIds provides valid Google sample test ad unit identifiers', () {
      expect(AdIds.rewardedAdUnitId, equals(AdIds.testRewardedAdUnitIdAndroid));
      expect(AdIds.rewardedAdUnitId, contains('5224354917'));

      expect(
        AdIds.interstitialAdUnitId,
        equals(AdIds.testInterstitialAdUnitIdAndroid),
      );
      expect(AdIds.interstitialAdUnitId, contains('1033173712'));

      expect(AdIds.appId, equals(AdIds.testAppIdAndroid));
      expect(AdIds.appId, contains('3347511713'));
    });

    test('DhabaDeal pool contains 5 diverse, balanced deals', () {
      final pool = DhabaDeal.defaultPool;
      expect(pool.length, equals(5));

      final types = pool.map((d) => d.type).toSet();
      expect(types, contains(DealType.staffTurbo));
      expect(types, contains(DealType.kitchenBoost));
      expect(types, contains(DealType.customerRush));
      expect(types, contains(DealType.instantCash));
      expect(types, contains(DealType.vipHelper));
    });

    test('Staff speed rebalancing provides smooth scaling for 2x boosts', () {
      expect(GameBalance.workerBaseSpeed, equals(135.0));
      expect(
        GameBalance.workerSpeedLevels,
        equals([135.0, 155.0, 180.0, 210.0]),
      );
    });
  });

  group('M9: GameWorld Deal Spawning, Stepping & Dismissal', () {
    test('Deal Pad spawns when timer reaches 0', () {
      final world = GameWorld();
      world.dealSpawnTimer = 0.5;

      world.tick(0.4);
      expect(world.isDealPadActive, isFalse);

      world.tick(0.2); // Timer completes
      expect(world.isDealPadActive, isTrue);
      expect(world.availableDeal, isNotNull);
      expect(world.isDealAvailable, isTrue);
    });

    test('Stepping onto the Deal Pad triggers onStepOnDealPad callback', () {
      final world = GameWorld();
      world.spawnRandomDeal(
        specificDeal: const DhabaDeal(
          type: DealType.staffTurbo,
          title: '2X STAFF SPEED',
          description: 'Turbo speed!',
          iconEmoji: '⚡',
        ),
      );

      DhabaDeal? requestedDeal;
      world.onStepOnDealPad = (deal) {
        requestedDeal = deal;
      };

      // Player stands away
      world.player.position.x = 100.0;
      world.player.position.y = 100.0;
      world.tick(0.016);
      expect(requestedDeal, isNull);

      // Player walks onto pad
      world.player.position.x = world.dealPadPosition.x;
      world.player.position.y = world.dealPadPosition.y;
      world.tick(0.016);
      expect(requestedDeal, isNotNull);
      expect(requestedDeal?.type, equals(DealType.staffTurbo));
    });

    test('Dismissing the deal pad clears it and sets respawn cooldown', () {
      final world = GameWorld();
      world.spawnRandomDeal();
      expect(world.isDealPadActive, isTrue);

      world.dismissDealPad();
      expect(world.isDealPadActive, isFalse);
      expect(world.availableDeal, isNull);
      expect(world.dealSpawnTimer, greaterThan(0.0));
    });
  });

  group('M9: Power-Up Boost Activation & Timers', () {
    test('Staff Turbo Boost speeds up player and workers for 90s', () {
      final world = GameWorld();
      final helper = StaffEntity(
        id: 1,
        name: 'Chotu',
        role: StaffRole.helper,
        startPosition: Vector2(400, 400),
      );
      world.staff.add(helper);

      final basePlayerSpeed = world.player.speed;
      final baseWorkerSpeed = helper.speed;

      const deal = DhabaDeal(
        type: DealType.staffTurbo,
        title: '2X STAFF SPEED',
        description: 'Turbo speed!',
        iconEmoji: '⚡',
        durationSeconds: 90,
      );

      world.activateDeal(deal);
      expect(world.isStaffTurboActive, isTrue);
      expect(world.activeDealRemainingSeconds, equals(90.0));

      world.tick(0.1);
      expect(world.player.speed, greaterThan(basePlayerSpeed));
      expect(helper.speed, greaterThan(baseWorkerSpeed));

      // Advance by 91 seconds -> boost expires
      world.tick(91.0);
      expect(world.isStaffTurboActive, isFalse);
      expect(world.activeDeal, isNull);

      // Speeds return to normal
      world.tick(0.1);
      expect(world.player.speed, equals(basePlayerSpeed));
    });

    test('Kitchen Boost activates 2x cooking speed for 90s', () {
      final world = GameWorld();
      const deal = DhabaDeal(
        type: DealType.kitchenBoost,
        title: '2X KITCHEN BOOST',
        description: '2x cook speed!',
        iconEmoji: '🔥',
        durationSeconds: 90,
      );

      world.activateDeal(deal);
      expect(world.isKitchenBoostActive, isTrue);

      // Advance 91s -> boost expires
      world.tick(91.0);
      expect(world.isKitchenBoostActive, isFalse);
    });

    test('Customer Rush activates 2x rush frequency for 90s', () {
      final world = GameWorld();
      const deal = DhabaDeal(
        type: DealType.customerRush,
        title: 'CUSTOMER RUSH',
        description: 'Rush!',
        iconEmoji: '👥',
        durationSeconds: 90,
      );

      world.activateDeal(deal);
      expect(world.isCustomerRushActive, isTrue);

      world.tick(91.0);
      expect(world.isCustomerRushActive, isFalse);
    });

    test('Instant Cash Drop immediately rewards cash without lingering timer', () {
      final world = GameWorld(initialRupees: 100.0);
      const deal = DhabaDeal(
        type: DealType.instantCash,
        title: 'INSTANT CASH',
        description: 'Cash!',
        iconEmoji: '💰',
        durationSeconds: 0,
        cashReward: 600.0,
      );

      world.activateDeal(deal);
      expect(world.rupees, equals(700.0));
      expect(world.lifetimeRupees, equals(700.0));
      expect(world.activeDeal, isNull);
      expect(world.dealSpawnTimer, greaterThan(0.0));
    });

    test('Golden VIP Helper joins shop for 120s and despawns upon expiration', () {
      final world = GameWorld();
      expect(world.staff.where((s) => s.isVip), isEmpty);

      const deal = DhabaDeal(
        type: DealType.vipHelper,
        title: 'GOLDEN VIP HELPER',
        description: 'VIP helper!',
        iconEmoji: '👷',
        durationSeconds: 120,
      );

      world.activateDeal(deal);
      expect(world.isVipHelperActive, isTrue);
      expect(world.vipHelper, isNotNull);
      expect(world.vipHelper?.isVip, isTrue);
      expect(world.vipHelper?.carryCapacity, equals(5));
      expect(world.staff.where((s) => s.isVip).length, equals(1));

      // Advance 121 seconds -> VIP helper leaves
      world.tick(121.0);
      expect(world.isVipHelperActive, isFalse);
      expect(world.vipHelper, isNull);
      expect(world.staff.where((s) => s.isVip), isEmpty);
    });
  });

  group('M9: UI DealPopup Widget Tests', () {
    testWidgets('DealPopup displays animated gift, title, duration, and claim button', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final controller = GameController();
      const deal = DhabaDeal(
        type: DealType.staffTurbo,
        title: '2X STAFF TURBO SPEED',
        description: 'Owner & helpers run 2x faster for 90 seconds!',
        iconEmoji: '⚡',
        durationSeconds: 90,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () => DealPopup.show(context, controller, deal),
                  child: const Text('Open Deal'),
                );
              },
            ),
          ),
        ),
      );

      // Tap open
      await tester.tap(find.text('Open Deal'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify contents
      expect(find.text('SPECIAL DHABA DEAL'), findsOneWidget);
      expect(find.text('2X STAFF TURBO SPEED'), findsOneWidget);
      expect(find.text('90 SECONDS BOOST'), findsOneWidget);
      expect(find.text('WATCH AD & CLAIM'), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      // Tap close
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('SPECIAL DHABA DEAL'), findsNothing);
    });

    testWidgets('Tapping WATCH AD & CLAIM claims deal and closes popup', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final controller = GameController();
      const deal = DhabaDeal(
        type: DealType.instantCash,
        title: 'INSTANT CASH DROP',
        description: 'Direct ₹600 cash drop!',
        iconEmoji: '💰',
        durationSeconds: 0,
        cashReward: 600.0,
      );

      final initialRupees = controller.rupees;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () => DealPopup.show(context, controller, deal),
                  child: const Text('Open Deal'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Deal'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Tap claim (in test environment, fallback grants reward immediately)
      await tester.tap(find.text('WATCH AD & CLAIM'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Popup is closed
      expect(find.text('SPECIAL DHABA DEAL'), findsNothing);
      // Reward is granted
      expect(controller.rupees, equals(initialRupees + 600.0));
    });
  });
}
