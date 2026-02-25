import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_agency_app/domain/models/booking_info.dart';
import 'package:travel_agency_app/domain/models/fueltype.dart';
import 'package:travel_agency_app/domain/models/services.dart';
import 'package:travel_agency_app/domain/models/status.dart';
import 'package:travel_agency_app/domain/models/vehicles.dart';
import 'package:travel_agency_app/domain/models/vehicletype.dart';
import 'package:travel_agency_app/domain/usecase/addVehicleUseCase.dart';

@immutable
class AddVehicleState {

final bool isLoading;
  final Map<String, dynamic>? data;
  final String? error;
  final int? vehicleId;
  final int? serviceId;
  final AsyncValue<List<VehicleType>> fetchVehicleTypeList;
  final AsyncValue<List<Status>> fetchstatusList;
  final AsyncValue<List<Fueltype>> fetchFuelTypeList;
  final AsyncValue<List<BookingInfo>> fetchTripsByVehicleId;
   final AsyncValue<List<Services>> fetchServiceRecords;

  const AddVehicleState({
     this.isLoading = false,
     this.data ,
    this.error,
    this.vehicleId,
    this.serviceId,
    this.fetchVehicleTypeList = const AsyncValue.loading(),
    this.fetchstatusList = const AsyncValue.loading(),
    this.fetchFuelTypeList = const AsyncValue.loading(),
    this.fetchTripsByVehicleId = const AsyncValue.loading(),
    this.fetchServiceRecords = const AsyncValue.loading(),
      });

  AddVehicleState copyWith({
        int? vehicleId,
        int? serviceId,
       bool? isLoading,
    Map<String, dynamic>? data,
    String? error,
        bool clearError = false,
        bool clearData = false,
    AsyncValue<List<VehicleType>>? fetchVehicleTypeList,
    AsyncValue<List<Status>>? fetchstatusList,
    AsyncValue<List<Fueltype>>? fetchFuelTypeList,
    AsyncValue<List<BookingInfo>>? fetchTripsByVehicleId,
     AsyncValue<List<Services>>? fetchServiceRecords,

  }) {
    return AddVehicleState(
       vehicleId: vehicleId ?? this.vehicleId,
       serviceId: serviceId ?? this.serviceId,
       isLoading: isLoading ?? this.isLoading,
      data: data ?? this.data,
      error: error ?? this.error,
      fetchVehicleTypeList: fetchVehicleTypeList ?? this.fetchVehicleTypeList,
      fetchstatusList: fetchstatusList ?? this.fetchstatusList,
      fetchFuelTypeList: fetchFuelTypeList ?? this.fetchFuelTypeList,
      fetchTripsByVehicleId: fetchTripsByVehicleId ?? this.fetchTripsByVehicleId,
      fetchServiceRecords: fetchServiceRecords ?? this.fetchServiceRecords,
    );
  }
}


class AddVehicleViewModel extends StateNotifier<AddVehicleState> {
  final Ref ref;
  final AddVehicleUseCase usecase;

  AddVehicleViewModel(this.ref, this.usecase)
      : super(const AddVehicleState());

Future<int> addVehicle(Vehicles vehicle) async {
  state = state.copyWith(isLoading: true, clearData: true, clearError: true);
  try {
    final result = await usecase.addVehicle(vehicle);
    final int vehicleId = result['VehicleId'] as int; 
    state = state.copyWith(isLoading: false, data: result);
    return vehicleId;
  } on DioException catch (e) {
    final serverMessage = e.response?.data?['message'];
    state = state.copyWith(isLoading: false, error: serverMessage ?? 'Server error');
    rethrow;
  } catch (e) {
    state = state.copyWith(isLoading: false, error: e.toString());
    rethrow;
  }
}

Future<void> updateVehicle(Vehicles vehicle) async {
  state = state.copyWith(isLoading: true, error: null);

  try {
    final result = await usecase.updateVehicle(vehicle);
    state = state.copyWith(isLoading: false, data: result);
  } catch (e) {
    state = state.copyWith(isLoading: false, error: e.toString());
    rethrow;
  }
}


