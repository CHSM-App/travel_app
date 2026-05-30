import 'package:flutter/material.dart';
import 'package:travel_agency_app/core/network/error_messages.dart';

/// Full-screen error state that mirrors the Trips page: a wifi-off icon and
/// "You appear to be offline" copy for transport failures, otherwise a generic
/// cloud-off "Something went wrong" with the friendly message underneath.
///
/// Use in `AsyncValue.when(error: (e, _) => NetworkErrorView(error: e))`.
class NetworkErrorView extends StatelessWidget {
  final Object error;
  final VoidCallback? onRetry;

  const NetworkErrorView({super.key, required this.error, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final offline = isNetworkError(error);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: offline ? Colors.grey.shade100 : Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                offline ? Icons.wifi_off_rounded : Icons.cloud_off_rounded,
                color: offline ? Colors.grey.shade500 : Colors.red.shade300,
                size: 28,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              offline ? 'You appear to be offline' : 'Something went wrong',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1D2E),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              friendlyErrorMessage(error),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF7B82A0)),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
