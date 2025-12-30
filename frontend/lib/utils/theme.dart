import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Core Colors
  static const Color primary = Color(0xFF7C3AED);    // Purple #7c3aed
  static const Color secondary = Color(0xFF06B6D4);  // Cyan #06b6d4
  static const Color accent = Color(0xFFEC4899);     // Pink #ec4899
  static const Color background = Color(0xFF0F0F23); // Deep space #0f0f23
  static const Color cardBackground = Color(0xFF1A1A2E); // Card bg #1a1a2e
  static const Color textPrimary = Color(0xFFF2F2F2); // Primary text #f2f2f2
  static const Color textMuted = Color(0xFF7A7A8F);   // Muted text #7a7a8f
  static const Color border = Color(0xFF3E3E4E);     // Border #3e3e4e
  static const Color success = Color(0xFF10B981);    // Green #10b981
  static const Color warning = Color(0xFFF59E0B);    // Yellow #f59e0b

  // Aliases for backward compatibility
  static Color get backgroundColor => background;
  static Color get primaryColor => primary;
  static Color get mutedColor => textMuted;

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, accent],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient cosmicGradient = LinearGradient(
    colors: [background, cardBackground],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Shadows
  static const BoxShadow glowShadow = BoxShadow(
    color: primary,
    blurRadius: 20,
    spreadRadius: 0,
  );

  // Typography
  static TextTheme get textTheme => GoogleFonts.interTextTheme().copyWith(
    displayLarge: GoogleFonts.pressStart2p(
      fontSize: 32,
      color: textPrimary,
      letterSpacing: -0.5,
    ),
    headlineLarge: GoogleFonts.pressStart2p(
      fontSize: 24,
      color: textPrimary,
    ),
    bodyLarge: GoogleFonts.inter(
      fontSize: 16,
      color: textPrimary,
    ),
    bodyMedium: GoogleFonts.spaceMono(
      fontSize: 14,
      color: textMuted,
    ),
  );

  // Component Themes
  static CardThemeData get cardTheme => CardThemeData(
    color: cardBackground,
    shadowColor: primary.withValues(alpha: 0.3),
    elevation: 8,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
  );

  static ButtonThemeData get buttonTheme => ButtonThemeData(
    buttonColor: primary,
    textTheme: ButtonTextTheme.primary,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  );

  // App Theme
  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: background,
    cardTheme: cardTheme,
    buttonTheme: buttonTheme,
    textTheme: textTheme,
    colorScheme: const ColorScheme.dark(
      primary: primary,
      secondary: secondary,
      surface: cardBackground,
      error: Colors.redAccent,
      onPrimary: textPrimary,
      onSecondary: textPrimary,
      onSurface: textPrimary,
      onError: textPrimary,
    ),
  );
}
