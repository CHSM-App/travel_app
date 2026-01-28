import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_agency_app/domain/models/booking_info.dart';
import 'package:travel_agency_app/domain/usecase/tripbooking_usecase.dart';

class UpcomingTripState {
  final bool isLoading;
  final List<dynamic>? data;
  final String? error;

  final AsyncValue<List<BookingInfo>> upcomingTripList;

  const UpcomingTripState({
    this.isLoading = false,
    this.data,
    this.error,
    this.upcomingTripList = const AsyncValue.loading(),
  });

  UpcomingTripState copyWith({
    bool? isLoading,
    List<dynamic>? data,
    String? error,
    AsyncValue<List<BookingInfo>>? upcomingTripList,
  }) {
    return UpcomingTripState(
      isLoading: isLoading ?? this.isLoading,
      data: data ?? this.data,
      error: error ?? this.error,
      upcomingTripList: upcomingTripList ?? this.upcomingTripList,
    );
  }
}

class UpcomingTripViewModel extends StateNotifier<UpcomingTripState> {

  final TripbookingUsecase usecase;

  UpcomingTripViewModel(this.usecase) : super(const UpcomingTripState());

  /// Fetch upcoming trips
  Future<void> fetchUpcomingTrips() async {
    state = state.copyWith(upcomingTripList: const AsyncValue.loading());

    try {
      final result = await usecase.upcomingTrip();
      state = state.copyWith(
        upcomingTripList: AsyncValue.data(result),
      );
    } catch (e,st) {
      state = state.copyWith(
       upcomingTripList: AsyncValue.error(e,st));
    }
    }
  } 
  