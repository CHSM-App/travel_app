// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:vego/core/network/network_state_notifier.dart';

// class NetworkOverlay extends ConsumerWidget {
//   final Widget child;
  
//   const NetworkOverlay({super.key, required this.child});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final networkState = ref.watch(networkStateProvider);
    
//     return Stack(
//       children: [
//         child,
//         // Show overlay when network is lost during runtime
//         if (networkState.isInitialized && !networkState.isConnected)
//           Container(
//             color: Colors.black.withValues(alpha: 0.8),
//             child: Center(
//               child: Card(
//                 margin: const EdgeInsets.all(32),
//                 child: Padding(
//                   padding: const EdgeInsets.all(24),
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       const Icon(
//                         Icons.wifi_off,
//                         size: 64,
//                         color: Colors.red,
//                       ),
//                       const SizedBox(height: 16),
//                       const Text(
//                         'Connection Lost',
//                         style: TextStyle(
//                           fontSize: 24,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//                       Text(
//                         networkState.errorMessage ?? 'Please check your internet connection',
//                         textAlign: TextAlign.center,
//                         style: const TextStyle(fontSize: 16),
//                       ),
//                       const SizedBox(height: 24),
//                       SizedBox(
//                         width: double.infinity,
//                         child: ElevatedButton.icon(
//                           onPressed: () {
//                             ref.read(networkStateProvider.notifier).retryConnection();
//                           },
//                           icon: const Icon(Icons.refresh),
//                           label: const Text('Retry'),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ),
//       ],
//     );
//   }
// }
