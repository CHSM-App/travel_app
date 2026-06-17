import 'package:flutter/material.dart';
import 'package:travel_agency_app/core/network/error_messages.dart';
import 'package:travel_agency_app/core/theme/app_colors.dart';
import 'package:travel_agency_app/core/theme/app_scroll_behavior.dart';

/// Common offline / error state for the whole app — mirrors the Trips page so
/// every screen shows the SAME thing when a load fails: an indigo circle with a
/// wifi-off (offline) or error icon, a title + friendly message, and a Retry
/// button.
///
/// When [onRetry] is supplied it drives BOTH the Retry button and pull-to-
/// refresh (the body is wrapped in a [RefreshIndicator] over an always-
/// scrollable list, so the user can pull down OR tap retry to re-load).
///
/// Pass [scrollable] = false to drop just the centred message + button into a
/// parent that already provides its own scroll / refresh (e.g. an embedded
/// card), so two [RefreshIndicator]s never nest.
///
/// Use in `AsyncValue.when(error: (e, _) => NetworkErrorView(error: e, onRetry: _load))`.
class NetworkErrorView extends StatelessWidget {
  final Object error;

  /// Re-runs the failed load. Must return a Future so the pull-to-refresh
  /// spinner stays up until the reload settles. When null, no Retry button or
  /// pull-to-refresh is shown (static message only).
  final Future<void> Function()? onRetry;

  /// Whether to wrap the message in a pull-to-refresh scroll view. Set false
  /// when embedding inside a parent that already scrolls/refreshes.
  final bool scrollable;

  const NetworkErrorView({
    super.key,
    required this.error,
    this.onRetry,
    this.scrollable = true,
  });

  @override
  Widget build(BuildContext context) {
    final offline = isNetworkError(error);

    final content = Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                offline ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
                size: 56,
                color: offline ? Colors.grey.shade500 : Colors.red.shade300,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              offline ? 'You appear to be offline' : 'Something went wrong',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              offline
                  ? 'Check your connection and pull to refresh, or tap retry.'
                  : friendlyErrorMessage(error),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    // Embedded mode (or nothing to retry): just the centred message — the
    // parent owns any scroll/refresh.
    if (!scrollable || onRetry == null) return content;

    // Pull-to-refresh + Retry button both run the same reload. The min-height
    // box keeps the content centred while staying always-scrollable so the
    // RefreshIndicator can be pulled even though everything fits on screen.
    return RefreshIndicator(
      onRefresh: onRetry!,
      color: AppColors.brandPrimary,
      child: LayoutBuilder(
        builder: (context, constraints) => ListView(
          physics: kBouncyAlwaysScrollable,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: content,
            ),
          ],
        ),
      ),
    );
  }
}
