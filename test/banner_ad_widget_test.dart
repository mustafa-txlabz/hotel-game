import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:chai_dhaba_empire/services/ad_ids.dart';
import 'package:chai_dhaba_empire/ui/widgets/banner_ad_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    BannerAdWidget.testMode = true;
    BannerAdWidget.testMockLoaded = false;
  });

  tearDown(() {
    BannerAdWidget.testMode = false;
    BannerAdWidget.testMockLoaded = false;
  });

  group('BannerAd Configuration & AdIds Tests', () {
    test('AdIds provides valid test banner ad unit identifier', () {
      expect(AdIds.bannerAdUnitId, equals(AdIds.testBannerAdUnitIdAndroid));
      expect(AdIds.bannerAdUnitId, contains('6300978111'));
    });
  });

  group('BannerAdWidget Clean Screen & Display Tests', () {
    testWidgets('Clean screen rule: Renders SizedBox.shrink when ad is not loaded', (
      WidgetTester tester,
    ) async {
      BannerAdWidget.testMockLoaded = false;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BannerAdWidget(),
          ),
        ),
      );
      await tester.pump();

      // Verify widget renders
      expect(find.byType(BannerAdWidget), findsOneWidget);
      // Clean screen guarantee: NO placeholder text or border rendered!
      expect(find.text('DHABA TYCOON • AD BANNER'), findsNothing);
      expect(find.byIcon(Icons.local_cafe_rounded), findsNothing);
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('Renders full-width simulated test ad banner when loaded', (
      WidgetTester tester,
    ) async {
      BannerAdWidget.testMockLoaded = true;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BannerAdWidget(),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(BannerAdWidget), findsOneWidget);
      expect(find.text('TEST AD • FULL-WIDTH BANNER'), findsOneWidget);
    });

    testWidgets('BannerAdWidget uses 45-second default auto-refresh interval', (
      WidgetTester tester,
    ) async {
      const widget = BannerAdWidget();
      expect(widget.refreshInterval, equals(const Duration(seconds: 45)));
      expect(widget.autoRefresh, isTrue);
    });

    testWidgets('refreshAd() public method updates banner display state', (
      WidgetTester tester,
    ) async {
      final key = GlobalKey<BannerAdWidgetState>();
      BannerAdWidget.testMockLoaded = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BannerAdWidget(key: key),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('TEST AD • FULL-WIDTH BANNER'), findsNothing);

      // Simulate ad becoming available and trigger refreshAd
      BannerAdWidget.testMockLoaded = true;
      key.currentState?.refreshAd();
      await tester.pump();

      expect(find.text('TEST AD • FULL-WIDTH BANNER'), findsOneWidget);
    });
  });
}
