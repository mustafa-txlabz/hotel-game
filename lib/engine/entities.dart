import 'dart:math' as math;

import 'stations.dart';

/// Simple 2D vector for pure Dart physics simulation.
class Vector2 {
  double x;
  double y;

  Vector2([this.x = 0.0, this.y = 0.0]);

  Vector2 copy() => Vector2(x, y);

  double get length => math.sqrt(x * x + y * y);

  double distanceTo(Vector2 other) {
    final dx = x - other.x;
    final dy = y - other.y;
    return math.sqrt(dx * dx + dy * dy);
  }

  void normalize() {
    final len = length;
    if (len > 0.0001) {
      x /= len;
      y /= len;
    } else {
      x = 0.0;
      y = 0.0;
    }
  }

  void scale(double s) {
    x *= s;
    y *= s;
  }
}

/// Represents the player character controlled via joystick.
class PlayerEntity {
  final Vector2 position;
  final Vector2 velocity;
  double angle; // Facing angle in radians (0 = facing right, pi/2 = down)
  double speed; // Pixels per second
  double radius; // Collision radius
  bool isMoving;
  double walkCycle; // Animation phase (0 to 2*PI)

  // Item carrying stats & physics wobble
  int carryCapacity;
  final List<ItemType> carriedItems;
  double wobbleAngle; // Sway in radians
  double wobbleVelocity;

  PlayerEntity({
    Vector2? startPosition,
    this.speed = 220.0,
    this.radius = 20.0,
    this.carryCapacity = 3,
  }) : position = startPosition ?? Vector2(450.0, 600.0),
       velocity = Vector2(0.0, 0.0),
       angle = math.pi / 2, // Default facing forward/down
       isMoving = false,
       walkCycle = 0.0,
       carriedItems = [],
       wobbleAngle = 0.0,
       wobbleVelocity = 0.0;

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

  void update(double dt) {
    if (dt <= 0.0) return;

    final currentSpeed = velocity.length;
    if (currentSpeed > 1.0) {
      isMoving = true;
      position.x += velocity.x * dt;
      position.y += velocity.y * dt;

      // Smooth turning angle
      final targetAngle = math.atan2(velocity.y, velocity.x);
      angle = targetAngle;

      walkCycle = (walkCycle + dt * 14.0) % (math.pi * 2);

      // Inertia wobble when moving: sways with walking stride + velocity
      final targetWobble = math.sin(walkCycle) * 0.12 * (currentSpeed / speed);
      wobbleAngle += (targetWobble - wobbleAngle) * math.min(1.0, dt * 10.0);
    } else {
      isMoving = false;
      walkCycle = 0.0;
      // Spring back to center upright position when standing still
      wobbleAngle += (0.0 - wobbleAngle) * math.min(1.0, dt * 8.0);
    }
  }
}
