import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_agency_app/domain/models/booking_info.dart';
import 'package:travel_agency_app/domain/usecase/tripbooking_usecase.dart';

class UnpaidTripState {
  final bool isLoading;
  final List<dynamic>? data;
  final String? error;

  final AsyncValue<List<BookingInfo>> UnpaidTripList;

  const UnpaidTripState({
    this.isLoading = false,
    this.data,
    this.error,
    this.UnpaidTripList = const AsyncValue.loading(),
  });

  UnpaidTripState copyWith({
    bool? isLoading,
    List<dynamic>? data,
    String? error,
    AsyncValue<List<BookingInfo>>? UnpaidTripList,
  }) {
    return UnpaidTripState(
      isLoading: isLoading ?? this.isLoading,
      data: data ?? this.data,
      error: error ?? this.error,
      UnpaidTripList: UnpaidTripList ?? this.UnpaidTripList,
    );
  }
}

class UnpaidTripViewModel extends StateNotifier<UnpaidTripState> {

  final TripbookingUsecase usecase;

  UnpaidTripViewModel(this.usecase) : super(const UnpaidTripState());

  /// Fetch Unpaid trips
  Future<void> fetchUnpaidTrips() async {
    state = state.copyWith(UnpaidTripList: const AsyncValue.loading());

    try {
      final result = await usecase.unpaidTrip();
      state = state.copyWith(
        UnpaidTripList: AsyncValue.data(result),
      );
    } catch (e,st) {
      state = state.copyWith(
       UnpaidTripList: AsyncValue.error(e,st));
    }
    }
  } 
  