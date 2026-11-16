import 'package:flutter/foundation.dart';

import '../engine/game_world.dart';

/// Central game controller binding [GameWorld] simulation to Flutter UI.
class GameController extends ChangeNotifier {
  final GameWorld _world;

  GameController({GameWorld? world}) : _world = world ?? GameWorld();

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
