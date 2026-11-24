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

  group('BannerAdWidget Display Tests', () {
    testWidgets('Renders placeholder when ad is not loaded', (
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
      // Verify placeholder branding text
      expect(find.text('DHABA TYCOON • AD BANNER'), findsOneWidget);
    });

    testWidgets('Renders simulated test ad banner when loaded', (
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
      expect(find.text('TEST AD • BANNER (320x50)'), findsOneWidget);
    });

    testWidgets('BannerAdWidget uses 45-second default auto-refresh interval', (
      WidgetTester tester,
    ) async {
      const widget = BannerAdWidget();
      expect(widget.refreshInterval, equals(const Duration(seconds: 45)));
      expect(widget.autoRefresh, isTrue);
    });
  });
}
