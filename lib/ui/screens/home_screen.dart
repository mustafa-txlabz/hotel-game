import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/number_format.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../state/game_controller.dart';
import '../game/game_viewport.dart';

/// Main Menu / Home Screen for Dhaba Tycoon Empire.
/// Displays active store progress, wallet balances, store locations preview,
/// and primary entry point into the arcade game arena.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _enterDhabaArena(BuildContext context) {
    HapticFeedback.mediumImpact();
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const GameViewport(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<GameController>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF1E0E06),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Ambient Background Gradient with subtle warm radial center
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0.0, -0.3),
                radius: 1.3,
                colors: [
                  Color(0xFF381B0B),
                  Color(0xFF221006),
                  Color(0xFF130602),
                ],
              ),
            ),
          ),

          // 2. Pattern Motif
          CustomPaint(
            painter: _HomeMotifPainter(),
            size: Size.infinite,
          ),

          // 3. Main Screen UI Layout
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Column(
                children: [
                  // Top Header Row (Title Pill & Wallets)
                  _buildHeaderRow(context, controller),

                  const Spacer(flex: 1),

                  // Center Active Store Hero Card
                  _buildActiveStoreCard(context, controller),

                  const Spacer(flex: 2),

                  // Main Action Button: TAP TO ENTER DHABA
                  _buildPlayButton(context),

                  const SizedBox(height: 14),

                  // Secondary Action Row (Map / Locations & Settings)
                  _buildSecondaryActions(context),

                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderRow(BuildContext context, GameController controller) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Game Logo Pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.chaiDarkBrown,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.saffronOrange, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: const [
              Icon(
                Icons.restaurant_rounded,
                color: AppTheme.goldYellow,
                size: 18,
              ),
              SizedBox(width: 6),
              Text(
                AppStrings.appTitle,
                style: TextStyle(
                  color: AppTheme.cream,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),

        // Currency Badges (Cash & Gems)
        Row(
          children: [
            // Cash Wallet Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.truckArtGreen, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2.5),
                    decoration: const BoxDecoration(
                      color: AppTheme.truckArtGreen,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.currency_rupee_rounded,
                      color: Colors.white,
                      size: 13,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '${AppStrings.currencySymbol}${GameNumberFormat.format(controller.rupees)}',
                    style: const TextStyle(
                      color: AppTheme.chaiDarkBrown,
                      fontWeight: FontWeight.w900,
                      fontSize: 13.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 6),

            // Gems Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF00E5FF), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2.5),
                    decoration: const BoxDecoration(
                      color: Color(0xFF00B0FF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.diamond_rounded,
                      color: Colors.white,
                      size: 13,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    GameNumberFormat.format(controller.gems.toDouble()),
                    style: const TextStyle(
                      color: AppTheme.chaiDarkBrown,
                      fontWeight: FontWeight.w900,
                      fontSize: 13.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActiveStoreCard(BuildContext context, GameController controller) {
    final world = controller.world;
    final isMastered = world.isStoreMastered;
    final repPercent = world.reputationPercent;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF2B150A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isMastered ? AppTheme.goldYellow : AppTheme.saffronOrange,
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isMastered
                ? AppTheme.goldYellow.withValues(alpha: 0.3)
                : AppTheme.saffronOrange.withValues(alpha: 0.25),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Banner Top Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF3B1E0F),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(21)),
              border: Border(
                bottom: BorderSide(
                  color: AppTheme.saffronOrange.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
            ),
            child: Row(
              children: [
                // Store Icon Avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.chaiDarkBrown,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.goldYellow, width: 2),
                  ),
                  child: const Center(
                    child: Text(
                      '🏪',
                      style: TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Store Name & Location
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        world.progressionConfig.storeName,
                        style: const TextStyle(
                          color: AppTheme.cream,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'Location 1 • Grand Trunk Road Highway',
                        style: TextStyle(
                          color: Color(0xFFBCAAA4),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              children: [
                // Reputation Status Pill & Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1D0E06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isMastered ? const Color(0xFFFFD54F) : const Color(0xFF4CAF50),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isMastered ? '⭐ 100% STORE MASTERED' : '🔥 STORE REPUTATION',
                            style: TextStyle(
                              color: isMastered ? AppTheme.goldYellow : const Color(0xFF00E676),
                              fontWeight: FontWeight.w900,
                              fontSize: 11.5,
                              letterSpacing: 0.6,
                            ),
                          ),
                          Text(
                            '${repPercent.toStringAsFixed(1)}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Progress Bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (repPercent / 100.0).clamp(0.0, 1.0),
                          minHeight: 7,
                          backgroundColor: const Color(0xFF3E2723),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isMastered ? AppTheme.goldYellow : const Color(0xFF00E676),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Quick Equipment & Staff Stats Grid
                Row(
                  children: [
                    _buildStatPill('☕ Kettle', 'Lvl ${world.chaiStation.level}'),
                    const SizedBox(width: 8),
                    _buildStatPill(
                      '🫓 Paratha',
                      world.parathaStation.isUnlocked
                          ? 'Lvl ${world.parathaStation.level}'
                          : 'Locked',
                    ),
                    const SizedBox(width: 8),
                    _buildStatPill('👥 Staff', '${world.staff.length} Hired'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF1E0E06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.saffronOrange.withValues(alpha: 0.35),
            width: 1.2,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFFD7CCC8),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              style: const TextStyle(
                color: AppTheme.goldYellow,
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayButton(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF00E676),
            Color(0xFF00C853),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E676).withValues(alpha: 0.5),
            blurRadius: 18,
            spreadRadius: 2,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.6),
          width: 2.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _enterDhabaArena(context),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 38,
              ),
              SizedBox(width: 8),
              Text(
                'ENTER DHABA',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  letterSpacing: 1.5,
                  shadows: [
                    Shadow(
                      color: Colors.black54,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryActions(BuildContext context) {
    return Row(
      children: [
        // Map / Locations Button
        Expanded(
          flex: 2,
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFF3E1F0D),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.saffronOrange,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  HapticFeedback.selectionClick();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text(
                        '🗺️ City Travel Map coming in M13! Store 2 awaits!',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      backgroundColor: const Color(0xFF2E170A),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.map_rounded,
                      color: AppTheme.goldYellow,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'MAP & LOCATIONS',
                      style: TextStyle(
                        color: AppTheme.cream,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        const SizedBox(width: 10),

        // Settings Button
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0xFF3E1F0D),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.saffronOrange,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                HapticFeedback.selectionClick();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text(
                      '⚙️ Settings modal coming in M12!',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    backgroundColor: const Color(0xFF2E170A),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              },
              child: const Center(
                child: Icon(
                  Icons.settings_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Subtle vector background pattern for Home Screen
class _HomeMotifPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x0AFFFFFF)
      ..strokeWidth = 1.0;

    const spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