  Future<void> fetchVehicleTypeList() async {
    state = state.copyWith(fetchVehicleTypeList: const AsyncValue.loading());
    try {
      final result = await usecase.getVehicleTypes();
      state = state.copyWith(fetchVehicleTypeList: AsyncValue.data(result));
    } catch (e, st) {
      state = state.copyWith(fetchVehicleTypeList: AsyncValue.error(e, st));
    }
  }


   Future<void> fetchVehicleFuelTypeList() async {
    state = state.copyWith(fetchFuelTypeList: const AsyncValue.loading());
    try {
      final result = await usecase.getVehicleFuelTypes();
      state = state.copyWith(fetchFuelTypeList: AsyncValue.data(result));
    } catch (e, st) {
      state = state.copyWith(fetchFuelTypeList: AsyncValue.error(e, st));
    }
  }


    Future<void> fetchstatusList() async {
    state = state.copyWith(fetchstatusList: const AsyncValue.loading());
    try {
      final result = await usecase.getVehicleStatuses();
      state = state.copyWith(fetchstatusList: AsyncValue.data(result));
    } catch (e, st) {
      state = state.copyWith(fetchstatusList: AsyncValue.error(e, st));
    }
  }
  
  
  Future<dynamic> uploadVehicleDocument(File rcDocuments, int vehicleId, String agencyId) async {
    try {
      state = state.copyWith(isLoading: true);
      final response = await usecase.uploadVehicleDocument(rcDocuments, vehicleId.toString(), agencyId);
      state = state.copyWith(isLoading: false);
      return response;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

    Future<void> getTripsByVehicle(int vehicleId) async {
    state = state.copyWith(fetchTripsByVehicleId: const AsyncValue.loading());
    try {
      final result = await usecase.getTripsByVehicle(vehicleId);
      state = state.copyWith(fetchTripsByVehicleId: AsyncValue.data(result));
    } catch (e, st) {
      state = state.copyWith(fetchTripsByVehicleId: AsyncValue.error(e, st));
    }
  }

   Future<void> getServiceRecords(String agencyId, int vehicleId) async {
    state = state.copyWith(fetchServiceRecords: const AsyncValue.loading());
    try {
       print("Calling API...");
      final result = await usecase.getServiceRecords(agencyId,vehicleId);
      print("API RESULT: $result");
      state = state.copyWith(fetchServiceRecords: AsyncValue.data(result));
    } catch (e, st) {
       print("API ERROR: $e");
    print("STACK: $st");

      state = state.copyWith(fetchServiceRecords: AsyncValue.error(e, st));
    }
  }

  Future<void> addService(Services service) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await usecase.addService(service );
      state = state.copyWith(isLoading: false, data: result);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateService(int serviceId, Services services) async {
     state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await usecase.updateService(serviceId,services );
      state = state.copyWith(isLoading: false, data: result);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> deleteService(int serviceId) async {
  state = state.copyWith(isLoading: true, error: null);
  try {
    await usecase.deleteService(serviceId);
    state = state.copyWith(isLoading: false);
  } catch (e) {
    state = state.copyWith(isLoading: false, error: e.toString());
    rethrow;
  }
}



Future<Map<String, dynamic>> deleteVehicle(int vehicleid) async {
  state = state.copyWith(isLoading: true, error: null);

  try {
    final result = await usecase.deleteVehicle(vehicleid);
    state = state.copyWith(isLoading: false);
    final status = result['status'];
    final isSuccess = status == 1 || status == '1' || status == true;

    if (isSuccess) {
      return {'success': true, 'message': result['message'] ?? 'Deleted successfully'};
    } else {
      return {'success': false, 'message': result['message'] ?? 'Delete failed'};
    }
  } on DioException catch (e) {
    final message = e.response?.data?['message'] ?? "Server error";
    state = state.copyWith(isLoading: false, error: message);
    return {'success': false, 'message': message};
  } catch (e) {
    final message = e.toString();
    state = state.copyWith(isLoading: false, error: message);
    return {'success': false, 'message': message};
  }
}
 }
