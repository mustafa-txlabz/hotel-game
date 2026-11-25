import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/number_format.dart';
import '../../core/theme.dart';
import '../../data/city_shops_catalog.dart';
import '../../state/game_controller.dart';
import '../game/game_viewport.dart';
import '../widgets/banner_ad_widget.dart';

/// Interactive City Travel Map displaying all 10 franchise shops along a
/// scenic winding mountain highway.
///
/// - Shop 1 (Highway Kadak Dhaba) is live and playable.
/// - Shops 2–9 are unique themed previews (Fast Food, Sweets, Bakery, Ice Cream, etc.).
/// - Shop 10 is the colossal Grand Empire Supermarket at the mountain summit.
class CityMapScreen extends StatefulWidget {
  const CityMapScreen({super.key});

  @override
  State<CityMapScreen> createState() => _CityMapScreenState();
}

class _CityMapScreenState extends State<CityMapScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<BannerAdWidgetState> _bannerKey =
      GlobalKey<BannerAdWidgetState>();

  // Layout constants for the vertical scrollable map canvas
  static const double _topPadding = 160.0;
  static const double _shop10ExtraHeight = 200.0;
  static const double _rowHeight = 168.0;
  static const double _bottomPadding = 110.0;

  // 9 lower shops + Shop 10 summit
  static double get _mapHeight =>
      _topPadding + _shop10ExtraHeight + (9 * _rowHeight) + _bottomPadding;

  @override
  void initState() {
    super.initState();
    // Start scrolled at the bottom so Shop 1 (starting location) is in view,
    // allowing the player to scroll up the highway towards the Mountain Summit!
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Computes the Y center for a shop (1 = bottom, 10 = mountain summit).
  double _shopCenterY(int shopNumber) {
    if (shopNumber == 10) {
      return _topPadding + 95.0;
    }
    // Shop 9 is near top (below Shop 10), Shop 1 is near bottom
    final indexFromTop = 9 - shopNumber; // 0 for Shop 9, 8 for Shop 1
    return _topPadding + _shop10ExtraHeight + (indexFromTop * _rowHeight) + 72.0;
  }

  void _openShopPreview(
    BuildContext context,
    CityShopInfo shop,
    GameController controller,
  ) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ShopPreviewSheet(
        shop: shop,
        controller: controller,
        onEnterPlayableShop: () {
          Navigator.of(ctx).pop();
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (_, _, _) => const GameViewport(),
              transitionsBuilder: (_, animation, _, child) => FadeTransition(
                opacity: CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOut,
                ),
                child: child,
              ),
              transitionDuration: const Duration(milliseconds: 350),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<GameController>(context);
    final shops = CityShopsCatalog.shops;

    return Scaffold(
      backgroundColor: const Color(0xFF4CAF50),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
          // 1. Scrollable Scenic Road & 10 Shops Canvas
          SingleChildScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                return SizedBox(
                  width: width,
                  height: _mapHeight,
                  child: Stack(
                    children: [
                      // Scenic Sky, Mountains, Trees, and Winding Highway
                      CustomPaint(
                        painter: _ScenicHighwayPainter(
                          shopYCenters: List.generate(
                            10,
                            (i) => _shopCenterY(i + 1),
                          ),
                        ),
                        size: Size(width, _mapHeight),
                      ),

                      // Summit Banner Label above Shop 10
                      Positioned(
                        top: 96,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4A148C).withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppTheme.goldYellow,
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: const Text(
                              '⛰️ EMPIRE SUMMIT • GRAND FINALE',
                              style: TextStyle(
                                color: AppTheme.goldYellow,
                                fontWeight: FontWeight.w900,
                                fontSize: 11,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // 10 Shop Nodes placed along the road sides
                      for (final shop in shops)
                        _buildPositionedShopNode(
                          context,
                          shop,
                          width,
                          controller,
                        ),

                      // Foothills Starting Sign below Shop 1
                      Positioned(
                        bottom: 24,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2E170A).withValues(alpha: 0.88),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppTheme.saffronOrange,
                                width: 1.5,
                              ),
                            ),
                            child: const Text(
                              '🛣️ GT ROAD START • SCROLL UP TO EXPLORE 10 SHOPS ↑',
                              style: TextStyle(
                                color: AppTheme.cream,
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // 2. Floating Top App Bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  // Back Button
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E170A).withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppTheme.saffronOrange,
                        width: 1.8,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => Navigator.of(context).maybePop(),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Map Title Pill
                  Expanded(
                    child: Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E170A).withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppTheme.goldYellow.withValues(alpha: 0.7),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Text('🗺️', style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'CITY TRAVEL MAP',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                                letterSpacing: 0.8,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00C853).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFF00E676),
                                width: 1,
                              ),
                            ),
                            child: const Text(
                              '1/10 OPEN',
                              style: TextStyle(
                                color: Color(0xFF00E676),
                                fontWeight: FontWeight.w900,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
          ),
          // Bottom Full-Width AdMob Banner (Clean: collapses if no ad loaded)
          SafeArea(
            top: false,
            child: BannerAdWidget(key: _bannerKey),
          ),
        ],
      ),
    );
  }

  Widget _buildPositionedShopNode(
    BuildContext context,
    CityShopInfo shop,
    double canvasWidth,
    GameController controller,
  ) {
    final centerY = _shopCenterY(shop.number);

    // Shop 10 (Grand Empire Supermarket) is centered & grander at the summit
    if (shop.isSupermarket) {
      final cardWidth = math.min(280.0, canvasWidth - 36);
      return Positioned(
        top: centerY - 62,
        left: (canvasWidth - cardWidth) / 2,
        width: cardWidth,
        child: _ShopBuildingCard(
          shop: shop,
          controller: controller,
          onTap: () => _openShopPreview(context, shop, controller),
        ),
      );
    }

    // Shops 1–9 alternate left and right sides of the winding highway
    final isLeft = shop.number.isOdd;
    final cardWidth = math.min(182.0, (canvasWidth * 0.48));
    final leftPos = isLeft ? 14.0 : (canvasWidth - cardWidth - 14.0);

    return Positioned(
      top: centerY - 58,
      left: leftPos,
      width: cardWidth,
      child: _ShopBuildingCard(
        shop: shop,
        controller: controller,
        onTap: () => _openShopPreview(context, shop, controller),
      ),
    );
  }
}

