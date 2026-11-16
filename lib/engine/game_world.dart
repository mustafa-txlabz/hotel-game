import 'dart:math' as math;

import 'entities.dart';

/// Pure Dart world simulation managing physical bounds, entities, and collisions.
class GameWorld {
  // World arena dimensions in virtual points
  final double worldWidth;
  final double worldHeight;

  // Boundary wall padding
  final double wallThickness;

  // Entities
  final PlayerEntity player;

  // Economy & currency (soft currency)
  double rupees;

  GameWorld({
    this.worldWidth = 900.0,
    this.worldHeight = 1200.0,
    this.wallThickness = 30.0,
    double initialRupees = 0.0,
  }) : player = PlayerEntity(startPosition: Vector2(450.0, 600.0)),
       rupees = initialRupees;

  /// Sets joystick input vector normalized (-1.0 to 1.0).
  void setJoystickInput(double dx, double dy) {
    final length = math.sqrt(dx * dx + dy * dy);
    if (length > 0.1) {
      // Clamp magnitude to 1.0
      final normX = dx / (length > 1.0 ? length : 1.0);
      final normY = dy / (length > 1.0 ? length : 1.0);
      player.velocity.x = normX * player.speed;
      player.velocity.y = normY * player.speed;
    } else {
      player.velocity.x = 0.0;
      player.velocity.y = 0.0;
    }
  }

  /// Progresses the world simulation by [dt] seconds.
  void tick(double dt) {
    if (dt <= 0.0) return;

    // Update player movement
    player.update(dt);

    // Collision against perimeter boundary walls
    _clampPlayerToWorldBounds();
  }

  void _clampPlayerToWorldBounds() {
    final minX = wallThickness + player.radius;
    final maxX = worldWidth - wallThickness - player.radius;
    final minY = wallThickness + player.radius;
    final maxY = worldHeight - wallThickness - player.radius;

    if (player.position.x < minX) player.position.x = minX;
    if (player.position.x > maxX) player.position.x = maxX;
    if (player.position.y < minY) player.position.y = minY;
    if (player.position.y > maxY) player.position.y = maxY;
  }
}
