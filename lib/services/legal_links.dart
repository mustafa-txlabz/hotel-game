import 'package:material_ui/material_ui.dart';
import '../core/theme.dart';

/// Configuration for Legal, Terms, and Support URLs.
///
/// NOTE FOR OWNER:
/// Deploy the files in `web_legal/` to Vercel (or any web host),
/// then paste your live deployed URLs here.
/// Currently defaulted to `#` as requested.
class LegalLinks {
  LegalLinks._();

  /// Vercel or live web URL for Privacy Policy (default `#`)
  static const String privacyPolicyUrl = '#';

  /// Vercel or live web URL for Terms of Use (default `#`)
  static const String termsOfUseUrl = '#';

  /// Vercel or live web URL for Help & Support (default `#`)
  static const String supportUrl = '#';

  /// Contact email for user support
  static const String supportEmail = 'support@chaidhaba.com';

  /// Opens the legal document viewer or external link.
  static void openLegalPage(
    BuildContext context, {
    required String title,
    required String url,
    required String iconEmoji,
    required List<String> bulletPoints,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _LegalDocSheet(
        title: title,
        url: url,
        iconEmoji: iconEmoji,
        bulletPoints: bulletPoints,
      ),
    );
  }
}

class _LegalDocSheet extends StatelessWidget {
  final String title;
  final String url;
  final String iconEmoji;
  final List<String> bulletPoints;

  const _LegalDocSheet({
    required this.title,
    required this.url,
    required this.iconEmoji,
    required this.bulletPoints,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.75,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF1E0E06),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: AppTheme.saffronOrange, width: 2.0),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 18.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top drag bar
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title Header
              Row(
                children: [
                  Text(
                    iconEmoji,
                    style: const TextStyle(fontSize: 26),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title.toUpperCase(),
                      style: const TextStyle(
                        color: AppTheme.goldYellow,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              // URL badge indicator
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.saffronOrange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.saffronOrange.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.link_rounded, size: 14, color: AppTheme.goldYellow),
                    const SizedBox(width: 6),
                    Text(
                      'Linked URL: $url',
                      style: const TextStyle(
                        color: AppTheme.cream,
                        fontSize: 11,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Summary bullets
              Expanded(
                child: ListView.separated(
                  itemCount: bulletPoints.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '• ',
                          style: TextStyle(
                            color: AppTheme.goldYellow,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            bulletPoints[index],
                            style: const TextStyle(
                              color: AppTheme.cream,
                              fontSize: 13,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),

              // Owner Note
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white12),
                ),
                child: const Text(
                  '💡 Note for Owner: Complete HTML version is located in web_legal/ ready for instant Vercel deployment. Update links in legal_links.dart anytime.',
                  style: TextStyle(
                    color: Color(0x99FFFFFF),
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 14),

              // Close Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.saffronOrange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'GOT IT',
                    style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2),
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
