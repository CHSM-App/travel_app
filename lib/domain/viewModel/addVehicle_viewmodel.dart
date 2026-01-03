import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_agency_app/domain/models/customers.dart';
import 'package:travel_agency_app/domain/models/drivers.dart';
import 'package:travel_agency_app/domain/models/tripbooking_info.dart';
import 'package:travel_agency_app/domain/models/vehicles.dart';
import 'package:travel_agency_app/domain/usecase/tripbooking_usecase.dart';

@immutable
class AddVehicleState {

final bool isLoading;
  final Map<String, dynamic>? data;
  final String? error;


  // final String? data;
  // final AsyncValue<List<Drivers>> fetchDriverList;
  // final AsyncValue<List<Vehicles>> fetchVehicleList;
  // final AsyncValue<List<Customer>> fetchCustomerList;

  const AddVehicleState({
     this.isLoading = false,
     this.data ,
    this.error,

    // this.fetchDriverList = const AsyncValue.loading(),
    // this.fetchVehicleList = const AsyncValue.loading(),
    // this.fetchCustomerList = const AsyncValue.loading(),
      });

  AddVehicleState copyWith({

       bool? isLoading,
    Map<String, dynamic>? data,
    String? error,
    // AsyncValue<List<Drivers>>? fetchDriverList,
    // AsyncValue<List<Vehicles>>? fetchVehicleList,
    // AsyncValue<List<Customer>>? fetchCustomerList,
  }) {
    return AddVehicleState(
    
       isLoading: isLoading ?? this.isLoading,
      data: data ?? this.data,
      error: error ?? this.error,
      // fetchDriverList: fetchDriverList ?? this.fetchDriverList,
      // fetchVehicleList: fetchVehicleList ?? this.fetchVehicleList
      // ,fetchCustomerList: fetchCustomerList ?? this.fetchCustomerList
    );
  }
}


class AddVehicleViewModel extends StateNotifier<AddVehicleState> {
  final Ref ref;
  final TripbookingUsecase usecase;

  AddVehicleViewModel(this.ref, this.usecase)
      : super(const AddVehicleState());

 Future<void> addVehicle(Vehicles vehicle) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // final result = await usecase.addVehicle(vehicle);
      
    }catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }

}

 }