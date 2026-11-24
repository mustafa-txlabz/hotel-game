import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chai_dhaba_empire/engine/game_world.dart';
import 'package:chai_dhaba_empire/services/audio_service.dart';
import 'package:chai_dhaba_empire/services/legal_links.dart';
import 'package:chai_dhaba_empire/services/save_service.dart';
import 'package:chai_dhaba_empire/state/game_controller.dart';
import 'package:chai_dhaba_empire/ui/overlays/settings_dialog.dart';
import 'package:chai_dhaba_empire/ui/screens/home_screen.dart';
import 'package:chai_dhaba_empire/ui/widgets/banner_ad_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    BannerAdWidget.testMode = true;
    BannerAdWidget.testMockLoaded = true;
  });

  group('M12: Audio & Haptics Persistence (SaveService)', () {
    test('Sound and haptics preferences default to true and can be saved/loaded', () async {
      final saveService = SaveService();

      expect(await saveService.loadSoundEnabled(), isTrue);
      expect(await saveService.loadHapticsEnabled(), isTrue);

      await saveService.saveSoundEnabled(false);
      expect(await saveService.loadSoundEnabled(), isFalse);

      await saveService.saveHapticsEnabled(false);
      expect(await saveService.loadHapticsEnabled(), isFalse);

      await saveService.saveSoundEnabled(true);
      expect(await saveService.loadSoundEnabled(), isTrue);
    });

    test('clearAllData clears save key and audio settings', () async {
      final saveService = SaveService();
      await saveService.saveSoundEnabled(false);
      await saveService.saveHapticsEnabled(false);

      await saveService.clearAllData();
      // Should fall back to default values
      expect(await saveService.loadSoundEnabled(), isTrue);
      expect(await saveService.loadHapticsEnabled(), isTrue);
    });
  });

  group('M12: AudioService & GameController Audio/Haptics Control', () {
    test('AudioService respects isMuted and isHapticsEnabled flags', () {
      final audio = AudioService();
      expect(audio.isMuted, isFalse);
      expect(audio.isHapticsEnabled, isTrue);

      audio.isMuted = true;
      audio.isHapticsEnabled = false;

      // Ensure no exceptions occur when calling sound triggers in muted/no-haptic state
      audio.playTap();
      audio.playBuy();
      audio.playMilestone();
      audio.playCarHorn();
      audio.playCarBrake();
      audio.dispose();
    });

    test('GameController toggleSound and toggleHaptics update state and persist', () async {
      final saveService = SaveService();
      final controller = GameController(saveService: saveService);
      // Wait for async _initSave
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(controller.isSoundEnabled, isTrue);
      expect(controller.isHapticsEnabled, isTrue);

      await controller.toggleSound();
      expect(controller.isSoundEnabled, isFalse);
      expect(await saveService.loadSoundEnabled(), isFalse);

      await controller.toggleHaptics();
      expect(controller.isHapticsEnabled, isFalse);
      expect(await saveService.loadHapticsEnabled(), isFalse);

      await controller.toggleSound();
      expect(controller.isSoundEnabled, isTrue);
    });

    test('GameController resetAllProgress clears data and resets store level', () async {
      final world = GameWorld();
      world.rupees = 5000.0;
      world.gems = 15;
      world.reputationPercent = 85.0;

      final controller = GameController(world: world);
      await controller.resetAllProgress();

      expect(controller.rupees, equals(0.0));
      expect(controller.gems, equals(0));
      expect(world.reputationPercent, equals(0.0));
      expect(controller.isSoundEnabled, isTrue);
      expect(controller.isHapticsEnabled, isTrue);
    });
  });

  group('M12: LegalLinks Configuration (# URLs)', () {
    test('LegalLinks defaults all legal options to # for Vercel deployment', () {
      expect(LegalLinks.privacyPolicyUrl, equals('#'));
      expect(LegalLinks.termsOfUseUrl, equals('#'));
      expect(LegalLinks.supportUrl, equals('#'));
      expect(LegalLinks.supportEmail, equals('support@chaidhaba.com'));
    });
  });

  group('M12: SettingsDialog Widget Tests', () {
    testWidgets('SettingsDialog renders all sections and toggles', (
      WidgetTester tester,
    ) async {
      final controller = GameController();

      await tester.pumpWidget(
        ChangeNotifierProvider<GameController>.value(
          value: controller,
          child: MaterialApp(
            home: Scaffold(
              body: SettingsDialog(controller: controller),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      // Header
      expect(find.text('SETTINGS'), findsOneWidget);

      // Section A: Audio & Controls
      expect(find.text('AUDIO & CONTROLS'), findsOneWidget);
      expect(find.text('Sound Effects (SFX)'), findsOneWidget);
      expect(find.text('Haptic Feedback'), findsOneWidget);

      // Section B: Legal & Privacy
      expect(find.text('LEGAL & PRIVACY'), findsOneWidget);
      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.text('Terms of Use'), findsOneWidget);
      expect(find.text('Help & Player Support'), findsOneWidget);
      // All 3 legal links show '#' badge
      expect(find.text('#'), findsNWidgets(3));

      // Section C: About Game
      expect(find.text('ABOUT GAME'), findsOneWidget);
      expect(find.textContaining('Version 1.0.0'), findsOneWidget);

      // Section D: Danger Zone
      expect(find.text('RESET GAME PROGRESS'), findsOneWidget);
    });

    testWidgets('Tapping sound switch toggles sound FX state', (
      WidgetTester tester,
    ) async {
      final controller = GameController();

      await tester.pumpWidget(
        ChangeNotifierProvider<GameController>.value(
          value: controller,
          child: MaterialApp(
            home: Scaffold(
              body: SettingsDialog(controller: controller),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      final soundSwitch = find.byType(Switch).first;
      expect(controller.isSoundEnabled, isTrue);

      await tester.tap(soundSwitch);
      await tester.pump();

      expect(controller.isSoundEnabled, isFalse);
    });

    testWidgets('Tapping Privacy Policy opens bottom legal sheet', (
      WidgetTester tester,
    ) async {
      final controller = GameController();

      await tester.pumpWidget(
        ChangeNotifierProvider<GameController>.value(
          value: controller,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => SettingsDialog.show(context, controller),
                  child: const Text('OPEN'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('OPEN'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 100));

      final privacyTile = find.text('Privacy Policy');
      expect(privacyTile, findsOneWidget);

      await tester.tap(privacyTile);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 100));

      // Legal sheet is now open
      expect(find.text('PRIVACY POLICY'), findsOneWidget);
      expect(find.text('Linked URL: #'), findsOneWidget);
      expect(find.text('GOT IT'), findsOneWidget);

      // Dismiss the bottom sheet
      Navigator.of(tester.element(find.text('PRIVACY POLICY'))).pop();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('Tapping Settings button on HomeScreen opens SettingsDialog', (
      WidgetTester tester,
    ) async {
      final controller = GameController();

      await tester.pumpWidget(
        ChangeNotifierProvider<GameController>.value(
          value: controller,
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pump();

      final settingsButton = find.byIcon(Icons.settings_rounded);
      expect(settingsButton, findsOneWidget);

      await tester.tap(settingsButton);
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 50));

      // Settings dialog should be visible
      expect(find.byType(SettingsDialog), findsOneWidget);
      expect(find.text('SETTINGS'), findsOneWidget);
    });
  });
}
