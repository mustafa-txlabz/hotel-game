import 'dart:math' as math;

import '../data/balance.dart';
import 'entities.dart';
import 'stations.dart';

/// Roles of hired workers in the Dhaba.
enum StaffRole {
  cashier,
  chotu, // Waiter / Runner
}

/// Preferred duty specialization for Chotu workers.
enum ChotuDuty {
  runner, // Focuses on Chai kettle -> Counter restocking
  busboy, // Focuses on Dining table cleaning & tips -> Trash bin
}

/// AI Task states for autonomous Chotus (Waiters).
enum ChotuTaskState {
  idle,
  fetchingChai,
  deliveringChai,
  cleaningTable,
  dumpingTrash,
}

/// Represents a hired worker (Cashier or Chotu Waiter).
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

  // AI Task & duty tracking for Chotus
  ChotuTaskState taskState;
  ChotuDuty duty;
  int? assignedTableId;
  double stateTimer;

  StaffEntity({
    required this.id,
    required this.name,
    required this.role,
    required Vector2 startPosition,
    this.speed = GameBalance.workerBaseSpeed,
    this.radius = 18.0,
    this.carryCapacity = GameBalance.workerBaseCapacity,
    this.duty = ChotuDuty.runner,
    this.assignedTableId,
  }) : position = startPosition.copy(),
       targetPosition = startPosition.copy(),
       angle = math.pi / 2, // Facing down
       isMoving = false,
       walkCycle = 0.0,
       carriedItems = [],
       wobbleAngle = 0.0,
       taskState = ChotuTaskState.idle,
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

  /// Updates movement towards targetPosition.
  void updateMovement(double dt) {
    if (dt <= 0.0) return;

    final dist = position.distanceTo(targetPosition);
    final step = speed * dt;

    if (dist <= step || dist <= 3.0) {
      position.x = targetPosition.x;
      position.y = targetPosition.y;
      isMoving = false;
      walkCycle = 0.0;
      // Spring wobble back upright
      wobbleAngle += (0.0 - wobbleAngle) * math.min(1.0, dt * 8.0);
    } else {
      isMoving = true;
      final dx = targetPosition.x - position.x;
      final dy = targetPosition.y - position.y;

      position.x += (dx / dist) * step;
      position.y += (dy / dist) * step;

      angle = math.atan2(dy, dx);
      walkCycle = (walkCycle + dt * 14.0) % (math.pi * 2);

      final targetWobble = math.sin(walkCycle) * 0.12;
      wobbleAngle += (targetWobble - wobbleAngle) * math.min(1.0, dt * 10.0);
    }
  }
}
