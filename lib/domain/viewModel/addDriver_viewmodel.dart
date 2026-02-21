import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_agency_app/domain/models/drivers.dart';
import 'package:travel_agency_app/domain/usecase/adddriverUseCase.dart';

@immutable
class AddDriverState {
  final bool isLoading;
  final Map<String, dynamic>? data;
  final String? error;

  const AddDriverState({
    this.isLoading = false,
    this.data,
    this.error,
  });

  AddDriverState copyWith({
    bool? isLoading,
    Map<String, dynamic>? data,
    String? error,
  }) {
    return AddDriverState(
      isLoading: isLoading ?? this.isLoading,
      data: data ?? this.data,
      error: error ?? this.error,
    );
  }
}

class AdddriverViewmodel extends StateNotifier<AddDriverState> {
  final Ref ref;
  final AddDeiverUseCase usecase;

  AdddriverViewmodel(this.ref, this.usecase) : super(const AddDriverState());

  Future<int> addDriver(Drivers driver) async {
    state = state.copyWith(isLoading: true, error: null, data: null);

    try {
      final result = await usecase.addDriver(driver);
      final driverId = _extractDriverId(result);

      state = state.copyWith(
        isLoading: false,
        data: result is Map<String, dynamic>
            ? result
            : <String, dynamic>{'driver6Id': driverId},
        error: null,
      );
      return driverId;
    } on DioException catch (e) {
      final serverMessage = e.response?.data?['message'];
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
    state = state.copyWith(isLoading: true, error: null);
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
    state = state.copyWith(isLoading: true, error: null);
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
    if (result is Map<String, dynamic>) {
      final raw =
          result['driverId'] ?? result['DriverId'] ?? result['id'] ?? result['ID'];
      if (raw is int) return raw;
      final parsed = int.tryParse(raw?.toString() ?? '');
      if (parsed != null) return parsed;
    }
    throw Exception('Unable to extract driver ID from API response');
  }
}
