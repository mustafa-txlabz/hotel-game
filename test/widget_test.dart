import 'package:flutter_test/flutter_test.dart';
import 'package:chai_dhaba_empire/app.dart';
import 'package:chai_dhaba_empire/core/strings.dart';

void main() {
  testWidgets('App launches and displays placeholder screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ChaiDhabaEmpireApp());
    expect(find.text(AppStrings.appTitle), findsOneWidget);
    expect(find.text(AppStrings.welcome), findsOneWidget);
  });
}
