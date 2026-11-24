import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../data/deals_catalog.dart';
import '../engine/deals.dart';
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

    _world.onStepOnDealPad = (deal) {
      onDealRequested?.call(deal);
      notifyListeners();
    };

    _world.onDoorOpened = () {
      notifyListeners();
    };

    _world.onDoorClosed = () {
      notifyListeners();
    };

    _world.onVipCarArrived = (car) {
      this.audioService.playCarHorn();
      _triggerHaptic(HapticFeedback.heavyImpact);
      notifyListeners();
    };

    _world.onVipCarParked = (car) {
      this.audioService.playCarBrake();
      _triggerHaptic(HapticFeedback.mediumImpact);
      notifyListeners();
    };

    _world.onVipCarCompleted = (car) {
      this.audioService.playMilestone();
      this.audioService.playCoin();
      _triggerHaptic(HapticFeedback.heavyImpact);
      saveGame();
      notifyListeners();
    };

    _world.onVipCarLeftUnhappy = (car) {
      _triggerHaptic(HapticFeedback.mediumImpact);
      notifyListeners();
    };
  }

  /// Optional callback invoked when the player walks onto the Deal Pad
  void Function(DhabaDeal deal)? onDealRequested;

  Future<void> _initSave() async {
    final soundEnabled = await _saveService.loadSoundEnabled(defaultValue: true);
    final hapticsEnabled = await _saveService.loadHapticsEnabled(defaultValue: true);
    audioService.isMuted = !soundEnabled;
    audioService.isHapticsEnabled = hapticsEnabled;

    await _saveService.loadStoreState(_world);
    _isInitialized = true;
    notifyListeners();
  }

  /// Whether sound FX are currently enabled.
  bool get isSoundEnabled => !audioService.isMuted;

  /// Whether tactile haptic feedback is currently enabled.
  bool get isHapticsEnabled => audioService.isHapticsEnabled;

  /// Toggles sound FX on/off and persists preference immediately.
  Future<void> toggleSound() async {
    final next = !isSoundEnabled;
    audioService.isMuted = !next;
    await _saveService.saveSoundEnabled(next);
    if (next) {
      audioService.playTap();
    }
    notifyListeners();
  }

  /// Toggles haptic feedback on/off and persists preference immediately.
  Future<void> toggleHaptics() async {
    final next = !isHapticsEnabled;
    audioService.isHapticsEnabled = next;
    await _saveService.saveHapticsEnabled(next);
    if (next) {
      try {
        HapticFeedback.mediumImpact();
      } catch (_) {}
    }
    notifyListeners();
  }

  /// Completely resets current store progress and settings.
  Future<void> resetAllProgress() async {
    await _saveService.clearAllData();
    _world.rupees = 0.0;
    _world.gems = 0;
    _world.lifetimeRupees = 0.0;
    _world.reputationPercent = 0.0;
    _world.isReputationLocked100 = false;
    _world.completedMissionIds.clear();
    _world.isStoreMasteredCelebrated = false;
    _world.isMasteryRewardClaimed = false;
    _world.chaiStation.level = 1;
    _world.parathaStation.isUnlocked = false;
    _world.parathaStation.level = 1;
    for (final table in _world.diningTables) {
      table.isUnlocked = false;
      for (final seat in table.seats) {
        seat.isOccupied = false;
      }
    }
    _world.staff.clear();
    _world.playerSpeedLevel = 0;
    _world.playerCapacityLevel = 0;
    _world.workerSpeedLevel = 0;
    _world.workerCapacityLevel = 0;
    _world.cashierSpeedLevel = 0;
    _world.counter.foodTowers.clear();
    _world.counter.cashBundleCount = 0;
    _world.counter.isCashierPresent = false;
    _world.customerSystem.activeCustomers.clear();
    _world.customerSystem.queue.customers.clear();
    audioService.isMuted = false;
    audioService.isHapticsEnabled = true;
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

  /// Claims a rewarded ad power-up deal
  void claimDeal(DhabaDeal deal) {
    _world.activateDeal(deal);
    audioService.playBuy();
    saveGame();
    notifyListeners();
  }

  /// Dismisses an active deal pad
  void dismissDeal() {
    _world.dismissDealPad();
    notifyListeners();
  }

  /// Buys an on-demand Reward Center deal using Store Gems
  bool buyStoreDealWithGems(CatalogDealItem deal) {
    final success = _world.buyCatalogDealWithGems(deal);
    if (success) {
      audioService.playBuy();
      saveGame();
      notifyListeners();
    }
    return success;
  }

  /// Claims an on-demand Reward Center deal via Rewarded Ad
  void claimStoreDealWithAd(CatalogDealItem deal) {
    _world.claimCatalogDealWithAd(deal);
    audioService.playBuy();
    saveGame();
    notifyListeners();
  }

  SaveService get saveService => _saveService;
  bool get isInitialized => _isInitialized;

  void _triggerHaptic(AsyncCallback hapticFn) {
    if (!audioService.isHapticsEnabled) return;
    final now = DateTime.now();
    if (now.difference(_lastHapticTime).inMilliseconds >= 70) {
      _lastHapticTime = now;
      hapticFn();
    }
  }

  GameWorld get world => _world;
  double get rupees => _world.rupees;
  int get gems => _world.gems;

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
