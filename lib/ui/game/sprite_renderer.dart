import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';
import '../../engine/entities.dart';
import '../../engine/stations.dart';

/// Vector-based high-performance sprite and character renderer for Dhaba Arcade Tycoon.
class SpriteRenderer {
  /// Draws the player character with walking animation, apron, cap,
  /// dynamic drop shadow, towering head stack with wobble physics, and MAX badge.
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
        width: 38 * shadowScale,
        height: 20 * shadowScale,
      ),
      shadowPaint,
    );

    // 2. Walking bob offset (slight vertical bounce)
    final bobOffset = player.isMoving
        ? math.sin(player.walkCycle * 2).abs() * -4.0
        : 0.0;
    canvas.translate(0, bobOffset);

    // 3. Rotate torso/head toward movement heading
    canvas.save();
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

    canvas.restore(); // Restore body rotation

    // 4. Towering Item Stack above head (with wobble physics!)
    if (player.carriedCount > 0) {
      _drawCarriedStack(canvas, player);
    }

    canvas.restore();
  }

  /// Draws the towering vertical stack of chai cups above the character's head
  /// with dynamic sway and "MAX" badge.
  static void _drawCarriedStack(Canvas canvas, PlayerEntity player) {
    const baseSpacing = 16.0;
    double currentX = 0.0;
    double currentY = -24.0;

    for (int i = 0; i < player.carriedCount; i++) {
      // Dynamic wobble sway increases with height
      final sway = player.wobbleAngle * (i + 1) * 8.0;
      currentX += sway;
      currentY -= baseSpacing;

      canvas.save();
      canvas.translate(currentX, currentY);
      canvas.rotate(player.wobbleAngle * (i + 1) * 0.4);

      // Draw single chai cup in stack
      _drawChaiCup(canvas);

      canvas.restore();
    }

    // "MAX" badge if capacity is reached
    if (player.isFull) {
      final pulse =
          1.0 + math.sin(DateTime.now().millisecondsSinceEpoch * 0.008) * 0.12;
      canvas.save();
      canvas.translate(currentX, currentY - 20);
      canvas.scale(pulse, pulse);

      final badgePaint = Paint()..color = const Color(0xFFD32F2F);
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      final badgeRect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: 44, height: 20),
        const Radius.circular(8),
      );

      canvas.drawRRect(badgeRect, badgePaint);
      canvas.drawRRect(badgeRect, borderPaint);

      // Draw "MAX" text
      final textPainter = TextPainter(
        text: const TextSpan(
          text: 'MAX',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 11,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -textPainter.height / 2),
      );

      canvas.restore();
    }
  }

  /// Draws a single stylized Desi Chai cup.
  static void _drawChaiCup(Canvas canvas) {
    // Cup shadow
    final shadowPaint = Paint()..color = const Color(0x33000000);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 6), width: 22, height: 8),
      shadowPaint,
    );

    // Cup body (Clay/cream terracotta cup)
    final cupPaint = Paint()..color = const Color(0xFFE8D3B9);
    final cupBorder = Paint()
      ..color = const Color(0xFF8B5A2B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final cupPath = Path()
      ..moveTo(-10, -6)
      ..lineTo(-8, 5)
      ..quadraticBezierTo(0, 7, 8, 5)
      ..lineTo(10, -6)
      ..close();

    canvas.drawPath(cupPath, cupPaint);
    canvas.drawPath(cupPath, cupBorder);

    // Warm brown chai inside cup
    final chaiPaint = Paint()..color = const Color(0xFFC07028);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, -6), width: 18, height: 6),
      chaiPaint,
    );

    // Cup handle
    final handlePaint = Paint()
      ..color = const Color(0xFF8B5A2B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawArc(
      Rect.fromCenter(center: const Offset(11, -1), width: 8, height: 8),
      -math.pi / 2,
      math.pi,
      false,
      handlePaint,
    );

    // Subtle steam curls (animated)
    final steamPhase =
        (DateTime.now().millisecondsSinceEpoch * 0.005) % (math.pi * 2);
    final steamPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final steamX = math.sin(steamPhase) * 2.0;
    canvas.drawLine(
      Offset(steamX - 2, -9),
      Offset(steamX - 2, -15),
      steamPaint,
    );
    canvas.drawLine(
      Offset(-steamX + 2, -9),
      Offset(-steamX + 2, -14),
      steamPaint,
    );
  }

  /// Draws the Chai Brewing Kettle station including counter, brass kettle,
  /// steam, output shelf cups, and glowing floor pickup zone.
  static void drawChaiStation(Canvas canvas, ChaiStation station) {
    // 1. Interactive Floor Pickup Zone (Golden dashed circle)
    final pzCenter = station.pickupZoneCenter;
    final pzRadius = station.pickupZoneRadius;

    final zoneFill = Paint()
      ..color = AppTheme.goldYellow.withValues(alpha: 0.18);
    canvas.drawCircle(Offset(pzCenter.x, pzCenter.y), pzRadius, zoneFill);

    final zoneBorder = Paint()
      ..color = AppTheme.saffronOrange
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    // Draw dashed outline
    const dashCount = 20;
    for (int i = 0; i < dashCount; i += 2) {
      final startAngle = (i / dashCount) * (math.pi * 2);
      final sweepAngle = (1 / dashCount) * (math.pi * 2);
      canvas.drawArc(
        Rect.fromCircle(
          center: Offset(pzCenter.x, pzCenter.y),
          radius: pzRadius,
        ),
        startAngle,
        sweepAngle,
        false,
        zoneBorder,
      );
    }

    // Pickup Zone Label / Icon
    final pzText = TextPainter(
      text: const TextSpan(
        text: 'PICKUP',
        style: TextStyle(
          color: AppTheme.chaiDarkBrown,
          fontWeight: FontWeight.w900,
          fontSize: 10,
          letterSpacing: 0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    pzText.paint(
      canvas,
      Offset(pzCenter.x - pzText.width / 2, pzCenter.y - pzText.height / 2),
    );

    // 2. Solid Kitchen Counter Table
    final left = station.position.x - station.width / 2;
    final top = station.position.y - station.height / 2;

    // Table shadow
    final tableShadow = Paint()..color = const Color(0x33000000);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(left - 4, top + 6, station.width + 8, station.height + 6),
        const Radius.circular(8),
      ),
      tableShadow,
    );

    // Table base (Warm rich wood)
    final woodPaint = Paint()..color = const Color(0xFF6D4C41);
    final woodBorder = Paint()
      ..color = const Color(0xFF3E2723)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final tableRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, station.width, station.height),
      const Radius.circular(8),
    );
    canvas.drawRRect(tableRRect, woodPaint);
    canvas.drawRRect(tableRRect, woodBorder);

    // Steel prep counter top
    final steelPaint = Paint()..color = const Color(0xFFB0BEC5);
    final steelRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left + 6, top + 6, station.width - 12, station.height - 12),
      const Radius.circular(6),
    );
    canvas.drawRRect(steelRRect, steelPaint);

    // 3. Brass Chai Kettle on the left side of counter
    final kettleX = left + 36.0;
    final kettleY = top + station.height / 2;

    // Kettle body (Brass/copper gradient)
    final kettlePaint = Paint()..color = const Color(0xFFFFA000);
    final kettleBorder = Paint()
      ..color = const Color(0xFFB26A00)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawCircle(Offset(kettleX, kettleY), 18, kettlePaint);
    canvas.drawCircle(Offset(kettleX, kettleY), 18, kettleBorder);

    // Kettle Lid handle
    final lidPaint = Paint()..color = const Color(0xFF795548);
    canvas.drawCircle(Offset(kettleX, kettleY - 3), 6, lidPaint);

    // Kettle Spout
    final spoutPaint = Paint()
      ..color = const Color(0xFFB26A00)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;
    canvas.drawLine(
      Offset(kettleX - 12, kettleY - 6),
      Offset(kettleX - 22, kettleY - 14),
      spoutPaint,
    );

    // Brewing circular progress around kettle
    final progressPaint = Paint()
      ..color = AppTheme.truckArtGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: Offset(kettleX, kettleY), radius: 23),
      -math.pi / 2,
      station.brewProgress * (math.pi * 2),
      false,
      progressPaint,
    );

    // 4. Output Shelf with brewed cups (right side of counter)
    final shelfStartX = left + 80.0;
    final shelfY = top + 26.0;

    // Shelf Tray
    final trayPaint = Paint()..color = const Color(0xFF78909C);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(shelfStartX + 12, shelfY + 12),
          width: 44,
          height: 32,
        ),
        const Radius.circular(4),
      ),
      trayPaint,
    );

    // Render brewed cups in shelf tray
    for (int i = 0; i < station.shelfCount; i++) {
      final col = i % 2;
      final row = i ~/ 2;
      final cupPos = Offset(shelfStartX + col * 20.0, shelfY + row * 10.0);

      canvas.save();
      canvas.translate(cupPos.dx, cupPos.dy);
      canvas.scale(0.75, 0.75); // slightly smaller in shelf
      _drawChaiCup(canvas);
      canvas.restore();
    }

    // Shelf Capacity Count Tag (e.g. "3 / 8")
    final countPainter = TextPainter(
      text: TextSpan(
        text: '☕ ${station.shelfCount}/${station.shelfCapacity}',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final tagBg = Paint()..color = AppTheme.chaiDarkBrown;
    final tagRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(station.position.x, top - 8),
        width: countPainter.width + 12,
        height: countPainter.height + 6,
      ),
      const Radius.circular(6),
    );
    canvas.drawRRect(tagRect, tagBg);
    countPainter.paint(
      canvas,
      Offset(
        station.position.x - countPainter.width / 2,
        top - 8 - countPainter.height / 2,
      ),
    );
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
