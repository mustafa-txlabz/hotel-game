import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:chai_dhaba_empire/core/strings.dart';
import 'package:chai_dhaba_empire/state/game_controller.dart';
import 'package:chai_dhaba_empire/ui/game/game_viewport.dart';
import 'package:chai_dhaba_empire/ui/screens/home_screen.dart';
import 'package:chai_dhaba_empire/ui/screens/splash_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SplashScreen Tests (M11)', () {
    testWidgets('SplashScreen renders title, app icon, progress bar, and quotes', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<GameController>(
          create: (_) => GameController(),
          child: const MaterialApp(
            home: SplashScreen(
              duration: Duration(milliseconds: 500),
              autoNavigate: false,
            ),
          ),
        ),
      );

      // Verify title branding and subtitle badge
      expect(find.text(AppStrings.appTitle.toUpperCase()), findsOneWidget);
      expect(find.text('ARCADE IDLE TYCOON'), findsOneWidget);

      // Verify initial loading progress
      expect(find.byType(SplashScreen), findsOneWidget);

      // Verify version footer
      expect(find.text('v1.0.0 • Dhaba Arcade Tycoon'), findsOneWidget);
    });

    testWidgets('SplashScreen navigates to HomeScreen when loading finishes', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<GameController>(
          create: (_) => GameController(),
          child: const MaterialApp(
            home: SplashScreen(
              duration: Duration(milliseconds: 100),
              autoNavigate: true,
            ),
          ),
        ),
      );

      // Pump through the progress controller duration
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();

      // HomeScreen should now be displayed
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('ENTER DHABA'), findsOneWidget);
    });
  });

  group('HomeScreen Main Menu Tests (M11)', () {
    testWidgets('HomeScreen renders store showcase card, wallets, and action buttons', (
      WidgetTester tester,
    ) async {
      final controller = GameController();
      controller.world.rupees = 1500.0;
      controller.world.gems = 12;

      await tester.pumpWidget(
        ChangeNotifierProvider<GameController>.value(
          value: controller,
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pump();

      // Verify Header Row
      expect(find.text(AppStrings.appTitle), findsOneWidget);
      expect(find.text('Rs 1.50K'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);

      // Verify Active Store Showcase Card
      expect(find.text('Highway Kadak Dhaba'), findsOneWidget);
      expect(find.text('Location 1 • Grand Trunk Road Highway'), findsOneWidget);
      expect(find.text('☕ Kettle'), findsOneWidget);
      expect(find.text('🫓 Paratha'), findsOneWidget);
      expect(find.text('👥 Staff'), findsOneWidget);

      // Verify Main Action Buttons
      expect(find.text('ENTER DHABA'), findsOneWidget);
      expect(find.text('MAP & LOCATIONS'), findsOneWidget);
      expect(find.byIcon(Icons.settings_rounded), findsOneWidget);
    });

    testWidgets('Tapping ENTER DHABA navigates to GameViewport', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<GameController>(
          create: (_) => GameController(),
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pump();

      final playButton = find.text('ENTER DHABA');
      expect(playButton, findsOneWidget);

      await tester.tap(playButton);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 50));

      // Viewport is now displayed
      expect(find.byType(GameViewport), findsOneWidget);
    });

    testWidgets('Tapping MAP & LOCATIONS displays coming soon preview snackbar', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<GameController>(
          create: (_) => GameController(),
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pump();

      final mapButton = find.text('MAP & LOCATIONS');
      await tester.tap(mapButton);
      await tester.pump();

      expect(find.text('🗺️ City Travel Map coming in M13! Store 2 awaits!'), findsOneWidget);
    });
  });
}
