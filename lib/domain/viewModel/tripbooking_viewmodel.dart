import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_agency_app/domain/models/booking_info.dart';
import 'package:travel_agency_app/domain/models/customers.dart';
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
  final AsyncValue<List<Drivers>> fetchDeletedDriverList;
  final AsyncValue<List<Vehicles>> fetchVehicleList;
  final AsyncValue<List<Vehicles>> fetchDeletedVehicleList;
  final AsyncValue<List<Customer>> fetchCustomerList;
  final AsyncValue<List<Vehicles>> availableVehicles;
final AsyncValue<List<Drivers>> availableDrivers;
  final AsyncValue<List<BookingInfo>> routeHistory;
  final String? agencyId;
  const TripBookingState({
    this.isLoading = false,
    this.data,
    this.error,
    this.fetchDriverList = const AsyncValue.loading(),
    this.fetchVehicleList = const AsyncValue.loading(),
    this.fetchCustomerList = const AsyncValue.loading(),
    this.availableVehicles = const AsyncValue.loading(),
    this.availableDrivers = const AsyncValue.loading(),
    this.fetchDeletedDriverList = const AsyncValue.loading(),
    this.fetchDeletedVehicleList = const AsyncValue.loading(),
    this.routeHistory = const AsyncValue.data(<BookingInfo>[]),
    this.agencyId,
  });

  TripBookingState copyWith({
    bool? isLoading,
    Map<String, dynamic>? data,
    String? error,
    AsyncValue<List<Drivers>>? fetchDriverList,
    AsyncValue<List<Vehicles>>? fetchVehicleList,
    AsyncValue<List<Customer>>? fetchCustomerList,
    AsyncValue<List<Vehicles>>? availableVehicles,
    AsyncValue<List<Drivers>>? availableDrivers,
    AsyncValue<List<Drivers>>? fetchDeletedDriverList,
    AsyncValue<List<Vehicles>>? fetchDeletedVehicleList,
    AsyncValue<List<BookingInfo>>? routeHistory,

    String? agencyId,
  }) {
    return TripBookingState(
      isLoading: isLoading ?? this.isLoading,
      data: data ?? this.data,
      error: error ?? this.error,
      fetchDriverList: fetchDriverList ?? this.fetchDriverList,
      fetchVehicleList: fetchVehicleList ?? this.fetchVehicleList,
      fetchCustomerList: fetchCustomerList ?? this.fetchCustomerList,
      availableVehicles: availableVehicles ?? this.availableVehicles,
      availableDrivers: availableDrivers ?? this.availableDrivers,
      routeHistory: routeHistory ?? this.routeHistory,
      fetchDeletedDriverList: fetchDeletedDriverList ?? this.fetchDeletedDriverList,
      fetchDeletedVehicleList: fetchDeletedVehicleList ?? this.fetchDeletedVehicleList,
      agencyId: agencyId ?? this.agencyId,
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

  Future<void> driverList(String agencyId) async {
    state = state.copyWith(fetchDriverList: const AsyncValue.loading());
    try {
      final result = await usecase.driverList(agencyId);
      state = state.copyWith(
        fetchDriverList: AsyncValue.data(result),
        agencyId: agencyId,
      );
    } catch (e, st) {
      state = state.copyWith(fetchDriverList: AsyncValue.error(e, st));
    }
  }

   Future<void> deletedDriverList(String agencyId) async {
    state = state.copyWith(fetchDeletedDriverList: const AsyncValue.loading());
    try {
      final result = await usecase.deletedDriverList(agencyId);
      state = state.copyWith(
        fetchDeletedDriverList: AsyncValue.data(result),
        agencyId: agencyId,
      );
    } catch (e, st) {
      state = state.copyWith(fetchDeletedDriverList: AsyncValue.error(e, st));
    }
  }

  Future<void> vehicleList(String agencyId) async {
    state = state.copyWith(isLoading: true,);
    try {
      final result = await usecase.vehicleList(agencyId);
      // final result = await usecase.vehicleList(agencyId);
      state = state.copyWith(
        isLoading: false,
        fetchVehicleList: AsyncValue.data(result),
        agencyId: agencyId,
      );
    } catch (e, st) {
      state = state.copyWith(
        isLoading: false,
        fetchVehicleList: AsyncValue.error(e, st),
      );
    }
  }

  Future<void> deletedVehicleList(String agencyId) async {
    state = state.copyWith(isLoading: true);
    try {
      final result = await usecase.deletedVehicleList(agencyId);
      // final result = await usecase.vehicleList(agencyId);
      state = state.copyWith(
        isLoading: false,
        fetchDeletedVehicleList: AsyncValue.data(result),
        agencyId: agencyId,
      );
    } catch (e, st) {
      state = state.copyWith(
        isLoading: false,
        fetchDeletedVehicleList: AsyncValue.error(e, st),
      );
    }
  }

  Future<void> customerList(String agencyId) async {
    state = state.copyWith(isLoading: true);
    try {
      final result = await usecase.customerList(agencyId);

      state = state.copyWith(
        isLoading: false,
        fetchCustomerList: AsyncValue.data(result),
        agencyId: agencyId,
      );
    } catch (e, st) {
      state = state.copyWith(
        isLoading: false,
        fetchCustomerList: AsyncValue.error(e, st),
      );
    }
  }

  /// Loads the agency's completed trips so the booking form can suggest a
  /// fare whenever the operator enters a pickup/drop that was billed before
  /// (any customer). Reuses the existing `users/HistoryTrip/:agency_id`
  /// endpoint and is fetched once when the form opens.
  Future<void> loadRouteHistory(String agencyId) async {
    state = state.copyWith(routeHistory: const AsyncValue.loading());
    try {
      final result = await usecase.historyTrip(agencyId);
      state = state.copyWith(routeHistory: AsyncValue.data(result));
    } catch (e, st) {
      state = state.copyWith(routeHistory: AsyncValue.error(e, st));
    }
  }

  void addVehicle(Vehicles vehicles) {
    // usecase.addVehicle(vehicles);
    final currentList = state.fetchVehicleList.value ?? [];
    final updatedList = List<Vehicles>.from(currentList)..add(vehicles);
    state = state.copyWith(fetchVehicleList: AsyncValue.data(updatedList));
  }


    Future<void> getTripsByVehicle(String agencyId) async {
    state = state.copyWith(isLoading: true);
    try {
      final result = await usecase.customerList(agencyId);

      state = state.copyWith(
        isLoading: false,
        fetchCustomerList: AsyncValue.data(result),
      );
    } catch (e, st) {
      state = state.copyWith(
        isLoading: false,
        fetchCustomerList: AsyncValue.error(e, st),
      );
    }
  }

  Future<void> updateTripBooking(int tripId, TripBooking booking) async {
     state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await usecase.updateTripBooking(tripId, booking);
      state = state.copyWith(isLoading: false, data: result);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> fetchAvailableVehicles(String agencyId, DateTime start, DateTime end, int? tripId) async {
      state = state.copyWith(availableVehicles: const AsyncValue.loading());
    try {
      final result = await usecase.fetchAvailableVehicles(agencyId, start, end, tripId);

      state = state.copyWith(
        isLoading: false,
        availableVehicles: AsyncValue.data(result),
      );
    } catch (e, st) {
      state = state.copyWith(
        isLoading: false,
        availableVehicles: AsyncValue.error(e, st),
      );
    }
  }

  void fetchAvailableDrivers(String agencyId, DateTime start, DateTime end, int? tripId) async{
     state = state.copyWith(availableDrivers: const AsyncValue.loading());
    try {
      final result = await usecase.fetchAvailableDrivers(agencyId, start, end, tripId);

      state = state.copyWith(
        isLoading: false,
        availableDrivers: AsyncValue.data(result),
      );
    } catch (e, st) {
      state = state.copyWith(
        isLoading: false,
        availableDrivers: AsyncValue.error(e, st),
      );
    }
  }

}
