import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/number_format.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../data/balance.dart';
import '../../state/game_controller.dart';
import '../widgets/business_tile.dart';
import '../widgets/cup_button.dart';
import '../widgets/floating_tap_overlay.dart';

/// Milestone M1 Dhaba (Home) screen:
/// - Real-time Rs counter and income rate (10 Hz delta time)
/// - Interactive cup tap mechanic with bounce and floating numbers
/// - First 3 businesses (Chai Thela, Paratha Stall, Roadside Dhaba)
class DhabaScreen extends StatefulWidget {
  const DhabaScreen({super.key});

  @override
  State<DhabaScreen> createState() => _DhabaScreenState();
}

class _DhabaScreenState extends State<DhabaScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Provider.of<GameController>(context, listen: false);
      controller.onMilestoneReached = _showMilestoneToast;
    });
  }

  void _showMilestoneToast(String businessName, int milestone) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.star_rounded, color: AppTheme.goldYellow),
            const SizedBox(width: 8),
            Text(
              '$businessName reached $milestone! ${AppStrings.milestoneReachedToast}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: AppTheme.chaiDarkBrown,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameController>(
      builder: (context, controller, child) {
        // Milestone M1 features the first 3 businesses
        final m1Businesses = GameBalance.allBusinesses.take(3).toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              AppStrings.appTitle,
              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5),
            ),
            elevation: 3,
          ),
          body: Stack(
            children: [
              SafeArea(
                child: Column(
                  children: [
                    // Top Currency & Income Dashboard
                    _buildHeaderDashboard(controller),

                    // Interactive Chai Cup Button
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: CupButton(onTap: (pos) => controller.tapCup(pos)),
                    ),

                    // Section Divider & Title
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 4.0,
                      ),
                      child: Row(
                        children: const [
                          Icon(
                            Icons.store_mall_directory_rounded,
                            color: AppTheme.chaiBrown,
                            size: 20,
                          ),
                          SizedBox(width: 6),
                          Text(
                            AppStrings.businessesSectionTitle,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.chaiDarkBrown,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // First 3 Businesses List
                    Expanded(
                      child: ListView.builder(
                        itemCount: m1Businesses.length,
                        padding: const EdgeInsets.only(bottom: 24),
                        itemBuilder: (context, index) {
                          return BusinessTile(
                            key: ValueKey(m1Businesses[index].id),
                            config: m1Businesses[index],
                            controller: controller,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Floating tap particle layer on top
              FloatingTapOverlay(particles: controller.particles),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeaderDashboard(GameController controller) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(14.0),
      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 14.0),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.saffronOrange, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.chaiDarkBrown.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Total Rupees Display
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: AppTheme.goldYellow,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.currency_rupee_rounded,
                  color: AppTheme.chaiDarkBrown,
                  size: 26,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${AppStrings.currencySymbol}${GameNumberFormat.format(controller.rupees)}',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.chaiDarkBrown,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Income Rate Display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.cream,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.truckArtGreen, width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.trending_up_rounded,
                  color: AppTheme.truckArtGreen,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  '${AppStrings.incomeRateLabel}: ${AppStrings.currencySymbol}${GameNumberFormat.formatRate(controller.totalIncomePerSecond)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.truckArtGreen,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
