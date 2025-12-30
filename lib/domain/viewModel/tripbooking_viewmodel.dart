import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_agency_app/domain/models/tripbooking_info.dart';
import 'package:travel_agency_app/domain/usecase/tripbooking_usecase.dart';

@immutable
class TripBookingState {

final bool isLoading;
  final Map<String, dynamic>? data;
  final String? error;
  const TripBookingState({
   
     this.isLoading = false,
    this.data,
    this.error,
  });



  TripBookingState copyWith({

       bool? isLoading,
    Map<String, dynamic>? data,
    String? error,
  }) {
    return TripBookingState(
    
       isLoading: isLoading ?? this.isLoading,
      data: data ?? this.data,
      error: error ?? this.error,
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
}

