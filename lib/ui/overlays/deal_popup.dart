import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';
import '../../engine/deals.dart';
import '../../services/ads_service.dart';
import '../../state/game_controller.dart';

/// Modal dialog displaying special Dhaba power-up deals with an animated gift box
/// and a green "WATCH AD & CLAIM" button.
class DealPopup extends StatefulWidget {
  final GameController controller;
  final DhabaDeal deal;

  const DealPopup({
    super.key,
    required this.controller,
    required this.deal,
  });

  /// Displays the deal popup modal.
  static Future<void> show(
    BuildContext context,
    GameController controller,
    DhabaDeal deal,
  ) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (ctx) => DealPopup(controller: controller, deal: deal),
    );
  }

  @override
  State<DealPopup> createState() => _DealPopupState();
}

class _DealPopupState extends State<DealPopup>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _bounceAnimation;
  late final Animation<double> _glowAnimation;

  bool _isClaiming = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(begin: -6.0, end: 6.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOutSine),
    );

    _glowAnimation = Tween<double>(begin: 0.35, end: 0.85).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onClaim() {
    if (_isClaiming) return;
    setState(() => _isClaiming = true);

    AdsService.instance.showRewardedAd(
      onUserEarnedReward: () {
        if (!mounted) return;
        widget.controller.claimDeal(widget.deal);
        Navigator.of(context, rootNavigator: true).pop();
      },
      onAdDismissed: () {
        if (mounted) {
          setState(() => _isClaiming = false);
        }
      },
      onAdFailed: () {
        if (mounted) {
          setState(() => _isClaiming = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Video ad not ready. Please check your internet connection! 📶',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              backgroundColor: AppTheme.chaiDarkBrown,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 3),
            ),
          );
        }
      },
    );
  }

  void _onDismiss() {
    widget.controller.dismissDeal();
    Navigator.of(context, rootNavigator: true).pop();
  }

  @override
  Widget build(BuildContext context) {
    final deal = widget.deal;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 320,
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: const Color(0xFF2C1E14), // Dhaba Dark Wood theme
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppTheme.goldYellow,
              width: 2.2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.goldYellow.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Bar with Title and Close Button
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(
                        color: AppTheme.saffronOrange,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.local_fire_department_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'SPECIAL DHABA DEAL',
                        style: TextStyle(
                          color: AppTheme.goldYellow,
                          fontWeight: FontWeight.w900,
                          fontSize: 14.0,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white70),
                      splashRadius: 18,
                      onPressed: _onDismiss,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Animated Center Gift Box / Reward Icon
              AnimatedBuilder(
                animation: _animController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _bounceAnimation.value),
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppTheme.goldYellow.withValues(
                              alpha: _glowAnimation.value,
                            ),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Center(
                        child: Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E140C),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.goldYellow,
                              width: 2.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.goldYellow.withValues(
                                  alpha: 0.4,
                                ),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              deal.iconEmoji,
                              style: const TextStyle(fontSize: 34),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 12),

              // Deal Title & Duration Badge
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    Text(
                      deal.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (deal.durationSeconds > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.saffronOrange.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.saffronOrange,
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.timer_outlined,
                              color: AppTheme.goldYellow,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${deal.durationSeconds} SECONDS BOOST',
                              style: const TextStyle(
                                color: AppTheme.goldYellow,
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 10),
                    Text(
                      deal.description,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFD7CCC8),
                        fontSize: 12.5,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Bottom Big Vibrant Green Button: WATCH AD & CLAIM
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: GestureDetector(
                  onTap: _isClaiming ? null : _onClaim,
                  child: Container(
                    width: double.infinity,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00E676), Color(0xFF00C853)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00E676).withValues(alpha: 0.45),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.videocam_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'WATCH AD & CLAIM',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
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
}
