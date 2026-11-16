import 'package:material_ui/material_ui.dart';

/// Warm, friendly 2D cartoon dhaba theme with truck-art inspired accents.
class AppTheme {
  // Brand colors
  static const Color chaiBrown = Color(0xFF6F3C1A);
  static const Color chaiDarkBrown = Color(0xFF4A250E);
  static const Color cream = Color(0xFFFFF7E6);
  static const Color saffronOrange = Color(0xFFFF7A00);
  static const Color goldYellow = Color(0xFFFFC107);
  static const Color truckArtGreen = Color(0xFF00A859);
  static const Color truckArtRed = Color(0xFFD32F2F);
  static const Color truckArtCyan = Color(0xFF00ACC1);
  static const Color cardBg = Color(0xFFFFFDF8);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: chaiBrown,
        primary: chaiBrown,
        secondary: saffronOrange,
        tertiary: goldYellow,
        surface: cream,
      ),
      scaffoldBackgroundColor: cream,
      appBarTheme: const AppBarTheme(
        backgroundColor: chaiBrown,
        foregroundColor: cream,
        elevation: 2,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: saffronOrange, width: 1.5),
        ),
      ),
    );
  }
}
