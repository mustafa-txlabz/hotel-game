import 'dart:math' as math;

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

  // Item carrying stats (for M1+)
  int carryCapacity;
  int carriedCount;

  PlayerEntity({
    Vector2? startPosition,
    this.speed = 220.0,
    this.radius = 20.0,
    this.carryCapacity = 3,
  }) : position = startPosition ?? Vector2(400.0, 500.0),
       velocity = Vector2(0.0, 0.0),
       angle = math.pi / 2, // Default facing forward/down
       isMoving = false,
       walkCycle = 0.0,
       carriedCount = 0;

  void update(double dt) {
    if (dt <= 0.0) return;

    if (velocity.length > 1.0) {
      isMoving = true;
      position.x += velocity.x * dt;
      position.y += velocity.y * dt;
      angle = math.atan2(velocity.y, velocity.x);
      walkCycle = (walkCycle + dt * 14.0) % (math.pi * 2);
    } else {
      isMoving = false;
      walkCycle = 0.0;
    }
  }
}
