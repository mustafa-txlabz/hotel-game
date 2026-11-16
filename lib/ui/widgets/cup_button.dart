import 'package:material_ui/material_ui.dart';

import '../../core/strings.dart';
import '../../core/theme.dart';

/// Interactive animated cup button that bounces on tap and emits tap coordinates.
class CupButton extends StatefulWidget {
  final void Function(Offset globalPosition) onTap;

  const CupButton({super.key, required this.onTap});

  @override
  State<CupButton> createState() => _CupButtonState();
}

class _CupButtonState extends State<CupButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      lowerBound: 0.0,
      upperBound: 1.0,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  void _handleTapDown(TapDownDetails details) {
    _animController.forward();
    widget.onTap(details.globalPosition);
  }

  void _handleTapUp(TapUpDetails details) {
    _animController.reverse();
  }

  void _handleTapCancel() {
    _animController.reverse();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTapDown: _handleTapDown,
          onTapUp: _handleTapUp,
          onTapCancel: _handleTapCancel,
          behavior: HitTestBehavior.opaque,
          child: AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) =>
                Transform.scale(scale: _scaleAnimation.value, child: child),
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: AppTheme.cream,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.saffronOrange, width: 5),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.chaiDarkBrown.withValues(alpha: 0.25),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: AppTheme.goldYellow.withValues(alpha: 0.4),
                    blurRadius: 2,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Truck-art decorative ring
                  Container(
                    width: 116,
                    height: 116,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.truckArtGreen.withValues(alpha: 0.5),
                        width: 2,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.local_cafe_rounded,
                    size: 72,
                    color: AppTheme.chaiBrown,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          AppStrings.tapPrompt,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppTheme.chaiDarkBrown,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}
