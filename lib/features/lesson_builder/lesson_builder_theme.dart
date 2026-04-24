import 'package:flutter/material.dart';

/// Shared visual constants for the lesson builder feature.
/// Add here only when a value appears in ≥2 builder files.
abstract final class LessonBuilderTheme {
  // ── Brand colours ────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFFE85D04);
  static const Color primaryLight = Color(0xFFFFF4EE);

  // ── Surface / border ─────────────────────────────────────────────────────────
  static const Color surfaceBorder = Color(0xFFE5E5E5);
  static const Color cardBackground = Color(0xFFF9FAFB);

  // ── Text ─────────────────────────────────────────────────────────────────────
  static const Color textMuted = Color(0xFF6B7280);
  static const Color textDark = Color(0xFF374151);

  // ── Step-type category palette ───────────────────────────────────────────────
  /// Accent colour for a step-type category — used for icons and pills.
  static Color categoryAccent(String category) {
    switch (category) {
      case 'Foundation':
        return Colors.blue.shade600;
      case 'Assessment':
        return Colors.purple.shade600;
      case 'Sound & Phonics':
        return Colors.teal.shade600;
      case 'Reading':
        return Colors.green.shade600;
      case 'Story':
        return Colors.amber.shade700;
      default:
        return Colors.grey.shade600;
    }
  }

  /// Soft background tint for the same category icon badge.
  static Color categoryBackground(String category) {
    switch (category) {
      case 'Foundation':
        return Colors.blue.shade50;
      case 'Assessment':
        return Colors.purple.shade50;
      case 'Sound & Phonics':
        return Colors.teal.shade50;
      case 'Reading':
        return Colors.green.shade50;
      case 'Story':
        return Colors.amber.shade50;
      default:
        return Colors.grey.shade100;
    }
  }
}
