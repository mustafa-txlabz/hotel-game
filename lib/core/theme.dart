import 'package:material_ui/material_ui.dart';

/// Dhaba cartoon color palette and styling for Arcade Idle.
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

  // Floor & Arena Colors
  static const Color floorTileLight = Color(0xFFF3DEC8);
  static const Color floorTileDark = Color(0xFFE5CCB3);
  static const Color wallBrickColor = Color(0xFF8B4513);
  static const Color wallCapColor = Color(0xFF5C2B09);

  // Character Colors
  static const Color characterSkin = Color(0xFFFFCC80);
  static const Color characterApron = Color(0xFFD32F2F);
  static const Color characterShirt = Color(0xFFFFFFFF);
  static const Color characterCap = Color(0xFFD32F2F);
  static const Color characterShadow = Color(0x33000000);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: chaiBrown,
        primary: chaiBrown,
        secondary: saffronOrange,
        surface: cream,
      ),
      scaffoldBackgroundColor: const Color(
        0xFF2C180B,
      ), // Dark surround outside world
    );
  }
}
