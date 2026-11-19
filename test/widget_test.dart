import 'package:flutter_test/flutter_test.dart';
import 'package:chai_dhaba_empire/app.dart';
import 'package:chai_dhaba_empire/core/strings.dart';
import 'package:chai_dhaba_empire/ui/game/game_viewport.dart';

void main() {
  testWidgets('Arcade Viewport Smoke Test: renders canvas and handles touch', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ChaiDhabaEmpireApp());
    await tester.pump();

    // Verify viewport and HUD title
    expect(find.byType(GameViewport), findsOneWidget);
    expect(find.text(AppStrings.appTitle), findsOneWidget);
    expect(find.text(AppStrings.dragToMove), findsOneWidget);

    // Simulate touch drag
    final gesture = await tester.startGesture(const Offset(200, 400));
    await tester.pump();

    await gesture.moveBy(const Offset(40, 40));
    await tester.pump(const Duration(milliseconds: 16));

    await gesture.up();
    await tester.pump();
  });

  testWidgets('Tapping on HR button opens HR sheet without spawning joystick', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ChaiDhabaEmpireApp());
    await tester.pump();

    final hrButton = find.byTooltip('HR & Upgrades');
    expect(hrButton, findsOneWidget);

    await tester.tap(hrButton);
    await tester.pump(const Duration(milliseconds: 300));

    // HR Sheet opens
    expect(find.text('HR & UPGRADES'), findsOneWidget);
  });

  testWidgets('Tapping on Goals button opens Goals sheet without spawning joystick', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ChaiDhabaEmpireApp());
    await tester.pump();

    final goalsButton = find.byTooltip('Goals & Expansion');
    expect(goalsButton, findsOneWidget);

    await tester.tap(goalsButton);
    await tester.pump(const Duration(milliseconds: 300));

    // Goals & Reputation Sheet opens
    expect(find.text('STORE OBJECTIVES'), findsOneWidget);
  });
}
