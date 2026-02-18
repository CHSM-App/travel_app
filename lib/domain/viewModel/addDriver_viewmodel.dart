import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:travel_agency_app/domain/models/drivers.dart';
import 'package:travel_agency_app/domain/usecase/adddriverUseCase.dart';

@immutable

class AddDriverState{

  final bool isLoading;
  final Map<String,dynamic>? data;
  final String? error;

  AddDriverState({
    
  this.isLoading=false, 
  this.data, 
  this.error});

  AddDriverState copyWith({
  bool? isLoading,
  Map<String,dynamic>? data,
  String? error
 }){
  return AddDriverState(
    isLoading: isLoading?? this.isLoading,
    data: data?? this.data,
    error: error?? this.error
    );
 }
  
}
class AdddriverViewmodel extends StateNotifier<AddDriverState> {
  final Ref ref;
  final AddDeiverUseCase usecase;

  AdddriverViewmodel(this.ref, this.usecase)
      : super(AddDriverState());

  Future<void> addDriver(Drivers drivers) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      data: null, // reset old data
    );

    try {
      final result = await usecase.addDriver(drivers);

      /// ✅ IMPORTANT: SET DATA ON SUCCESS
      state = state.copyWith(
        isLoading: false,
        data: {
          "success": true,
          "message": "Driver added",
        },
        error: null,
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

  Future<void> updateDriver(Drivers driver) async {
  state = state.copyWith(isLoading: true, error: null);

  try {
    final result = await usecase.updateDriver(driver);
    state = state.copyWith(isLoading: false, data: result);
  } catch (e) {
    state = state.copyWith(isLoading: false, error: e.toString());
  }
}

}


