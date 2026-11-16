import 'package:flutter_test/flutter_test.dart';
import 'package:chai_dhaba_empire/engine/game_engine.dart';

void main() {
  group('GameEngine Initial State', () {
    test('initial state has 0 rupees', () {
      final engine = GameEngine();
      expect(engine.state.rupees, 0.0);
    });
  });
}

