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

/// Floating combat-text style currency popups (+Rs 10) rendered in world space.
class FloatingTextEntity {
  final Vector2 position;
  final String text;
  double lifeTime;
  final double maxLifeTime;

  FloatingTextEntity({
    required Vector2 position,
    required this.text,
    this.lifeTime = 1.2,
  }) : position = position.copy(),
       maxLifeTime = lifeTime;

  bool get isExpired => lifeTime <= 0.0;

  void update(double dt) {
    lifeTime -= dt;
    position.y -= dt * 45.0; // Float upwards
  }
}

/// 3D-styled green Rupee cash bundle dropped on the counter or floor.
class CashBundleEntity {
  final Vector2 position;
  final double value;
  bool isFlying;
  double flySpeed;
  double spawnBounceTimer;

  CashBundleEntity({required Vector2 position, required this.value})
    : position = position.copy(),
      isFlying = false,
      flySpeed = 180.0,
      spawnBounceTimer = 0.2;

  /// Progresses vacuum suction towards target (player).
  /// Returns true when absorbed into the player's wallet.
  bool updateTowards(Vector2 targetPos, double dt) {
    if (spawnBounceTimer > 0.0) {
      spawnBounceTimer -= dt;
    }

    if (!isFlying) return false;

    final dist = position.distanceTo(targetPos);
    final step = flySpeed * dt;
    if (dist <= 22.0 || step >= dist) {
      return true; // Reached player, collect!
    }

    // Accelerate magnetic suction as it flies
    flySpeed += dt * 800.0;
    final dx = targetPos.x - position.x;
    final dy = targetPos.y - position.y;

    position.x += (dx / dist) * step;
    position.y += (dy / dist) * step;

    return false;
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
  bool isOutside;

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
       wobbleVelocity = 0.0,
       isOutside = false;

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
