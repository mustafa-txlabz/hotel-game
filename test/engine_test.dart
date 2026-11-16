import 'package:flutter_test/flutter_test.dart';
import 'package:chai_dhaba_empire/data/balance.dart';
import 'package:chai_dhaba_empire/engine/game_engine.dart';
import 'package:chai_dhaba_empire/engine/models.dart';

void main() {
  group('GameEngine Core Formulas (AGENTS.md 5.4 & 5.5)', () {
    test('Initial state starts with 0 rupees and no businesses', () {
      final engine = GameEngine();
      expect(engine.state.rupees, 0.0);
      expect(engine.state.lifetimeRupees, 0.0);
      expect(engine.state.shohrat, 0);
      expect(engine.totalIncomePerSecond, 0.0);
    });

    test('Cost of single unit follows baseCost * (1.13 ^ owned)', () {
      // Chai Thela baseCost = 10, g = 1.13
      final cost0 = GameEngine.calculateCost(
        baseCost: 10.0,
        owned: 0,
        count: 1,
      );
      expect(cost0, 10.0);

      final cost1 = GameEngine.calculateCost(
        baseCost: 10.0,
        owned: 1,
        count: 1,
      );
      expect(cost1, closeTo(11.3, 0.01));

      final cost5 = GameEngine.calculateCost(
        baseCost: 10.0,
        owned: 5,
        count: 1,
      );
      expect(cost5, closeTo(10.0 * 1.8424, 0.01));
    });

    test('Bulk cost formula matches geometric series', () {
      // 10 units starting from 0: baseCost * (g^10 - 1) / (g - 1)
      final bulkCost10 = GameEngine.calculateCost(
        baseCost: 10.0,
        owned: 0,
        count: 10,
      );
      double manualSum = 0;
      for (int i = 0; i < 10; i++) {
        manualSum += GameEngine.calculateCost(
          baseCost: 10.0,
          owned: i,
          count: 1,
        );
      }
      expect(bulkCost10, closeTo(manualSum, 0.001));
    });

    test('Max affordable calculation matches cash available', () {
      final cash = 100.0;
      final max = GameEngine.calculateMaxAffordable(
        cash: cash,
        baseCost: 10.0,
        owned: 0,
      );
      final costForMax = GameEngine.calculateCost(
        baseCost: 10.0,
        owned: 0,
        count: max,
      );
      final costForMaxPlusOne = GameEngine.calculateCost(
        baseCost: 10.0,
        owned: 0,
        count: max + 1,
      );

      expect(cash >= costForMax, isTrue);
      expect(cash < costForMaxPlusOne, isTrue);
    });

    test('Business income and total income calculation', () {
      // Chai Thela gives 0.5 Rs/s per unit
      final engine = GameEngine(
        const GameState(
          rupees: 50.0,
          businesses: {'chai_thela': BusinessState(id: 'chai_thela', owned: 2)},
        ),
      );

      expect(engine.businessIncomePerSecond('chai_thela'), 1.0);
      expect(engine.totalIncomePerSecond, 1.0);
    });

    test('Prestige Shohrat multiplier gives +3% per shohrat', () {
      final engine = GameEngine(
        const GameState(
          rupees: 0.0,
          shohrat: 10, // +30%
          businesses: {
            'chai_thela': BusinessState(
              id: 'chai_thela',
              owned: 10,
            ), // 10 * 0.5 = 5.0
          },
        ),
      );

      // 5.0 * (1 + 0.03 * 10) = 5.0 * 1.30 = 6.5
      expect(engine.totalIncomePerSecond, closeTo(6.5, 0.001));
    });

    test('Milestone multiplier doubles income at 25, 50, 100', () {
      expect(GameBalance.getMilestoneMultiplier(0), 1.0);
      expect(GameBalance.getMilestoneMultiplier(24), 1.0);
      expect(GameBalance.getMilestoneMultiplier(25), 2.0); // 1st milestone
      expect(GameBalance.getMilestoneMultiplier(49), 2.0);
      expect(GameBalance.getMilestoneMultiplier(50), 4.0); // 2nd milestone
      expect(GameBalance.getMilestoneMultiplier(100), 8.0); // 3rd milestone
    });

    test('Tap cup gives 1 + 0.02 * totalIncomePerSecond', () {
      final engine = GameEngine(
        const GameState(
          rupees: 0.0,
          businesses: {
            'chai_thela': BusinessState(
              id: 'chai_thela',
              owned: 100,
            ), // income = 100 * 0.5 * 8 = 400
          },
        ),
      );

      final income = engine.totalIncomePerSecond;
      expect(income, 400.0);

      // Tap should give 1 + 0.02 * 400 = 9 Rs
      final earned = engine.tapCup();
      expect(earned, 9.0);
      expect(engine.state.rupees, 9.0);
      expect(engine.state.lifetimeRupees, 9.0);
    });

    test('GameEngine tick accumulates income by delta-time', () {
      final engine = GameEngine(
        const GameState(
          rupees: 0.0,
          businesses: {
            'chai_thela': BusinessState(id: 'chai_thela', owned: 2), // 1.0 Rs/s
          },
        ),
      );

      engine.tick(0.5); // half a second
      expect(engine.state.rupees, closeTo(0.5, 0.001));

      engine.tick(1.0); // one full second
      expect(engine.state.rupees, closeTo(1.5, 0.001));
    });

    test('Business unlocking rules', () {
      final engine = GameEngine();
      // Chai Thela (index 1) is unlocked by default
      expect(engine.isBusinessUnlocked('chai_thela'), isTrue);
      // Paratha Stall (index 2) is locked until 1 Chai Thela is owned
      expect(engine.isBusinessUnlocked('paratha_stall'), isFalse);

      final unlockedEngine = GameEngine(
        const GameState(
          businesses: {'chai_thela': BusinessState(id: 'chai_thela', owned: 1)},
        ),
      );
      expect(unlockedEngine.isBusinessUnlocked('paratha_stall'), isTrue);
      expect(unlockedEngine.isBusinessUnlocked('roadside_dhaba'), isFalse);
    });

    test('Buy business reduces cash and increments owned', () {
      final engine = GameEngine(const GameState(rupees: 25.0));
      expect(engine.canAfford('chai_thela'), isTrue);

      final result = engine.buyBusiness('chai_thela');
      expect(result.success, isTrue);
      expect(engine.state.rupees, closeTo(15.0, 0.01));
      expect(engine.state.getBusiness('chai_thela').owned, 1);
    });
  });
}
