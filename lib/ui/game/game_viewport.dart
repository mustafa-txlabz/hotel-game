import 'package:flutter/scheduler.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../data/balance.dart';
import '../../state/game_controller.dart';
import '../overlays/goals_overlay.dart';
import '../overlays/hr_upgrade_sheet.dart';
import '../overlays/hud_overlay.dart';
import '../overlays/joystick_widget.dart';
import 'world_painter.dart';

/// Interactive game viewport with 60 FPS Ticker loop, smooth camera follow,
/// and virtual floating joystick touch controls.
class GameViewport extends StatefulWidget {
  const GameViewport({super.key});

  @override
  State<GameViewport> createState() => _GameViewportState();
}

class _GameViewportState extends State<GameViewport>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;

  // Camera offset in world coordinates
  Offset _cameraOffset = const Offset(450.0, 600.0);

  // Floating Joystick state
  Offset? _joystickOrigin;
  Offset? _joystickCurrent;
  int? _activePointerId;
  bool _hasMovedOnce = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      if (mounted) {
        context.read<GameController>().saveGame();
      }
    }
  }

  void _onTick(Duration elapsed) {
    if (_lastElapsed == Duration.zero) {
      _lastElapsed = elapsed;
      return;
    }

    final dt = (elapsed - _lastElapsed).inMicroseconds / 1000000.0;
    _lastElapsed = elapsed;

    if (!mounted || dt <= 0.0) return;

    final controller = Provider.of<GameController>(context, listen: false);

    // 1. Tick world simulation
    controller.tick(dt.clamp(0.0, 0.05)); // clamp to avoid huge lag spikes

    // 2. Smooth camera follow (lerp towards player position)
    final playerPos = controller.world.player.position;
    final targetOffset = Offset(playerPos.x, playerPos.y);

    setState(() {
      _cameraOffset = Offset.lerp(
        _cameraOffset,
        targetOffset,
        GameBalance.cameraLerpFactor,
      )!;
    });
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (_activePointerId != null) return; // Ignore secondary touches
    _activePointerId = event.pointer;

    setState(() {
      _joystickOrigin = event.position;
      _joystickCurrent = event.position;
      _hasMovedOnce = true;
    });
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (event.pointer != _activePointerId || _joystickOrigin == null) return;

    setState(() {
      _joystickCurrent = event.position;
    });

    final delta = event.position - _joystickOrigin!;
    final distance = delta.distance;
    final clampedDistance = distance > GameBalance.joystickRadius
        ? GameBalance.joystickRadius
        : distance;
    final direction = distance > 0.001 ? delta / distance : Offset.zero;
    final normalized =
        direction * (clampedDistance / GameBalance.joystickRadius);

    final controller = Provider.of<GameController>(context, listen: false);
    controller.setJoystickInput(normalized.dx, normalized.dy);
  }

  void _resetJoystick() {
    _activePointerId = null;
    setState(() {
      _joystickOrigin = null;
      _joystickCurrent = null;
    });

    final controller = Provider.of<GameController>(context, listen: false);
    controller.setJoystickInput(0.0, 0.0);
  }

  void _handlePointerUp(PointerUpEvent event) {
    if (event.pointer != _activePointerId) return;
    _resetJoystick();
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    if (event.pointer != _activePointerId) return;
    _resetJoystick();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<GameController>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF2C180B),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. World Canvas with Joystick Touch Listener (captures drags on the game arena only)
          Positioned.fill(
            child: Listener(
              onPointerDown: _handlePointerDown,
              onPointerMove: _handlePointerMove,
              onPointerUp: _handlePointerUp,
              onPointerCancel: _handlePointerCancel,
              behavior: HitTestBehavior.opaque,
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: WorldPainter(
                    world: controller.world,
                    cameraOffset: _cameraOffset,
                  ),
                  size: Size.infinite,
                ),
              ),
            ),
          ),

          // 2. Floating Virtual Joystick
          JoystickWidget(origin: _joystickOrigin, current: _joystickCurrent),

          // 3. Top HUD (Rupees & Carry Counter)
          IgnorePointer(
            child: HudOverlay(
              rupees: controller.rupees,
              carriedCount: controller.world.player.carriedCount,
              carryCapacity: controller.world.player.carryCapacity,
              showTutorial: !_hasMovedOnce,
            ),
          ),

          // 4. Left-Side Action Badges (HR & Upgrades, Goals, Settings)
          Positioned(
            left: 16,
            top: 0,
            bottom: 0,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildGlassIconButton(
                    icon: Icons.assignment_ind_rounded,
                    iconColor: AppTheme.goldYellow,
                    tooltip: 'HR & Upgrades',
                    onTap: () {
                      _resetJoystick();
                      HrUpgradeSheet.show(context, controller);
                    },
                  ),
                  const SizedBox(height: 14),
                  _buildGlassIconButton(
                    icon: Icons.emoji_events_rounded,
                    iconColor: const Color(0xFF00E676),
                    tooltip: 'Goals & Expansion',
                    onTap: () {
                      _resetJoystick();
                      GoalsOverlay.show(context, controller);
                    },
                  ),
                  const SizedBox(height: 14),
                  _buildGlassIconButton(
                    icon: Icons.settings_rounded,
                    iconColor: Colors.white,
                    tooltip: 'Settings',
                    onTap: () {
                      _resetJoystick();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text(
                            'Settings coming soon! ⚙️',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          backgroundColor: AppTheme.chaiDarkBrown,
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassIconButton({
    required IconData icon,
    required Color iconColor,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.chaiDarkBrown.withValues(alpha: 0.65),
            shape: BoxShape.circle,
            border: Border.all(
              color: iconColor.withValues(alpha: 0.45),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}
