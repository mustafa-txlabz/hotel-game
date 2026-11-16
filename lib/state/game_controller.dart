import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../engine/game_world.dart';

/// Central game controller binding [GameWorld] simulation to Flutter UI.
class GameController extends ChangeNotifier {
  final GameWorld _world;

  // Throttle haptics so fast collection feels snappy without buzzing uncontrollably
  DateTime _lastHapticTime = DateTime.fromMillisecondsSinceEpoch(0);

  GameController({GameWorld? world}) : _world = world ?? GameWorld() {
    _world.onItemPickedUp = (_) {
      _triggerHaptic(HapticFeedback.lightImpact);
      notifyListeners();
    };

    _world.onItemServed = (_) {
      _triggerHaptic(HapticFeedback.mediumImpact);
      notifyListeners();
    };

    _world.onCashCollected = (_) {
      _triggerHaptic(HapticFeedback.selectionClick);
      notifyListeners();
    };

    _world.onItemDiscarded = () {
      _triggerHaptic(HapticFeedback.lightImpact);
      notifyListeners();
    };
  }

  void _triggerHaptic(AsyncCallback hapticFn) {
    final now = DateTime.now();
    if (now.difference(_lastHapticTime).inMilliseconds >= 75) {
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
    notifyListeners();
  }
}
