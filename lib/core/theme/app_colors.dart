import 'package:flutter/material.dart';

/// Single source of truth for the app's brand indigo. Replaces the 15+
/// hand-rolled indigo variants previously scattered across screen files.
///
/// Phase 1 only consolidates the indigo family — semantic accents
/// (success/warning/danger) and neutrals/text are still per-screen for now.
class AppColors {
  AppColors._();

  /// Indigo-600. Primary brand action color: active states, primary buttons,
  /// active nav items, brand gradients, chip outlines.
  static const Color brandPrimary = Color(0xFF4F46E5);

  /// Indigo-700. Pressed / hover state. Darker gradient companion when
  /// pairing a brand gradient that needs to feel grounded.
  static const Color brandPrimaryDark = Color(0xFF4338CA);

  /// Indigo-400. Lighter gradient companion (use as the lighter stop
  /// in primary→light gradients, e.g. AppBar washes).
  static const Color brandPrimaryLight = Color(0xFF818CF8);

  /// Indigo-50. Soft tinted background for chips, selected pills,
  /// and brand-tinted surfaces.
  static const Color brandSoft = Color(0xFFEEF2FF);

  // ── Semantic accents ──────────────────────────────────────────────────────
  // Use these for state, not for brand. Each has a `*Soft` tint for use as a
  // chip/badge background behind the solid colour as foreground/icon.

  /// Green-600. Positive / done states: paid, completed trips.
  static const Color success = Color(0xFF16A34A);

  /// Green-50. Soft background tint for success chips/badges.
  static const Color successSoft = Color(0xFFDCFCE7);

  /// Amber-500. Attention / pending states: unpaid, partially paid, upcoming.
  static const Color warning = Color(0xFFF59E0B);

  /// Amber-50. Soft background tint for warning chips/badges.
  static const Color warningSoft = Color(0xFFFEF3C7);

  /// Red-600. Negative / terminal states: cancelled trips, errors.
  static const Color danger = Color(0xFFDC2626);

  /// Red-50. Soft background tint for danger chips/badges.
  static const Color dangerSoft = Color(0xFFFEE2E2);

  /// Sky-500. In-progress / live states: active trips.
  static const Color info = Color(0xFF0EA5E9);

  /// Sky-50. Soft background tint for info chips/badges.
  static const Color infoSoft = Color(0xFFE0F2FE);

  // ── Neutrals / text ───────────────────────────────────────────────────────

  /// Slate-50. Default page / scaffold background.
  static const Color surface = Color(0xFFF8FAFC);

  /// Slate-900. Primary text / headings.
  static const Color textPrimary = Color(0xFF0F172A);

  /// Slate-500. Secondary text / captions / hints.
  static const Color textSecondary = Color(0xFF64748B);

  /// Slate-200. Hairline borders, dividers, card outlines.
  static const Color border = Color(0xFFE2E8F0);
}
