
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_agency_app/domain/models/booking_info.dart';
import 'package:travel_agency_app/domain/usecase/tripbooking_usecase.dart';


class TripPageState {

final bool isLoading;
  final Map<String, dynamic>? data;
  final String? error;
  final AsyncValue<List<BookingInfo>> upcomingList;
  final AsyncValue<List<BookingInfo>> historyList;
  final AsyncValue<List<BookingInfo>> unpaidList;
  final AsyncValue<List<BookingInfo>> activeList;
  final AsyncValue<List<BookingInfo>> cancelledList;
 
  const TripPageState({
   
     this.isLoading = false,
    this.data,
    this.error,
    this.upcomingList = const AsyncValue.loading(),
    this.historyList = const AsyncValue.loading(),
    this.unpaidList = const AsyncValue.loading(),
    this.activeList = const AsyncValue.loading(),
    this.cancelledList = const AsyncValue.loading(),
 
      });

  TripPageState copyWith({

       bool? isLoading,
    Map<String, dynamic>? data,
    String? error,
    AsyncValue<List<BookingInfo>>? upcomingList,
    AsyncValue<List<BookingInfo>>? historyList,
    AsyncValue<List<BookingInfo>>? unpaidList,
    AsyncValue<List<BookingInfo>>? activeList,
    AsyncValue<List<BookingInfo>>? cancelledList,
   
  }) {
    return TripPageState(
    
       isLoading: isLoading ?? this.isLoading,
      data: data ?? this.data,
      error: error ?? this.error,
      upcomingList: upcomingList ?? this.upcomingList,
      historyList: historyList ?? this.historyList,
      unpaidList: unpaidList ?? this.unpaidList,
      activeList: activeList ?? this.activeList,
      cancelledList: cancelledList ?? this.cancelledList,
       
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

    Future<void> activeList() async {
    state = state.copyWith(activeList: const AsyncValue.loading());
    try {
      final result = await usecase.activeTrip();
      state = state.copyWith(activeList: AsyncValue.data(result));
    } catch (e, st) {
      state = state.copyWith(activeList: AsyncValue.error(e, st));
    }
  }

  Future<void> cancelledList() async {
    state = state.copyWith(cancelledList: const AsyncValue.loading());
    try {
      final result = await usecase.cancelledTrip();
      state = state.copyWith(cancelledList: AsyncValue.data(result));
    } catch (e, st) {
      state = state.copyWith(cancelledList: AsyncValue.error(e, st));
    }
  }


   Future<void> updatePaymentStatus(BookingInfo bookinginfo) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await usecase.updatePaymentStatus(bookinginfo);
      state = state.copyWith(isLoading: false, data: result);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  
}




