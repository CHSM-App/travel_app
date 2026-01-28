import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_agency_app/domain/models/booking_info.dart';
import 'package:travel_agency_app/domain/models/customers.dart';
import 'package:travel_agency_app/domain/models/drivers.dart';
import 'package:travel_agency_app/domain/models/tripbooking_info.dart';
import 'package:travel_agency_app/domain/models/vehicles.dart';
import 'package:travel_agency_app/domain/usecase/tripbooking_usecase.dart';

@immutable
class TripPageState {

final bool isLoading;
  final Map<String, dynamic>? data;
  final String? error;
  final AsyncValue<List<BookingInfo>> upcomingList;
  final AsyncValue<List<BookingInfo>> historyList;
  final AsyncValue<List<BookingInfo>> unpaidList;
  const TripPageState({
   
     this.isLoading = false,
    this.data,
    this.error,
    this.upcomingList = const AsyncValue.loading(),
    this.historyList = const AsyncValue.loading(),
    this.unpaidList = const AsyncValue.loading(),
      });



  TripPageState copyWith({

       bool? isLoading,
    Map<String, dynamic>? data,
    String? error,
    AsyncValue<List<BookingInfo>>? upcomingList,
    AsyncValue<List<BookingInfo>>? historyList,
    AsyncValue<List<BookingInfo>>? unpaidList
  }) {
    return TripPageState(
    
       isLoading: isLoading ?? this.isLoading,
      data: data ?? this.data,
      error: error ?? this.error,
      upcomingList: upcomingList ?? this.upcomingList,
      historyList: historyList ?? this.historyList
      ,unpaidList: unpaidList ?? this.unpaidList
    );
  }
}
class TripPageViewModel extends StateNotifier<TripPageState> {
  final Ref ref;
  final TripbookingUsecase usecase;

  TripPageViewModel(this.ref, this.usecase)
      : super(const TripPageState());

    Future<void> upcomingList() async {
    state = state.copyWith(upcomingList: const AsyncValue.loading());
    try {
      final result = await usecase.upcomingTrip();
      state = state.copyWith(upcomingList: AsyncValue.data(result));
    } catch (e, st) {
      state = state.copyWith(upcomingList: AsyncValue.error(e, st));
    }
  }

  Future<void> historyList() async {
    state = state.copyWith(historyList: const AsyncValue.loading());
    try {
      final result = await usecase.historyTrip();
      state = state.copyWith(historyList: AsyncValue.data(result));
    } catch (e, st) {
      state = state.copyWith(historyList: AsyncValue.error(e, st));
    }
  }

  Future<void> unpaidList() async {
    state = state.copyWith(unpaidList: const AsyncValue.loading());
    try {
      final result = await usecase.unpaidTrip();
      state = state.copyWith(unpaidList: AsyncValue.data(result));
    } catch (e, st) {
      state = state.copyWith(unpaidList: AsyncValue.error(e, st));
    }
  }



}