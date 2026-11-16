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
}
