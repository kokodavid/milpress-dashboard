// lib/theme/milpress_colors.dart
//
// Brand color tokens exposed as a ThemeExtension so every widget can read
// semantic colors via `Theme.of(context).extension<AppColors>()!` instead
// of hard-coding hex values sprinkled across the codebase.
//
// Values match the design system established in the "Add Lesson" redesign
// prototype. When changing colors, change them HERE — nowhere else.

import 'package:flutter/material.dart';

@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    // Brand
    required this.primary,
    required this.primaryHover,
    required this.primaryWash,
    required this.primaryWashBorder,

    // Neutrals (warm off-white scale)
    required this.ink,
    required this.inkSoft,
    required this.inkMuted,
    required this.inkFaint,
    required this.line,
    required this.lineSoft,
    required this.surface,
    required this.surfaceAlt,
    required this.surfaceDim,

    // Sidebar / nav
    required this.navBg,
    required this.navBgAlt,

    // Status
    required this.danger,
    required this.warn,
    required this.ok,
    required this.warnWash,
    required this.okWash,
    required this.dangerWash,
  });

  final Color primary;
  final Color primaryHover;
  final Color primaryWash;
  final Color primaryWashBorder;

  final Color ink;
  final Color inkSoft;
  final Color inkMuted;
  final Color inkFaint;
  final Color line;
  final Color lineSoft;
  final Color surface;
  final Color surfaceAlt;
  final Color surfaceDim;

  final Color navBg;
  final Color navBgAlt;

  final Color danger;
  final Color warn;
  final Color ok;
  final Color warnWash;
  final Color okWash;
  final Color dangerWash;

  /// The canonical Milpress palette. Import this in [milpress_theme.dart];
  /// don't construct AppColors directly from feature code.
  static const AppColors light = AppColors(
    primary: Color(0xFFE85D04),
    primaryHover: Color(0xFFD35403),
    primaryWash: Color(0xFFFFF2EA),
    primaryWashBorder: Color(0xFFFBD5BC),

    ink: Color(0xFF0F1115),
    inkSoft: Color(0xFF2B2F38),
    inkMuted: Color(0xFF5A6170),
    inkFaint: Color(0xFF8A92A0),
    line: Color(0xFFE6E4E0),
    lineSoft: Color(0xFFEFEDE8),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFFAF8F4),
    surfaceDim: Color(0xFFF4F1EB),

    navBg: Color(0xFF1A1C22),
    navBgAlt: Color(0xFF23252C),

    danger: Color(0xFFC43B3B),
    warn: Color(0xFFB07600),
    ok: Color(0xFF2E7D5B),
    warnWash: Color(0xFFFFF4D6),
    okWash: Color(0xFFE4F3EC),
    dangerWash: Color(0xFFFFE8E8),
  );

  @override
  AppColors copyWith({
    Color? primary,
    Color? primaryHover,
    Color? primaryWash,
    Color? primaryWashBorder,
    Color? ink,
    Color? inkSoft,
    Color? inkMuted,
    Color? inkFaint,
    Color? line,
    Color? lineSoft,
    Color? surface,
    Color? surfaceAlt,
    Color? surfaceDim,
    Color? navBg,
    Color? navBgAlt,
    Color? danger,
    Color? warn,
    Color? ok,
    Color? warnWash,
    Color? okWash,
    Color? dangerWash,
  }) {
    return AppColors(
      primary: primary ?? this.primary,
      primaryHover: primaryHover ?? this.primaryHover,
      primaryWash: primaryWash ?? this.primaryWash,
      primaryWashBorder: primaryWashBorder ?? this.primaryWashBorder,
      ink: ink ?? this.ink,
      inkSoft: inkSoft ?? this.inkSoft,
      inkMuted: inkMuted ?? this.inkMuted,
      inkFaint: inkFaint ?? this.inkFaint,
      line: line ?? this.line,
      lineSoft: lineSoft ?? this.lineSoft,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      surfaceDim: surfaceDim ?? this.surfaceDim,
      navBg: navBg ?? this.navBg,
      navBgAlt: navBgAlt ?? this.navBgAlt,
      danger: danger ?? this.danger,
      warn: warn ?? this.warn,
      ok: ok ?? this.ok,
      warnWash: warnWash ?? this.warnWash,
      okWash: okWash ?? this.okWash,
      dangerWash: dangerWash ?? this.dangerWash,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      primary: Color.lerp(primary, other.primary, t)!,
      primaryHover: Color.lerp(primaryHover, other.primaryHover, t)!,
      primaryWash: Color.lerp(primaryWash, other.primaryWash, t)!,
      primaryWashBorder:
          Color.lerp(primaryWashBorder, other.primaryWashBorder, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      inkSoft: Color.lerp(inkSoft, other.inkSoft, t)!,
      inkMuted: Color.lerp(inkMuted, other.inkMuted, t)!,
      inkFaint: Color.lerp(inkFaint, other.inkFaint, t)!,
      line: Color.lerp(line, other.line, t)!,
      lineSoft: Color.lerp(lineSoft, other.lineSoft, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
      surfaceDim: Color.lerp(surfaceDim, other.surfaceDim, t)!,
      navBg: Color.lerp(navBg, other.navBg, t)!,
      navBgAlt: Color.lerp(navBgAlt, other.navBgAlt, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      warn: Color.lerp(warn, other.warn, t)!,
      ok: Color.lerp(ok, other.ok, t)!,
      warnWash: Color.lerp(warnWash, other.warnWash, t)!,
      okWash: Color.lerp(okWash, other.okWash, t)!,
      dangerWash: Color.lerp(dangerWash, other.dangerWash, t)!,
    );
  }
}

/// Shorthand to pull [AppColors] out of the theme without calling
/// `.extension<AppColors>()!` at every callsite.
extension AppColorsX on BuildContext {
  AppColors get appColors => Theme.of(this).extension<AppColors>()!;
}
