/// Pure Dart game state models.
///
/// NOTE: No Flutter imports are allowed in this file.
library;

class BusinessState {
  final String id;
  final int owned;
  final int lastMilestoneClaimed;

  const BusinessState({
    required this.id,
    this.owned = 0,
    this.lastMilestoneClaimed = 0,
  });

  BusinessState copyWith({String? id, int? owned, int? lastMilestoneClaimed}) {
    return BusinessState(
      id: id ?? this.id,
      owned: owned ?? this.owned,
      lastMilestoneClaimed: lastMilestoneClaimed ?? this.lastMilestoneClaimed,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'owned': owned,
    'lastMilestoneClaimed': lastMilestoneClaimed,
  };

  factory BusinessState.fromJson(Map<String, dynamic> json) {
    return BusinessState(
      id: json['id'] as String,
      owned: (json['owned'] as num?)?.toInt() ?? 0,
      lastMilestoneClaimed:
          (json['lastMilestoneClaimed'] as num?)?.toInt() ?? 0,
    );
  }
}

class GameState {
  final double rupees;
  final double lifetimeRupees;
  final double runRupees;
  final int shohrat;
  final double boostMultiplier;
  final Map<String, BusinessState> businesses;

  const GameState({
    this.rupees = 0.0,
    this.lifetimeRupees = 0.0,
    this.runRupees = 0.0,
    this.shohrat = 0,
    this.boostMultiplier = 1.0,
    this.businesses = const {},
  });

  GameState copyWith({
    double? rupees,
    double? lifetimeRupees,
    double? runRupees,
    int? shohrat,
    double? boostMultiplier,
    Map<String, BusinessState>? businesses,
  }) {
    return GameState(
      rupees: rupees ?? this.rupees,
      lifetimeRupees: lifetimeRupees ?? this.lifetimeRupees,
      runRupees: runRupees ?? this.runRupees,
      shohrat: shohrat ?? this.shohrat,
      boostMultiplier: boostMultiplier ?? this.boostMultiplier,
      businesses: businesses ?? this.businesses,
    );
  }

  BusinessState getBusiness(String id) {
    return businesses[id] ?? BusinessState(id: id);
  }

  Map<String, dynamic> toJson() => {
    'rupees': rupees,
    'lifetimeRupees': lifetimeRupees,
    'runRupees': runRupees,
    'shohrat': shohrat,
    'boostMultiplier': boostMultiplier,
    'businesses': businesses.map((k, v) => MapEntry(k, v.toJson())),
  };

  factory GameState.fromJson(Map<String, dynamic> json) {
    final rawBiz = json['businesses'] as Map<String, dynamic>? ?? {};
    final bizMap = <String, BusinessState>{};
    for (final entry in rawBiz.entries) {
      if (entry.value is Map<String, dynamic>) {
        bizMap[entry.key] = BusinessState.fromJson(
          entry.value as Map<String, dynamic>,
        );
      }
    }
    return GameState(
      rupees: (json['rupees'] as num?)?.toDouble() ?? 0.0,
      lifetimeRupees: (json['lifetimeRupees'] as num?)?.toDouble() ?? 0.0,
      runRupees: (json['runRupees'] as num?)?.toDouble() ?? 0.0,
      shohrat: (json['shohrat'] as num?)?.toInt() ?? 0,
      boostMultiplier: (json['boostMultiplier'] as num?)?.toDouble() ?? 1.0,
      businesses: bizMap,
    );
  }
}
