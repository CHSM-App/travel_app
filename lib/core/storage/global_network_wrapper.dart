import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_agency_app/core/network/dio_provider.dart';
import 'package:travel_agency_app/domain/viewModel/network_model.dart';
import 'package:travel_agency_app/presentation/providers/viewmodel_provider.dart';

class GlobalNetworkWrapper extends ConsumerStatefulWidget {
  final Widget child;
  
  const GlobalNetworkWrapper({super.key, required this.child});

  @override
  ConsumerState<GlobalNetworkWrapper> createState() => _GlobalNetworkWrapperState();
}

class _GlobalNetworkWrapperState extends ConsumerState<GlobalNetworkWrapper> {
  bool? _lastKnownNetworkState;
  bool? _lastKnownApiState;
  OverlayEntry? _networkOverlay;
  OverlayEntry? _serverOverlay;
  bool _isInitialized = false;
  
  @override
  void initState() {
    super.initState();
    
    // Add a small delay to ensure providers are ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeStates();
    });
  }
  
  void _initializeStates() {
    final networkState = ref.read(networkStateProvider);
    final apiState = ref.read(apiStateProvider);
    
    if (networkState.isInitialized) {
      _lastKnownNetworkState = networkState.isConnected;
    }
    _lastKnownApiState = apiState.isApiAvailable;
    _isInitialized = true;
  }
  
  @override
  Widget build(BuildContext context) {
    // Watch both states and handle changes immediately
    final networkState = ref.watch(networkStateProvider);
    final apiState = ref.watch(apiStateProvider);
    
    // Handle state changes in build method for immediate response
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isInitialized) {
        _handleNetworkChange(networkState);
        _handleApiChange(networkState, apiState);
      } else if (networkState.isInitialized) {
        _initializeStates();
      }
    });
    
    return widget.child;
  }
  
  void _handleNetworkChange(NetworkState current) {
    
    if (!current.isInitialized) {
      return;
    }
    
    // Runtime disconnection detected
    if (_lastKnownNetworkState == true && !current.isConnected) {
      _showNetworkOverlay();
    }
    // Runtime reconnection detected
    else if (_lastKnownNetworkState == false && current.isConnected) {
      _hideNetworkOverlay();
    }
    
    _lastKnownNetworkState = current.isConnected;
  }
  
  void _handleApiChange(NetworkState networkState, ApiState current) {
    if (!networkState.isConnected) {
      return; // Don't show API error if no network
    }
    
    // Runtime API failure detected
    if (_lastKnownApiState == true && !current.isApiAvailable && current.lastChecked != null) {
      _showServerOverlay();
    }
    // Runtime API recovery detected
    else if (_lastKnownApiState == false && current.isApiAvailable) {
      _hideServerOverlay();
    }
    
    _lastKnownApiState = current.isApiAvailable;
  }
  
  void _showNetworkOverlay() {
    if (_networkOverlay != null) {
      return; // Already showing
    }
    _hideServerOverlay(); // Hide server overlay if showing
    
    _networkOverlay = OverlayEntry(
      builder: (context) => Material(
        color: Colors.black.withOpacity(0.8),
        child: SafeArea(
          child: Center(
            child: Container(
              margin: const EdgeInsets.all(32),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.wifi_off_rounded,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Connection Lost',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your internet connection was lost while using the app.\nPlease check your connection.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            ref.read(networkStateProvider.notifier).retryConnection(context);
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry Connection'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      _hideNetworkOverlay();
                    },
                    child: const Text('Dismiss'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    
    try {
      Overlay.of(context).insert(_networkOverlay!);
    } catch (e) {
      _networkOverlay = null;
    }
  }
  
  void _hideNetworkOverlay() {
    if (_networkOverlay == null) {
      return;
    }
    
    try {
      _networkOverlay!.remove();
      _networkOverlay = null;
    } catch (e) {
      _networkOverlay = null;
    }
  }
  
  void _showServerOverlay() {
    if (_serverOverlay != null) {
      return; // Already showing
    }
    _serverOverlay = OverlayEntry(
      builder: (context) => Material(
        color: Colors.black.withOpacity(0.8),
        child: SafeArea(
          child: Center(
            child: Container(
              margin: const EdgeInsets.all(32),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2C),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.dns_rounded,
                    size: 64,
                    color: Colors.red.shade300,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Server Error',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'The server is not responding while you were using the app.\nThis is usually temporary.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            ref.read(apiStateProvider.notifier).checkApiHealth();
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry Server'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      _hideServerOverlay();
                    },
                    child: const Text(
                      'Dismiss',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    
    try {
      Overlay.of(context).insert(_serverOverlay!);
    } catch (e) {
      _serverOverlay = null;
    }
  }
  
  void _hideServerOverlay() {
    if (_serverOverlay == null) {
      return;
    }
    
    try {
      _serverOverlay!.remove();
      _serverOverlay = null;
    } catch (e) {
      _serverOverlay = null;
    }
  }
  
  @override
  void dispose() {
    _hideNetworkOverlay();
    _hideServerOverlay();
    super.dispose();
  }
}