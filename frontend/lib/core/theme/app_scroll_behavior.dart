import 'package:flutter/material.dart';

/// Shared physics for scrollables that must stay scrollable even when their
/// content is shorter than the viewport (e.g. lists wrapped in a
/// [RefreshIndicator]). Gives the iOS rubber-band overscroll on every platform.
const ScrollPhysics kBouncyAlwaysScrollable =
    AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics());

/// App-wide scroll behaviour wired into [MaterialApp.scrollBehavior].
///
/// Two effects, applied to every scrollable that doesn't override `physics`:
///  • iOS "rubber-band" overscroll on all platforms (incl. Android), and
///  • no Material overscroll glow — the bounce itself is the feedback.
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const BouncingScrollPhysics();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    // Suppress the Android glow so the bounce reads cleanly like iOS.
    return child;
  }
}
