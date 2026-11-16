import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:chai_dhaba_empire/app.dart';
import 'package:chai_dhaba_empire/core/strings.dart';

void main() {
  testWidgets('Core loop UI smoke test: taps cup and verifies UI updates', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ChaiDhabaEmpireApp());
    await tester.pump();

    // Verify Title & Initial Header
    expect(find.text(AppStrings.appTitle), findsOneWidget);
    expect(find.text('${AppStrings.currencySymbol}0.0'), findsOneWidget);
    expect(find.text(AppStrings.tapPrompt), findsOneWidget);

    // Verify First Business is visible
    expect(find.text('Chai Thela'), findsOneWidget);
    expect(find.text(AppStrings.buyButton), findsWidgets);

    // Tap the big cup
    final cupFinder = find.byIcon(Icons.local_cafe_rounded);
    expect(cupFinder, findsOneWidget);
    await tester.tap(cupFinder);
    await tester.pump();

    // After 1 tap, rupees should be 1.0
    expect(find.text('${AppStrings.currencySymbol}1.0'), findsOneWidget);
  });
}
