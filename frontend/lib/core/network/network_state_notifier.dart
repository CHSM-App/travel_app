import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vego/data/api/api_service.dart';

const _noValue = Object();

class NetworkState {
  final bool isConnected;
  final bool isInitialized;
  final bool isRetrying;
  final String? errorMessage;
  final DateTime? lastChecked;
  final ConnectivityResult? connectionType;

  const NetworkState({
    required this.isConnected,
    this.isInitialized = false,
    this.isRetrying = false,
    this.errorMessage,
    this.lastChecked,
    this.connectionType,
  });

  NetworkState copyWith({
    bool? isConnected,
    bool? isInitialized,
    bool? isRetrying,
    Object? errorMessage = _noValue,
    DateTime? lastChecked,
    ConnectivityResult? connectionType,
  }) {
    return NetworkState(
      isConnected: isConnected ?? this.isConnected,
      isInitialized: isInitialized ?? this.isInitialized,
      isRetrying: isRetrying ?? this.isRetrying,
      errorMessage: identical(errorMessage, _noValue)
          ? this.errorMessage
          : errorMessage as String?,
      lastChecked: lastChecked ?? this.lastChecked,
      connectionType: connectionType ?? this.connectionType,
    );
  }
}

class ApiState {
  final bool isApiAvailable;
  final String? errorMessage;
  final DateTime? lastChecked;
  final bool isChecking;

  const ApiState({
    required this.isApiAvailable,
    this.errorMessage,
    this.lastChecked,
    this.isChecking = false,
  });

  ApiState copyWith({
    bool? isApiAvailable,
    Object? errorMessage = _noValue,
    DateTime? lastChecked,
    bool? isChecking,
  }) {
    return ApiState(
      isApiAvailable: isApiAvailable ?? this.isApiAvailable,
      errorMessage: identical(errorMessage, _noValue)
          ? this.errorMessage
          : errorMessage as String?,
      lastChecked: lastChecked ?? this.lastChecked,
      isChecking: isChecking ?? this.isChecking,
    );
  }
}

class EnhancedNetworkStateNotifier extends StateNotifier<NetworkState> {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _probeTimer;
  AppLifecycleListener? _appLifecycleListener;
  bool _isChecking = false;
  DateTime? _lastTransportFailureAt;
  static final List<Uri> _internetProbeUris = [
    Uri.parse('https://clients3.google.com/generate_204'),
    Uri.parse('https://cloudflare.com/cdn-cgi/trace'),
    Uri.parse('https://example.com'),
  ];

  EnhancedNetworkStateNotifier()
    : super(const NetworkState(isConnected: true, isInitialized: false)) {
    _init();
  }

  Future<void> _init() async {
    try {
      await _performConnectivityCheck();

      _appLifecycleListener = AppLifecycleListener(
        onResume: () {
          if (!mounted) return;
          unawaited(_performConnectivityCheck());
        },
      );

      _subscription = _connectivity.onConnectivityChanged.listen((_) async {
        await _performConnectivityCheck();
      });

      _probeTimer = Timer.periodic(const Duration(seconds: 8), (_) async {
        if (!mounted) return;
        await _performConnectivityCheck();
      });
    } catch (e) {
      state = state.copyWith(
        isConnected: false,
        isInitialized: true,
        errorMessage: 'Network initialization failed: $e',
        lastChecked: DateTime.now(),
      );
    }
  }

  Future<void> _performConnectivityCheck() async {
    if (_isChecking) return;
    _isChecking = true;
    try {
      final results = await _connectivity.checkConnectivity();
      final hasNetworkLink = !results.contains(ConnectivityResult.none);
      final connectionType =
          results.isNotEmpty ? results.first : ConnectivityResult.none;
      final isConnected = hasNetworkLink && await _hasInternetAccess();

      state = state.copyWith(
        isConnected: isConnected,
        isInitialized: true,
        errorMessage: isConnected ? null : 'No network connection',
        lastChecked: DateTime.now(),
        connectionType: connectionType,
      );
    } catch (e) {
      state = state.copyWith(
        isConnected: false,
        isInitialized: true,
        errorMessage: 'Network check failed: $e',
        lastChecked: DateTime.now(),
      );
    } finally {
      _isChecking = false;
    }
  }

