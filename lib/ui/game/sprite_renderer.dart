import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';
import '../../engine/customer_ai.dart';
import '../../engine/entities.dart';
import '../../engine/ground_pad.dart';
import '../../engine/staff_ai.dart';
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

      final item = player.carriedItems[i];
      if (item == ItemType.dirtyTray) {
        _drawCarriedDirtyTray(canvas);
      } else {
        _drawChaiCup(canvas);
      }

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

  /// Draws a stylized restaurant serving tray with empty glass and crumpled napkin.
  static void _drawCarriedDirtyTray(Canvas canvas, [double scale = 1.0]) {
    canvas.save();
    canvas.scale(scale, scale);

    // Tray base (Dark Slate Gray with rounded rim)
    final trayPaint = Paint()..color = const Color(0xFF455A64);
    final trayRRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: const Offset(0, 0), width: 34, height: 14),
      const Radius.circular(3),
    );
    canvas.drawRRect(trayRRect, trayPaint);

    final rimPaint = Paint()
      ..color = const Color(0xFF263238)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(trayRRect, rimPaint);

    // Empty cup with tea residue ring
    final cupPaint = Paint()..color = const Color(0x99ECEFF1);
    final cupRRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: const Offset(-6, -4), width: 10, height: 10),
      const Radius.circular(2),
    );
    canvas.drawRRect(cupRRect, cupPaint);

    final residuePaint = Paint()..color = AppTheme.chaiDarkBrown;
    canvas.drawCircle(const Offset(-6, -2), 3, residuePaint);

    // Crumpled napkin
    final napkinPaint = Paint()..color = Colors.white70;
    canvas.drawCircle(const Offset(6, -3), 4, napkinPaint);

    canvas.restore();
  }

  /// Draws an animated cartoon customer with clothing variant, hair/cap,
  /// walking animation, drop shadow, and floating order speech bubble.
  static void drawCustomer(Canvas canvas, CustomerEntity customer) {
    if (customer.state == CustomerState.despawned) return;

    canvas.save();
    canvas.translate(customer.position.x, customer.position.y);

    // 1. Drop shadow beneath feet
    final shadowScale =
        1.0 +
        (customer.isMoving ? math.sin(customer.walkCycle * 2) * 0.08 : 0.0);
    final shadowPaint = Paint()..color = AppTheme.characterShadow;
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(0, 16),
        width: 32 * shadowScale,
        height: 16 * shadowScale,
      ),
      shadowPaint,
    );

    // 2. Walking bob
    final bobOffset = customer.isMoving
        ? math.sin(customer.walkCycle * 2).abs() * -3.5
        : 0.0;
    canvas.translate(0, bobOffset);

    // 3. Body rotation towards facing angle
    canvas.save();
    canvas.rotate(customer.angle - math.pi / 2);

    // Feet / Shoes
    final leftFoot = customer.isMoving
        ? math.sin(customer.walkCycle) * 6.0
        : 0.0;
    final rightFoot = customer.isMoving
        ? -math.sin(customer.walkCycle) * 6.0
        : 0.0;
    final shoePaint = Paint()..color = const Color(0xFF263238);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(-7, 12 + leftFoot),
          width: 7,
          height: 12,
        ),
        const Radius.circular(3),
      ),
      shoePaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(7, 12 + rightFoot),
          width: 7,
          height: 12,
        ),
        const Radius.circular(3),
      ),
      shoePaint,
    );

    // Torso / Clothing (Variant Shalwar Kameez Colors)
    Color shirtColor;
    switch (customer.variant % 4) {
      case 0:
        shirtColor = const Color(0xFF1976D2); // Royal Blue
        break;
      case 1:
        shirtColor = const Color(0xFF2E7D32); // Emerald Green
        break;
      case 2:
        shirtColor = const Color(0xFFC2185B); // Maroon / Rose
        break;
      default:
        shirtColor = const Color(0xFFE65100); // Warm Saffron
        break;
    }

    final torsoPaint = Paint()..color = shirtColor;
    final torsoRRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: const Offset(0, 2), width: 26, height: 18),
      const Radius.circular(6),
    );
    canvas.drawRRect(torsoRRect, torsoPaint);

    // Head
    final headPaint = Paint()..color = AppTheme.characterSkin;
    canvas.drawCircle(const Offset(0, -6), 11, headPaint);

    // Hair / Cap / Turban based on variant
    if (customer.variant % 2 == 0) {
      // Peshawari / Kufi Cap
      final capPaint = Paint()..color = const Color(0xFFECEFF1);
      canvas.drawArc(
        Rect.fromCircle(center: const Offset(0, -9), radius: 10),
        math.pi,
        math.pi,
        true,
        capPaint,
      );
    } else {
      // Dark Hair
      final hairPaint = Paint()..color = const Color(0xFF212121);
      canvas.drawArc(
        Rect.fromCircle(center: const Offset(0, -9), radius: 10),
        math.pi,
        math.pi,
        true,
        hairPaint,
      );
    }

    // Hands
    final handPaint = Paint()..color = AppTheme.characterSkin;
    canvas.drawCircle(const Offset(-13, 2), 4.5, handPaint);
    canvas.drawCircle(const Offset(13, 2), 4.5, handPaint);

    // If walking to table, waiting for table, or leaving happy from takeaway (not after dine-in meal), carry a cup of chai in hand!
    if (customer.state == CustomerState.walkingToTable ||
        customer.state == CustomerState.waitingForTable ||
        (customer.state == CustomerState.leavingHappy && !customer.hasDinedIn)) {
      canvas.save();
      canvas.translate(0, 12);
      _drawChaiCup(canvas, 0.65);
      canvas.restore();
    }

    canvas.restore(); // Restore rotation

    // 4. Floating Speech Bubble (Order Bubble when in queue, or reaction when leaving / eating)
    if (customer.state == CustomerState.waitingInQueue ||
        customer.state == CustomerState.beingServed ||
        customer.state == CustomerState.spawning) {
      _drawOrderSpeechBubble(canvas, customer);
    } else if (customer.state == CustomerState.waitingForTable) {
      _drawWaitingForTableReaction(canvas, customer);
    } else if (customer.state == CustomerState.leavingUnhappy) {
      _drawUnhappyReaction(canvas);
    } else if (customer.state == CustomerState.leavingHappy) {
      _drawHappyReaction(canvas);
    } else if (customer.state == CustomerState.eating) {
      _drawEatingReaction(canvas, customer);
    }

    canvas.restore();
  }

  static void _drawEatingReaction(Canvas canvas, CustomerEntity customer) {
    const bubbleWidth = 38.0;
    const bubbleHeight = 22.0;
    const bubbleY = -34.0;

    final bubblePath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: const Offset(0, bubbleY),
            width: bubbleWidth,
            height: bubbleHeight,
          ),
          const Radius.circular(8),
        ),
      );

    canvas.drawShadow(bubblePath, Colors.black38, 3.0, false);
    canvas.drawPath(bubblePath, Paint()..color = Colors.white);

    // Speech bubble tail pointing towards customer
    final tail = Path()
      ..moveTo(-4, bubbleY + bubbleHeight / 2)
      ..lineTo(0, bubbleY + bubbleHeight / 2 + 5)
      ..lineTo(4, bubbleY + bubbleHeight / 2)
      ..close();
    canvas.drawPath(tail, Paint()..color = Colors.white);

    final textPainter = TextPainter(
      text: const TextSpan(
        text: '☕😋',
        style: TextStyle(fontSize: 10),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(-textPainter.width / 2, bubbleY - textPainter.height / 2),
    );
  }

  static void _drawWaitingForTableReaction(
    Canvas canvas,
    CustomerEntity customer,
  ) {
    const bubbleWidth = 42.0;
    const bubbleHeight = 22.0;
    const bubbleY = -34.0;

    final bubblePath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: const Offset(0, bubbleY),
            width: bubbleWidth,
            height: bubbleHeight,
          ),
          const Radius.circular(8),
        ),
      );

    canvas.drawShadow(bubblePath, Colors.black38, 3.0, false);
    canvas.drawPath(bubblePath, Paint()..color = Colors.white);

    // Border
    canvas.drawPath(
      bubblePath,
      Paint()
        ..color = const Color(0xFFCFD8DC)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Tail
    final tail = Path()
      ..moveTo(-4, bubbleY + bubbleHeight / 2)
      ..lineTo(0, bubbleY + bubbleHeight / 2 + 5)
      ..lineTo(4, bubbleY + bubbleHeight / 2)
      ..close();
    canvas.drawPath(tail, Paint()..color = Colors.white);

    final textPainter = TextPainter(
      text: const TextSpan(
        text: '🪑⏳',
        style: TextStyle(fontSize: 10),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(-textPainter.width / 2, bubbleY - textPainter.height / 2),
    );
  }

  static void _drawOrderSpeechBubble(Canvas canvas, CustomerEntity customer) {
    final remaining = customer.desiredCount - customer.receivedCount;
    final bubbleWidth = remaining >= 10 ? 50.0 : 44.0;
    const bubbleHeight = 24.0;
    const bubbleY = -34.0;

    final bubblePath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: const Offset(0, bubbleY),
            width: bubbleWidth,
            height: bubbleHeight,
          ),
          const Radius.circular(8),
        ),
      )
      ..moveTo(-4, bubbleY + bubbleHeight / 2)
      ..lineTo(0, bubbleY + bubbleHeight / 2 + 5)
      ..lineTo(4, bubbleY + bubbleHeight / 2)
      ..close();

    // Drop shadow
    canvas.drawPath(
      bubblePath,
      Paint()
        ..color = const Color(0x2A000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );

    // Bubble white body
    canvas.drawPath(bubblePath, Paint()..color = Colors.white);
    canvas.drawPath(
      bubblePath,
      Paint()
        ..color = const Color(0xFFCFD8DC)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Miniature Cup icon
    canvas.save();
    canvas.translate(-10, bubbleY - 2);
    _drawChaiCup(canvas, 0.55);
    canvas.restore();

    // Order count text
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'x$remaining',
        style: const TextStyle(
          color: Color(0xFF263238),
          fontWeight: FontWeight.w900,
          fontSize: 10,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(4, bubbleY - textPainter.height / 2));
  }

  static void _drawUnhappyReaction(Canvas canvas) {
    final badgePaint = Paint()..color = const Color(0xFFD32F2F);
    canvas.drawCircle(const Offset(0, -32), 10, badgePaint);
    final textPainter = TextPainter(
      text: const TextSpan(text: '😤', style: TextStyle(fontSize: 12)),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(-textPainter.width / 2, -32 - textPainter.height / 2),
    );
  }

  static void _drawHappyReaction(Canvas canvas) {
    final badgePaint = Paint()..color = const Color(0xFF388E3C);
    canvas.drawCircle(const Offset(0, -32), 10, badgePaint);
    final textPainter = TextPainter(
      text: const TextSpan(text: '😊', style: TextStyle(fontSize: 12)),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(-textPainter.width / 2, -32 - textPainter.height / 2),
    );
  }

  static void _drawChaiCup(Canvas canvas, [double scale = 1.0]) {
    canvas.save();
    if (scale != 1.0) canvas.scale(scale, scale);

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

    canvas.restore();
  }

  /// Draws the Chai Brewing Kettle station.
  static void drawChaiStation(Canvas canvas, ChaiStation station) {
    // 1. All-Around Interactive Floor Pickup Pad (accessible from front, behind, left, right)
    final padRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(station.position.x, station.position.y),
        width: station.width + 60.0,
        height: station.height + 60.0,
      ),
      const Radius.circular(20.0),
    );

    final padFill = Paint()
      ..color = AppTheme.goldYellow.withValues(alpha: 0.16);
    canvas.drawRRect(padRect, padFill);

    final padBorder = Paint()
      ..color = AppTheme.saffronOrange
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRRect(padRect, padBorder);

    // Front pickup label
    final pzCenter = station.pickupZoneCenter;
    final pzText = TextPainter(
      text: const TextSpan(
        text: '☕ PICKUP CHAI',
        style: TextStyle(
          color: AppTheme.chaiDarkBrown,
          fontWeight: FontWeight.w900,
          fontSize: 9,
          letterSpacing: 0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    pzText.paint(
      canvas,
      Offset(
        pzCenter.x - pzText.width / 2,
        pzCenter.y + 14 - pzText.height / 2,
      ),
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

    final shelfStartX = left + 78.0;
    final shelfBaseY = top + station.height - 20.0;

    final trayPaint = Paint()..color = const Color(0xFF78909C);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(shelfStartX + 10, top + station.height / 2),
          width: 48,
          height: station.height - 16,
        ),
        const Radius.circular(4),
      ),
      trayPaint,
    );

    // 2 columns side-by-side, cups stack UPWARDS (new items land on top!)
    for (int i = 0; i < station.shelfCount; i++) {
      final col = i % 2;
      final layer = i ~/ 2;
      final cupX = shelfStartX + (col * 20.0);
      final cupY = shelfBaseY - (layer * 5.5); // Stacks UPWARDS

      canvas.save();
      canvas.translate(cupX, cupY);
      _drawChaiCup(canvas, 0.68);
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

  /// Draws the Three-Part Front Serving Counter with Left Food Towers, Center Cashier,
  /// and Right 3D Money Towers.
  static void drawServingCounter(Canvas canvas, ServingCounter counter) {
    // -------------------------------------------------------------
    // 1. Floor Interactive Zones Around Counter
    // -------------------------------------------------------------

    // Left: Food Deposit Zone Pad (compact wrap top/behind, left flank, and bottom/front)
    final leftPadRect = RRect.fromRectAndCorners(
      const Rect.fromLTRB(265.0, 660.0, 396.0, 780.0),
      topLeft: const Radius.circular(14),
      bottomLeft: const Radius.circular(14),
      topRight: const Radius.circular(6),
      bottomRight: const Radius.circular(6),
    );
    final leftPadFill = Paint()
      ..color = AppTheme.saffronOrange.withValues(alpha: 0.14);
    canvas.drawRRect(leftPadRect, leftPadFill);
    final leftPadBorder = Paint()
      ..color = AppTheme.saffronOrange
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRRect(leftPadRect, leftPadBorder);

    // Single clean label for left food zone
    _drawZoneText(
      canvas,
      const Offset(330.0, 646.0),
      'DEPOSIT',
      AppTheme.saffronOrange,
    );

    // Center: Cashier Standing Station (Comfortable Green Center Circle)
    final cz = counter.cashierZoneCenter;
    final czRadius = counter.cashierZoneRadius;
    final isPresent = counter.isCashierPresent;
    final czFill = Paint()
      ..color = (isPresent
          ? AppTheme.truckArtGreen.withValues(alpha: 0.45)
          : AppTheme.truckArtGreen.withValues(alpha: 0.18));
    canvas.drawCircle(Offset(cz.x, cz.y), czRadius, czFill);
    _drawDashedCircle(
      canvas,
      Offset(cz.x, cz.y),
      czRadius,
      isPresent
          ? AppTheme.truckArtGreen
          : AppTheme.truckArtGreen.withValues(alpha: 0.8),
    );
    _drawZoneText(
      canvas,
      Offset(cz.x, cz.y),
      'CASHIER',
      isPresent ? Colors.white : AppTheme.truckArtGreen,
    );

    // Right: Cash Collection Zone Pad (compact wrap top/behind, right flank, and bottom/front)
    final rightPadRect = RRect.fromRectAndCorners(
      const Rect.fromLTRB(504.0, 660.0, 635.0, 780.0),
      topRight: const Radius.circular(14),
      bottomRight: const Radius.circular(14),
      topLeft: const Radius.circular(6),
      bottomLeft: const Radius.circular(6),
    );
    final rightPadFill = Paint()
      ..color = AppTheme.goldYellow.withValues(alpha: 0.14);
    canvas.drawRRect(rightPadRect, rightPadFill);
    final rightPadBorder = Paint()
      ..color = AppTheme.goldYellow
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRRect(rightPadRect, rightPadBorder);

    // Single clean label for right cash zone
    _drawZoneText(
      canvas,
      const Offset(570.0, 646.0),
      'COLLECT',
      AppTheme.chaiDarkBrown,
    );

    // -------------------------------------------------------------
    // 2. Physical Three-Part Counter Structure
    // -------------------------------------------------------------
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

    // Counter mahogany base
    final woodPaint = Paint()..color = const Color(0xFF4E342E);
    final woodBorder = Paint()
      ..color = const Color(0xFF271510)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final counterRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, counter.width, counter.height),
      const Radius.circular(8),
    );
    canvas.drawRRect(counterRRect, woodPaint);
    canvas.drawRRect(counterRRect, woodBorder);

    // -------------------------------------------------------------
    // 3. Counter Surfaces (Left: Food, Center: Register, Right: Money)
    // -------------------------------------------------------------

    // Left Surface: Food Storage Tray
    final foodTrayRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left + 8, top + 6, 90, counter.height - 12),
      const Radius.circular(6),
    );
    canvas.drawRRect(foodTrayRect, Paint()..color = const Color(0xFF795548));

    // Center Surface: Cashier Till & Bell
    final centerTrayRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(counter.position.x, counter.position.y),
        width: 80,
        height: counter.height - 12,
      ),
      const Radius.circular(6),
    );
    canvas.drawRRect(centerTrayRect, Paint()..color = const Color(0xFF3E2723));

    // Cash Register
    final registerPaint = Paint()..color = const Color(0xFF263238);
    final regRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(counter.position.x - 8, counter.position.y),
        width: 32,
        height: 24,
      ),
      const Radius.circular(4),
    );
    canvas.drawRRect(regRect, registerPaint);

    // Service Bell
    final bellPaint = Paint()..color = AppTheme.goldYellow;
    canvas.drawCircle(
      Offset(counter.position.x + 22, counter.position.y),
      6,
      bellPaint,
    );

    // Right Surface: Cash Tray
    final cashTrayRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        left + counter.width - 98,
        top + 6,
        90,
        counter.height - 12,
      ),
      const Radius.circular(6),
    );
    canvas.drawRRect(
      cashTrayRect,
      Paint()..color = const Color(0xFF1B5E20).withValues(alpha: 0.6),
    );

    // -------------------------------------------------------------
    // 4. Render Left Counter Food Towers (Single-Item Towers!)
    // -------------------------------------------------------------
    for (int tIdx = 0; tIdx < counter.foodTowers.length; tIdx++) {
      final tower = counter.foodTowers[tIdx];
      if (tower.count > 0) {
        final towerBaseX = left + 28.0 + (tIdx * 24.0);
        final towerBaseY = top + counter.height / 2 + 6.0;

        // Draw items in vertical stack
        for (int i = 0; i < tower.count; i++) {
          final itemY = towerBaseY - (i * 6.5);
          canvas.save();
          canvas.translate(towerBaseX, itemY);
          _drawChaiCup(canvas, 0.65);
          canvas.restore();
        }

        // Tower Count Badge above the stack
        final topY = towerBaseY - (tower.count * 6.5) - 14.0;
        _drawMiniCountBadge(
          canvas,
          Offset(towerBaseX, topY),
          '☕ ${tower.count}',
        );
      }
    }

    // -------------------------------------------------------------
    // 5. Render Right Counter 3D Cash Towers (Grid of Cash Stacks!)
    // -------------------------------------------------------------
    if (counter.cashBundleCount > 0) {
      final totalBundles = counter.cashBundleCount;
      final cashBaseX = left + counter.width - 70.0;
      final cashBaseY = top + counter.height / 2 + 4.0;

      // Draw up to 4 towers in a 2x2 grid
      const maxPerStack = 6;
      for (int i = 0; i < totalBundles; i++) {
        final stackIdx = (i ~/ maxPerStack) % 4;
        final heightIdx = i % maxPerStack;

        final col = stackIdx % 2;
        final row = stackIdx ~/ 2;

        final bundleX = cashBaseX + (col * 24.0) - 12.0;
        final bundleY = cashBaseY + (row * 6.0) - (heightIdx * 5.0);

        _drawStaticCashBundle(canvas, Offset(bundleX, bundleY));
      }

      // Cash Total Badge above towers
      final totalCash = totalBundles * 10;
      _drawMiniCountBadge(
        canvas,
        Offset(cashBaseX, top - 8),
        'Rs $totalCash',
        AppTheme.truckArtGreen,
      );
    }
  }

  static void _drawDashedCircle(
    Canvas canvas,
    Offset center,
    double radius,
    Color color,
  ) {
    final border = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    const dashCount = 20;
    for (int i = 0; i < dashCount; i += 2) {
      final startAngle = (i / dashCount) * (math.pi * 2);
      final sweepAngle = (1 / dashCount) * (math.pi * 2);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        border,
      );
    }
  }

  static void _drawZoneText(
    Canvas canvas,
    Offset center,
    String text,
    Color color,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 9,
          letterSpacing: 0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    painter.paint(
      canvas,
      Offset(center.dx - painter.width / 2, center.dy - painter.height / 2),
    );
  }

  static void _drawMiniCountBadge(
    Canvas canvas,
    Offset center,
    String text, [
    Color bgColor = AppTheme.chaiDarkBrown,
  ]) {
    final countPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 9,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final tagBg = Paint()..color = bgColor;
    final tagRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: center,
        width: countPainter.width + 10,
        height: countPainter.height + 4,
      ),
      const Radius.circular(5),
    );
    canvas.drawRRect(tagRect, tagBg);
    countPainter.paint(
      canvas,
      Offset(
        center.dx - countPainter.width / 2,
        center.dy - countPainter.height / 2,
      ),
    );
  }

  /// Draws a single static 3D isometric cash bundle in a counter tower.
  static void _drawStaticCashBundle(Canvas canvas, Offset pos) {
    canvas.save();
    canvas.translate(pos.dx, pos.dy);

    // Shadow
    final shadowPaint = Paint()..color = const Color(0x2A000000);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 5), width: 18, height: 8),
      shadowPaint,
    );

    // Isometric green cash block
    final sidePaint = Paint()..color = const Color(0xFF2E7D32);
    final sideRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: const Offset(0, 2), width: 18, height: 10),
      const Radius.circular(2),
    );
    canvas.drawRRect(sideRect, sidePaint);

    final topPaint = Paint()..color = const Color(0xFF4CAF50);
    final topRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: const Offset(0, 0), width: 18, height: 8),
      const Radius.circular(2),
    );
    canvas.drawRRect(topRect, topPaint);

    // Golden strap
    final bandPaint = Paint()..color = AppTheme.goldYellow;
    canvas.drawRect(Rect.fromLTWH(-2.5, -4, 5, 8), bandPaint);

    canvas.restore();
  }

  /// Draws the Trash Bin.
  static void drawTrashBin(Canvas canvas, TrashBin trashBin) {
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

    final lidPaint = Paint()..color = const Color(0xFF455A64);
    canvas.drawCircle(
      Offset(trashBin.position.x, trashBin.position.y),
      trashBin.radius - 6,
      lidPaint,
    );

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

  /// Draws a flying 3D isometric green Rupee cash bundle.
  static void drawCashBundle(Canvas canvas, CashBundleEntity bundle) {
    canvas.save();
    canvas.translate(bundle.position.x, bundle.position.y);

    if (bundle.spawnBounceTimer > 0.0) {
      final s = 1.0 + (bundle.spawnBounceTimer * 0.8);
      canvas.scale(s, s);
    }

    final shadowPaint = Paint()..color = const Color(0x2E000000);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 8), width: 22, height: 10),
      shadowPaint,
    );

    final sidePaint = Paint()..color = const Color(0xFF2E7D32);
    final sideRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: const Offset(0, 3), width: 20, height: 12),
      const Radius.circular(3),
    );
    canvas.drawRRect(sideRect, sidePaint);

    final topPaint = Paint()..color = const Color(0xFF4CAF50);
    final topRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: const Offset(0, 0), width: 20, height: 10),
      const Radius.circular(3),
    );
    canvas.drawRRect(topRect, topPaint);

    final bandPaint = Paint()..color = AppTheme.goldYellow;
    canvas.drawRect(Rect.fromLTWH(-3, -5, 6, 10), bandPaint);

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

    // Welcome mat at inside entrance threshold
    final matPaint = Paint()..color = AppTheme.truckArtGreen;
    final matBorder = Paint()
      ..color = AppTheme.goldYellow
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    final matRect = Rect.fromCenter(
      center: Offset(width / 2, height - wallThickness - 14.0),
      width: doorWidth - 24.0,
      height: 24.0,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(matRect, const Radius.circular(5)),
      matPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(matRect, const Radius.circular(5)),
      matBorder,
    );

    // Subtle decorative geometric line on mat
    final goldLinePaint = Paint()
      ..color = AppTheme.goldYellow.withValues(alpha: 0.6)
      ..strokeWidth = 1.5;
    canvas.drawLine(
      Offset(width / 2 - 45, height - wallThickness - 14.0),
      Offset(width / 2 + 45, height - wallThickness - 14.0),
      goldLinePaint,
    );
  }

  /// Draws the modern double sliding glass automatic doors with overhead motion sensor,
  /// frosted safety bands, chrome tubular handles, and aluminum framing.
  static void drawAutomaticDoors(
    Canvas canvas,
    double width,
    double height,
    double wallThickness,
    double doorOpenFactor,
  ) {
    const doorWidth = 180.0;
    final doorLeft = (width - doorWidth) / 2; // 360.0
    final doorRight = doorLeft + doorWidth; // 540.0
    final doorCenter = width / 2; // 450.0
    final doorY = height - wallThickness; // 1168.0

    // 1. Stainless Steel Floor Guide Track / Threshold Plate
    final trackPaint = Paint()..color = const Color(0xFF546E7A);
    final trackShine = Paint()
      ..color = const Color(0xFFCFD8DC)
      ..strokeWidth = 1.5;
    canvas.drawRect(
      Rect.fromLTWH(
        doorLeft - 6.0,
        doorY + wallThickness - 8.0,
        doorWidth + 12.0,
        7.0,
      ),
      trackPaint,
    );
    canvas.drawLine(
      Offset(doorLeft - 4.0, doorY + wallThickness - 5.0),
      Offset(doorRight + 4.0, doorY + wallThickness - 5.0),
      trackShine,
    );

    // 2. Sliding Double Glass Panels
    final slideDist = doorOpenFactor * 78.0;
    const panelWidth = 88.0;
    const panelHeight = 22.0;
    final panelTop = doorY + 5.0;

    // Paints for Glass Panels
    final glassShadow = Paint()..color = const Color(0x33000000);
    final glassFill = Paint()..color = const Color(0x9980DEEA);
    final glassFrame = Paint()
      ..color = const Color(0xFFECEFF1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    final safetyStripe = Paint()
      ..color = const Color(0x88FFFFFF)
      ..strokeWidth = 1.5;
    final reflectionGleam = Paint()
      ..color = const Color(0x44FFFFFF)
      ..strokeWidth = 1.8;
    final handlePaint = Paint()
      ..color = const Color(0xFFCFD8DC)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    final handleHighlight = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    void renderDoorLeaf({required double left, required bool isLeftLeaf}) {
      final leafRect = Rect.fromLTWH(left, panelTop, panelWidth, panelHeight);
      final leafRRect = RRect.fromRectAndRadius(
        leafRect,
        const Radius.circular(3),
      );

      // Panel drop shadow
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          leafRect.translate(0, 2),
          const Radius.circular(3),
        ),
        glassShadow,
      );

      // Glass fill
      canvas.drawRRect(leafRRect, glassFill);

      // Diagonal specular reflection streak
      canvas.drawLine(
        Offset(left + 15, panelTop + 3),
        Offset(left + 45, panelTop + panelHeight - 3),
        reflectionGleam,
      );

      // Frosted safety stripes
      canvas.drawLine(
        Offset(left + 6, panelTop + panelHeight / 2 - 2),
        Offset(left + panelWidth - 6, panelTop + panelHeight / 2 - 2),
        safetyStripe,
      );
      canvas.drawLine(
        Offset(left + 6, panelTop + panelHeight / 2 + 3),
        Offset(left + panelWidth - 6, panelTop + panelHeight / 2 + 3),
        safetyStripe,
      );

      // Aluminum border frame
      canvas.drawRRect(leafRRect, glassFrame);

      // Vertical tubular handle bar
      final handleX = isLeftLeaf ? (left + panelWidth - 9.0) : (left + 9.0);
      canvas.drawLine(
        Offset(handleX, panelTop + 3.0),
        Offset(handleX, panelTop + panelHeight - 3.0),
        handlePaint,
      );
      canvas.drawLine(
        Offset(handleX - 0.5, panelTop + 4.0),
        Offset(handleX - 0.5, panelTop + panelHeight - 4.0),
        handleHighlight,
      );
    }

    // Draw Left and Right Panels
    renderDoorLeaf(
      left: (doorCenter - panelWidth) - slideDist,
      isLeftLeaf: true,
    );
    renderDoorLeaf(left: doorCenter + slideDist, isLeftLeaf: false);

    // 3. Vertical Aluminum Door Jambs
    final jambPaint = Paint()..color = const Color(0xFF37474F);
    final jambBevel = Paint()
      ..color = const Color(0xFF78909C)
      ..strokeWidth = 1.0;

    // Left Jamb
    final leftJambRect = Rect.fromLTWH(
      doorLeft - 4.0,
      doorY,
      7.0,
      wallThickness,
    );
    canvas.drawRect(leftJambRect, jambPaint);
    canvas.drawLine(
      Offset(doorLeft + 3.0, doorY),
      Offset(doorLeft + 3.0, doorY + wallThickness),
      jambBevel,
    );

    // Right Jamb
    final rightJambRect = Rect.fromLTWH(
      doorRight - 3.0,
      doorY,
      7.0,
      wallThickness,
    );
    canvas.drawRect(rightJambRect, jambPaint);
    canvas.drawLine(
      Offset(doorRight - 3.0, doorY),
      Offset(doorRight - 3.0, doorY + wallThickness),
      jambBevel,
    );

    // 4. Overhead Header Beam & Automatic Motion Sensor Box
    final headerPaint = Paint()..color = const Color(0xFF263238);
    final headerBevel = Paint()
      ..color = const Color(0xFF90A4AE)
      ..strokeWidth = 1.2;
    final headerRect = Rect.fromLTWH(
      doorLeft - 8.0,
      doorY - 3.0,
      doorWidth + 16.0,
      7.0,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(headerRect, const Radius.circular(2)),
      headerPaint,
    );
    canvas.drawLine(
      Offset(doorLeft - 6.0, doorY - 2.0),
      Offset(doorRight + 6.0, doorY - 2.0),
      headerBevel,
    );

    // Motion Sensor Pod in center of header
    final sensorBodyPaint = Paint()..color = const Color(0xFF102027);
    final sensorRRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(doorCenter, doorY),
        width: 36.0,
        height: 7.0,
      ),
      const Radius.circular(3),
    );
    canvas.drawRRect(sensorRRect, sensorBodyPaint);

    // Motion sensor indicator LED
    final isSensorActive = doorOpenFactor > 0.05;
    final ledPaint = Paint()
      ..color = isSensorActive
          ? const Color(0xFF00E676)
          : const Color(0xFFFF5252);
    canvas.drawCircle(Offset(doorCenter, doorY), 2.0, ledPaint);

    if (isSensorActive) {
      final glowPaint = Paint()..color = const Color(0x5500E676);
      canvas.drawCircle(Offset(doorCenter, doorY), 5.5, glowPaint);
    }

    // 5. Flanking Porch Terracotta Planter Pots
    void renderPlanterPot(double cx, double cy) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, cy + 12), width: 28, height: 14),
        glassShadow,
      );
      final potPaint = Paint()..color = const Color(0xFFD84315);
      final potRim = Paint()..color = const Color(0xFFBF360C);
      final potPath = Path()
        ..moveTo(cx - 10, cy)
        ..lineTo(cx + 10, cy)
        ..lineTo(cx + 7, cy + 12)
        ..lineTo(cx - 7, cy + 12)
        ..close();
      canvas.drawPath(potPath, potPaint);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx, cy), width: 22, height: 5),
          const Radius.circular(2),
        ),
        potRim,
      );

      final foliageBase = Paint()..color = const Color(0xFF1B5E20);
      final foliageMid = Paint()..color = const Color(0xFF2E7D32);
      final foliageLight = Paint()..color = const Color(0xFF4CAF50);

      canvas.drawCircle(Offset(cx, cy - 6), 11.0, foliageBase);
      canvas.drawCircle(Offset(cx - 3, cy - 8), 9.0, foliageMid);
      canvas.drawCircle(Offset(cx + 4, cy - 7), 8.0, foliageLight);

      final flowerPaint = Paint()..color = const Color(0xFFFFC107);
      canvas.drawCircle(Offset(cx - 2, cy - 9), 2.0, flowerPaint);
      canvas.drawCircle(Offset(cx + 3, cy - 5), 1.8, flowerPaint);
    }

    renderPlanterPot(doorLeft - 35.0, doorY + wallThickness + 14.0);
    renderPlanterPot(doorRight + 35.0, doorY + wallThickness + 14.0);
  }

  /// Draws the complete Grand Trunk Highway exterior environment:
  /// - Paved sidewalk with interlocking patio pavers
  /// - Pakistani Yellow & Black striped road curb with wheelchair/pedestrian ramp
  /// - Multi-lane dark asphalt highway with shoulder solid lines and yellow dashed center line
  /// - Pedestrian zebra crossing right in front of the Dhaba entrance
  /// - Directional road arrows on asphalt
  /// - Authentic Pakistani Bedford Truck with vibrant truck art parked on the highway shoulder
  /// - Iconic green & yellow Auto-Rickshaw (Tuk-Tuk) taking a chai break
  /// - Roadside Dhaba neon totem signboard (24/7 KADAK CHAI) & street lamppost
  /// - Far roadside grass verge and surrounding countryside terrain
  static void drawExteriorEnvironment(
    Canvas canvas,
    double width,
    double height,
    double wallThickness,
  ) {
    const minExtX = -450.0;
    final maxExtX = width + 450.0;

    // 1. Base Terrain / Earth Surround (Packed soil & countryside earth)
    final earthPaint = Paint()..color = const Color(0xFF4E342E);
    canvas.drawRect(
      Rect.fromLTRB(minExtX, -350.0, maxExtX, height + 650.0),
      earthPaint,
    );

    // Left landscape area (West of building)
    final gravelPaint = Paint()..color = const Color(0xFF5D4037);
    final grassCluster = Paint()..color = const Color(0xFF2E7D32);
    canvas.drawRect(
      Rect.fromLTRB(minExtX, -350.0, 0.0, height),
      gravelPaint,
    );
    canvas.drawCircle(const Offset(-120.0, 200.0), 45.0, grassCluster);
    canvas.drawCircle(const Offset(-180.0, 500.0), 60.0, grassCluster);
    canvas.drawCircle(const Offset(-100.0, 850.0), 50.0, grassCluster);

    // Right landscape area (East of building)
    canvas.drawRect(
      Rect.fromLTRB(width, -350.0, maxExtX, height),
      gravelPaint,
    );
    canvas.drawCircle(Offset(width + 120.0, 250.0), 55.0, grassCluster);
    canvas.drawCircle(Offset(width + 160.0, 600.0), 65.0, grassCluster);
    canvas.drawCircle(Offset(width + 110.0, 950.0), 50.0, grassCluster);

    // Top landscape area (North of building)
    canvas.drawRect(
      Rect.fromLTRB(0.0, -350.0, width, 0.0),
      gravelPaint,
    );
    canvas.drawCircle(Offset(width * 0.3, -80.0), 50.0, grassCluster);
    canvas.drawCircle(Offset(width * 0.7, -90.0), 55.0, grassCluster);

    // 2. South Sidewalk / Paved Porch Promenade (y: 1200.0 to 1290.0)
    final sidewalkPaint = Paint()..color = const Color(0xFFCFD8DC);
    canvas.drawRect(
      Rect.fromLTRB(minExtX, height, maxExtX, height + 90.0),
      sidewalkPaint,
    );

    // Sidewalk paver grid seams
    final paverGrout = Paint()
      ..color = const Color(0xFFB0BEC5)
      ..strokeWidth = 1.0;
    for (double px = minExtX; px <= maxExtX; px += 35.0) {
      canvas.drawLine(
        Offset(px, height),
        Offset(px, height + 90.0),
        paverGrout,
      );
    }
    canvas.drawLine(
      Offset(minExtX, height + 45.0),
      Offset(maxExtX, height + 45.0),
      paverGrout,
    );

    // Entrance Porch Apron (x: 270 to 630, y: 1200 to 1290)
    final porchApron = Paint()..color = const Color(0xFFBCAAA4);
    canvas.drawRect(
      Rect.fromLTRB(270.0, height, 630.0, height + 90.0),
      porchApron,
    );
    final apronLine = Paint()
      ..color = const Color(0xFF8D6E63).withValues(alpha: 0.35)
      ..strokeWidth = 1.0;
    for (double ax = 270.0; ax <= 630.0; ax += 30.0) {
      canvas.drawLine(Offset(ax, height), Offset(ax, height + 90.0), apronLine);
    }
    final wallDropShadow = Paint()..color = const Color(0x33000000);
    canvas.drawRect(Rect.fromLTWH(0.0, height, width, 5.0), wallDropShadow);

    // 3. Roadside Dhaba Marquee Totem Billboard (at x: 190, y: 1245)
    _drawDhabaBillboard(canvas, 190.0, height + 45.0);

    // 4. Highway Street Lamppost (at x: 740, y: 1245)
    _drawStreetLamp(canvas, 740.0, height + 45.0);

    // 5. Pakistani Yellow & Black Striped Road Curb Stones (y: 1290.0 to 1310.0)
    final curbTop = height + 90.0; // 1290.0
    const curbHeight = 20.0;
    final curbBottom = curbTop + curbHeight; // 1310.0

    const stripeWidth = 26.0;
    final curbYellow = Paint()..color = AppTheme.goldYellow;
    final curbBlack = Paint()..color = const Color(0xFF212121);
    final curbHighlight = Paint()
      ..color = const Color(0x55FFFFFF)
      ..strokeWidth = 1.5;
    final curbShadow = Paint()
      ..color = const Color(0x66000000)
      ..strokeWidth = 2.0;

    int stripeIdx = 0;
    for (double cx = minExtX; cx < maxExtX; cx += stripeWidth) {
      final isRamp = cx >= 395.0 && cx <= 505.0;
      if (!isRamp) {
        final isYellow = (stripeIdx % 2 == 0);
        final stripePath = Path()
          ..moveTo(cx, curbTop)
          ..lineTo(cx + stripeWidth, curbTop)
          ..lineTo(cx + stripeWidth - 8.0, curbBottom)
          ..lineTo(cx - 8.0, curbBottom)
          ..close();
        canvas.drawPath(stripePath, isYellow ? curbYellow : curbBlack);
      }
      stripeIdx++;
    }

    // Pedestrian curb drop ramp (x: 390 to 510)
    final rampPaint = Paint()..color = const Color(0xFFFFB300);
    final rampRect = Rect.fromLTRB(390.0, curbTop, 510.0, curbBottom);
    canvas.drawRect(rampRect, rampPaint);
    final bumpPaint = Paint()..color = const Color(0xFFFFA000);
    for (double bx = 400.0; bx <= 500.0; bx += 14.0) {
      canvas.drawCircle(Offset(bx, curbTop + 10.0), 2.5, bumpPaint);
    }

    // Curb 3D top edge highlight & bottom cast shadow
    canvas.drawLine(
      Offset(minExtX, curbTop),
      Offset(maxExtX, curbTop),
      curbHighlight,
    );
    canvas.drawLine(
      Offset(minExtX, curbBottom),
      Offset(maxExtX, curbBottom),
      curbShadow,
    );

    // 6. Grand Trunk Highway (GT Road Asphalt Bed) (y: 1310.0 to 1660.0)
    final asphaltTop = curbBottom; // 1310.0
    final asphaltBottom = asphaltTop + 350.0; // 1660.0
    final roadPaint = Paint()..color = const Color(0xFF212529);
    canvas.drawRect(
      Rect.fromLTRB(minExtX, asphaltTop, maxExtX, asphaltBottom),
      roadPaint,
    );

    // Subtle asphalt texture tire wear bands
    final tireTrackPaint = Paint()
      ..color = const Color(0xFF1B1E21)
      ..strokeWidth = 28.0;
    canvas.drawLine(
      Offset(minExtX, asphaltTop + 70.0),
      Offset(maxExtX, asphaltTop + 70.0),
      tireTrackPaint,
    );
    canvas.drawLine(
      Offset(minExtX, asphaltTop + 240.0),
      Offset(maxExtX, asphaltTop + 240.0),
      tireTrackPaint,
    );

    // North Shoulder Solid White Line
    final whiteLine = Paint()
      ..color = const Color(0xEEFFFFFF)
      ..strokeWidth = 5.0;
    canvas.drawLine(
      Offset(minExtX, asphaltTop + 25.0),
      Offset(maxExtX, asphaltTop + 25.0),
      whiteLine,
    );

    // Highway Center Divider: Dashed Yellow Line
    final yellowDash = Paint()
      ..color = const Color(0xFFFFD54F)
      ..strokeWidth = 4.5;
    const dashLen = 50.0;
    const dashGap = 35.0;
    final dashY = asphaltTop + 175.0;
    for (double dx = minExtX; dx < maxExtX; dx += (dashLen + dashGap)) {
      canvas.drawLine(
        Offset(dx, dashY),
        Offset(dx + dashLen, dashY),
        yellowDash,
      );
    }

    // South Shoulder Solid White Line
    canvas.drawLine(
      Offset(minExtX, asphaltBottom - 25.0),
      Offset(maxExtX, asphaltBottom - 25.0),
      whiteLine,
    );

    // Directional Painted Road Arrows on asphalt
    _drawRoadArrow(canvas, 270.0, asphaltTop + 100.0, pointingEast: true);
    _drawRoadArrow(canvas, 640.0, asphaltTop + 255.0, pointingEast: false);

    // Note: Vehicles (truck, rickshaw) temporarily removed per user request for empty highway

    // 7. Far Roadside Verge & Greenery (y: 1660.0 to 1850.0)
    final farVerge = Paint()..color = const Color(0xFF6D4C41);
    canvas.drawRect(
      Rect.fromLTRB(minExtX, asphaltBottom, maxExtX, asphaltBottom + 35.0),
      farVerge,
    );
    final farGrass = Paint()..color = const Color(0xFF2E7D32);
    canvas.drawRect(
      Rect.fromLTRB(minExtX, asphaltBottom + 35.0, maxExtX, height + 650.0),
      farGrass,
    );

    // Highway W-Beam Metal Guardrail along bottom verge
    final guardrailPaint = Paint()
      ..color = const Color(0xFF90A4AE)
      ..strokeWidth = 4.0;
    final guardrailPost = Paint()
      ..color = const Color(0xFF546E7A)
      ..strokeWidth = 3.5;
    final grY = asphaltBottom + 18.0;
    canvas.drawLine(Offset(minExtX, grY), Offset(maxExtX, grY), guardrailPaint);
    for (double rx = minExtX; rx < maxExtX; rx += 70.0) {
      canvas.drawLine(
        Offset(rx, grY - 4.0),
        Offset(rx, grY + 12.0),
        guardrailPost,
      );
    }
  }

  static void _drawDhabaBillboard(Canvas canvas, double cx, double cy) {
    final postPaint = Paint()
      ..color = const Color(0xFF455A64)
      ..strokeWidth = 3.5;
    canvas.drawLine(
      Offset(cx - 24, cy - 10),
      Offset(cx - 24, cy + 22),
      postPaint,
    );
    canvas.drawLine(
      Offset(cx + 24, cy - 10),
      Offset(cx + 24, cy + 22),
      postPaint,
    );

    final boardRect = Rect.fromCenter(
      center: Offset(cx, cy - 15),
      width: 120,
      height: 38,
    );
    final boardRRect = RRect.fromRectAndRadius(
      boardRect,
      const Radius.circular(6),
    );
    final boardBg = Paint()..color = const Color(0xFF0F1E2E);
    final boardBorder = Paint()
      ..color = AppTheme.saffronOrange
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        boardRect.translate(0, 3),
        const Radius.circular(6),
      ),
      Paint()..color = const Color(0x44000000),
    );
    canvas.drawRRect(boardRRect, boardBg);
    canvas.drawRRect(boardRRect, boardBorder);

    final titlePainter = TextPainter(
      text: const TextSpan(
        text: 'CHAI DHABA ☕',
        style: TextStyle(
          color: AppTheme.goldYellow,
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    titlePainter.paint(
      canvas,
      Offset(cx - titlePainter.width / 2, cy - 28),
    );

    final subPainter = TextPainter(
      text: const TextSpan(
        text: '★ 24/7 OPEN ★',
        style: TextStyle(
          color: Colors.white,
          fontSize: 8.0,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    subPainter.paint(
      canvas,
      Offset(cx - subPainter.width / 2, cy - 14),
    );
  }

  static void _drawStreetLamp(Canvas canvas, double cx, double cy) {
    final glowPaint = Paint()..color = const Color(0x18FFE082);
    canvas.drawCircle(Offset(cx, cy + 20), 55.0, glowPaint);

    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 20), width: 18, height: 10),
      Paint()..color = const Color(0x33000000),
    );

    final polePaint = Paint()
      ..color = const Color(0xFF607D8B)
      ..strokeWidth = 4.0;
    canvas.drawLine(Offset(cx, cy + 20), Offset(cx, cy - 35), polePaint);

    final armPaint = Paint()
      ..color = const Color(0xFF455A64)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    final armPath = Path()
      ..moveTo(cx, cy - 35)
      ..quadraticBezierTo(cx - 15, cy - 45, cx - 22, cy - 30);
    canvas.drawPath(armPath, armPaint);

    final lanternPaint = Paint()..color = AppTheme.goldYellow;
    canvas.drawCircle(Offset(cx - 22, cy - 30), 5.0, lanternPaint);
  }

  static void _drawRoadArrow(
    Canvas canvas,
    double cx,
    double cy, {
    required bool pointingEast,
  }) {
    final arrowPaint = Paint()..color = const Color(0xAAFFFFFF);
    final dir = pointingEast ? 1.0 : -1.0;

    final shaft = Rect.fromCenter(
      center: Offset(cx - dir * 8.0, cy),
      width: 28.0,
      height: 4.5,
    );
    canvas.drawRect(shaft, arrowPaint);

    final headPath = Path()
      ..moveTo(cx + dir * 16.0, cy)
      ..lineTo(cx + dir * 4.0, cy - 8.0)
      ..lineTo(cx + dir * 4.0, cy + 8.0)
      ..close();
    canvas.drawPath(headPath, arrowPaint);
  }

  /// Draws an authentic Pakistani Bedford Truck with traditional truck art.
  static void drawPakistaniTruck(Canvas canvas, double cx, double cy) {
    canvas.save();
    canvas.translate(cx, cy);

    final truckShadow = Paint()..color = const Color(0x55000000);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(0, 16), width: 140, height: 48),
        const Radius.circular(8),
      ),
      truckShadow,
    );

    final tirePaint = Paint()..color = const Color(0xFF1E1E1E);
    final rimPaint = Paint()..color = const Color(0xFFB0BEC5);

    void drawWheel(double wx, double wy) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(wx, wy), width: 22, height: 10),
          const Radius.circular(3),
        ),
        tirePaint,
      );
      canvas.drawCircle(Offset(wx, wy), 2.5, rimPaint);
    }

    drawWheel(42, -18);
    drawWheel(42, 18);
    drawWheel(-30, -18);
    drawWheel(-30, 18);
    drawWheel(-50, -18);
    drawWheel(-50, 18);

    final bedRect = Rect.fromCenter(
      center: const Offset(-20, 0),
      width: 85,
      height: 38,
    );
    final bedPaint = Paint()..color = const Color(0xFFD84315);
    canvas.drawRRect(
      RRect.fromRectAndRadius(bedRect, const Radius.circular(4)),
      bedPaint,
    );

    final colors = [
      AppTheme.goldYellow,
      AppTheme.truckArtGreen,
      AppTheme.truckArtCyan,
      AppTheme.truckArtRed,
    ];
    for (int i = 0; i < 4; i++) {
      final panelX = -56.0 + i * 20.0;
      final panelRect = Rect.fromLTWH(panelX, -15.0, 17.0, 30.0);
      final pColor = colors[i % colors.length];
      canvas.drawRRect(
        RRect.fromRectAndRadius(panelRect, const Radius.circular(2)),
        Paint()..color = pColor,
      );
      final diamondPath = Path()
        ..moveTo(panelX + 8.5, -12.0)
        ..lineTo(panelX + 15.0, 0.0)
        ..lineTo(panelX + 8.5, 12.0)
        ..lineTo(panelX + 2.0, 0.0)
        ..close();
      canvas.drawPath(
        diamondPath,
        Paint()..color = Colors.white.withValues(alpha: 0.8),
      );
    }

    final cabRect = Rect.fromLTWH(22, -17, 34, 34);
    final cabPaint = Paint()..color = const Color(0xFF00ACC1);
    canvas.drawRRect(
      RRect.fromRectAndRadius(cabRect, const Radius.circular(4)),
      cabPaint,
    );

    final windshield = Rect.fromLTWH(38, -13, 14, 26);
    canvas.drawRRect(
      RRect.fromRectAndRadius(windshield, const Radius.circular(3)),
      Paint()..color = const Color(0xCCB2EBF2),
    );

    final tajPath = Path()
      ..moveTo(24, -17)
      ..lineTo(32, -24)
      ..lineTo(40, -19)
      ..lineTo(48, -24)
      ..lineTo(54, -17)
      ..close();
    canvas.drawPath(tajPath, Paint()..color = AppTheme.goldYellow);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(57, 0), width: 6, height: 32),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0xFFECEFF1),
    );

    final flapPaint = Paint()..color = const Color(0xFF212121);
    canvas.drawRect(const Rect.fromLTWH(-64, -17, 4, 12), flapPaint);
    canvas.drawRect(const Rect.fromLTWH(-64, 5, 4, 12), flapPaint);
    final heartPaint = Paint()..color = Colors.redAccent;
    canvas.drawCircle(const Offset(-62, -11), 2.0, heartPaint);
    canvas.drawCircle(const Offset(-62, 11), 2.0, heartPaint);

    canvas.restore();
  }

  /// Draws an iconic Pakistani green and yellow Auto-Rickshaw (Tuk-Tuk).
  static void drawAutoRickshaw(Canvas canvas, double cx, double cy) {
    canvas.save();
    canvas.translate(cx, cy);

    final rickshawShadow = Paint()..color = const Color(0x44000000);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 10), width: 56, height: 34),
      rickshawShadow,
    );

    final tirePaint = Paint()..color = const Color(0xFF212121);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(-16, -14), width: 14, height: 6),
        const Radius.circular(2),
      ),
      tirePaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(-16, 14), width: 14, height: 6),
        const Radius.circular(2),
      ),
      tirePaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(18, 0), width: 12, height: 6),
        const Radius.circular(2),
      ),
      tirePaint,
    );

    final bodyPaint = Paint()..color = AppTheme.truckArtGreen;
    final bodyRect = Rect.fromCenter(
      center: const Offset(-4, 0),
      width: 38,
      height: 26,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, const Radius.circular(5)),
      bodyPaint,
    );

    final nosePath = Path()
      ..moveTo(12, -10)
      ..lineTo(20, -6)
      ..lineTo(22, 0)
      ..lineTo(20, 6)
      ..lineTo(12, 10)
      ..close();
    canvas.drawPath(nosePath, Paint()..color = AppTheme.goldYellow);

    canvas.drawCircle(const Offset(22, 0), 2.5, Paint()..color = Colors.white);

    final roofRect = Rect.fromCenter(
      center: const Offset(-6, 0),
      width: 30,
      height: 22,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(roofRect, const Radius.circular(4)),
      Paint()..color = const Color(0xFF1E1E1E),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(-19, 0), width: 4, height: 12),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0x88B2EBF2),
    );

    canvas.restore();
  }

  /// Draws an interactive floor rectangle pad for in-place machine upgrades or floor unlocks.
  static void drawGroundPad(Canvas canvas, GroundPad pad) {
    if (pad.type == PadType.floorUnlock && pad.isCompleted) return;

    final rect = Rect.fromCenter(
      center: Offset(pad.position.x, pad.position.y),
      width: pad.width,
      height: pad.height,
    );
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(10));

    // Pad Background Fill
    final isUpgrade = pad.type == PadType.machineUpgrade;
    final baseColor = isUpgrade ? AppTheme.goldYellow : AppTheme.truckArtGreen;
    final fillPaint = Paint()..color = baseColor.withValues(alpha: 0.18);
    canvas.drawRRect(rrect, fillPaint);

    // Dashed or Solid Border
    final borderPaint = Paint()
      ..color = baseColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRRect(rrect, borderPaint);

    if (pad.isCompleted && pad.isMaxLevel) {
      // Golden MAX badge
      final maxPainter = TextPainter(
        text: const TextSpan(
          text: 'MAX',
          style: TextStyle(
            color: Color(0xFFD84315),
            fontWeight: FontWeight.w900,
            fontSize: 12,
            letterSpacing: 1.0,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      maxPainter.paint(
        canvas,
        Offset(
          pad.position.x - maxPainter.width / 2,
          pad.position.y - maxPainter.height / 2,
        ),
      );
      return;
    }

    // Title text at top of pad
    final titlePainter = TextPainter(
      text: TextSpan(
        text: pad.title,
        style: const TextStyle(
          color: AppTheme.chaiDarkBrown,
          fontWeight: FontWeight.w900,
          fontSize: 8.5,
          letterSpacing: 0.3,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    titlePainter.paint(
      canvas,
      Offset(
        pad.position.x - titlePainter.width / 2,
        pad.position.y - pad.height / 2 + 6,
      ),
    );

    // Cash Icon & Remaining Amount
    final costPainter = TextPainter(
      text: TextSpan(
        text: '💵 Rs ${pad.remainingCost.ceil()}',
        style: const TextStyle(
          color: Color(0xFF1B5E20),
          fontWeight: FontWeight.w900,
          fontSize: 10,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    costPainter.paint(
      canvas,
      Offset(pad.position.x - costPainter.width / 2, pad.position.y - 2),
    );

    // Progress bar along bottom of pad
    const barWidth = 56.0;
    const barHeight = 4.0;
    final barY = pad.position.y + pad.height / 2 - 8;
    final barBg = Rect.fromCenter(
      center: Offset(pad.position.x, barY),
      width: barWidth,
      height: barHeight,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(barBg, const Radius.circular(2)),
      Paint()..color = const Color(0x33000000),
    );

    if (pad.progress > 0.0) {
      final fillWidth = barWidth * pad.progress;
      final fillRect = Rect.fromLTWH(
        pad.position.x - barWidth / 2,
        barY - barHeight / 2,
        fillWidth,
        barHeight,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(fillRect, const Radius.circular(2)),
        Paint()..color = const Color(0xFF2E7D32),
      );
    }
  }

  /// Draws an unlocked wooden Dhaba dining table with chairs, customer meal,
  /// dirty trays, cash tips, and clean indicators.
  static void drawDiningTable(Canvas canvas, DiningTable table) {
    if (!table.isUnlocked) return;

    final left = table.position.x - table.width / 2;
    final top = table.position.y - table.height / 2;

    // Clean / Interaction zone indicator when dirty or with cash tip
    if (table.hasDirtyTray || table.cashTip > 0.0) {
      final pulse = 0.5 + 0.5 * math.sin(DateTime.now().millisecondsSinceEpoch * 0.006);
      final cleanZoneRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(table.position.x, table.position.y),
          width: table.width + 48.0,
          height: table.height + 48.0,
        ),
        const Radius.circular(20.0),
      );
      final zonePaint = Paint()
        ..color = (table.cashTip > 0.0
            ? AppTheme.goldYellow.withValues(alpha: 0.12 + 0.08 * pulse)
            : AppTheme.saffronOrange.withValues(alpha: 0.10 + 0.06 * pulse));
      canvas.drawRRect(cleanZoneRect, zonePaint);

      final zoneBorder = Paint()
        ..color = (table.cashTip > 0.0
            ? AppTheme.goldYellow.withValues(alpha: 0.6)
            : AppTheme.saffronOrange.withValues(alpha: 0.5))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawRRect(cleanZoneRect, zoneBorder);
    }

    // Drop shadow
    final shadowPaint = Paint()..color = const Color(0x2E000000);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(left - 2, top + 4, table.width + 4, table.height + 4),
        const Radius.circular(8),
      ),
      shadowPaint,
    );

    // Wooden Table Top (Mahogany / Rich Teak)
    final woodPaint = Paint()..color = const Color(0xFF5D4037);
    final borderPaint = Paint()
      ..color = const Color(0xFF3E2723)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final tableRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, table.width, table.height),
      const Radius.circular(6),
    );
    canvas.drawRRect(tableRRect, woodPaint);
    canvas.drawRRect(tableRRect, borderPaint);

    // Truck Art Table Runner in center
    final runnerRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(table.position.x, table.position.y),
        width: table.width - 24,
        height: table.height - 16,
      ),
      const Radius.circular(3),
    );
    canvas.drawRRect(runnerRect, Paint()..color = AppTheme.saffronOrange);
    canvas.drawRRect(
      runnerRect,
      Paint()
        ..color = AppTheme.goldYellow
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Stools around the table (2 on Top side, 2 on Bottom side)
    final stoolPaint = Paint()..color = const Color(0xFF8D6E63);
    final stoolBorder = Paint()
      ..color = const Color(0xFF4E342E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Top stools (Left & Right)
    canvas.drawCircle(Offset(table.position.x - 30.0, top - 12), 8, stoolPaint);
    canvas.drawCircle(Offset(table.position.x - 30.0, top - 12), 8, stoolBorder);
    canvas.drawCircle(Offset(table.position.x + 30.0, top - 12), 8, stoolPaint);
    canvas.drawCircle(Offset(table.position.x + 30.0, top - 12), 8, stoolBorder);

    // Bottom stools (Left & Right)
    canvas.drawCircle(
      Offset(table.position.x - 30.0, top + table.height + 12),
      8,
      stoolPaint,
    );
    canvas.drawCircle(
      Offset(table.position.x - 30.0, top + table.height + 12),
      8,
      stoolBorder,
    );
    canvas.drawCircle(
      Offset(table.position.x + 30.0, top + table.height + 12),
      8,
      stoolPaint,
    );
    canvas.drawCircle(
      Offset(table.position.x + 30.0, top + table.height + 12),
      8,
      stoolBorder,
    );

    // Render per-seat table surface items (hot chai, dirty trays, and cash tips)
    for (final seat in table.seats) {
      final surfaceX = seat.position.x;
      final surfaceY =
          seat.facingAngle > 0 ? (table.position.y - 14.0) : (table.position.y + 14.0);

      // Active diner eating chai at this seat (only visible once diner has reached and sat at the table!)
      if (seat.isOccupied && seat.isSeated) {
        canvas.save();
        canvas.translate(surfaceX, surfaceY);
        _drawChaiCup(canvas, 0.65);
        canvas.restore();
      }

      // Dirty tray left at this seat
      if (seat.hasDirtyTray) {
        canvas.save();
        canvas.translate(surfaceX, surfaceY);
        _drawCarriedDirtyTray(canvas, 0.85);
        canvas.restore();
      }

      // Cash tip left at this seat
      if (seat.cashTip > 0.0) {
        final tipBundle = CashBundleEntity(
          position: Vector2(surfaceX, surfaceY),
          value: seat.cashTip,
        );
        drawCashBundle(canvas, tipBundle);
      }
    }

    // Floating "CLEAN ME" tag above table if any seat has a dirty tray
    if (table.hasDirtyTray) {
      final tagRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(table.position.x, top - 20.0),
          width: 80,
          height: 18,
        ),
        const Radius.circular(5),
      );
      canvas.drawRRect(tagRect, Paint()..color = const Color(0xFFD84315));
      final cleanText = TextPainter(
        text: TextSpan(
          text: '🧹 CLEAN (${table.dirtyCount})',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 9,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      cleanText.paint(
        canvas,
        Offset(
          table.position.x - cleanText.width / 2,
          top - 20.0 - cleanText.height / 2,
        ),
      );
    }

    // Floating total tip badge above table if any seat has a tip
    if (table.cashTip > 0.0) {
      final tipBadgeY = top - (table.hasDirtyTray ? 42.0 : 20.0);
      final tipBadgeRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(table.position.x, tipBadgeY),
          width: 74,
          height: 18,
        ),
        const Radius.circular(5),
      );
      canvas.drawRRect(tipBadgeRect, Paint()..color = const Color(0xFF2E7D32));
      final tipText = TextPainter(
        text: TextSpan(
          text: '₹${table.cashTip.toInt()} TIP!',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 9,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tipText.paint(
        canvas,
        Offset(
          table.position.x - tipText.width / 2,
          tipBadgeY - tipText.height / 2,
        ),
      );
    }
  }

  /// Draws the HR Desk station with mahogany table, computer monitor, desk lamp,
  /// paperwork clipboard, executive chair, and glowing interaction zone.
  static void drawHRDesk(Canvas canvas, HRDesk desk, bool isPlayerInsideZone) {
    final x = desk.position.x;
    final y = desk.position.y;
    final halfH = desk.height / 2;

    // 1. Interaction Zone on the floor in front of desk
    final zoneCenter = desk.interactionZoneCenter;
    final pulse = 1.0 + math.sin(DateTime.now().millisecondsSinceEpoch * 0.005) * 0.05;
    final ringPaint = Paint()
      ..color = isPlayerInsideZone
          ? AppTheme.saffronOrange.withValues(alpha: 0.4)
          : AppTheme.truckArtGreen.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isPlayerInsideZone ? 3.0 : 2.0;

    canvas.drawCircle(Offset(zoneCenter.x, zoneCenter.y), desk.zoneRadius * pulse, ringPaint);

    final zoneFill = Paint()
      ..color = isPlayerInsideZone
          ? AppTheme.saffronOrange.withValues(alpha: 0.15)
          : AppTheme.truckArtGreen.withValues(alpha: 0.08);
    canvas.drawCircle(Offset(zoneCenter.x, zoneCenter.y), desk.zoneRadius * pulse, zoneFill);

    // Zone Badge
    final zoneBadgeRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(zoneCenter.x, zoneCenter.y), width: 70, height: 20),
      const Radius.circular(8),
    );
    canvas.drawRRect(
      zoneBadgeRect,
      Paint()..color = isPlayerInsideZone ? AppTheme.saffronOrange : AppTheme.truckArtGreen,
    );
    final zoneText = TextPainter(
      text: const TextSpan(
        text: '📋 HR DESK',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 9,
          letterSpacing: 0.4,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    zoneText.paint(
      canvas,
      Offset(zoneCenter.x - zoneText.width / 2, zoneCenter.y - zoneText.height / 2),
    );

    // 2. Swivel Chair behind desk
    final chairPaint = Paint()..color = const Color(0xFF37474F);
    canvas.drawCircle(Offset(x, y - halfH - 12), 14, chairPaint);
    final cushionPaint = Paint()..color = const Color(0xFF263238);
    canvas.drawCircle(Offset(x, y - halfH - 12), 10, cushionPaint);

    // 3. Desk Shadow
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(x + 4, y + 6), width: desk.width, height: desk.height),
        const Radius.circular(8),
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.25),
    );

    // 4. Mahogany Wood Desk Surface
    final deskRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(x, y), width: desk.width, height: desk.height),
      const Radius.circular(8),
    );
    final deskPaint = Paint()..color = const Color(0xFF5D4037);
    canvas.drawRRect(deskRect, deskPaint);

    // Desk border / bevel
    final borderPaint = Paint()
      ..color = const Color(0xFF8D6E63)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRRect(deskRect, borderPaint);

    // 5. Desktop Computer Monitor (left side of desk)
    final monX = x - 20.0;
    final monY = y - 4.0;
    // Stand base
    canvas.drawRect(
      Rect.fromCenter(center: Offset(monX, monY + 12), width: 14, height: 4),
      Paint()..color = const Color(0xFF424242),
    );
    // Screen bezel
    final screenRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(monX, monY), width: 26, height: 18),
      const Radius.circular(3),
    );
    canvas.drawRRect(screenRect, Paint()..color = const Color(0xFF212121));
    // Display screen with bar chart
    final displayRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(monX, monY), width: 22, height: 14),
      const Radius.circular(2),
    );
    canvas.drawRRect(displayRect, Paint()..color = const Color(0xFF004D40));
    // Bar chart lines on screen
    final barPaint = Paint()..color = const Color(0xFF00E676);
    canvas.drawLine(Offset(monX - 6, monY + 4), Offset(monX - 6, monY - 1), barPaint..strokeWidth = 2);
    canvas.drawLine(Offset(monX - 2, monY + 4), Offset(monX - 2, monY - 4), barPaint..strokeWidth = 2);
    canvas.drawLine(Offset(monX + 2, monY + 4), Offset(monX + 2, monY + 1), barPaint..strokeWidth = 2);
    canvas.drawLine(Offset(monX + 6, monY + 4), Offset(monX + 6, monY - 5), barPaint..strokeWidth = 2);

    // 6. Clipboard with Papers (right side of desk)
    final clipX = x + 22.0;
    final clipY = y;
    final clipBoardRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(clipX, clipY), width: 18, height: 24),
      const Radius.circular(3),
    );
    canvas.drawRRect(clipBoardRect, Paint()..color = const Color(0xFFD7CCC8));
    // Paper on clipboard
    final paperRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(clipX, clipY + 1), width: 14, height: 18),
      const Radius.circular(1),
    );
    canvas.drawRRect(paperRect, Paint()..color = Colors.white);
    // Clip at top
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(clipX, clipY - 10), width: 8, height: 4),
        const Radius.circular(1),
      ),
      Paint()..color = const Color(0xFF757575),
    );

    // 7. Desk Lamp (top right corner of desk)
    final lampX = x + 34.0;
    final lampY = y - 14.0;
    canvas.drawCircle(Offset(lampX, lampY), 5, Paint()..color = const Color(0xFFFFD54F));
    canvas.drawCircle(
      Offset(lampX, lampY),
      9,
      Paint()..color = const Color(0xFFFFD54F).withValues(alpha: 0.35),
    );
  }

  /// Draws the hired Cashier character standing behind the counter inside the green zone.
  static void drawCashier(Canvas canvas, StaffEntity cashier) {
    canvas.save();
    canvas.translate(cashier.position.x, cashier.position.y);

    // 1. Shadow
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 16), width: 34, height: 16),
      Paint()..color = AppTheme.characterShadow,
    );

    // 2. Torso (facing South)
    // White collared shirt
    canvas.drawCircle(const Offset(0, 2), 15, Paint()..color = Colors.white);

    // Emerald green Dhaba waistcoat vest with gold trim
    final vestRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: const Offset(0, 4), width: 20, height: 15),
      const Radius.circular(4),
    );
    canvas.drawRRect(vestRect, Paint()..color = const Color(0xFF1B5E20));

    // Gold vest buttons
    final goldPaint = Paint()..color = AppTheme.goldYellow;
    canvas.drawCircle(const Offset(0, 0), 1.5, goldPaint);
    canvas.drawCircle(const Offset(0, 4), 1.5, goldPaint);
    canvas.drawCircle(const Offset(0, 8), 1.5, goldPaint);

    // Bow tie
    final tiePaint = Paint()..color = const Color(0xFFB71C1C);
    canvas.drawCircle(const Offset(0, -5), 2.5, tiePaint);

    // 3. Head & Face
    canvas.drawCircle(const Offset(0, -6), 13, Paint()..color = AppTheme.characterSkin);

    // Hair / Cap (neat black hair)
    final hairPaint = Paint()..color = const Color(0xFF212121);
    final hairPath = Path()
      ..moveTo(-11, -8)
      ..quadraticBezierTo(0, -18, 11, -8)
      ..quadraticBezierTo(12, -4, 9, -2)
      ..quadraticBezierTo(0, -10, -9, -2)
      ..close();
    canvas.drawPath(hairPath, hairPaint);

    // Mustache & Smile
    final mustachePaint = Paint()..color = const Color(0xFF212121);
    final mustachePath = Path()
      ..moveTo(-5, -4)
      ..quadraticBezierTo(-2, -6, 0, -4)
      ..quadraticBezierTo(2, -6, 5, -4)
      ..quadraticBezierTo(0, -2, -5, -4)
      ..close();
    canvas.drawPath(mustachePath, mustachePaint);

    // Eyes
    canvas.drawCircle(const Offset(-4, -9), 1.5, Paint()..color = const Color(0xFF212121));
    canvas.drawCircle(const Offset(4, -9), 1.5, Paint()..color = const Color(0xFF212121));

    // Hands resting forward
    canvas.drawCircle(const Offset(-12, 3), 4, Paint()..color = AppTheme.characterSkin);
    canvas.drawCircle(const Offset(12, 3), 4, Paint()..color = AppTheme.characterSkin);

    // 4. Cashier badge above head
    final badgeRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: const Offset(0, -28), width: 56, height: 16),
      const Radius.circular(5),
    );
    canvas.drawRRect(badgeRect, Paint()..color = AppTheme.truckArtGreen);
    final badgeText = TextPainter(
      text: const TextSpan(
        text: '👔 CASHIER',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 8,
          letterSpacing: 0.3,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    badgeText.paint(
      canvas,
      Offset(-badgeText.width / 2, -28 - badgeText.height / 2),
    );

    canvas.restore();
  }

  /// Draws the autonomous Helper / Waiter running around, with walking physics,
  /// yellow uniform, head stack wobble, and MAX badge.
  static void drawHelper(Canvas canvas, StaffEntity helper) {
    canvas.save();
    canvas.translate(helper.position.x, helper.position.y);

    // 1. Drop shadow (scales slightly while running)
    final shadowScale =
        1.0 + (helper.isMoving ? math.sin(helper.walkCycle * 2) * 0.08 : 0.0);
    final shadowPaint = Paint()..color = AppTheme.characterShadow;
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(0, 16),
        width: 32 * shadowScale,
        height: 16 * shadowScale,
      ),
      shadowPaint,
    );

    // 2. Walking bob
    final bobOffset = helper.isMoving
        ? math.sin(helper.walkCycle * 2).abs() * -3.5
        : 0.0;
    canvas.translate(0, bobOffset);

    // 3. Rotate towards heading
    canvas.save();
    canvas.rotate(helper.angle - math.pi / 2);

    // Feet animation
    final leftFootOffset = helper.isMoving
        ? math.sin(helper.walkCycle) * 6.0
        : 0.0;
    final rightFootOffset = helper.isMoving
        ? -math.sin(helper.walkCycle) * 6.0
        : 0.0;
    final shoePaint = Paint()..color = const Color(0xFF4E342E);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(-7, 12 + leftFootOffset), width: 7, height: 12),
        const Radius.circular(3),
      ),
      shoePaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(7, 12 + rightFootOffset), width: 7, height: 12),
        const Radius.circular(3),
      ),
      shoePaint,
    );

    // Body: White shalwar kameez
    canvas.drawCircle(const Offset(0, 2), 14, Paint()..color = const Color(0xFFF5F5F5));

    // Cohesive Vibrant Yellow Uniform for all shop workers (Helpers)
    const apronColor = Color(0xFFFFB300); // Warm Golden Yellow
    const pocketColor = Color(0xFFF57F17); // Rich Amber Pocket Accent
    const bandColor = Color(0xFFE65100); // Deep Amber / Runner Headband
    const badgeBgColor = Color(0xFFE65100); // Deep Amber Badge

    final apronRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: const Offset(0, 3), width: 19, height: 14),
      const Radius.circular(4),
    );
    canvas.drawRRect(apronRect, Paint()..color = apronColor);

    // Apron Pocket
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(0, 6), width: 9, height: 5),
        const Radius.circular(2),
      ),
      Paint()..color = pocketColor,
    );

    // Head
    canvas.drawCircle(const Offset(0, -6), 12, Paint()..color = AppTheme.characterSkin);

    // Headband / Kerchief
    final bandPaint = Paint()..color = bandColor;
    canvas.drawCircle(const Offset(0, -7), 10, bandPaint);
    canvas.drawRect(
      Rect.fromCenter(center: const Offset(0, -6), width: 18, height: 4),
      bandPaint,
    );

    // Hands
    canvas.drawCircle(const Offset(-12, 1), 4, Paint()..color = AppTheme.characterSkin);
    canvas.drawCircle(const Offset(12, 1), 4, Paint()..color = AppTheme.characterSkin);

    canvas.restore(); // Restore body rotation

    // 4. Carried Item Stack above head
    if (helper.carriedCount > 0) {
      _drawWorkerCarriedStack(canvas, helper);
    }

    // 5. Name badge above head (if not carrying items)
    if (helper.carriedCount == 0) {
      final nameBadge = RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(0, -25), width: 44, height: 14),
        const Radius.circular(4),
      );
      canvas.drawRRect(nameBadge, Paint()..color = badgeBgColor);
      final nameText = TextPainter(
        text: TextSpan(
          text: helper.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 7.5,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      nameText.paint(
        canvas,
        Offset(-nameText.width / 2, -25 - nameText.height / 2),
      );
    }

    canvas.restore();
  }

  /// Alias for backward compatibility
  static void drawChotu(Canvas canvas, StaffEntity chotu) => drawHelper(canvas, chotu);

  static void _drawWorkerCarriedStack(Canvas canvas, StaffEntity staff) {
    const baseSpacing = 16.0;
    double currentX = 0.0;
    double currentY = -24.0;

    for (int i = 0; i < staff.carriedCount; i++) {
      final sway = staff.wobbleAngle * (i + 1) * 8.0;
      currentX += sway;
      currentY -= baseSpacing;

      canvas.save();
      canvas.translate(currentX, currentY);
      canvas.rotate(staff.wobbleAngle * (i + 1) * 0.4);

      final item = staff.carriedItems[i];
      if (item == ItemType.dirtyTray) {
        _drawCarriedDirtyTray(canvas);
      } else {
        _drawChaiCup(canvas);
      }

      canvas.restore();
    }

    if (staff.isFull) {
      final pulse =
          1.0 + math.sin(DateTime.now().millisecondsSinceEpoch * 0.008) * 0.12;
      canvas.save();
      canvas.translate(currentX, currentY - 20);
      canvas.scale(pulse, pulse);

      final badgeRect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: 40, height: 18),
        const Radius.circular(6),
      );
      canvas.drawRRect(badgeRect, Paint()..color = const Color(0xFFD32F2F));
      canvas.drawRRect(
        badgeRect,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );

      final textPainter = TextPainter(
        text: const TextSpan(
          text: 'MAX',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 10,
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
}
