
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_agency_app/domain/models/booking_info.dart';
import 'package:travel_agency_app/domain/models/payment_history.dart';
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
  final AsyncValue<List<BookingInfo>> allList;
  final AsyncValue<List<PaymentHistory>> paymentHistory;

  const TripPageState({

     this.isLoading = false,
    this.data,
    this.error,
    this.upcomingList = const AsyncValue.loading(),
    this.historyList = const AsyncValue.loading(),
    this.unpaidList = const AsyncValue.loading(),
    this.activeList = const AsyncValue.loading(),
    this.cancelledList = const AsyncValue.loading(),
    this.allList = const AsyncValue.loading(),
    this.paymentHistory = const AsyncValue.loading(),

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
    AsyncValue<List<BookingInfo>>? allList,
      AsyncValue<List<PaymentHistory>>? paymentHistory,

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
      allList: allList ?? this.allList,
      paymentHistory: paymentHistory ?? this.paymentHistory,
    );
  }
}



class TripPageViewModel extends StateNotifier<TripPageState> {
  final Ref ref;
  final TripbookingUsecase usecase;

  TripPageViewModel(this.ref, this.usecase)
      : super(const TripPageState());

    Future<void> upcomingList(String agencyId) async {
    state = state.copyWith(upcomingList: const AsyncValue.loading());
    try {
      final result = await usecase.upcomingTrip(agencyId);
      state = state.copyWith(upcomingList: AsyncValue.data(result));
    } catch (e, st) {
      state = state.copyWith(upcomingList: AsyncValue.error(e, st));
    }
  }

  Future<void> historyList(String agencyId) async {
    state = state.copyWith(historyList: const AsyncValue.loading());
    try {
      final result = await usecase.historyTrip(agencyId);
      state = state.copyWith(historyList: AsyncValue.data(result));
    } catch (e, st) {
      state = state.copyWith(historyList: AsyncValue.error(e, st));
    }
  }

  Future<void> unpaidList(String agencyId) async {
    state = state.copyWith(unpaidList: const AsyncValue.loading());
    try {
      final result = await usecase.unpaidTrip(agencyId);
      state = state.copyWith(unpaidList: AsyncValue.data(result));
    } catch (e, st) {
      state = state.copyWith(unpaidList: AsyncValue.error(e, st));
    }
  }

    Future<void> activeList(String agencyId) async {
    state = state.copyWith(activeList: const AsyncValue.loading());
    try {
      final result = await usecase.activeTrip(agencyId);
      state = state.copyWith(activeList: AsyncValue.data(result));
    } catch (e, st) {
      state = state.copyWith(activeList: AsyncValue.error(e, st));
    }
  }

  Future<void> cancelledList(String agencyId) async {
    state = state.copyWith(cancelledList: const AsyncValue.loading());
    try {
      final result = await usecase.cancelledTrip(agencyId);
      state = state.copyWith(cancelledList: AsyncValue.data(result));
    } catch (e, st) {
      state = state.copyWith(cancelledList: AsyncValue.error(e, st));
    }
  }


  /// "All" tab: no single backend endpoint returns every trip, so fetch the
  /// five status lists in parallel, de-dupe by trip id (a trip can appear in
  /// more than one list, e.g. partially-paid history), and sort newest-first.
  Future<void> allTrips(String agencyId) async {
    state = state.copyWith(allList: const AsyncValue.loading());
    try {
      final results = await Future.wait([
        usecase.activeTrip(agencyId),
        usecase.upcomingTrip(agencyId),
        usecase.historyTrip(agencyId),
        usecase.unpaidTrip(agencyId),
        usecase.cancelledTrip(agencyId),
      ]);

      final byId = <int, BookingInfo>{};
      final noId = <BookingInfo>[];
      for (final list in results) {
        for (final trip in list) {
          final id = trip.tripId;
          if (id == null) {
            noId.add(trip);
          } else {
            byId.putIfAbsent(id, () => trip);
          }
        }
      }

      final merged = [...byId.values, ...noId];
      merged.sort((a, b) {
        final ka = a.bookingDate ?? a.startDateTime;
        final kb = b.bookingDate ?? b.startDateTime;
        if (ka != null && kb != null) {
          final c = kb.compareTo(ka);
          if (c != 0) return c;
        } else if (ka == null && kb != null) {
          return 1;
        } else if (ka != null && kb == null) {
          return -1;
        }
        return (b.tripId ?? 0).compareTo(a.tripId ?? 0);
      });

      state = state.copyWith(allList: AsyncValue.data(merged));
    } catch (e, st) {
      state = state.copyWith(allList: AsyncValue.error(e, st));
    }
  }


  
  Future<void> paymentHistory(int tripId) async {
    state = state.copyWith(paymentHistory: const AsyncValue.loading());
    try {
      final result = await usecase.getPaymentHistory(tripId);
      state = state.copyWith(paymentHistory: AsyncValue.data(result));
    } catch (e, st) {
      state = state.copyWith(paymentHistory: AsyncValue.error(e, st));
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


  Future<void> cancelTrip(int trip_id) async {
     state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await usecase.cancelTrip(trip_id);
      state = state.copyWith(isLoading: false, data: result);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Ends an active trip: stamps the end datetime (defaulting to now on the
  /// backend if not supplied), records final charges + amount received, and
  /// moves the trip to unpaid / paid based on what was collected.
  Future<void> endTrip(BookingInfo bookinginfo) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await usecase.endTrip(bookinginfo);
      state = state.copyWith(isLoading: false, data: result);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  
}