/// Stylized 2.5D arcade shop building card placed on the map roadside.
class _ShopBuildingCard extends StatelessWidget {
  final CityShopInfo shop;
  final GameController controller;
  final VoidCallback onTap;

  const _ShopBuildingCard({
    required this.shop,
    required this.controller,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPlayable = shop.isPlayable;
    final isSupermarket = shop.isSupermarket;
    final rep = controller.world.reputationPercent;
    final isMastered = controller.world.isStoreMastered;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isPlayable
              ? const Color(0xFFFFFBF0)
              : isSupermarket
                  ? const Color(0xFFFFF8E1)
                  : const Color(0xFFF3EFE6),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isPlayable
                ? const Color(0xFF00E676)
                : isSupermarket
                    ? AppTheme.goldYellow
                    : Colors.white.withValues(alpha: 0.75),
            width: isPlayable || isSupermarket ? 2.4 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isPlayable
                  ? const Color(0xFF00E676).withValues(alpha: 0.35)
                  : isSupermarket
                      ? AppTheme.goldYellow.withValues(alpha: 0.45)
                      : Colors.black.withValues(alpha: 0.25),
              blurRadius: isPlayable || isSupermarket ? 14 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Striped Awning / Roof Header
            Container(
              height: isSupermarket ? 32 : 26,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: shop.roofColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(15),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '#${shop.number}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  Text(
                    isPlayable
                        ? (isMastered ? '⭐ MASTERED' : '🟢 OPEN')
                        : isSupermarket
                            ? '👑 MEGA MALL'
                            : '🔒 PREVIEW',
                    style: TextStyle(
                      color: isPlayable
                          ? const Color(0xFF69F0AE)
                          : isSupermarket
                              ? AppTheme.goldYellow
                              : Colors.white70,
                      fontWeight: FontWeight.w900,
                      fontSize: 9.5,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),

            // Shop Body
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Shop Icon Emblem
                      Container(
                        width: isSupermarket ? 46 : 38,
                        height: isSupermarket ? 46 : 38,
                        decoration: BoxDecoration(
                          color: shop.accentColor.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: shop.accentColor.withValues(alpha: 0.5),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          shop.emoji,
                          style: TextStyle(fontSize: isSupermarket ? 26 : 21),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              shop.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppTheme.chaiDarkBrown,
                                fontWeight: FontWeight.w900,
                                fontSize: isSupermarket ? 13 : 11.5,
                                height: 1.15,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              shop.category,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: shop.roofColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Live Reputation Progress for Playable Shop 1
                  if (isPlayable) ...[
                    const SizedBox(height: 7),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: (rep / 100.0).clamp(0.0, 1.0),
                        minHeight: 6,
                        backgroundColor: const Color(0xFFE0D7C6),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF00C853),
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Rep: ${rep.toStringAsFixed(0)}%',
                              style: const TextStyle(
                                color: Color(0xFF2E7D32),
                                fontWeight: FontWeight.w800,
                                fontSize: 9.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Text(
                              'PLAY ▶',
                              style: TextStyle(
                                color: AppTheme.saffronOrange,
                                fontWeight: FontWeight.w900,
                                fontSize: 9.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// CustomPainter rendering the sky gradient, layered snow-capped mountains,
/// roadside trees, and the winding highway connecting all 10 shops.
class _ScenicHighwayPainter extends CustomPainter {
  final List<double> shopYCenters;

  _ScenicHighwayPainter({required this.shopYCenters});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Scenic Sky -> Lush Valley -> Foothills Background Gradient
    final bgRect = Rect.fromLTWH(0, 0, w, h);
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        stops: [0.0, 0.11, 0.22, 0.65, 1.0],
        colors: [
          Color(0xFF4FC3F7), // Crisp mountain sky
          Color(0xFF81D4FA), // Horizon sky
          Color(0xFF66BB6A), // Highland meadow
          Color(0xFF43A047), // Valley green
          Color(0xFF388E3C), // GT Road plains
        ],
      ).createShader(bgRect);
    canvas.drawRect(bgRect, bgPaint);

    // 2. Warm Sun & Soft Clouds in Mountain Sky
    final sunPaint = Paint()..color = const Color(0xFFFFEB3B).withValues(alpha: 0.9);
    canvas.drawCircle(Offset(w * 0.82, 95), 34, sunPaint);
    final sunGlow = Paint()..color = const Color(0xFFFFF59D).withValues(alpha: 0.35);
    canvas.drawCircle(Offset(w * 0.82, 95), 50, sunGlow);

    _drawCloud(canvas, Offset(w * 0.22, 85), 1.0);
    _drawCloud(canvas, Offset(w * 0.62, 120), 0.78);

    // 3. Distant & Midground Layered Mountains
    _drawMountainRange(canvas, w);

    // 4. Compute Winding Road Control Points (Bottom Shop 1 -> Top Shop 10)
    final roadPoints = <Offset>[];
    // Start below Shop 1
    roadPoints.add(Offset(w * 0.5, h));
    for (int i = 0; i < shopYCenters.length; i++) {
      final shopNumber = i + 1;
      final y = shopYCenters[i];
      double x;
      if (shopNumber == 10) {
        x = w * 0.5;
      } else {
        // Gentle S-curve weaving opposite the shop sides
        x = shopNumber.isOdd ? w * 0.58 : w * 0.42;
      }
      roadPoints.add(Offset(x, y));
    }

    // Build smooth Bezier path along the road points
    final roadPath = Path()..moveTo(roadPoints.first.dx, roadPoints.first.dy);
    for (int i = 0; i < roadPoints.length - 1; i++) {
      final p0 = roadPoints[i];
      final p1 = roadPoints[i + 1];
      final midY = (p0.dy + p1.dy) / 2;
      roadPath.cubicTo(p0.dx, midY, p1.dx, midY, p1.dx, p1.dy);
    }

    // 5. Roadside Trees & Bushes (placed cleanly away from the road & cards)
    _drawRoadsideScenery(canvas, w, h);

    // 6. Draw Connector Sidewalks from Road to Each Shop Building
    final connectorPaint = Paint()
      ..color = const Color(0xFFD7CCC8)
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < shopYCenters.length - 1; i++) {
      final shopNumber = i + 1;
      final y = shopYCenters[i];
      final roadX = shopNumber.isOdd ? w * 0.58 : w * 0.42;
      final shopEdgeX = shopNumber.isOdd ? w * 0.28 : w * 0.72;
      canvas.drawLine(Offset(roadX, y), Offset(shopEdgeX, y), connectorPaint);
    }

    // 7. Draw Highway Road (Curb -> Asphalt -> Center Dashed Line)
    final curbPaint = Paint()
      ..color = const Color(0xFFBCAAA4)
      ..strokeWidth = 54
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(roadPath, curbPaint);

    final asphaltPaint = Paint()
      ..color = const Color(0xFF37474F)
      ..strokeWidth = 42
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(roadPath, asphaltPaint);

    // Dashed yellow center lane markings
    final dashPaint = Paint()
      ..color = const Color(0xFFFFD54F)
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (final metric in roadPath.computeMetrics()) {
      double distance = 0.0;
      const dashLen = 14.0;
      const gapLen = 14.0;
      while (distance < metric.length) {
        final next = math.min(distance + dashLen, metric.length);
        final segment = metric.extractPath(distance, next);
        canvas.drawPath(segment, dashPaint);
        distance += dashLen + gapLen;
      }
    }
  }

  void _drawCloud(Canvas canvas, Offset center, double scale) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.85);
    canvas.drawCircle(center, 18 * scale, paint);
    canvas.drawCircle(center + Offset(-16 * scale, 4 * scale), 13 * scale, paint);
    canvas.drawCircle(center + Offset(16 * scale, 4 * scale), 14 * scale, paint);
  }

  void _drawMountainRange(Canvas canvas, double w) {
    // Back Mountain Silhouette (Cool Slate Blue)
    final backPath = Path()
      ..moveTo(0, 290)
      ..lineTo(w * 0.18, 150)
      ..lineTo(w * 0.38, 235)
      ..lineTo(w * 0.56, 125)
      ..lineTo(w * 0.78, 220)
      ..lineTo(w * 0.94, 145)
      ..lineTo(w, 195)
      ..lineTo(w, 330)
      ..lineTo(0, 330)
      ..close();
    canvas.drawPath(backPath, Paint()..color = const Color(0xFF546E7A));

    // Snow Caps on Back Peaks
    final snowPaint = Paint()..color = Colors.white.withValues(alpha: 0.9);
    _drawSnowCap(canvas, Offset(w * 0.18, 150), 28, snowPaint);
    _drawSnowCap(canvas, Offset(w * 0.56, 125), 34, snowPaint);
    _drawSnowCap(canvas, Offset(w * 0.94, 145), 24, snowPaint);

    // Midground Green Foothills
    final midPath = Path()
      ..moveTo(0, 310)
      ..quadraticBezierTo(w * 0.25, 240, w * 0.5, 285)
      ..quadraticBezierTo(w * 0.78, 325, w, 255)
      ..lineTo(w, 380)
      ..lineTo(0, 380)
      ..close();
    canvas.drawPath(midPath, Paint()..color = const Color(0xFF2E7D32));
  }

  void _drawSnowCap(Canvas canvas, Offset peak, double size, Paint paint) {
    final cap = Path()
      ..moveTo(peak.dx, peak.dy)
      ..lineTo(peak.dx - size * 0.75, peak.dy + size)
      ..lineTo(peak.dx - size * 0.2, peak.dy + size * 0.75)
      ..lineTo(peak.dx, peak.dy + size * 0.95)
      ..lineTo(peak.dx + size * 0.25, peak.dy + size * 0.75)
      ..lineTo(peak.dx + size * 0.75, peak.dy + size)
      ..close();
    canvas.drawPath(cap, paint);
  }

  void _drawRoadsideScenery(Canvas canvas, double w, double h) {
    final treeTrunk = Paint()..color = const Color(0xFF5D4037);
    final pinePaint = Paint()..color = const Color(0xFF1B5E20);
    final lushPaint = Paint()..color = const Color(0xFF2E7D32);

    // Scatter scenic trees in the outer margins & center gaps
    for (double y = 370; y < h - 90; y += 115) {
      final isEven = ((y ~/ 115) % 2 == 0);
      final treeX = isEven ? w * 0.88 : w * 0.12;
      // Trunk
      canvas.drawRect(Rect.fromLTWH(treeX - 3, y, 6, 16), treeTrunk);
      // Foliage
      if (y < 900) {
        // Pine tree in upper highlands
        final pine = Path()
          ..moveTo(treeX, y - 26)
          ..lineTo(treeX - 15, y + 2)
          ..lineTo(treeX + 15, y + 2)
          ..close();
        canvas.drawPath(pine, pinePaint);
      } else {
        // Round roadside tree in lower valley
        canvas.drawCircle(Offset(treeX, y - 8), 15, lushPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ScenicHighwayPainter oldDelegate) => false;
}

/// Sleek bottom sheet displaying detailed preview info for any tapped shop.
class _ShopPreviewSheet extends StatelessWidget {
  final CityShopInfo shop;
  final GameController controller;
  final VoidCallback onEnterPlayableShop;

  const _ShopPreviewSheet({
    required this.shop,
    required this.controller,
    required this.onEnterPlayableShop,
  });

  @override
  Widget build(BuildContext context) {
    final world = controller.world;
    final isPlayable = shop.isPlayable;
    final isSupermarket = shop.isSupermarket;

    return Container(
      margin: const EdgeInsets.only(top: 60),
      decoration: const BoxDecoration(
        color: Color(0xFFFBF8EE),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Grab handle
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Header
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: shop.accentColor.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: shop.accentColor, width: 2),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      shop.emoji,
                      style: const TextStyle(fontSize: 30),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: shop.roofColor,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'SHOP #${shop.number}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              shop.category.toUpperCase(),
                              style: TextStyle(
                                color: shop.roofColor,
                                fontWeight: FontWeight.w800,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          shop.name,
                          style: const TextStyle(
                            color: AppTheme.chaiDarkBrown,
                            fontWeight: FontWeight.w900,
                            fontSize: 19,
                          ),
                        ),
                        Text(
                          shop.subtitle,
                          style: const TextStyle(
                            color: Color(0xFF795548),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppTheme.chaiDarkBrown,
                    ),
                  ),
                ],
              ),
              const Divider(height: 22, color: Color(0xFFE8DFCE)),

              // Description
              Text(
                shop.description,
                style: const TextStyle(
                  color: Color(0xFF4E342E),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),

              // Specialty Items Chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: shop.specialtyItems
                    .map(
                      (item) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: shop.accentColor.withValues(alpha: 0.45),
                          ),
                        ),
                        child: Text(
                          item,
                          style: const TextStyle(
                            color: AppTheme.chaiDarkBrown,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),

              // Playable Shop 1 Live Stats OR Locked Preview Banner
              if (isPlayable) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE0D7C6)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _statColumn(
                        '⭐ REPUTATION',
                        '${world.reputationPercent.toStringAsFixed(0)}%',
                      ),
                      _statColumn(
                        '💵 WALLET',
                        '₹${GameNumberFormat.format(world.rupees)}',
                      ),
                      _statColumn(
                        '💎 GEMS',
                        '${world.gems}',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: onEnterPlayableShop,
                    icon: const Icon(Icons.play_arrow_rounded, size: 26),
                    label: const Text(
                      'TRAVEL & PLAY',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        letterSpacing: 1.0,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00C853),
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSupermarket
                        ? const Color(0xFFFFF8E1)
                        : const Color(0xFFEDE7DC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSupermarket
                          ? AppTheme.goldYellow
                          : const Color(0xFFD7CCC8),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        isSupermarket ? '👑' : '🔒',
                        style: const TextStyle(fontSize: 22),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          isSupermarket
                              ? 'Grand Empire Supermarket will combine all 9 shops + mega groceries in a massive hall!'
                              : 'Shop Preview — Complete earlier locations to unlock this franchise in future updates!',
                          style: const TextStyle(
                            color: Color(0xFF5D4037),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFCFD8DC),
                      foregroundColor: const Color(0xFF455A64),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'COMING SOON • CLOSE PREVIEW',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _statColumn(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF8D6E63),
            fontWeight: FontWeight.w800,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.chaiDarkBrown,
            fontWeight: FontWeight.w900,
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}
