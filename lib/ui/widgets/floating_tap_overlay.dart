import 'package:material_ui/material_ui.dart';

import '../../core/number_format.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../state/game_controller.dart';

/// Renders floating "+Rs X" animations at tap locations that float upward and fade.
class FloatingTapOverlay extends StatelessWidget {
  final List<TapParticle> particles;

  const FloatingTapOverlay({super.key, required this.particles});

  @override
  Widget build(BuildContext context) {
    if (particles.isEmpty) return const SizedBox.shrink();

    final now = DateTime.now();

    return IgnorePointer(
      child: Stack(
        children: particles.map((p) {
          final elapsedMs = now.difference(p.createdAt).inMilliseconds;
          final progress = (elapsedMs / 800.0).clamp(0.0, 1.0);
          final opacity = (1.0 - progress).clamp(0.0, 1.0);
          final dyOffset = progress * 60.0; // float upwards 60px

          return Positioned(
            left: p.x - 40,
            top: p.y - 40 - dyOffset,
            child: Opacity(
              opacity: opacity,
              child: Text(
                '+${AppStrings.currencySymbol}${GameNumberFormat.format(p.amount)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.saffronOrange,
                  shadows: [
                    Shadow(
                      color: Colors.black45,
                      blurRadius: 4,
                      offset: Offset(1, 1),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
