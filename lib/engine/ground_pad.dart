import 'dart:math' as math;

import 'entities.dart';

enum PadType { machineUpgrade, floorUnlock }

/// An interactive floor rectangle pad for in-place machine upgrades or floor unlocks.
/// Features smooth cash pouring, partial progress memory, and tactile level-up triggers.
class GroundPad {
  final String id;
  final PadType type;
  final Vector2 position;
  final double width;
  final double height;

  String title;
  double totalCost;
  double remainingCost;
  int currentLevel;
  final int maxLevel;
  bool isCompleted;

  // Pouring mechanics
  double pourInterval;
  double pourTimer;
  double pourRate; // Rupees poured per second

  // Callbacks
  final double Function(int targetLevel)? costForLevel;
  final String Function(int targetLevel)? titleForLevel;
  void Function(int newLevel)? onLevelUp;
  void Function()? onUnlocked;

  GroundPad({
    required this.id,
    required this.type,
    required this.position,
    this.width = 78.0,
    this.height = 50.0,
    required this.title,
    required this.totalCost,
    this.currentLevel = 1,
    this.maxLevel = 5,
    this.pourInterval = 0.06,
    this.pourRate = 60.0, // 60 Rs per second smooth pour
    this.costForLevel,
    this.titleForLevel,
    this.onLevelUp,
    this.onUnlocked,
  }) : remainingCost = totalCost,
       isCompleted = false,
       pourTimer = 0.0;

  double get progress => totalCost > 0.0
      ? (1.0 - (remainingCost / totalCost)).clamp(0.0, 1.0)
      : 1.0;

  bool get isMaxLevel => currentLevel >= maxLevel;

  /// Sets current level directly and updates title/cost (used during state restoration).
  void setLevel(int level) {
    currentLevel = level;
    if (currentLevel >= maxLevel) {
      isCompleted = true;
      title = 'MAX';
      remainingCost = 0.0;
    } else {
      if (costForLevel != null) {
        totalCost = costForLevel!(currentLevel + 1);
        remainingCost = totalCost;
      }
      if (titleForLevel != null) {
        title = titleForLevel!(currentLevel + 1);
      }
    }
  }

  /// Checks if character is standing inside the pad rectangle with comfortable reach.
  bool isInside(Vector2 pos) {
    final halfW = width / 2 + 10.0;
    final halfH = height / 2 + 10.0;
    return (pos.x >= position.x - halfW &&
        pos.x <= position.x + halfW &&
        pos.y >= position.y - halfH &&
        pos.y <= position.y + halfH);
  }

  /// Pours cash from available wallet into the pad.
  /// Returns the amount of rupees consumed in this tick.
  double pourCash(double availableRupees, double dt) {
    if (isCompleted ||
        remainingCost <= 0.0 ||
        availableRupees <= 0.0 ||
        dt <= 0.0) {
      return 0.0;
    }

    // Amount to pour based on pour rate and dt
    final maxPossiblePour = pourRate * dt;
    final amountToPour = math.min(
      maxPossiblePour,
      math.min(remainingCost, availableRupees),
    );

    if (amountToPour <= 0.0) return 0.0;

    remainingCost -= amountToPour;
    if (remainingCost < 0.001) {
      remainingCost = 0.0;
      _triggerCompletion();
    }

    return amountToPour;
  }

  void _triggerCompletion() {
    if (type == PadType.floorUnlock) {
      isCompleted = true;
      onUnlocked?.call();
    } else if (type == PadType.machineUpgrade) {
      currentLevel++;
      onLevelUp?.call(currentLevel);

      if (currentLevel >= maxLevel) {
        isCompleted = true;
        title = 'MAX';
        remainingCost = 0.0;
      } else {
        // Prepare next level curve
        if (costForLevel != null) {
          totalCost = costForLevel!(currentLevel + 1);
          remainingCost = totalCost;
        }
        if (titleForLevel != null) {
          title = titleForLevel!(currentLevel + 1);
        }
      }
    }
  }
}