  Future<bool> _hasInternetAccess() async {
    final probeDio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 4),
        receiveTimeout: const Duration(seconds: 4),
        sendTimeout: const Duration(seconds: 4),
        followRedirects: false,
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    try {
      for (final uri in _internetProbeUris) {
        try {
          final response = await probeDio.getUri<dynamic>(uri);
          if (response.statusCode != null) {
            return true;
          }
        } on DioException catch (e) {
          if (e.type == DioExceptionType.badResponse && e.response != null) {
            return true;
          }
        } catch (_) {
          // Try next probe endpoint before declaring offline.
        }
      }

      return false;
    } catch (_) {
      return false;
    } finally {
      probeDio.close(force: true);
    }
  }

  Future<void> checkConnection() async {
    await _performConnectivityCheck();
  }

  Future<void> retryConnection() async {
    state = state.copyWith(
      isRetrying: true,
      errorMessage: null,
    );

    await Future.delayed(const Duration(milliseconds: 400));
    await _performConnectivityCheck();

    state = state.copyWith(
      isRetrying: false,
      isInitialized: true,
    );
  }

  Future<void> handleTransportFailure([String? message]) async {
    final now = DateTime.now();
    final lastFailure = _lastTransportFailureAt;

    // Prevent rapid-fire failures from flipping state repeatedly.
    if (lastFailure != null && now.difference(lastFailure).inMilliseconds < 1200) {
      return;
    }
    _lastTransportFailureAt = now;

    final hasInternet = await _hasInternetAccess();
    if (hasInternet) {
      markConnectedFromRequest();
      return;
    }

    markDisconnectedFromRequest(message ?? 'No internet connection');
  }

  void markDisconnectedFromRequest([String? message]) {
    state = state.copyWith(
      isConnected: false,
      isInitialized: true,
      errorMessage: message ?? 'No network connection',
      lastChecked: DateTime.now(),
    );
  }

  void markConnectedFromRequest() {
    state = state.copyWith(
      isConnected: true,
      isInitialized: true,
      errorMessage: null,
      lastChecked: DateTime.now(),
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _probeTimer?.cancel();
    _appLifecycleListener?.dispose();
    super.dispose();
  }
}

class ApiStateNotifier extends StateNotifier<ApiState> {
  final ApiService _apiService;
  Timer? _healthCheckTimer;

  ApiStateNotifier(this._apiService)
    : super(const ApiState(isApiAvailable: true)) {
    _startInitialCheck();
  }

  void _startInitialCheck() async {
    await Future.delayed(const Duration(milliseconds: 300));
    await checkApiHealth();

    _healthCheckTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      if (!state.isChecking && mounted) {
        checkApiHealth();
      }
    });
  }

  Future<void> checkApiHealth() async {
    if (state.isChecking) {
      return;
    }

    state = state.copyWith(isChecking: true);

    try {
      await _apiService.checkHealth().timeout(const Duration(seconds: 10));

      state = state.copyWith(
        isApiAvailable: true,
        errorMessage: null,
        lastChecked: DateTime.now(),
        isChecking: false,
      );
    } catch (e) {
      String errorMessage;
      if (e is DioException) {
        switch (e.type) {
          case DioExceptionType.connectionTimeout:
          case DioExceptionType.sendTimeout:
          case DioExceptionType.receiveTimeout:
            errorMessage = 'Server timeout';
            break;
          case DioExceptionType.connectionError:
            errorMessage = 'Cannot reach server';
            break;
          case DioExceptionType.badResponse:
            state = state.copyWith(
              isApiAvailable: true,
              errorMessage: null,
              lastChecked: DateTime.now(),
              isChecking: false,
            );
            return;
          default:
            errorMessage = 'Server unavailable';
        }
      } else {
        errorMessage = 'API health check failed';
      }

      state = state.copyWith(
        isApiAvailable: false,
        errorMessage: errorMessage,
        lastChecked: DateTime.now(),
        isChecking: false,
      );
    }
  }

  @override
  void dispose() {
    _healthCheckTimer?.cancel();
    super.dispose();
  }
}

final networkStateProvider =
    StateNotifierProvider<EnhancedNetworkStateNotifier, NetworkState>(
  (ref) => EnhancedNetworkStateNotifier(),
);


