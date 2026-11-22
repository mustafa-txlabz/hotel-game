import 'package:flutter/scheduler.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../data/balance.dart';
import '../../state/game_controller.dart';
import '../overlays/deal_popup.dart';
import '../overlays/goals_overlay.dart';
import '../overlays/hr_upgrade_sheet.dart';
import '../overlays/hud_overlay.dart';
import '../overlays/joystick_widget.dart';
import '../overlays/level_complete_dialog.dart';
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
  bool _hasShownMasteryCelebration = false;
  bool _isDealPopupOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = Provider.of<GameController>(context, listen: false);
    if (controller.world.isStoreMasteredCelebrated) {
      _hasShownMasteryCelebration = true;
    }
    controller.onDealRequested = (deal) {
      if (!_isDealPopupOpen && mounted) {
        _isDealPopupOpen = true;
        _resetJoystick();
        DealPopup.show(context, controller, deal).then((_) {
          _isDealPopupOpen = false;
        });
      }
    };
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

    // 2. Smooth camera follow (lerp towards cinematic target or player position)
    final Offset targetOffset;
    if (controller.world.cinematicCameraTarget != null) {
      final camTarget = controller.world.cinematicCameraTarget!;
      targetOffset = Offset(camTarget.x, camTarget.y);
    } else {
      final playerPos = controller.world.player.position;
      targetOffset = Offset(playerPos.x, playerPos.y);
    }

    setState(() {
      _cameraOffset = Offset.lerp(
        _cameraOffset,
        targetOffset,
        GameBalance.cameraLerpFactor,
      )!;
    });

    // 3. Trigger Store Mastery Victory Celebration (M8)
    if (controller.world.isStoreMastered && !_hasShownMasteryCelebration) {
      _hasShownMasteryCelebration = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _resetJoystick();
          LevelCompleteDialog.show(context, controller);
        }
      });
    }
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

          // 3. Top HUD (Rupees, Carry Counter & Store Reputation Bar)
          HudOverlay(
            rupees: controller.rupees,
            gems: controller.gems,
            carriedCount: controller.world.player.carriedCount,
            carryCapacity: controller.world.player.carryCapacity,
            reputationPercent: controller.world.reputationPercent,
            reputationLevel: controller.world.reputationLevel,
            onReputationTap: () {
              _resetJoystick();
              GoalsOverlay.show(context, controller);
            },
            showMasteryRewardBar:
                controller.world.isStoreMastered &&
                !controller.world.isMasteryRewardClaimed,
            masteryRewardBonus: controller.world.masteryRewardBonus,
            onClaimMasteryReward: () {
              _resetJoystick();
              controller.claimMasteryReward();
            },
            showTutorial: !_hasMovedOnce,
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
                  const SizedBox(height: 14),
                  // M10: Call VVIP Luxury Car Test/Trigger Button
                  _buildGlassIconButton(
                    icon: Icons.directions_car_filled_rounded,
                    iconColor: const Color(0xFF00E5FF),
                    tooltip: 'Call VVIP Car',
                    onTap: () {
                      _resetJoystick();
                      controller.world.spawnVipCar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text(
                            '🚗 VVIP Luxury Car arriving outside! 📯',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          backgroundColor: const Color(0xFF006064),
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    },
                  ),
                  // 4. M9: Special Deal Gift Badge OR Active Countdown Timer
                  if (controller.world.activeDeal != null) ...[
                    const SizedBox(height: 14),
                    _buildActiveDealTimerButton(context, controller),
                  ] else if (controller.world.isDealAvailable) ...[
                    const SizedBox(height: 14),
                    _buildDealGiftButton(context, controller),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDealGiftButton(BuildContext context, GameController controller) {
    return Tooltip(
      message: 'Special Deal 🎁',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          _resetJoystick();
          final deal = controller.world.availableDeal;
          if (deal != null) {
            DealPopup.show(context, controller, deal);
          }
        },
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF2C1E14).withValues(alpha: 0.90),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppTheme.goldYellow,
              width: 2.0,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.goldYellow.withValues(alpha: 0.5),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(
                Icons.card_giftcard_rounded,
                color: AppTheme.goldYellow,
                size: 24,
              ),
              Positioned(
                top: 2,
                right: 2,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E676),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'FREE',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w900,
                      fontSize: 6.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveDealTimerButton(
    BuildContext context,
    GameController controller,
  ) {
    final deal = controller.world.activeDeal;
    if (deal == null) return const SizedBox.shrink();

    final total = controller.world.activeDealTotalSeconds > 0
        ? controller.world.activeDealTotalSeconds
        : 1.0;
    final progress =
        (controller.world.activeDealRemainingSeconds / total).clamp(0.0, 1.0);
    final remainingSecs =
        controller.world.activeDealRemainingSeconds.ceil().clamp(0, 999);

    return Tooltip(
      message: '${deal.title} (${remainingSecs}s)',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          _resetJoystick();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${deal.title} Active! (${remainingSecs}s remaining)',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              backgroundColor: AppTheme.chaiDarkBrown,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        },
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF1E140C).withValues(alpha: 0.92),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00E676).withValues(alpha: 0.35),
                blurRadius: 8,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Circular countdown green border
              SizedBox(
                width: 46,
                height: 46,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 3.5,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF00E676),
                  ),
                  backgroundColor: Colors.white10,
                ),
              ),
              // Inside: Icon & Remaining Seconds
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    deal.iconEmoji,
                    style: const TextStyle(fontSize: 14),
                  ),
                  Text(
                    '${remainingSecs}s',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 8.5,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
