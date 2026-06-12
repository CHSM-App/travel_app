// import 'package:flutter/material.dart';

// /// Single source of truth for the app's brand indigo. Replaces the 15+
// /// hand-rolled indigo variants previously scattered across screen files.
// ///
// /// Phase 1 only consolidates the indigo family — semantic accents
// /// (success/warning/danger) and neutrals/text are still per-screen for now.
// class AppColors {
//   AppColors._();

//   /// Indigo-600. Primary brand action color: active states, primary buttons,
//   /// active nav items, brand gradients, chip outlines.
//   static const Color brandPrimary = Color(0xFF4F46E5);

//   /// Indigo-700. Pressed / hover state. Darker gradient companion when
//   /// pairing a brand gradient that needs to feel grounded.
//   static const Color brandPrimaryDark = Color(0xFF4338CA);

//   /// Indigo-400. Lighter gradient companion (use as the lighter stop
//   /// in primary→light gradients, e.g. AppBar washes).
//   static const Color brandPrimaryLight = Color(0xFF818CF8);

//   /// Indigo-50. Soft tinted background for chips, selected pills,
//   /// and brand-tinted surfaces.
//   static const Color brandSoft = Color(0xFFEEF2FF);

//   // ── Semantic accents ──────────────────────────────────────────────────────
//   // Use these for state, not for brand. Each has a `*Soft` tint for use as a
//   // chip/badge background behind the solid colour as foreground/icon.

//   /// Green-600. Positive / done states: paid, completed trips.
//   static const Color success = Color(0xFF16A34A);

//   /// Green-50. Soft background tint for success chips/badges.
//   static const Color successSoft = Color(0xFFDCFCE7);

//   /// Amber-500. Attention / pending states: unpaid, partially paid, upcoming.
//   static const Color warning = Color(0xFFF59E0B);

//   /// Amber-50. Soft background tint for warning chips/badges.
//   static const Color warningSoft = Color(0xFFFEF3C7);

//   /// Red-600. Negative / terminal states: cancelled trips, errors.
//   static const Color danger = Color(0xFFDC2626);

//   /// Red-50. Soft background tint for danger chips/badges.
//   static const Color dangerSoft = Color(0xFFFEE2E2);

//   /// Sky-500. In-progress / live states: active trips.
//   static const Color info = Color(0xFF0EA5E9);

//   /// Sky-50. Soft background tint for info chips/badges.
//   static const Color infoSoft = Color(0xFFE0F2FE);

//   // ── Neutrals / text ───────────────────────────────────────────────────────

//   /// Slate-50. Default page / scaffold background.
//   static const Color surface = Color(0xFFF8FAFC);

//   /// Slate-900. Primary text / headings.
//   static const Color textPrimary = Color(0xFF0F172A);

//   /// Slate-500. Secondary text / captions / hints.
//   static const Color textSecondary = Color(0xFF64748B);

//   /// Slate-200. Hairline borders, dividers, card outlines.
//   static const Color border = Color(0xFFE2E8F0);
// }



import 'package:flutter/material.dart';

/// Single source of truth for the app's brand colors.
///
/// Warm Sand — a modern, minimal, aesthetic palette: warm-charcoal headers
/// with a muted clay/terracotta accent, on soft cream surfaces. Restrained
/// and editorial — lots of negative space, hairline borders, soft-tint chips
/// instead of bold fills. Status colors are warmed/muted so they read as
/// information, not decoration. Everything is a FLAT SOLID — no gradients.
///
/// Two brand families:
///   • [brandHeader]  — warm charcoal for app bars, top headers, hero cards.
///   • [brandPrimary] — the muted clay accent for buttons, active nav, links,
///                      selected states and other interactive elements.
class AppColors {
  AppColors._();

  // ── Brand header (warm charcoal) ──────────────────────────────────────────

  /// Warm charcoal. App bars, top headers, hero/summary card backgrounds.
  /// Cream/white text sits on top of this.
  static const Color brandHeader = Color(0xFF292420);

  /// Deeper warm charcoal for pressed / elevated header elements and shadows.
  static const Color brandHeaderDark = Color(0xFF1C1813);

  // ── Brand accent (muted clay) ─────────────────────────────────────────────

  /// Clay / terracotta. Primary interactive accent: primary buttons, active
  /// nav items, links, selected states, location pins, chip outlines.
  static const Color brandPrimary = Color(0xFFB5651D);

  /// Deeper clay. Pressed / hover state for the accent.
  static const Color brandPrimaryDark = Color(0xFF92500F);

  /// Lighter clay companion. Subtle accents and soft fills. (Retained for call
  /// sites that previously used a lighter brand tint; no gradients.)
  static const Color brandPrimaryLight = Color(0xFFC98A4B);

  /// Warm sand tint. Soft background for chips, selected pills, icon chips
  /// and brand-tinted surfaces.
  static const Color brandSoft = Color(0xFFF6EEE6);

