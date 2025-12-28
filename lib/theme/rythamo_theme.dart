import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:catppuccin_flutter/catppuccin_flutter.dart';

enum RythamoThemeMode {
  latte,
  frappe,
  macchiato,
  mocha,
}

class RythamoColors {
  // SHARED / UTILS
  static const Color salmonOrange = Color(0xFFFF6B6B); // Keep for brand identity if needed, or replace with Catppuccin Red/Peach
  static const Color mintGreen = Color(0xFFB8E0C3); // Keep or replace with Catppuccin Green/Teal
  static const Color darkCharcoalText = Color(0xFF1C1C1E);
}

class RythamoTypography {
  // ============ GOLDEN RATIO TYPOGRAPHY SCALE ============
  // Base: 16px, Ratio: φ ≈ 1.618
  // Scale: 10 → 16 → 26 → 42 → 68
  static const double _phi = 1.618;
  static const double _baseSize = 16.0;
  
  // Caption: Small labels, hints (10px)
  static double get captionSize => _baseSize / _phi;  // ~9.9px
  // Body: Default reading text (16px)
  static double get bodySize => _baseSize;            // 16px
  // Subhead: Section headers, important labels (26px)
  static double get subheadSize => _baseSize * _phi;  // ~25.9px
  // Headline: Main headings (42px)
  static double get headlineSize => _baseSize * _phi * _phi;  // ~41.9px
  // Display: Hero text, greeting names (68px)
  static double get displaySize => _baseSize * _phi * _phi * _phi;  // ~67.8px

  // Golden Ratio Text Styles
  static TextStyle grCaption(Color color) => GoogleFonts.inter(
    fontSize: captionSize,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.5,
    color: color.withOpacity(0.6),
  );

  static TextStyle grBody(Color color) => GoogleFonts.inter(
    fontSize: bodySize,
    fontWeight: FontWeight.w400,
    color: color,
  );

  static TextStyle grSubhead(Color color) => GoogleFonts.outfit(
    fontSize: subheadSize,
    fontWeight: FontWeight.w600,
    color: color,
  );

  static TextStyle grHeadline(Color color) => GoogleFonts.outfit(
    fontSize: headlineSize,
    fontWeight: FontWeight.bold,
    color: color,
    height: 1.1,
  );

  static TextStyle grDisplay(Color color) => GoogleFonts.outfit(
    fontSize: displaySize,
    fontWeight: FontWeight.bold,
    color: color,
    height: 1.0,
  );

  // ============ LEGACY STYLES (kept for backward compatibility) ============
  static TextStyle get header => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
        color: Colors.white.withOpacity(0.6),
      );

  static TextStyle get metricBig => GoogleFonts.outfit(
        fontSize: 48,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      );

  static TextStyle get body => GoogleFonts.inter(
        fontSize: 18,
        color: Colors.white,
      );
      
  static TextStyle get buttonText => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: RythamoColors.darkCharcoalText,
  );

  static TextStyle get handwriting => GoogleFonts.indieFlower(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  static TextStyle get funnyHeader => GoogleFonts.amaticSc(
    fontSize: 40,
    fontWeight: FontWeight.bold,
    letterSpacing: 1.2,
    color: Colors.white,
  );
  
  // Dynamic getters based on color
  static TextStyle headerDynamic(Color color) => header.copyWith(color: color.withOpacity(0.6));
  static TextStyle metricBigDynamic(Color color) => metricBig.copyWith(color: color);
  static TextStyle bodyDynamic(Color color) => body.copyWith(color: color);
  static TextStyle handwritingDynamic(Color color) => handwriting.copyWith(color: color);
  static TextStyle funnyHeaderDynamic(Color color) => funnyHeader.copyWith(color: color);
}

class RythamoTheme {
  static ThemeData getTheme(RythamoThemeMode mode) {
    Flavor flavor;
    switch (mode) {
      case RythamoThemeMode.latte:
        flavor = catppuccin.latte;
        break;
      case RythamoThemeMode.frappe:
        flavor = catppuccin.frappe;
        break;
      case RythamoThemeMode.macchiato:
        flavor = catppuccin.macchiato;
        break;
      case RythamoThemeMode.mocha:
      default:
        flavor = catppuccin.mocha;
        break;
    }

    return _buildTheme(flavor, mode == RythamoThemeMode.latte);
  }

  static ThemeData _buildTheme(Flavor flavor, bool isLight) {
    final textColor = flavor.text;
    final surfaceColor = flavor.surface0;
    final backgroundColor = flavor.base;
    final primaryColor = flavor.mauve;

    return ThemeData(
      scaffoldBackgroundColor: backgroundColor,
      primaryColor: primaryColor,
      brightness: isLight ? Brightness.light : Brightness.dark,
      cardColor: surfaceColor,
      textTheme: TextTheme(
        displayLarge: RythamoTypography.metricBigDynamic(textColor),
        bodyLarge: RythamoTypography.bodyDynamic(textColor),
        labelSmall: RythamoTypography.headerDynamic(textColor),
      ),
      useMaterial3: true,
      // Add color scheme to help widgets automatically adapt
      colorScheme: ColorScheme(
        brightness: isLight ? Brightness.light : Brightness.dark,
        primary: primaryColor,
        onPrimary: flavor.crust,
        secondary: flavor.pink,
        onSecondary: flavor.crust,
        error: flavor.red,
        onError: flavor.crust,
        surface: surfaceColor,
        onSurface: textColor,
      ),
    );
  }
}
