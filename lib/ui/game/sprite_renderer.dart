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

  static void _drawCarriedStack(Canvas canvas, PlayerEntity player) {
    const baseSpacing = 16.0;
    double currentX = 0.0;
    double currentY = -24.0;

    for (int i = 0; i < player.carriedCount; i++) {
      final sway = player.wobbleAngle * (i + 1) * 8.0;
      currentX += sway;
      currentY -= baseSpacing;

      canvas.save();
      canvas.translate(currentX, currentY);
      canvas.rotate(player.wobbleAngle * (i + 1) * 0.4);

      _drawChaiCup(canvas);

      canvas.restore();
    }

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

  static void _drawChaiCup(Canvas canvas) {
    final shadowPaint = Paint()..color = const Color(0x33000000);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 6), width: 22, height: 8),
      shadowPaint,
    );

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

    final chaiPaint = Paint()..color = const Color(0xFFC07028);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, -6), width: 18, height: 6),
      chaiPaint,
    );

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

  /// Draws the Chai Brewing Kettle station.
  static void drawChaiStation(Canvas canvas, ChaiStation station) {
    final pzCenter = station.pickupZoneCenter;
    final pzRadius = station.pickupZoneRadius;

    final zoneFill = Paint()
      ..color = AppTheme.goldYellow.withValues(alpha: 0.18);
    canvas.drawCircle(Offset(pzCenter.x, pzCenter.y), pzRadius, zoneFill);

    final zoneBorder = Paint()
      ..color = AppTheme.saffronOrange
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

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

    final left = station.position.x - station.width / 2;
    final top = station.position.y - station.height / 2;

    final tableShadow = Paint()..color = const Color(0x33000000);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(left - 4, top + 6, station.width + 8, station.height + 6),
        const Radius.circular(8),
      ),
      tableShadow,
    );

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

    final steelPaint = Paint()..color = const Color(0xFFB0BEC5);
    final steelRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left + 6, top + 6, station.width - 12, station.height - 12),
      const Radius.circular(6),
    );
    canvas.drawRRect(steelRRect, steelPaint);

    final kettleX = left + 36.0;
    final kettleY = top + station.height / 2;

    final kettlePaint = Paint()..color = const Color(0xFFFFA000);
    final kettleBorder = Paint()
      ..color = const Color(0xFFB26A00)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawCircle(Offset(kettleX, kettleY), 18, kettlePaint);
    canvas.drawCircle(Offset(kettleX, kettleY), 18, kettleBorder);

    final lidPaint = Paint()..color = const Color(0xFF795548);
    canvas.drawCircle(Offset(kettleX, kettleY - 3), 6, lidPaint);

    final spoutPaint = Paint()
      ..color = const Color(0xFFB26A00)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;
    canvas.drawLine(
      Offset(kettleX - 12, kettleY - 6),
      Offset(kettleX - 22, kettleY - 14),
      spoutPaint,
    );

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

    final shelfStartX = left + 80.0;
    final shelfY = top + 26.0;

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

    for (int i = 0; i < station.shelfCount; i++) {
      final col = i % 2;
      final row = i ~/ 2;
      final cupPos = Offset(shelfStartX + col * 20.0, shelfY + row * 10.0);

      canvas.save();
      canvas.translate(cupPos.dx, cupPos.dy);
      canvas.scale(0.75, 0.75);
      _drawChaiCup(canvas);
      canvas.restore();
    }

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

  /// Draws the Front Serving Counter with staff delivery zone and cash drop area.
  static void drawServingCounter(Canvas canvas, ServingCounter counter) {
    // 1. Staff Delivery Zone (dashed zone behind counter)
    final dzCenter = counter.staffDropZoneCenter;
    final dzRadius = counter.staffDropZoneRadius;

    final zoneFill = Paint()
      ..color = AppTheme.truckArtGreen.withValues(alpha: 0.15);
    canvas.drawCircle(Offset(dzCenter.x, dzCenter.y), dzRadius, zoneFill);

    final zoneBorder = Paint()
      ..color = AppTheme.truckArtGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    const dashCount = 20;
    for (int i = 0; i < dashCount; i += 2) {
      final startAngle = (i / dashCount) * (math.pi * 2);
      final sweepAngle = (1 / dashCount) * (math.pi * 2);
      canvas.drawArc(
        Rect.fromCircle(
          center: Offset(dzCenter.x, dzCenter.y),
          radius: dzRadius,
        ),
        startAngle,
        sweepAngle,
        false,
        zoneBorder,
      );
    }

    final serveText = TextPainter(
      text: const TextSpan(
        text: 'SERVE',
        style: TextStyle(
          color: AppTheme.truckArtGreen,
          fontWeight: FontWeight.w900,
          fontSize: 10,
          letterSpacing: 0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    serveText.paint(
      canvas,
      Offset(
        dzCenter.x - serveText.width / 2,
        dzCenter.y - serveText.height / 2,
      ),
    );

    // 2. Physical Serving Counter Structure
    final left = counter.position.x - counter.width / 2;
    final top = counter.position.y - counter.height / 2;

    // Counter shadow
    final counterShadow = Paint()..color = const Color(0x33000000);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(left - 4, top + 6, counter.width + 8, counter.height + 6),
        const Radius.circular(10),
      ),
      counterShadow,
    );

    // Counter wood body
    final woodPaint = Paint()..color = const Color(0xFF5D4037);
    final woodBorder = Paint()
      ..color = const Color(0xFF3E2723)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final counterRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, counter.width, counter.height),
      const Radius.circular(8),
    );
    canvas.drawRRect(counterRRect, woodPaint);
    canvas.drawRRect(counterRRect, woodBorder);

    // Counter top polish surface
    final topSurfacePaint = Paint()..color = const Color(0xFF8D6E63);
    final topSurfaceRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left + 6, top + 6, counter.width - 12, counter.height - 12),
      const Radius.circular(6),
    );
    canvas.drawRRect(topSurfaceRRect, topSurfacePaint);

    // Cash register / order machine in middle
    final registerPaint = Paint()..color = const Color(0xFF37474F);
    final regRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(counter.position.x, counter.position.y),
        width: 36,
        height: 26,
      ),
      const Radius.circular(4),
    );
    canvas.drawRRect(regRect, registerPaint);

    // Service Bell (brass bell)
    final bellPaint = Paint()..color = AppTheme.goldYellow;
    canvas.drawCircle(
      Offset(counter.position.x + 36, counter.position.y),
      6,
      bellPaint,
    );

    // Order Counter Banner
    final bannerPainter = TextPainter(
      text: const TextSpan(
        text: 'COUNTER',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 9,
          letterSpacing: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    bannerPainter.paint(
      canvas,
      Offset(
        counter.position.x - bannerPainter.width / 2,
        top + counter.height - 13,
      ),
    );
  }

  /// Draws the Trash Bin.
  static void drawTrashBin(Canvas canvas, TrashBin trashBin) {
    // Floor discard zone
    final zonePaint = Paint()..color = const Color(0x22D32F2F);
    canvas.drawCircle(
      Offset(trashBin.position.x, trashBin.position.y),
      trashBin.zoneRadius,
      zonePaint,
    );

    final zoneBorder = Paint()
      ..color = const Color(0x66D32F2F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(
      Offset(trashBin.position.x, trashBin.position.y),
      trashBin.zoneRadius,
      zoneBorder,
    );

    // Metal Trash Can
    final canShadow = Paint()..color = const Color(0x33000000);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(trashBin.position.x, trashBin.position.y + 12),
        width: 30,
        height: 12,
      ),
      canShadow,
    );

    final canPaint = Paint()..color = const Color(0xFF607D8B);
    final canBorder = Paint()
      ..color = const Color(0xFF37474F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawCircle(
      Offset(trashBin.position.x, trashBin.position.y),
      trashBin.radius,
      canPaint,
    );
    canvas.drawCircle(
      Offset(trashBin.position.x, trashBin.position.y),
      trashBin.radius,
      canBorder,
    );

    // Trash Can Lid
    final lidPaint = Paint()..color = const Color(0xFF455A64);
    canvas.drawCircle(
      Offset(trashBin.position.x, trashBin.position.y),
      trashBin.radius - 6,
      lidPaint,
    );

    // Label
    final trashText = TextPainter(
      text: const TextSpan(
        text: 'TRASH',
        style: TextStyle(
          color: Color(0xFFD32F2F),
          fontWeight: FontWeight.w900,
          fontSize: 8,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    trashText.paint(
      canvas,
      Offset(
        trashBin.position.x - trashText.width / 2,
        trashBin.position.y - trashBin.zoneRadius - 10,
      ),
    );
  }

  /// Draws a 3D isometric green Rupee cash bundle with golden strap.
  static void drawCashBundle(Canvas canvas, CashBundleEntity bundle) {
    canvas.save();
    canvas.translate(bundle.position.x, bundle.position.y);

    // Initial spawn pop bounce
    if (bundle.spawnBounceTimer > 0.0) {
      final s = 1.0 + (bundle.spawnBounceTimer * 0.8);
      canvas.scale(s, s);
    }

    // Shadow
    final shadowPaint = Paint()..color = const Color(0x2E000000);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 8), width: 22, height: 10),
      shadowPaint,
    );

    // Isometric green cash block
    // 1. Dark green base/side
    final sidePaint = Paint()..color = const Color(0xFF2E7D32);
    final sideRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: const Offset(0, 3), width: 20, height: 12),
      const Radius.circular(3),
    );
    canvas.drawRRect(sideRect, sidePaint);

    // 2. Bright green top face
    final topPaint = Paint()..color = const Color(0xFF4CAF50);
    final topRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: const Offset(0, 0), width: 20, height: 10),
      const Radius.circular(3),
    );
    canvas.drawRRect(topRect, topPaint);

    // 3. Golden paper currency band/strap around center
    final bandPaint = Paint()..color = AppTheme.goldYellow;
    canvas.drawRect(Rect.fromLTWH(-3, -5, 6, 10), bandPaint);

    // 4. White currency mark
    final textPainter = TextPainter(
      text: const TextSpan(
        text: '₹',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 8,
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

  /// Draws floating "+Rs X" currency popups fading upward in world space.
  static void drawFloatingTexts(Canvas canvas, List<FloatingTextEntity> texts) {
    for (final ft in texts) {
      final progress = (ft.lifeTime / ft.maxLifeTime).clamp(0.0, 1.0);
      final opacity = progress.clamp(0.0, 1.0);

      canvas.save();
      canvas.translate(ft.position.x, ft.position.y);

      final textPainter = TextPainter(
        text: TextSpan(
          text: ft.text,
          style: TextStyle(
            color: AppTheme.truckArtGreen.withValues(alpha: opacity),
            fontWeight: FontWeight.w900,
            fontSize: 16,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: opacity * 0.6),
                blurRadius: 4,
                offset: const Offset(1, 1),
              ),
            ],
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
    canvas.drawRect(
      Rect.fromLTWH(wallThickness, wallThickness, width - wallThickness * 2, 8),
      shadowPaint,
    );

    // Left Wall
    canvas.drawRect(Rect.fromLTWH(0, 0, wallThickness, height), brickPaint);
    canvas.drawRect(Rect.fromLTWH(wallThickness - 6, 0, 6, height), capPaint);
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

    canvas.drawRect(
      Rect.fromLTWH(0, height - wallThickness, leftBottomWidth, wallThickness),
      brickPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, height - wallThickness, leftBottomWidth, 6),
      capPaint,
    );

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
