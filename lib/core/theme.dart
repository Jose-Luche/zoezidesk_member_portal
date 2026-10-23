import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand colors — ZoeziDesk "energy orange" dark theme
  static const Color brand      = Color(0xFFF97316);
  static const Color brandLight = Color(0xFFFB923C);
  static const Color brandSoft  = Color(0x33F97316); // brand at 20% over dark bg
  static const Color onBrand    = Color(0xFF0F172A); // dark text on orange (white fails contrast)
  static const Color success    = Color(0xFF22C55E);
  static const Color danger     = Color(0xFFEF4444);
  static const Color warning    = Color(0xFFF59E0B);
  static const Color background = Color(0xFF1F2937); // scaffold / page
  static const Color card       = Color(0xFF313742);
  static const Color surface    = Color(0xFF37414F); // input fills, insets
  static const Color textPrimary   = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFFCBD5E1);
  static const Color textFaint     = Color(0xFF94A3B8);
  static const Color border        = Color(0xFF374151);

  // Barlow for body, Barlow Condensed for display/headlines/titles
  static TextTheme get _textTheme {
    final body = GoogleFonts.barlowTextTheme(ThemeData.dark().textTheme);
    final display = GoogleFonts.barlowCondensedTextTheme(body);
    return body.copyWith(
      displayLarge:   display.displayLarge?.copyWith(fontWeight: FontWeight.w700),
      displayMedium:  display.displayMedium?.copyWith(fontWeight: FontWeight.w700),
      displaySmall:   display.displaySmall?.copyWith(fontWeight: FontWeight.w700),
      headlineLarge:  display.headlineLarge?.copyWith(fontWeight: FontWeight.w700),
      headlineMedium: display.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
      headlineSmall:  display.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
      titleLarge:     display.titleLarge?.copyWith(fontWeight: FontWeight.w600),
    ).apply(bodyColor: textPrimary, displayColor: textPrimary);
  }

  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: brand,
      onPrimary: onBrand,
      secondary: brandLight,
      onSecondary: onBrand,
      tertiary: success,
      onTertiary: onBrand,
      error: danger,
      onError: Colors.black,
      surface: background,
      onSurface: textPrimary,
      onSurfaceVariant: textSecondary,
      surfaceContainerHighest: surface,
      outline: border,
    ),
    scaffoldBackgroundColor: background,
    textTheme: _textTheme,
    fontFamily: GoogleFonts.barlow().fontFamily,
    dividerColor: border,
    appBarTheme: AppBarTheme(
      backgroundColor: background,
      foregroundColor: textPrimary,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.barlowCondensed(
        color: textPrimary,
        fontSize: 22,
        fontWeight: FontWeight.w700,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: card,
      indicatorColor: brandSoft,
      labelTextStyle: WidgetStatePropertyAll(
        GoogleFonts.barlow(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: brand,
        foregroundColor: onBrand,
        disabledBackgroundColor: brand.withValues(alpha: 0.5),
        disabledForegroundColor: onBrand,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        textStyle: GoogleFonts.barlowCondensed(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: brand),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      hintStyle: const TextStyle(color: textFaint),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: brand, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: danger),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    cardTheme: CardThemeData(
      color: card,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: border),
      ),
    ),
  );
}
