import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chai_dhaba_empire/data/city_shops_catalog.dart';
import 'package:chai_dhaba_empire/engine/game_world.dart';
import 'package:chai_dhaba_empire/state/game_controller.dart';
import 'package:chai_dhaba_empire/ui/game/game_viewport.dart';
import 'package:chai_dhaba_empire/ui/screens/city_map_screen.dart';

void main() {
  group('M13: CityShopsCatalog Tests', () {
    test('Catalog defines exactly 10 unique shops ending with Grand Empire Supermarket', () {
      const shops = CityShopsCatalog.shops;
      expect(shops.length, 10);

      // Verify sequential numbering 1..10
      for (int i = 0; i < 10; i++) {
        expect(shops[i].number, i + 1);
      }

      // Shop 1 is playable Highway Kadak Dhaba
      expect(shops.first.isPlayable, isTrue);
      expect(shops.first.name, 'Highway Kadak Dhaba');

      // Shops 2-9 are unique non-playable previews
      for (int i = 1; i < 9; i++) {
        expect(shops[i].isPlayable, isFalse);
        expect(shops[i].isSupermarket, isFalse);
      }

      // Shop 10 is the Grand Empire Supermarket
      expect(shops.last.isSupermarket, isTrue);
      expect(shops.last.isPlayable, isFalse);
      expect(shops.last.name, 'GRAND EMPIRE SUPERMARKET');
    });
  });

  group('M13: CityMapScreen Widget Tests', () {
    late GameController controller;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      final world = GameWorld(initialRupees: 750, initialGems: 12)
        ..reputationPercent = 45.0;
      controller = GameController(world: world);
    });

    testWidgets('CityMapScreen renders header, 1/10 OPEN badge, and Shop 1', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<GameController>.value(
          value: controller,
          child: const MaterialApp(
            home: CityMapScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('CITY TRAVEL MAP'), findsOneWidget);
      expect(find.text('1/10 OPEN'), findsOneWidget);
      expect(find.text('Highway Kadak Dhaba'), findsOneWidget);
      expect(find.text('Rep: 45%'), findsOneWidget);
    });

    testWidgets('Tapping Shop 1 opens preview sheet with stats and TRAVEL & PLAY', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<GameController>.value(
          value: controller,
          child: const MaterialApp(
            home: CityMapScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Highway Kadak Dhaba'));
      await tester.pumpAndSettle();

      expect(find.text('SHOP #1'), findsOneWidget);
      expect(find.text('45%'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.text('TRAVEL & PLAY'), findsOneWidget);

      // Tapping TRAVEL & PLAY navigates to GameViewport
      await tester.tap(find.text('TRAVEL & PLAY'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(GameViewport), findsOneWidget);
    });

    testWidgets('Scrolling to top reveals Shop 10 Grand Empire Supermarket preview', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<GameController>.value(
          value: controller,
          child: const MaterialApp(
            home: CityMapScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll up to the mountain summit (offset 0)
      final scrollable = find.byType(SingleChildScrollView);
      await tester.drag(scrollable, const Offset(0, 2500));
      await tester.pumpAndSettle();

      expect(find.text('GRAND EMPIRE SUPERMARKET'), findsOneWidget);
      expect(find.text('👑 MEGA MALL'), findsOneWidget);

      // Tap Shop 10 to open preview
      await tester.tap(find.text('GRAND EMPIRE SUPERMARKET'));
      await tester.pumpAndSettle();

      expect(find.text('SHOP #10'), findsOneWidget);
      expect(find.text('COMING SOON • CLOSE PREVIEW'), findsOneWidget);
    });
  });
}
