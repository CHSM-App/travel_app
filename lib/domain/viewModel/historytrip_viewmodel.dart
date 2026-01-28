import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_agency_app/domain/models/booking_info.dart';
import 'package:travel_agency_app/domain/usecase/tripbooking_usecase.dart';

class HistoryTripState {
  final bool isLoading;
  final List<dynamic>? data;
  final String? error;

  final AsyncValue<List<BookingInfo>> HistoryTripList;

  const HistoryTripState({
    this.isLoading = false,
    this.data,
    this.error,
    this.HistoryTripList = const AsyncValue.loading(),
  });

  HistoryTripState copyWith({
    bool? isLoading,
    List<dynamic>? data,
    String? error,
    AsyncValue<List<BookingInfo>>? HistoryTripList,
  }) {
    return HistoryTripState(
      isLoading: isLoading ?? this.isLoading,
      data: data ?? this.data,
      error: error ?? this.error,
      HistoryTripList: HistoryTripList ?? this.HistoryTripList,
    );
  }
}

class HistoryTripViewModel extends StateNotifier<HistoryTripState> {

  final TripbookingUsecase usecase;

  HistoryTripViewModel(this.usecase) : super(const HistoryTripState());

  /// Fetch History trips
  Future<void> fetchHistoryTrips() async {
    state = state.copyWith(HistoryTripList: const AsyncValue.loading());

    try {
      final result = await usecase.historyTrip();
      state = state.copyWith(
        HistoryTripList: AsyncValue.data(result),
      );
    } catch (e,st) {
      state = state.copyWith(
       HistoryTripList: AsyncValue.error(e,st));
    }
    }
  } 
  