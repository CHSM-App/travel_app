// ignore: file_names

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_agency_app/domain/models/ledger_entry.dart';
import 'package:travel_agency_app/domain/viewModel/addDriver_viewmodel.dart';
import 'package:travel_agency_app/domain/viewModel/addVehicle_viewmodel.dart';
import 'package:travel_agency_app/domain/viewModel/auth_model.dart';
import 'package:travel_agency_app/domain/viewModel/customerViewModel.dart';
import 'package:travel_agency_app/domain/viewModel/login_viewmodel.dart';
import 'package:travel_agency_app/domain/viewModel/report_viewmodel.dart';
import 'package:travel_agency_app/domain/viewModel/trippage_viewmodel.dart';
import 'package:travel_agency_app/domain/viewModel/tripbooking_viewmodel.dart';
import 'package:travel_agency_app/presentation/providers/usecase_provider.dart';

final authViewModelProvider =
    StateNotifierProvider<AuthViewModel, AuthState>((ref) {
      final usecase = ref.watch(authUseCaseProvider);
      return AuthViewModel(ref, usecase);
    });

final loginViewModelProvider =
    StateNotifierProvider<LoginViewModel, LoginState>((ref) {
      final usecase = ref.watch(loginUseCaseProvider);
      return LoginViewModel(usecase);
    });

final tripBookingViewModelProvider =
    StateNotifierProvider<TripBookingViewModel, TripBookingState>((ref) {
      final usecase = ref.watch(tripBookingUseCaseProvider);
      return TripBookingViewModel(ref, usecase);
    });

final addVehicleViewModelProvider =
    StateNotifierProvider<AddVehicleViewModel, AddVehicleState>((ref) {
      final usecase = ref.watch(addVehicleUseCaseProvider);
      return AddVehicleViewModel(ref, usecase);
    });

final customerViewModelProvider =
    StateNotifierProvider<CustomerViewModel, CustomerState>((ref) {
      final usecase = ref.watch(customerUseCaseProvider);
      return CustomerViewModel(usecase);
    });

final tripPageViewModelProvider =
    StateNotifierProvider<TripPageViewModel, TripPageState>((ref) {
      final usecase = ref.watch(tripBookingUseCaseProvider);
      return TripPageViewModel(ref, usecase);
    });

final addDriverViewModelProvider =
    StateNotifierProvider<AdddriverViewmodel, AddDriverState>((ref) {
      final usecase = ref.watch(addDriverUseCaseProvider);
      return AdddriverViewmodel(usecase);
    });

final reportViewModelProvider =
  StateNotifierProvider<ReportViewModel, ReportState>((ref) {
      final usecase = ref.watch(reportUseCaseProvider);
      return ReportViewModel(ref, usecase);
    });

// Agency-wide financial ledger for the vehicle report. Fetched ONCE per
// agencyId (Riverpod caches the future), then filtered in the UI by date and by
// vehicle. The report page groups it per vehicle; the per-vehicle detail page
// filters the same list by vehicleId. Call `ref.invalidate(...)` to refresh.
final vehicleReportLedgerProvider =
    FutureProvider.family<List<LedgerEntry>, String>((ref, agencyId) async {
  if (agencyId.isEmpty) return const <LedgerEntry>[];
  final usecase = ref.watch(addVehicleUseCaseProvider);
  return usecase.getVehicleReport(agencyId);
});

// Drives the bottom nav's current tab. The dashboard writes to this to deep-link
// the operator into Trips/Vehicles with the right filter pre-applied.
final bottomNavIndexProvider = StateProvider<int>((ref) => 0);

// One-shot signal: the filter TripPage should mount with (e.g. 'unpaid',
// 'upcoming', 'active'). TripPage consumes and clears it so a later manual
// tab switch doesn't get hijacked.
final tripPageInitialFilterProvider = StateProvider<String?>((ref) => null);

// One-shot companion to [tripPageInitialFilterProvider]: when a deep-link wants
// the trip list pinned to a day-and-onwards window, it sets this to the start
// date (e.g. the dashboard's "Upcoming Trips" row points at tomorrow, showing
// tomorrow and every later pickup). null means the deep-link clears any prior
// date filter back to "All". Consumed and cleared by TripPage alongside the
// filter signal.
final tripPageInitialDateProvider = StateProvider<DateTime?>((ref) => null);