/// Pure Dart game state models.
///
/// NOTE: No Flutter imports are allowed in this file.
library;

class BusinessState {
  final String id;
  final int owned;

  const BusinessState({
    required this.id,
    this.owned = 0,
  });

  BusinessState copyWith({
    String? id,
    int? owned,
  }) {
    return BusinessState(
      id: id ?? this.id,
      owned: owned ?? this.owned,
    );
  }
}

class GameState {
  final double rupees;
  final double lifetimeRupees;
  final double runRupees;
  final int shohrat;
  final Map<String, BusinessState> businesses;

  const GameState({
    this.rupees = 0.0,
    this.lifetimeRupees = 0.0,
    this.runRupees = 0.0,
    this.shohrat = 0,
    this.businesses = const {},
  });

  GameState copyWith({
    double? rupees,
    double? lifetimeRupees,
    double? runRupees,
    int? shohrat,
    Map<String, BusinessState>? businesses,
  }) {
    return GameState(
      rupees: rupees ?? this.rupees,
      lifetimeRupees: lifetimeRupees ?? this.lifetimeRupees,
      runRupees: runRupees ?? this.runRupees,
      shohrat: shohrat ?? this.shohrat,
      businesses: businesses ?? this.businesses,
    );
  }
}
