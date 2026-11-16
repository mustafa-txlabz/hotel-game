import 'dart:math' as math;

import 'entities.dart';
import 'stations.dart';

/// Pure Dart world simulation managing physical bounds, entities, stations, and collisions.
class GameWorld {
  // World arena dimensions in virtual points
  final double worldWidth;
  final double worldHeight;
  final double wallThickness;

  // Entities & Stations
  final PlayerEntity player;
  final ChaiStation chaiStation;

  // Economy & currency (soft currency)
  double rupees;

  // Callback triggered when an item is picked up (for haptics / sound)
  void Function(ItemType item)? onItemPickedUp;

  GameWorld({
    this.worldWidth = 900.0,
    this.worldHeight = 1200.0,
    this.wallThickness = 32.0,
    double initialRupees = 0.0,
    ChaiStation? station,
  }) : player = PlayerEntity(startPosition: Vector2(450.0, 600.0)),
       chaiStation = station ?? ChaiStation(position: Vector2(260.0, 260.0)),
       rupees = initialRupees;

  /// Sets joystick input vector normalized (-1.0 to 1.0).
  void setJoystickInput(double dx, double dy) {
    final length = math.sqrt(dx * dx + dy * dy);
    if (length > 0.1) {
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

    // 1. Update station brewing logic
    chaiStation.update(dt);

    // 2. Update player physics
    player.update(dt);

    // 3. Collision against perimeter boundary walls
    _clampPlayerToWorldBounds();

    // 4. Collision against station solid counter
    _resolveStationCollision();

    // 5. Item pickup zone detection
    _checkItemPickup();
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

  void _resolveStationCollision() {
    final halfW = chaiStation.width / 2;
    final halfH = chaiStation.height / 2;
    final left = chaiStation.position.x - halfW;
    final right = chaiStation.position.x + halfW;
    final top = chaiStation.position.y - halfH;
    final bottom = chaiStation.position.y + halfH;

    // Closest point on rectangle to circle center
    final closestX = player.position.x.clamp(left, right);
    final closestY = player.position.y.clamp(top, bottom);

    final dx = player.position.x - closestX;
    final dy = player.position.y - closestY;
    final distance = math.sqrt(dx * dx + dy * dy);

    if (distance < player.radius) {
      if (distance > 0.0001) {
        final push = player.radius - distance;
        player.position.x += (dx / distance) * push;
        player.position.y += (dy / distance) * push;
      } else {
        // Center is inside, push out to nearest edge
        final distLeft = (player.position.x - left).abs();
        final distRight = (right - player.position.x).abs();
        final distTop = (player.position.y - top).abs();
        final distBottom = (bottom - player.position.y).abs();
        final minDist = math.min(
          math.min(distLeft, distRight),
          math.min(distTop, distBottom),
        );

        if (minDist == distBottom) {
          player.position.y = bottom + player.radius;
        } else if (minDist == distTop) {
          player.position.y = top - player.radius;
        } else if (minDist == distRight) {
          player.position.x = right + player.radius;
        } else {
          player.position.x = left - player.radius;
        }
      }
    }
  }

  void _checkItemPickup() {
    if (player.isFull) return;

    if (chaiStation.isInsidePickupZone(player.position)) {
      if (chaiStation.tryTakeCup()) {
        player.addItem(ItemType.chai);
        onItemPickedUp?.call(ItemType.chai);
      }
    }
  }
}
