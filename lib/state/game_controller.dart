import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../data/balance.dart';
import '../engine/game_engine.dart';
import '../engine/models.dart';

/// Floating tap particle representing "+Rs X" floating upwards from tap position.
class TapParticle {
  final int id;
  final double amount;
  final double x;
  final double y;
  final DateTime createdAt;

  TapParticle({
    required this.id,
    required this.amount,
    required this.x,
    required this.y,
  }) : createdAt = DateTime.now();
}

/// Central state controller binding Flutter UI with [GameEngine].
///
/// Drives the 10 Hz delta-time tick loop, throttles haptic feedback,
/// and manages UI floating tap animations.
class GameController extends ChangeNotifier {
  final GameEngine _engine;
  Timer? _ticker;
  DateTime _lastTickTime = DateTime.now();

  // Haptic feedback throttling (max 10 per second = min 100ms interval)
  DateTime _lastHapticTime = DateTime.fromMillisecondsSinceEpoch(0);

  // Floating tap text particles
  int _particleIdCounter = 0;
  final List<TapParticle> _particles = [];

  // Milestone event callback for UI toast
  Function(String businessName, int milestone)? onMilestoneReached;

  GameController({GameEngine? engine}) : _engine = engine ?? GameEngine() {
    _startTicker();
  }

  GameEngine get engine => _engine;
  GameState get state => _engine.state;
  double get rupees => _engine.state.rupees;
  double get totalIncomePerSecond => _engine.totalIncomePerSecond;
  List<TapParticle> get particles => List.unmodifiable(_particles);

  void _startTicker() {
    _lastTickTime = DateTime.now();
    _ticker = Timer.periodic(
      const Duration(milliseconds: 100),
      (_) => _onTick(),
    );
  }

  void _onTick() {
    final now = DateTime.now();
    final dt = now.difference(_lastTickTime).inMicroseconds / 1000000.0;
    _lastTickTime = now;

    if (dt > 0.0) {
      _engine.tick(dt);

      // Clean up old floating tap particles older than 1 second
      _particles.removeWhere(
        (p) => now.difference(p.createdAt).inMilliseconds > 1000,
      );

      notifyListeners();
    }
  }

  /// Taps the chai cup to earn immediate rupees.
  /// Throttles haptics to max 10/s as specified in AGENTS.md 5.5.
  double tapCup([Offset? position]) {
    final gain = _engine.tapCup();

    // Spawn floating particle if position provided
    if (position != null) {
      _particles.add(
        TapParticle(
          id: ++_particleIdCounter,
          amount: gain,
          x: position.dx,
          y: position.dy,
        ),
      );
    }

    // Throttle haptic feedback to max 10 per second
    final now = DateTime.now();
    if (now.difference(_lastHapticTime).inMilliseconds >= 100) {
      _lastHapticTime = now;
      HapticFeedback.lightImpact();
    }

    notifyListeners();
    return gain;
  }

  /// Attempts to buy [count] units of [businessId].
  bool buyBusiness(String businessId, [int count = 1]) {
    final result = _engine.buyBusiness(businessId, count);
    if (result.success) {
      HapticFeedback.selectionClick();

      if (result.milestoneHit) {
        final config = GameBalance.allBusinesses.firstWhere(
          (b) => b.id == businessId,
        );
        final owned = _engine.state.getBusiness(businessId).owned;
        onMilestoneReached?.call(config.name, owned);
        HapticFeedback.mediumImpact();
      }

      notifyListeners();
      return true;
    }
    return false;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
