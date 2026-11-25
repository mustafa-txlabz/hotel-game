import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../state/game_controller.dart';
import '../game/game_viewport.dart';
import '../overlays/settings_dialog.dart';
import '../widgets/banner_ad_widget.dart';
import 'city_map_screen.dart';

/// Clean, punchy Main Menu / Home Screen for Dhaba Tycoon Empire.
/// Features central PLAY button and MAP button with game branding,
/// and full-width bottom AdMob banner with auto-refresh on route return.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<BannerAdWidgetState> _bannerKey =
      GlobalKey<BannerAdWidgetState>();

  Future<void> _enterDhabaArena(BuildContext context) async {
    HapticFeedback.mediumImpact();
    await Navigator.of(context).push(
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
    // Refresh banner when returning from Dhaba arena
    _bannerKey.currentState?.refreshAd();
  }

  Future<void> _openSettings(BuildContext context) async {
    HapticFeedback.selectionClick();
    final controller = Provider.of<GameController>(context, listen: false);
    await SettingsDialog.show(context, controller);
    _bannerKey.currentState?.refreshAd();
  }

  Future<void> _openMap(BuildContext context) async {
    HapticFeedback.mediumImpact();
    await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const CityMapScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
    // Refresh banner when returning from City Map
    _bannerKey.currentState?.refreshAd();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E0E06),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Ambient Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0.0, -0.2),
                radius: 1.3,
                colors: [
                  Color(0xFF381B0B),
                  Color(0xFF221006),
                  Color(0xFF130602),
                ],
              ),
            ),
          ),

          // 2. Subtle Dhaba Tiled Pattern
          CustomPaint(
            painter: _HomeMotifPainter(),
            size: Size.infinite,
          ),

          // 3. Top-Right Settings Shortcut
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 12.0, right: 16.0),
                child: Container(
                  width: 48,
                  height: 48,
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
                      onTap: () => _openSettings(context),
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
              ),
            ),
          ),

          // 4. Centered Content + Bottom Full-Width Banner Ad
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Spacer(flex: 3),

                          // App Logo Icon with warm gold glow
                          Container(
                            width: 124,
                            height: 124,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: AppTheme.goldYellow,
                                width: 3.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.saffronOrange.withValues(alpha: 0.4),
                                  blurRadius: 26,
                                  spreadRadius: 3,
                                  offset: const Offset(0, 8),
                                ),
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  blurRadius: 14,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(26),
                              child: Image.asset(
                                'assets/icon/app_icon_512.png',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: AppTheme.chaiDarkBrown,
                                    child: const Center(
                                      child: Icon(
                                        Icons.restaurant_rounded,
                                        color: AppTheme.goldYellow,
                                        size: 56,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),

                          const SizedBox(height: 22),

                          // Game Title
                          Text(
                            AppStrings.appTitle.toUpperCase(),
                            style: const TextStyle(
                              color: AppTheme.goldYellow,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                              shadows: [
                                Shadow(
                                  color: Colors.black87,
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 6),

                          // Subtitle Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.saffronOrange.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.saffronOrange.withValues(alpha: 0.6),
                                width: 1.2,
                              ),
                            ),
                            child: const Text(
                              'ARCADE IDLE TYCOON',
                              style: TextStyle(
                                color: AppTheme.cream,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2.0,
                              ),
                            ),
                          ),

                          // Compact gap: lifts PLAY & MAP buttons closer to badge
                          const Spacer(flex: 1),

                          // Big Juicy Green PLAY Button (lifted higher)
                          _buildPlayButton(context),

                          const SizedBox(height: 14),

                          // Amber/Gold MAP Button
                          _buildMapButton(context),

                          const Spacer(flex: 2),

                          // Version Footer
                          const Text(
                            'v1.0.0 • Dhaba Arcade Tycoon',
                            style: TextStyle(
                              color: Color(0x66FFFFFF),
                              fontSize: 11,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                        ],
                      ),
                    ),
                  ),
                ),

                // 5. Full Mobile Width AdMob Banner Ad (Clean: zero space if no ad loaded)
                BannerAdWidget(key: _bannerKey),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayButton(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 66,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
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
          color: Colors.white.withValues(alpha: 0.65),
          width: 2.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => _enterDhabaArena(context),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 42,
              ),
              SizedBox(width: 8),
              Text(
                'PLAY',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 24,
                  letterSpacing: 2.0,
                  shadows: [
                    Shadow(
                      color: Colors.black54,
                      blurRadius: 6,
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

  Widget _buildMapButton(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFFB300),
            Color(0xFFFFA000),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFB300).withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.6),
          width: 2.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _openMap(context),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(
                Icons.map_rounded,
                color: Color(0xFF3E1F0D),
                size: 26,
              ),
              SizedBox(width: 8),
              Text(
                'MAP',
                style: TextStyle(
                  color: Color(0xFF3E1F0D),
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
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
