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
/// Reference theme — modeled on the supplied travel-app design: a deep
/// indigo-navy header surface paired with a vivid rose-pink accent, on clean
/// white/near-white surfaces. Category & status colors are individually vivid
/// (blue / red / amber / green). Everything is a FLAT SOLID — the app uses
/// no gradients.
///
/// Two brand families now exist:
///   • [brandHeader]  — the navy used for app bars, top headers and hero cards.
///   • [brandPrimary] — the rose-pink accent for buttons, active nav, links,
///                      selected states and other interactive elements.
class AppColors {
  AppColors._();

  // ── Brand header (deep indigo-navy) ───────────────────────────────────────

  /// Indigo-navy. App bars, top headers, hero/summary card backgrounds.
  /// White text/icons sit on top of this.
  static const Color brandHeader = Color(0xFF262445);

  /// Darker navy for pressed / elevated header elements and shadows.
  static const Color brandHeaderDark = Color(0xFF1C1A33);

  // ── Brand accent (rose-pink) ──────────────────────────────────────────────

  /// Rose-pink. Primary interactive accent: primary buttons, active nav items,
  /// links ("Show More"), selected states, location pins, chip outlines.
  static const Color brandPrimary = Color(0xFFEC407A);

  /// Deeper pink. Pressed / hover state for pink accents.
  static const Color brandPrimaryDark = Color(0xFFD81B60);

  /// Lighter pink companion. Subtle accents and soft pink fills. (Retained
  /// for call sites that previously used a lighter brand tint; no gradients.)
  static const Color brandPrimaryLight = Color(0xFFF06292);

  /// Pink-50. Soft tinted background for chips, selected pills,
  /// and brand-tinted surfaces.
  static const Color brandSoft = Color(0xFFFCE4EC);

  // ── Semantic / category accents ───────────────────────────────────────────
  // Vivid, individually-colored — also used for the category icons
  // (Flights = info blue, Hotels = danger red, Destination = warning amber,
  // Rent = success green). Each has a `*Soft` tint for chip/badge backgrounds.

  /// Green-500. Positive / done states: paid, completed trips; "Rent" category.
  static const Color success = Color(0xFF22C55E);

  /// Green-50. Soft background tint for success chips/badges.
  static const Color successSoft = Color(0xFFDCFCE7);

  /// Amber-500. Attention / pending states; "Destination" category.
  static const Color warning = Color(0xFFF59E0B);

  /// Amber-50. Soft background tint for warning chips/badges.
  static const Color warningSoft = Color(0xFFFEF3C7);

  /// Red-500. Negative / terminal states: cancelled trips, errors; "Hotels".
  static const Color danger = Color(0xFFEF4444);

  /// Red-50. Soft background tint for danger chips/badges.
  static const Color dangerSoft = Color(0xFFFEE2E2);

  /// Blue-500. In-progress / live states: active trips; "Flights" category.
  static const Color info = Color(0xFF3B82F6);

  /// Blue-50. Soft background tint for info chips/badges.
  static const Color infoSoft = Color(0xFFDBEAFE);

  /// Amber/gold. Rating stars.
  static const Color star = Color(0xFFFFB400);

  // ── Neutrals / text ───────────────────────────────────────────────────────

  /// Near-white. Default page / scaffold background (lets white cards lift).
  static const Color surface = Color(0xFFF6F7FB);

  /// Ink navy. Primary text / headings.
  static const Color textPrimary = Color(0xFF232136);

  /// Slate-grey. Secondary text / captions / hints.
  static const Color textSecondary = Color(0xFF8A90A0);

  /// Hairline borders, dividers, card outlines.
  static const Color border = Color(0xFFEEF0F5);

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