import 'models.dart';

/// Core game logic engine.
///
/// NOTE: Pure Dart class with NO Flutter imports so it can be completely unit tested.
class GameEngine {
  GameState _state;

  GameEngine([GameState? initialState]) : _state = initialState ?? const GameState();

  GameState get state => _state;

  /// Updates state by a time delta [dt] in seconds.
  void tick(double dt) {
    if (dt <= 0) return;
    _state = _state.copyWith();
  }
}
