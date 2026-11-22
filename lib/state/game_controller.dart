import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../engine/game_world.dart';
import '../services/audio_service.dart';
import '../services/save_service.dart';

/// Central game controller binding [GameWorld] simulation to Flutter UI.
class GameController extends ChangeNotifier {
  final GameWorld _world;
  final SaveService _saveService;
  final AudioService audioService;

  DateTime _lastHapticTime = DateTime.fromMillisecondsSinceEpoch(0);
  double _autoSaveTimer = 0.0;
  bool _isInitialized = false;

  GameController({
    GameWorld? world,
    SaveService? saveService,
    AudioService? audioService,
  })  : _world = world ?? GameWorld(),
        _saveService = saveService ?? SaveService(),
        audioService = audioService ?? AudioService() {
    _initSave();

    _world.onItemPickedUp = (_) {
      this.audioService.playPour();
      _triggerHaptic(HapticFeedback.lightImpact);
      notifyListeners();
    };

    _world.onItemDeposited = (_) {
      _triggerHaptic(HapticFeedback.selectionClick);
      notifyListeners();
    };

    _world.onItemServed = (_) {
      this.audioService.playServe();
      _triggerHaptic(HapticFeedback.mediumImpact);
      notifyListeners();
    };

    _world.onCashCollected = (_) {
      this.audioService.playCoin();
      _triggerHaptic(HapticFeedback.selectionClick);
      notifyListeners();
    };

    _world.onItemDiscarded = () {
      _triggerHaptic(HapticFeedback.lightImpact);
      notifyListeners();
    };

    _world.onStoreMastered = () {
      this.audioService.playMilestone();
      saveGame();
      notifyListeners();
    };
  }

  Future<void> _initSave() async {
    await _saveService.loadStoreState(_world);
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> saveGame() async {
    await _saveService.saveStoreState(_world);
  }

  /// Claims the 100% store mastery reward bonus (₹1,000)
  void claimMasteryReward() {
    if (_world.claimMasteryReward()) {
      audioService.playBuy();
      saveGame();
      notifyListeners();
    }
  }

  SaveService get saveService => _saveService;
  bool get isInitialized => _isInitialized;

  void _triggerHaptic(AsyncCallback hapticFn) {
    final now = DateTime.now();
    if (now.difference(_lastHapticTime).inMilliseconds >= 70) {
      _lastHapticTime = now;
      hapticFn();
    }
  }

  GameWorld get world => _world;
  double get rupees => _world.rupees;

  /// Passes normalized joystick input (-1.0 to 1.0) to world simulation.
  void setJoystickInput(double dx, double dy) {
    _world.setJoystickInput(dx, dy);
  }

  /// Ticks the physics and world simulation by [dt] seconds.
  void tick(double dt) {
    _world.tick(dt);

    _autoSaveTimer += dt;
    if (_autoSaveTimer >= 5.0) {
      _autoSaveTimer = 0.0;
      _saveService.saveStoreState(_world);
    }

    notifyListeners();
  }
}
