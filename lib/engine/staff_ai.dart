import 'dart:math' as math;

import '../data/balance.dart';
import 'entities.dart';
import 'stations.dart';

/// Roles of hired workers in the shop.
enum StaffRole {
  cashier,
  helper, // Waiter / Runner / Helper
  chotu, // Alias for backward compatibility
}

/// Preferred duty specialization for Helper workers.
enum HelperDuty {
  runner, // Focuses on Chai kettle -> Counter restocking
  busboy, // Focuses on Dining table cleaning & tips -> Trash bin
}

typedef ChotuDuty = HelperDuty;

/// AI Task states for autonomous Helpers (Waiters).
enum HelperTaskState {
  idle,
  fetchingChai,
  deliveringChai,
  cleaningTable,
  dumpingTrash,
}

typedef ChotuTaskState = HelperTaskState;

/// Represents a hired worker (Cashier or Helper Waiter).
class StaffEntity {
  final int id;
  final String name;
  final StaffRole role;
  final Vector2 position;
  final Vector2 targetPosition;
  double angle; // Radians
  double speed;
  double radius;
  bool isMoving;
  double walkCycle;
  int carryCapacity;
  final List<ItemType> carriedItems;
  double wobbleAngle;

  // AI Task & duty tracking for Helpers
  HelperTaskState taskState;
  HelperDuty duty;
  int? assignedTableId;
  double stateTimer;
  bool isVip;

  StaffEntity({
    required this.id,
    required this.name,
    required this.role,
    required Vector2 startPosition,
    this.speed = GameBalance.workerBaseSpeed,
    this.radius = 18.0,
    this.carryCapacity = GameBalance.workerBaseCapacity,
    this.duty = HelperDuty.runner,
    this.assignedTableId,
    this.isVip = false,
  }) : position = startPosition.copy(),
       targetPosition = startPosition.copy(),
       angle = math.pi / 2, // Facing down
       isMoving = false,
       walkCycle = 0.0,
       carriedItems = [],
       wobbleAngle = 0.0,
       taskState = HelperTaskState.idle,
       stateTimer = 0.0;

  int get carriedCount => carriedItems.length;
  bool get isFull => carriedCount >= carryCapacity;

  bool addItem(ItemType item) {
    if (carriedCount < carryCapacity) {
      carriedItems.add(item);
      return true;
    }
    return false;
  }

  ItemType? removeItem() {
    if (carriedItems.isNotEmpty) {
      return carriedItems.removeLast();
    }
    return null;
  }

  /// Determines the effective navigation target to route cleanly around the counter
  /// through open side corridors when moving between the kitchen and dining zones.
  Vector2 getEffectiveTarget() {
    // Counter obstacle bounds with padding
    const counterTop = 674.0;
    const counterBottom = 766.0;
    const counterLeft = 280.0;
    const counterRight = 620.0;

    final crossesY = (position.y <= counterTop && targetPosition.y >= counterBottom) ||
        (position.y >= counterBottom && targetPosition.y <= counterTop);

    if (!crossesY) {
      return targetPosition;
    }

    final dy = targetPosition.y - position.y;
    if (dy.abs() < 0.0001) return targetPosition;

    final t = (720.0 - position.y) / dy;
    if (t < 0.0 || t > 1.0) return targetPosition;

    final crossX = position.x + t * (targetPosition.x - position.x);
    if (crossX < counterLeft || crossX > counterRight) {
      return targetPosition; // Direct path cleanly passes through side corridors
    }

    // Direct path intersects the counter! Route through the closest corridor:
    final goingSouth = position.y < 720.0;

    final leftNorth = Vector2(230.0, 650.0);
    final leftSouth = Vector2(230.0, 770.0);
    final rightNorth = Vector2(680.0, 650.0);
    final rightSouth = Vector2(680.0, 770.0);

    final double distLeft;
    final double distRight;

    if (goingSouth) {
      distLeft = position.distanceTo(leftNorth) + leftSouth.distanceTo(targetPosition);
      distRight = position.distanceTo(rightNorth) + rightSouth.distanceTo(targetPosition);
    } else {
      distLeft = position.distanceTo(leftSouth) + leftNorth.distanceTo(targetPosition);
      distRight = position.distanceTo(rightSouth) + rightNorth.distanceTo(targetPosition);
    }

    final useRight = distRight < distLeft;

    if (useRight) {
      if (goingSouth) {
        if (position.y < 650.0 || position.x < 650.0) {
          return rightNorth;
        } else if (position.y < 770.0) {
          return rightSouth;
        }
      } else {
        if (position.y > 770.0 || position.x < 650.0) {
          return rightSouth;
        } else if (position.y > 650.0) {
          return rightNorth;
        }
      }
    } else {
      if (goingSouth) {
        if (position.y < 650.0 || position.x > 260.0) {
          return leftNorth;
        } else if (position.y < 770.0) {
          return leftSouth;
        }
      } else {
        if (position.y > 770.0 || position.x > 260.0) {
          return leftSouth;
        } else if (position.y > 650.0) {
          return leftNorth;
        }
      }
    }

    return targetPosition;
  }

  /// Updates movement towards targetPosition, routing cleanly around solid counters.
  void updateMovement(double dt) {
    if (dt <= 0.0) return;

    final effectiveTarget = getEffectiveTarget();
    final dist = position.distanceTo(effectiveTarget);
    final finalDist = position.distanceTo(targetPosition);
    final step = speed * dt;

    if (finalDist <= step || finalDist <= 3.0) {
      position.x = targetPosition.x;
      position.y = targetPosition.y;
      isMoving = false;
      walkCycle = 0.0;
      // Spring wobble back upright
      wobbleAngle += (0.0 - wobbleAngle) * math.min(1.0, dt * 8.0);
    } else {
      isMoving = true;
      final moveDist = math.max(0.0001, dist);
      final dx = effectiveTarget.x - position.x;
      final dy = effectiveTarget.y - position.y;

      final actualStep = math.min(step, moveDist);
      position.x += (dx / moveDist) * actualStep;
      position.y += (dy / moveDist) * actualStep;

      angle = math.atan2(dy, dx);
      walkCycle = (walkCycle + dt * 14.0) % (math.pi * 2);

      final targetWobble = math.sin(walkCycle) * 0.12;
      wobbleAngle += (targetWobble - wobbleAngle) * math.min(1.0, dt * 10.0);
    }
  }
}
