import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_agency_app/domain/models/drivers.dart';
import 'package:travel_agency_app/domain/models/tripbooking_info.dart';
import 'package:travel_agency_app/domain/models/vehicles.dart';
import 'package:travel_agency_app/domain/usecase/tripbooking_usecase.dart';

@immutable
class TripBookingState {

final bool isLoading;
  final Map<String, dynamic>? data;
  final String? error;
   final AsyncValue<List<Drivers>> fetchDriverList;
  final AsyncValue<List<Vehicles>> fetchVehicleList;
  const TripBookingState({
   
     this.isLoading = false,
    this.data,
    this.error,
    this.fetchDriverList = const AsyncValue.loading(),
    this.fetchVehicleList = const AsyncValue.loading(),
      });



  TripBookingState copyWith({

       bool? isLoading,
    Map<String, dynamic>? data,
    String? error,
    AsyncValue<List<Drivers>>? fetchDriverList,
    AsyncValue<List<Vehicles>>? fetchVehicleList,
  }) {
    return TripBookingState(
    
       isLoading: isLoading ?? this.isLoading,
      data: data ?? this.data,
      error: error ?? this.error,
      fetchDriverList: fetchDriverList ?? this.fetchDriverList,
      fetchVehicleList: fetchVehicleList ?? this.fetchVehicleList
    );
  }
}
class TripBookingViewModel extends StateNotifier<TripBookingState> {
  final Ref ref;
  final TripbookingUsecase usecase;

  TripBookingViewModel(this.ref, this.usecase)
      : super(const TripBookingState());

 Future<void> addTripBooking(TripBooking tripbooking) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await usecase.addTripBooking(tripbooking);
      state = state.copyWith(isLoading: false, data: result);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
    Future<void> driverList() async {
    state = state.copyWith(fetchDriverList: const AsyncValue.loading());
    try {
      final result = await usecase.driverList();
      state = state.copyWith(fetchDriverList: AsyncValue.data(result));
    } catch (e, st) {
      state = state.copyWith(fetchDriverList: AsyncValue.error(e, st));
    }
  }

  Future<void> vehicleList() async {
    state = state.copyWith(fetchVehicleList: const AsyncValue.loading());
    try {
      final result = await usecase.vehicleList();
      state = state.copyWith(fetchVehicleList: AsyncValue.data(result));
    } catch (e, st) {
      state = state.copyWith(fetchVehicleList: AsyncValue.error(e, st));
    }
  }
}