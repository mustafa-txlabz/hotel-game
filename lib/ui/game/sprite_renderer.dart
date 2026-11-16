import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';
import '../../engine/entities.dart';

/// Vector-based high-performance sprite and character renderer for Dhaba Arcade Tycoon.
class SpriteRenderer {
  /// Draws the player character (Dhaba Manager / Chotu) with walking animation,
  /// apron, cap, and dynamic drop shadow.
  static void drawPlayer(Canvas canvas, PlayerEntity player) {
    canvas.save();
    canvas.translate(player.position.x, player.position.y);

    // 1. Drop shadow (oval beneath feet)
    final shadowScale =
        1.0 + (player.isMoving ? math.sin(player.walkCycle * 2) * 0.08 : 0.0);
    final shadowPaint = Paint()..color = AppTheme.characterShadow;
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(0, 18),
        width: 36 * shadowScale,
        height: 18 * shadowScale,
      ),
      shadowPaint,
    );

    // 2. Walking bob offset (slight vertical bounce)
    final bobOffset = player.isMoving
        ? math.sin(player.walkCycle * 2).abs() * -4.0
        : 0.0;
    canvas.translate(0, bobOffset);

    // 3. Rotate torso/head toward movement heading
    canvas.rotate(player.angle - math.pi / 2);

    // Feet / shoes (animate back and forth when walking)
    final leftFootOffset = player.isMoving
        ? math.sin(player.walkCycle) * 7.0
        : 0.0;
    final rightFootOffset = player.isMoving
        ? -math.sin(player.walkCycle) * 7.0
        : 0.0;

    final shoePaint = Paint()..color = const Color(0xFF333333);
    // Left foot
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(-8, 14 + leftFootOffset),
          width: 8,
          height: 14,
        ),
        const Radius.circular(4),
      ),
      shoePaint,
    );
    // Right foot
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(8, 14 + rightFootOffset),
          width: 8,
          height: 14,
        ),
        const Radius.circular(4),
      ),
      shoePaint,
    );

    // Body / Shirt (White shirt)
    final shirtPaint = Paint()..color = AppTheme.characterShirt;
    canvas.drawCircle(const Offset(0, 2), 16, shirtPaint);

    // Apron (Vibrant red dhaba apron with pocket)
    final apronPaint = Paint()..color = AppTheme.characterApron;
    final apronRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: const Offset(0, 4), width: 22, height: 16),
      const Radius.circular(5),
    );
    canvas.drawRRect(apronRect, apronPaint);

    // Apron pocket
    final pocketPaint = Paint()..color = const Color(0xFFB71C1C);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(0, 7), width: 10, height: 6),
        const Radius.circular(2),
      ),
      pocketPaint,
    );

    // Head (Skin tone)
    final skinPaint = Paint()..color = AppTheme.characterSkin;
    canvas.drawCircle(const Offset(0, -6), 14, skinPaint);

    // Cap / Hat (Red dhaba cap with visor facing forward)
    final capPaint = Paint()..color = AppTheme.characterCap;
    canvas.drawCircle(const Offset(0, -7), 12, capPaint);
    // Visor
    final visorPath = Path()
      ..moveTo(-10, -6)
      ..quadraticBezierTo(0, -16, 10, -6)
      ..close();
    canvas.drawPath(visorPath, capPaint);

    // Hands / Arms
    final handPaint = Paint()..color = AppTheme.characterSkin;
    canvas.drawCircle(const Offset(-14, 2), 5, handPaint);
    canvas.drawCircle(const Offset(14, 2), 5, handPaint);

    canvas.restore();
  }

  /// Draws the dhaba floor grid with checkered warm tiles.
  static void drawFloor(
    Canvas canvas,
    double width,
    double height,
    double wallThickness,
  ) {
    const tileSize = 60.0;
    final paintLight = Paint()..color = AppTheme.floorTileLight;
    final paintDark = Paint()..color = AppTheme.floorTileDark;
    final groutPaint = Paint()
      ..color = const Color(0x1A000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final startX = wallThickness;
    final endX = width - wallThickness;
    final startY = wallThickness;
    final endY = height - wallThickness;

    int row = 0;
    for (double y = startY; y < endY; y += tileSize) {
      int col = 0;
      final h = (y + tileSize > endY) ? (endY - y) : tileSize;
      for (double x = startX; x < endX; x += tileSize) {
        final w = (x + tileSize > endX) ? (endX - x) : tileSize;
        final isEven = (row + col) % 2 == 0;
        final rect = Rect.fromLTWH(x, y, w, h);

        canvas.drawRect(rect, isEven ? paintLight : paintDark);
        canvas.drawRect(rect, groutPaint);
        col++;
      }
      row++;
    }
  }

  /// Draws the 3D-styled boundary walls of the Dhaba with entrance opening at the bottom.
  static void drawWalls(
    Canvas canvas,
    double width,
    double height,
    double wallThickness,
  ) {
    final brickPaint = Paint()..color = AppTheme.wallBrickColor;
    final capPaint = Paint()..color = AppTheme.wallCapColor;
    final shadowPaint = Paint()..color = const Color(0x2E000000);

    // Top Wall
    canvas.drawRect(Rect.fromLTWH(0, 0, width, wallThickness), brickPaint);
    canvas.drawRect(Rect.fromLTWH(0, wallThickness - 6, width, 6), capPaint);
    // Top wall inner shadow
    canvas.drawRect(
      Rect.fromLTWH(wallThickness, wallThickness, width - wallThickness * 2, 8),
      shadowPaint,
    );

    // Left Wall
    canvas.drawRect(Rect.fromLTWH(0, 0, wallThickness, height), brickPaint);
    canvas.drawRect(Rect.fromLTWH(wallThickness - 6, 0, 6, height), capPaint);
    // Left wall inner shadow
    canvas.drawRect(
      Rect.fromLTWH(
        wallThickness,
        wallThickness,
        8,
        height - wallThickness * 2,
      ),
      shadowPaint,
    );

    // Right Wall
    canvas.drawRect(
      Rect.fromLTWH(width - wallThickness, 0, wallThickness, height),
      brickPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(width - wallThickness, 0, 6, height),
      capPaint,
    );

    // Bottom Wall with Entrance opening in middle
    const doorWidth = 180.0;
    final leftBottomWidth = (width - doorWidth) / 2;

    // Left section of bottom wall
    canvas.drawRect(
      Rect.fromLTWH(0, height - wallThickness, leftBottomWidth, wallThickness),
      brickPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, height - wallThickness, leftBottomWidth, 6),
      capPaint,
    );

    // Right section of bottom wall
    final rightBottomStart = leftBottomWidth + doorWidth;
    canvas.drawRect(
      Rect.fromLTWH(
        rightBottomStart,
        height - wallThickness,
        leftBottomWidth,
        wallThickness,
      ),
      brickPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        rightBottomStart,
        height - wallThickness,
        leftBottomWidth,
        6,
      ),
      capPaint,
    );

    // Welcome mat at entrance
    final matPaint = Paint()..color = AppTheme.truckArtGreen;
    final matBorder = Paint()
      ..color = AppTheme.goldYellow
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final matRect = Rect.fromCenter(
      center: Offset(width / 2, height - wallThickness / 2),
      width: doorWidth - 20,
      height: wallThickness + 10,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(matRect, const Radius.circular(6)),
      matPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(matRect, const Radius.circular(6)),
      matBorder,
    );
  }
}