  // ── Semantic / category accents ───────────────────────────────────────────
  // Warmed / muted so they read as information, not decoration. Each has a
  // `*Soft` tint for chip/badge backgrounds (Flights = info, Hotels = danger,
  // Destination = warning, Rent = success).

  /// Olive-green. Positive / done states: paid, completed trips; "Rent".
  static const Color success = Color(0xFF4D7C0F);

  /// Soft olive tint. Background for success chips/badges.
  static const Color successSoft = Color(0xFFECF4DE);

  /// Warm amber. Attention / pending states; "Destination" category.
  static const Color warning = Color(0xFFC2860B);

  /// Soft amber tint. Background for warning chips/badges.
  static const Color warningSoft = Color(0xFFF7EDD6);

  /// Brick red. Negative / terminal states: cancelled trips, errors; "Hotels".
  static const Color danger = Color(0xFFB91C1C);

  /// Soft red tint. Background for danger chips/badges.
  static const Color dangerSoft = Color(0xFFF7E3E0);

  /// Indigo-blue. In-progress / live states: active trips; "Flights".
  static const Color info = Color(0xFF2563EB);

  /// Soft blue tint. Background for info chips/badges.
  static const Color infoSoft = Color(0xFFE4EAFB);

  /// Muted gold. Rating stars.
  static const Color star = Color(0xFFCA8A04);

  // ── Neutrals / text ───────────────────────────────────────────────────────

  /// Soft cream. Default page / scaffold background (lets white cards lift).
  static const Color surface = Color(0xFFFAF7F2);

  /// Warm ink. Primary text / headings.
  static const Color textPrimary = Color(0xFF292420);

  /// Warm grey. Secondary text / captions / hints.
  static const Color textSecondary = Color(0xFF8A7F73);

  /// Hairline borders, dividers, card outlines.
  static const Color border = Color(0xFFECE4D9);

}


// /// Single source of truth for the app's brand colors.
// ///
// /// Ocean Teal palette — chosen for a travel app: teal primary with a
// /// sky-blue light companion evokes sea + horizon, while staying calm and
// /// professional for an admin/B2B dashboard.
// ///
// /// Phase 1 only consolidates the brand family — semantic accents
// /// (success/warning/danger) and neutrals/text follow below.
// class AppColors {
//   AppColors._();

//   // ── Brand (Ocean Teal) ────────────────────────────────────────────────────

//   /// Teal-500. Primary brand action color: active states, primary buttons,
//   /// active nav items, brand gradients, chip outlines.
//   static const Color brandPrimary = Color(0xFF0EA5A4);

//   /// Teal-700. Pressed / hover state. Darker gradient companion when
//   /// pairing a brand gradient that needs to feel grounded.
//   static const Color brandPrimaryDark = Color(0xFF0C7B7A);

//   /// Sky-400. Lighter gradient companion (use as the lighter stop
//   /// in primary→light gradients, e.g. AppBar washes). The sky-blue pairing
//   /// gives brand gradients a natural "horizon" feel.
//   static const Color brandPrimaryLight = Color(0xFF38BDF8);

//   /// Teal-50. Soft tinted background for chips, selected pills,
//   /// and brand-tinted surfaces.
//   static const Color brandSoft = Color(0xFFE0F5F4);

//   // ── Semantic accents ──────────────────────────────────────────────────────
//   // Use these for state, not for brand. Each has a `*Soft` tint for use as a
//   // chip/badge background behind the solid colour as foreground/icon.

//   /// Green-600. Positive / done states: paid, completed trips.
//   static const Color success = Color(0xFF16A34A);

//   /// Green-50. Soft background tint for success chips/badges.
//   static const Color successSoft = Color(0xFFDCFCE7);

//   /// Amber-500. Attention / pending states: unpaid, partially paid, upcoming.
//   static const Color warning = Color(0xFFF59E0B);

//   /// Amber-50. Soft background tint for warning chips/badges.
//   static const Color warningSoft = Color(0xFFFEF3C7);

//   /// Red-600. Negative / terminal states: cancelled trips, errors.
//   static const Color danger = Color(0xFFDC2626);

//   /// Red-50. Soft background tint for danger chips/badges.
//   static const Color dangerSoft = Color(0xFFFEE2E2);

//   /// Blue-500. In-progress / live states: active trips. Pushed to a truer
//   /// blue (away from Sky-500) so it stays visually distinct from the teal
//   /// brand and the sky-blue gradient companion.
//   static const Color info = Color(0xFF3B82F6);

//   /// Blue-50. Soft background tint for info chips/badges.
//   static const Color infoSoft = Color(0xFFDBEAFE);

//   // ── Neutrals / text ───────────────────────────────────────────────────────

//   /// Slate-50. Default page / scaffold background.
//   static const Color surface = Color(0xFFF8FAFC);

//   /// Slate-900. Primary text / headings.
//   static const Color textPrimary = Color(0xFF0F172A);

//   /// Slate-500. Secondary text / captions / hints.
//   static const Color textSecondary = Color(0xFF64748B);

//   /// Slate-200. Hairline borders, dividers, card outlines.
//   static const Color border = Color(0xFFE2E8F0);

// } 