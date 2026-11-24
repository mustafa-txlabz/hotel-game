import 'dart:async';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/strings.dart';
import '../../core/theme.dart';
import 'home_screen.dart';

/// Animated game splash & loading screen featuring custom App Icon,
/// dhaba cooking quotes, animated progress bar, and seamless entry into Home Screen.
class SplashScreen extends StatefulWidget {
  final Duration duration;
  final bool autoNavigate;

  const SplashScreen({
    super.key,
    this.duration = const Duration(milliseconds: 2200),
    this.autoNavigate = true,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progressController;
  late final Animation<double> _progressAnimation;
  Timer? _quoteTimer;
  int _currentQuoteIndex = 0;

  static const List<String> _loadingQuotes = [
    'Kadak Chai ubaal rahe hain... ☕',
    'Tawa garam ho raha hai... 🫓',
    'Masalay aur makkhan tayyar hain... 🔥',
    'VVIP table sajai ja rahi hai... ✨',
    'Dhaba khul raha hai... 🚪',
  ];

  @override
  void initState() {
    super.initState();

    _progressController = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _progressAnimation = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOutCubic,
    );

    _progressController.addListener(() {
      setState(() {});
    });

    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed && widget.autoNavigate && mounted) {
        _navigateToHome();
      }
    });

    // Cycle through dhaba loading quotes every 600ms
    _quoteTimer = Timer.periodic(const Duration(milliseconds: 600), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _currentQuoteIndex = (_currentQuoteIndex + 1) % _loadingQuotes.length;
      });
    });

    _progressController.forward();
  }

  void _navigateToHome() {
    HapticFeedback.selectionClick();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const HomeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _quoteTimer?.cancel();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _progressAnimation.value;

    return Scaffold(
      backgroundColor: const Color(0xFF1E0E06),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Ambient Background Gradient with stylized warm glow
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0.0, -0.2),
                radius: 1.2,
                colors: [
                  Color(0xFF3E1F0D),
                  Color(0xFF231006),
                  Color(0xFF140702),
                ],
              ),
            ),
          ),

          // 2. Subtle Dhaba Tiled Motif Overlay
          CustomPaint(
            painter: _SplashBackgroundMotifPainter(),
            size: Size.infinite,
          ),

          // 3. Main Center Branding & Loading Content
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 3),

                    // App Icon with pulsing golden halo
                    _buildPulsingAppIcon(),

                    const SizedBox(height: 28),

                    // Game Title & Tagline
                    _buildTitleSection(),

                    const Spacer(flex: 2),

                    // Dhaba Cooking Quote
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.0, 0.2),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      ),
                      child: Text(
                        _loadingQuotes[_currentQuoteIndex],
                        key: ValueKey<int>(_currentQuoteIndex),
                        style: const TextStyle(
                          color: AppTheme.cream,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Arcade Loading Progress Bar
                    _buildProgressBar(progress),

                    const SizedBox(height: 10),

                    // Percentage Text
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: const TextStyle(
                        color: AppTheme.saffronOrange,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),

                    const Spacer(flex: 1),

                    // Version Footer
                    const Text(
                      'v1.0.0 • Dhaba Arcade Tycoon',
                      style: TextStyle(
                        color: Color(0x66FFFFFF),
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPulsingAppIcon() {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.94, end: 1.0),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeInOut,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: Container(
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: AppTheme.goldYellow,
            width: 3.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.saffronOrange.withValues(alpha: 0.45),
              blurRadius: 28,
              spreadRadius: 4,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 16,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Image.asset(
            'assets/icon/app_icon_512.png',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              // Graceful fallback if asset file isn't loaded in test
              return Container(
                color: AppTheme.chaiDarkBrown,
                child: const Center(
                  child: Icon(
                    Icons.restaurant_rounded,
                    color: AppTheme.goldYellow,
                    size: 64,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTitleSection() {
    return Column(
      children: [
        // Bold 3D Stylized Title
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
      ],
    );
  }

  Widget _buildProgressBar(double progress) {
    return Container(
      width: 240,
      height: 12,
      decoration: BoxDecoration(
        color: const Color(0xFF2D160A),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: AppTheme.saffronOrange.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          FractionallySizedBox(
            widthFactor: progress.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4.5),
                gradient: const LinearGradient(
                  colors: [
                    AppTheme.saffronOrange,
                    AppTheme.goldYellow,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.goldYellow.withValues(alpha: 0.5),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Subtle vector background pattern for the splash screen
class _SplashBackgroundMotifPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x0CFFFFFF)
      ..strokeWidth = 1.0;

    const spacing = 45.0;
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
