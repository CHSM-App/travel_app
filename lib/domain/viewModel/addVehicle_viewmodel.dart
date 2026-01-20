import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_agency_app/domain/models/fueltype.dart';
import 'package:travel_agency_app/domain/models/status.dart';
import 'package:travel_agency_app/domain/models/vehicles.dart';
import 'package:travel_agency_app/domain/models/vehicletype.dart';
import 'package:travel_agency_app/domain/usecase/addVehicleUseCase.dart';

@immutable
class AddVehicleState {

final bool isLoading;
  final Map<String, dynamic>? data;
  final String? error;


  final AsyncValue<List<VehicleType>> fetchVehicleTypeList;
  final AsyncValue<List<Status>> fetchstatusList;
  final AsyncValue<List<Fueltype>> fetchFuelTypeList;

  const AddVehicleState({
     this.isLoading = false,
     this.data ,
    this.error,

    this.fetchVehicleTypeList = const AsyncValue.loading(),
    this.fetchstatusList = const AsyncValue.loading(),
    this.fetchFuelTypeList = const AsyncValue.loading(),
      });

  AddVehicleState copyWith({

       bool? isLoading,
    Map<String, dynamic>? data,
    String? error,
    AsyncValue<List<VehicleType>>? fetchVehicleTypeList,
    AsyncValue<List<Status>>? fetchstatusList,
    AsyncValue<List<Fueltype>>? fetchFuelTypeList,
  }) {
    return AddVehicleState(
    
       isLoading: isLoading ?? this.isLoading,
      data: data ?? this.data,
      error: error ?? this.error,
      fetchVehicleTypeList: fetchVehicleTypeList ?? this.fetchVehicleTypeList,
      fetchstatusList: fetchstatusList ?? this.fetchstatusList,
      fetchFuelTypeList: fetchFuelTypeList ?? this.fetchFuelTypeList
    );
  }
}


class AddVehicleViewModel extends StateNotifier<AddVehicleState> {
  final Ref ref;
  final AddVehicleUseCase usecase;

  AddVehicleViewModel(this.ref, this.usecase)
      : super(const AddVehicleState());


Future<void> addVehicle(Vehicles vehicle) async {
  state = state.copyWith(isLoading: true, error: null);

  try {
    final result = await usecase.addVehicle(vehicle);

    state = state.copyWith(
      isLoading: false,
      error: null, // success, so no error
    );

  } on DioException catch (e) {
    final serverMessage = e.response?.data?['message'];

    state = state.copyWith(
      isLoading: false,
      error: serverMessage ?? 'Server error',
    );

    debugPrint("Server error: $serverMessage");
  } catch (e) {
    state = state.copyWith(
      isLoading: false,
      error: e.toString(),
    );
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
  

 }