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
}
