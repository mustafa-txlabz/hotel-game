import 'package:material_ui/material_ui.dart';

import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../services/legal_links.dart';
import '../../state/game_controller.dart';

/// Settings modal dialog for audio toggles, legal links, and data management (M12).
class SettingsDialog extends StatelessWidget {
  final GameController controller;

  const SettingsDialog({super.key, required this.controller});

  static Future<void> show(BuildContext context, GameController controller) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (ctx) => SettingsDialog(controller: controller),
    );
  }

  void _showResetConfirmation(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF220E05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFFFF5252), width: 2),
        ),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFFF5252), size: 28),
            SizedBox(width: 8),
            Text(
              'RESET PROGRESS?',
              style: TextStyle(
                color: Color(0xFFFF5252),
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: const Text(
          'This will permanently reset your Dhaba wallet, gems, reputation, and equipment levels back to Level 1. This action cannot be undone.',
          style: TextStyle(color: AppTheme.cream, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('CANCEL', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5252),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await controller.resetAllProgress();
              if (context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Game progress reset to Level 1! ✨'),
                    backgroundColor: const Color(0xFF2E170A),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text(
              'RESET',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440),
        decoration: BoxDecoration(
          color: const Color(0xFF1E0E06),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: AppTheme.saffronOrange, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(23),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Header with Title & Close button
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF381B0B), Color(0xFF221006)],
                  ),
                  border: Border(
                    bottom: BorderSide(color: Color(0xFF4A2510), width: 1.5),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.settings_rounded,
                      color: AppTheme.goldYellow,
                      size: 26,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'SETTINGS',
                        style: TextStyle(
                          color: AppTheme.goldYellow,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Colors.white70,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Scrollable Settings Body
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section A: Audio & Haptics
                      _buildSectionHeader('AUDIO & CONTROLS', Icons.volume_up_rounded),
                      const SizedBox(height: 10),
                      _buildToggleTile(
                        icon: Icons.music_note_rounded,
                        title: 'Sound Effects (SFX)',
                        subtitle: 'Kettle, tawa, coins, and horn audio',
                        value: controller.isSoundEnabled,
                        onChanged: (val) => controller.toggleSound(),
                      ),
                      const SizedBox(height: 10),
                      _buildToggleTile(
                        icon: Icons.vibration_rounded,
                        title: 'Haptic Feedback',
                        subtitle: 'Tactile vibration on taps and actions',
                        value: controller.isHapticsEnabled,
                        onChanged: (val) => controller.toggleHaptics(),
                      ),

                      const SizedBox(height: 22),

                      // Section B: Legal & Privacy
                      _buildSectionHeader('LEGAL & PRIVACY', Icons.gavel_rounded),
                      const SizedBox(height: 10),
                      _buildActionTile(
                        icon: Icons.lock_outline_rounded,
                        title: 'Privacy Policy',
                        subtitle: 'AdMob and local storage disclosures',
                        urlBadge: LegalLinks.privacyPolicyUrl,
                        onTap: () {
                          LegalLinks.openLegalPage(
                            context,
                            title: 'Privacy Policy',
                            url: LegalLinks.privacyPolicyUrl,
                            iconEmoji: '🔒',
                            bulletPoints: const [
                              'No personal identifying information (name, address, phone) is collected to play.',
                              'Game progress, Rupees, and Gems are stored locally on your device via SharedPreferences.',
                              'Google AdMob processes anonymous advertising identifiers (GAID) for safe banner and rewarded ads.',
                              'Family-friendly gameplay compliant with COPPA and Google Play Families policy.',
                              'You can delete all local data anytime via the Reset Progress button.',
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      _buildActionTile(
                        icon: Icons.description_outlined,
                        title: 'Terms of Use',
                        subtitle: 'Gameplay rules & virtual economy terms',
                        urlBadge: LegalLinks.termsOfUseUrl,
                        onTap: () {
                          LegalLinks.openLegalPage(
                            context,
                            title: 'Terms of Use',
                            url: LegalLinks.termsOfUseUrl,
                            iconEmoji: '📜',
                            bulletPoints: const [
                              'Personal, non-transferable license to play for entertainment purposes.',
                              'In-game Rupees (₹) and Gems (💎) are fictional virtual items with zero real-world cash value.',
                              'Virtual currency cannot be redeemed, traded, or refunded for real money.',
                              'All game art, sound, and arcade idle mechanics are the intellectual property of Chai Dhaba Empire.',
                              'Rewarded power-ups require successful ad completion to activate.',
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      _buildActionTile(
                        icon: Icons.help_outline_rounded,
                        title: 'Help & Player Support',
                        subtitle: 'FAQs and feedback contact',
                        urlBadge: LegalLinks.supportUrl,
                        onTap: () {
                          LegalLinks.openLegalPage(
                            context,
                            title: 'Support & FAQs',
                            url: LegalLinks.supportUrl,
                            iconEmoji: '💬',
                            bulletPoints: const [
                              'VVIP Cars arrive every 3–4 minutes with 3 Gems (💎) reward per completed party order.',
                              'Audio and haptic settings persist automatically across game restarts.',
                              'Game automatically auto-saves every 5 seconds and after every transaction.',
                              'Contact support anytime at: ${LegalLinks.supportEmail}',
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 22),

                      // Section C: About Game & Version
                      _buildSectionHeader('ABOUT GAME', Icons.info_outline_rounded),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF281308),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFF45220E)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              AppStrings.appTitle,
                              style: TextStyle(
                                color: AppTheme.goldYellow,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Version 1.0.0 (Build 1) • Release Candidate\nPackage: com.chaidhaba.chai_dhaba_empire\nDeveloper: Chai Dhaba Empire',
                              style: TextStyle(
                                color: AppTheme.cream,
                                fontSize: 11,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 22),

                      // Section D: Danger Zone (Reset Progress)
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFFF5252),
                            side: const BorderSide(color: Color(0xFFFF5252)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(Icons.restart_alt_rounded, size: 20),
                          label: const Text(
                            'RESET GAME PROGRESS',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              letterSpacing: 1.0,
                            ),
                          ),
                          onPressed: () => _showResetConfirmation(context),
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
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.saffronOrange),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            color: AppTheme.saffronOrange,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildToggleTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF281308),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF45220E)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: value
                  ? AppTheme.saffronOrange.withValues(alpha: 0.2)
                  : Colors.white10,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 20,
              color: value ? AppTheme.goldYellow : Colors.white38,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeTrackColor: AppTheme.saffronOrange,
            activeThumbColor: AppTheme.goldYellow,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required String urlBadge,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF281308),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF45220E)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: AppTheme.cream),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  urlBadge,
                  style: const TextStyle(
                    color: AppTheme.goldYellow,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right_rounded, color: Colors.white38, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
