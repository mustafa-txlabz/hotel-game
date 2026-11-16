import 'package:flutter/foundation.dart';
import '../engine/game_engine.dart';

/// GameController binds the pure Dart [GameEngine] with Flutter's [ChangeNotifier].
class GameController extends ChangeNotifier {
  final GameEngine _engine;

  GameController({GameEngine? engine}) : _engine = engine ?? GameEngine();

  GameEngine get engine => _engine;
}

