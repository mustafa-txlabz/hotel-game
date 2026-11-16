import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';
import '../../data/balance.dart';

/// Floating visual representation of the virtual joystick.
class JoystickWidget extends StatelessWidget {
  final Offset? origin;
  final Offset? current;

  const JoystickWidget({
    super.key,
    required this.origin,
    required this.current,
  });

  @override
  Widget build(BuildContext context) {
    if (origin == null || current == null) {
      return const SizedBox.shrink();
    }

    final delta = current! - origin!;
    final distance = delta.distance;
    final clampedDistance = distance > GameBalance.joystickRadius
        ? GameBalance.joystickRadius
        : distance;
    final direction = distance > 0 ? delta / distance : Offset.zero;
    final knobOffset = direction * clampedDistance;

    return Positioned(
      left: origin!.dx - GameBalance.joystickRadius,
      top: origin!.dy - GameBalance.joystickRadius,
      child: IgnorePointer(
        child: SizedBox(
          width: GameBalance.joystickRadius * 2,
          height: GameBalance.joystickRadius * 2,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer Ring
              Container(
                width: GameBalance.joystickRadius * 2,
                height: GameBalance.joystickRadius * 2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.25),
                  border: Border.all(
                    color: AppTheme.saffronOrange.withValues(alpha: 0.8),
                    width: 3,
                  ),
                ),
              ),

              // Center Knob
              Transform.translate(
                offset: knobOffset,
                child: Container(
                  width: GameBalance.knobRadius * 2,
                  height: GameBalance.knobRadius * 2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [AppTheme.goldYellow, AppTheme.saffronOrange],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
