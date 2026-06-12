// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:travel_agency_app/core/network/dio_provider.dart';
// import 'package:travel_agency_app/core/network/network_state_notifier.dart';

// class GlobalNetworkWrapper extends ConsumerWidget {
//   final Widget child;

//   const GlobalNetworkWrapper({super.key, required this.child});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final networkState = ref.watch(networkStateProvider);
//     final apiState = ref.watch(apiStateProvider);

//     final showNetworkDialog =
//         networkState.isInitialized && !networkState.isConnected;
//     final showServerDialog =
//         networkState.isConnected &&
//         !apiState.isApiAvailable &&
//         apiState.lastChecked != null;

//     return Stack(
//       fit: StackFit.expand,
//       children: [
//         child,
//         if (showNetworkDialog)
//           const _FullScreenBlocker(
//             child: _NetworkDialog(),
//           ),
//         if (!showNetworkDialog && showServerDialog)
//           const _FullScreenBlocker(
//             child: _ServerDialog(),
//           ),
//       ],
//     );
//   }
// }

// class _FullScreenBlocker extends StatelessWidget {
//   final Widget child;

//   const _FullScreenBlocker({required this.child});

//   @override
//   Widget build(BuildContext context) {
//     return ColoredBox(
//       color: Colors.black.withValues(alpha: 0.8),
//       child: SafeArea(
//         child: Center(child: child),
//       ),
//     );
//   }
// }

// class _NetworkDialog extends ConsumerWidget {
//   const _NetworkDialog();

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final networkState = ref.watch(networkStateProvider);

//     return Container(
//       margin: const EdgeInsets.all(32),
//       padding: const EdgeInsets.all(24),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withValues(alpha: 0.3),
//             blurRadius: 10,
//             spreadRadius: 2,
//           ),
//         ],
//       ),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           const Icon(
//             Icons.wifi_off_rounded,
//             size: 64,
//             color: Colors.red,
//           ),
//           const SizedBox(height: 16),
//           const Text(
//             'Connection Lost',
//             style: TextStyle(
//               fontSize: 24,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             networkState.errorMessage ??
//                 'Your internet connection was lost while using the app.',
//             textAlign: TextAlign.center,
//             style: const TextStyle(fontSize: 16),
//           ),
//           const SizedBox(height: 24),
//           SizedBox(
//             width: double.infinity,
//             child: ElevatedButton(
//               onPressed: networkState.isRetrying
//                   ? null
//                   : () {
//                       ref
//                           .read(networkStateProvider.notifier)
//                           .retryConnection();
//                     },
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.blue,
//                 foregroundColor: Colors.white,
//                 padding: const EdgeInsets.symmetric(vertical: 12),
//               ),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   if (networkState.isRetrying) ...[
//                     const SizedBox(
//                       width: 18,
//                       height: 18,
//                       child: CircularProgressIndicator(
//                         strokeWidth: 2,
//                         color: Colors.white,
//                       ),
//                     ),
//                     const SizedBox(width: 10),
//                     const Text('Checking...'),
//                   ] else ...[
//                     const Icon(Icons.refresh),
//                     const SizedBox(width: 8),
//                     const Text('Retry Connection'),
//                   ],
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _ServerDialog extends ConsumerWidget {
//   const _ServerDialog();

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final apiState = ref.watch(apiStateProvider);

//     return Container(
//       margin: const EdgeInsets.all(32),
//       padding: const EdgeInsets.all(24),
//       decoration: BoxDecoration(
//         color: const Color(0xFF1E1E2C),
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withValues(alpha: 0.3),
//             blurRadius: 10,
//             spreadRadius: 2,
//           ),
//         ],
//       ),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(
//             Icons.dns_rounded,
//             size: 64,
//             color: Colors.red.shade300,
//           ),
//           const SizedBox(height: 16),
//           const Text(
//             'Server Error',
//             style: TextStyle(
//               fontSize: 24,
//               fontWeight: FontWeight.bold,
//               color: Colors.white,
//             ),
//           ),
//           const SizedBox(height: 8),
//           const Text(
//             'The server is not responding. This is usually temporary.',
//             textAlign: TextAlign.center,
//             style: TextStyle(fontSize: 16, color: Colors.white70),
//           ),
//           const SizedBox(height: 24),
//           SizedBox(
//             width: double.infinity,
//             child: ElevatedButton(
//               onPressed: apiState.isChecking
//                   ? null
//                   : () {
//                       ref.read(apiStateProvider.notifier).checkApiHealth();
//                     },
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.deepPurple,
//                 foregroundColor: Colors.white,
//                 padding: const EdgeInsets.symmetric(vertical: 12),
//               ),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   if (apiState.isChecking) ...[
//                     const SizedBox(
//                       width: 18,
//                       height: 18,
//                       child: CircularProgressIndicator(
//                         strokeWidth: 2,
//                         color: Colors.white,
//                       ),
//                     ),
//                     const SizedBox(width: 10),
//                     const Text('Checking...'),
//                   ] else ...[
//                     const Icon(Icons.refresh),
//                     const SizedBox(width: 8),
//                     const Text('Retry Server'),
//                   ],
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
