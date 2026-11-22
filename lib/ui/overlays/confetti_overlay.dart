import 'dart:math' as math;
import 'package:material_ui/material_ui.dart';

/// Lightweight, high-performance particle system for celebratory confetti and fireworks.
class ConfettiOverlay extends StatefulWidget {
  final Duration duration;
  final VoidCallback? onComplete;

  const ConfettiOverlay({
    super.key,
    this.duration = const Duration(seconds: 4),
    this.onComplete,
  });

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_ConfettiParticle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..forward().then((_) => widget.onComplete?.call());

    final random = math.Random();
    _particles = List.generate(85, (_) => _ConfettiParticle.random(random));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            size: Size.infinite,
            painter: _ConfettiPainter(
              progress: _controller.value,
              particles: _particles,
            ),
          );
        },
      ),
    );
  }
}

enum _ParticleShape { ribbon, circle, star }

class _ConfettiParticle {
  final double initialX;
  final double initialY;
  final double vx;
  final double vy;
  final double rotationSpeed;
  final double size;
  final Color color;
  final _ParticleShape shape;

  _ConfettiParticle({
    required this.initialX,
    required this.initialY,
    required this.vx,
    required this.vy,
    required this.rotationSpeed,
    required this.size,
    required this.color,
    required this.shape,
  });

  factory _ConfettiParticle.random(math.Random rand) {
    const colors = [
      Color(0xFFFFD700), // Gold
      Color(0xFFFF9100), // Saffron Orange
      Color(0xFF00E676), // Truck Art Green
      Color(0xFF00E5FF), // Cyan
      Color(0xFFFF1744), // Crimson Red
      Color(0xFFE040FB), // Magenta
      Color(0xFFFFFFFF), // White
      Color(0xFFFFEA00), // Electric Yellow
    ];

    final shape = _ParticleShape.values[rand.nextInt(_ParticleShape.values.length)];
    final angle = rand.nextDouble() * math.pi * 2;
    final speed = 180.0 + rand.nextDouble() * 320.0;

    return _ConfettiParticle(
      initialX: 0.5 + (rand.nextDouble() - 0.5) * 0.4,
      initialY: 0.35 + (rand.nextDouble() - 0.5) * 0.2,
      vx: math.cos(angle) * speed,
      vy: math.sin(angle) * speed - 150.0, // initial upward blast
      rotationSpeed: (rand.nextDouble() - 0.5) * 12.0,
      size: 5.0 + rand.nextDouble() * 7.0,
      color: colors[rand.nextInt(colors.length)],
      shape: shape,
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final double progress;
  final List<_ConfettiParticle> particles;

  _ConfettiPainter({required this.progress, required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress;
    final alpha = (1.0 - math.pow(t, 2.5)).clamp(0.0, 1.0);

    for (final p in particles) {
      final x = p.initialX * size.width + p.vx * t;
      // Gravity acceleration downward
      final y = p.initialY * size.height + p.vy * t + 0.5 * 450.0 * t * t;

      if (y > size.height + 20) continue;

      final paint = Paint()
        ..color = p.color.withValues(alpha: alpha.toDouble())
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.rotationSpeed * t);

      switch (p.shape) {
        case _ParticleShape.ribbon:
          final flutter = math.cos(p.rotationSpeed * t * 2.0);
          canvas.drawRect(
            Rect.fromCenter(
              center: Offset.zero,
              width: p.size * 1.6,
              height: p.size * flutter.abs(),
            ),
            paint,
          );
          break;
        case _ParticleShape.circle:
          canvas.drawCircle(Offset.zero, p.size / 2, paint);
          break;
        case _ParticleShape.star:
          final starPath = Path();
          const points = 5;
          final outer = p.size;
          final inner = p.size * 0.45;
          for (int i = 0; i < points * 2; i++) {
            final r = i.isEven ? outer : inner;
            final theta = (i * math.pi) / points;
            final px = math.cos(theta) * r;
            final py = math.sin(theta) * r;
            if (i == 0) {
              starPath.moveTo(px, py);
            } else {
              starPath.lineTo(px, py);
            }
          }
          starPath.close();
          canvas.drawPath(starPath, paint);
          break;
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => true;
}
