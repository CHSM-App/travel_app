import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_agency_app/domain/models/booking_info.dart';
import 'package:travel_agency_app/domain/models/drivers.dart';
import 'package:travel_agency_app/domain/usecase/adddriverUseCase.dart';

@immutable
class AddDriverState {
  final bool isLoading;
  final Map<String, dynamic>? data;
  final String? error;
  final AsyncValue<List<BookingInfo>> fetchTripsByDriverId;

  const AddDriverState({
    this.fetchTripsByDriverId = const AsyncValue.loading(),
    this.isLoading = false,
    this.data,
    this.error,
  });

  AddDriverState copyWith({
    bool? isLoading,
    Map<String, dynamic>? data,
    bool clearData = false,
    String? error,
    bool clearError = false,
    AsyncValue<List<BookingInfo>>? fetchTripsByDriverId,

  }) {
    return AddDriverState(
      isLoading: isLoading ?? this.isLoading,
      data: clearData ? null : (data ?? this.data),
      error: clearError ? null : (error ?? this.error),
      fetchTripsByDriverId: fetchTripsByDriverId ?? this.fetchTripsByDriverId,

    );
  }
}

class AdddriverViewmodel extends StateNotifier<AddDriverState> {
  final AddDeiverUseCase usecase;

  AdddriverViewmodel(this.usecase) : super(const AddDriverState());
  Future<int> addDriver(Drivers driver) async {
    state = state.copyWith(isLoading: true, clearError: true, clearData: true);
    try {
      final result = await usecase.addDriver(driver);
      final driverId = _extractDriverId(result);
      state = state.copyWith(
        isLoading: false,
        data: result is Map<String, dynamic>
            ? result
            : <String, dynamic>{'driverId': driverId},
        error: null,
      );
      return driverId;
    } on DioException catch (e) {
      final serverMessage = _extractErrorMessage(e);
      state = state.copyWith(
        isLoading: false,
        error: serverMessage ?? 'Server error',
      );
      rethrow;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> updateDriver(Drivers driver) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await usecase.updateDriver(driver);
      state = state.copyWith(
        isLoading: false,
        data: result is Map<String, dynamic> ? result : null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<dynamic> uploadDriverDocument(
    File licenceDocument,
    int driverId,
    String agencyId,
  ) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await usecase.uploadDriverDocument(
        licenceDocument,
        driverId.toString(),
        agencyId,
      );
      state = state.copyWith(isLoading: false);
      return response;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }


  int _extractDriverId(dynamic result) {
    final id = _findIdRecursive(result);
    if (id != null) return id;

    throw Exception(
      'Unable to extract driver ID from API response. '
      'Response type: ${result.runtimeType}',
    );
  }

  int? _findIdRecursive(dynamic node) {
    if (node == null) return null;

    if (node is int) return node;
    if (node is num) return node.toInt();

    if (node is String) {
      final direct = int.tryParse(node.trim());
      if (direct != null) return direct;
      final firstDigits = RegExp(r'\d+').firstMatch(node)?.group(0);
      if (firstDigits != null) return int.tryParse(firstDigits);
      return null;
    }

    if (node is Map) {
      const candidateKeys = <String>[
        'driverId',
        'DriverId',
        'driver_id',
        'DriverID',
        'driverID',
        'id',
        'ID',
        'insertId',
        'InsertId',
        'insertedId',
        'InsertedId',
      ];

      for (final key in candidateKeys) {
        if (node.containsKey(key)) {
          final found = _findIdRecursive(node[key]);
          if (found != null) return found;
        }
      }

      for (final value in node.values) {
        final found = _findIdRecursive(value);
        if (found != null) return found;
      }
      return null;
    }

    if (node is Iterable) {
      for (final item in node) {
        final found = _findIdRecursive(item);
        if (found != null) return found;
      }
      return null;
    }

    return null;
  }

  Future<void> fetchDriverHistory(int driverId) async {
     state = state.copyWith(
      fetchTripsByDriverId: const AsyncValue.loading(),
      clearError: true,
    );
    try {
      final result = await usecase.fetchDriverHistory(driverId);
      state = state.copyWith(fetchTripsByDriverId: AsyncValue.data(result));
    } catch (e, st) {
      state = state.copyWith(fetchTripsByDriverId: AsyncValue.error(e, st));
    }
  }
  
Future<Map<String, dynamic>> deleteDriver(int driverId) async {
  state = state.copyWith(isLoading: true, clearError: true);
  try {
    final result = await usecase.deleteDriver(driverId);
    state = state.copyWith(isLoading: false, data: result);
    final status = result['status'];
    final isSuccess = status == 1 || status == '1' || status == true;
    if (isSuccess) {
      return {'success': true, 'message': result['message'] ?? 'Deleted successfully'};
    } else {
      return {'success': false, 'message': result['message'] ?? 'Delete failed'};
    }
  } on DioException catch (e) {
    final message = _extractErrorMessage(e) ?? "Server error";
    state = state.copyWith(isLoading: false, error: message);
    return {'success': false, 'message': message};
  } catch (e) {
    final message = e.toString();
    state = state.copyWith(isLoading: false, error: message);
    return {'success': false, 'message': message};
  }
}

String? _extractErrorMessage(DioException e) {
  final raw = e.response?.data;
  if (raw is Map<String, dynamic>) {
    final msg = raw['message']?.toString().trim();
    if (msg != null && msg.isNotEmpty) return msg;
  }
  final fallback = e.message?.trim();
  if (fallback != null && fallback.isNotEmpty) return fallback;
  return null;
}
}
