// lib/theme/milpress_theme.dart
//
// Builds the [ThemeData] used by MilpressApp. Keeps the Material 3 chrome
// but retunes it for the warm neutral palette: subdued off-white surfaces,
// consistent orange accent, rounded-but-not-chubby controls, and a
// compact-ish density suited to a content-management tool.
//
// Other files should NEVER construct ThemeData directly. Use this.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'milpress_colors.dart';

ThemeData milpressTheme() {
  const colors = AppColors.light;

  // Color scheme seeded from primary, with neutrals tuned to match
  // our warm off-white surface tone instead of Material's default gray.
  const scheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFFE85D04),
    onPrimary: Colors.white,
    primaryContainer: Color(0xFFFFF2EA),
    onPrimaryContainer: Color(0xFFD35403),
    secondary: Color(0xFF2B2F38),
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFFF4F1EB),
    onSecondaryContainer: Color(0xFF2B2F38),
    error: Color(0xFFC43B3B),
    onError: Colors.white,
    surface: Color(0xFFFFFFFF),
    onSurface: Color(0xFF0F1115),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFFAF8F4),
    surfaceContainer: Color(0xFFF4F1EB),
    surfaceContainerHigh: Color(0xFFEFEDE8),
    surfaceContainerHighest: Color(0xFFE6E4E0),
    outline: Color(0xFFE6E4E0),
    outlineVariant: Color(0xFFEFEDE8),
    onSurfaceVariant: Color(0xFF5A6170),
  );

  // Type pairing: Inter for UI (body + labels), Fraunces for display.
  // JetBrains Mono for snake_case keys and URLs.
  final textTheme = TextTheme(
    displayLarge: GoogleFonts.fraunces(
      fontSize: 40, fontWeight: FontWeight.w600, letterSpacing: -0.6, color: colors.ink),
    displayMedium: GoogleFonts.fraunces(
      fontSize: 28, fontWeight: FontWeight.w600, letterSpacing: -0.4, color: colors.ink),
    displaySmall: GoogleFonts.fraunces(
      fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: -0.3, color: colors.ink),
    headlineSmall: GoogleFonts.inter(
      fontSize: 18, fontWeight: FontWeight.w600, color: colors.ink),
    titleLarge: GoogleFonts.inter(
      fontSize: 16, fontWeight: FontWeight.w600, color: colors.ink),
    titleMedium: GoogleFonts.inter(
      fontSize: 14, fontWeight: FontWeight.w600, color: colors.ink),
    titleSmall: GoogleFonts.inter(
      fontSize: 12, fontWeight: FontWeight.w600, color: colors.inkSoft),
    bodyLarge: GoogleFonts.inter(
      fontSize: 14, fontWeight: FontWeight.w400, color: colors.ink, height: 1.5),
    bodyMedium: GoogleFonts.inter(
      fontSize: 13, fontWeight: FontWeight.w400, color: colors.ink, height: 1.5),
    bodySmall: GoogleFonts.inter(
      fontSize: 12, fontWeight: FontWeight.w400, color: colors.inkMuted, height: 1.5),
    labelLarge: GoogleFonts.inter(
      fontSize: 13, fontWeight: FontWeight.w500, color: colors.inkSoft),
    labelMedium: GoogleFonts.inter(
      fontSize: 12, fontWeight: FontWeight.w500, color: colors.inkSoft),
    labelSmall: GoogleFonts.inter(
      fontSize: 11, fontWeight: FontWeight.w500, color: colors.inkMuted, letterSpacing: 0.1),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: colors.surfaceAlt,
    canvasColor: colors.surface,
    textTheme: textTheme,
    fontFamily: GoogleFonts.inter().fontFamily,

    extensions: const <ThemeExtension<dynamic>>[colors],

    dividerTheme: DividerThemeData(color: colors.lineSoft, space: 1, thickness: 1),

    iconTheme: IconThemeData(color: colors.inkMuted, size: 18),

    inputDecorationTheme: InputDecorationTheme(
      isDense: true,
      filled: true,
      fillColor: colors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      hintStyle: GoogleFonts.inter(fontSize: 13, color: colors.inkFaint),
      labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: colors.inkSoft),
      floatingLabelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: colors.inkSoft),
      floatingLabelBehavior: FloatingLabelBehavior.always,
      helperStyle: GoogleFonts.inter(fontSize: 11, color: colors.inkFaint),
      errorStyle: GoogleFonts.inter(fontSize: 11, color: colors.danger),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: colors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: colors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: colors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: colors.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: colors.danger, width: 1.5),
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: colors.inkSoft,
        side: BorderSide(color: colors.line),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: colors.inkMuted,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        textStyle: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w500),
      ),
    ),

    switchTheme: SwitchThemeData(
      trackColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? colors.primary : colors.line),
      thumbColor: WidgetStateProperty.all(Colors.white),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),

    checkboxTheme: CheckboxThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
      side: BorderSide(color: colors.inkFaint),
      fillColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? colors.primary : Colors.transparent),
    ),

    chipTheme: ChipThemeData(
      backgroundColor: colors.surfaceDim,
      labelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: colors.inkSoft),
      side: BorderSide(color: colors.line),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: colors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 24,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      titleTextStyle: GoogleFonts.fraunces(
        fontSize: 22, fontWeight: FontWeight.w600, color: colors.ink, letterSpacing: -0.3),
    ),

    cardTheme: CardThemeData(
      color: colors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: colors.line),
      ),
      margin: EdgeInsets.zero,
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: colors.ink,
      contentTextStyle: GoogleFonts.inter(fontSize: 13, color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      behavior: SnackBarBehavior.floating,
    ),

    appBarTheme: AppBarTheme(
      backgroundColor: colors.surface,
      foregroundColor: colors.ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 1,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 16, fontWeight: FontWeight.w600, color: colors.ink),
      iconTheme: IconThemeData(color: colors.inkSoft),
    ),

    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: colors.ink,
        borderRadius: BorderRadius.circular(4),
      ),
      textStyle: GoogleFonts.inter(fontSize: 11, color: Colors.white),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    ),

    visualDensity: const VisualDensity(horizontal: -1, vertical: -1),

    splashFactory: InkSparkle.splashFactory,
  );
}
