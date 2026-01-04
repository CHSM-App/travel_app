// ignore: file_names
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_agency_app/domain/viewModel/addVehicle_viewmodel.dart' show AddVehicleViewModel, AddVehicleState;

import 'package:travel_agency_app/domain/viewModel/auth_model.dart';
import 'package:travel_agency_app/domain/viewModel/network_model.dart';
import 'package:travel_agency_app/domain/viewModel/tripbooking_viewmodel.dart';
import 'package:travel_agency_app/presentation/providers/usecase_provider.dart';

 
final firebaseMessagingProvider = Provider<FirebaseMessaging>((ref) {
  return FirebaseMessaging.instance;
});

final networkStateProvider =
    StateNotifierProvider<EnhancedNetworkStateNotifier, NetworkState>(
        (ref) => EnhancedNetworkStateNotifier());
//         final networkStateProvider = 
//     StateNotifierProvider<EnhancedNetworkStateNotifier, NetworkState>(
//   (ref) {
//     print('📡 Creating networkStateProvider...');
//     return EnhancedNetworkStateNotifier();
//   },
// );
final authViewModelProvider =
    StateNotifierProvider<AuthViewModel, AuthState>((ref) {
  final usecase = ref.watch(authUseCaseProvider);
 
  return AuthViewModel(ref,usecase);

  });

final tripBookingViewModelProvider =
    StateNotifierProvider<TripBookingViewModel, TripBookingState>((ref) {
  final usecase = ref.watch(tripBookingUseCaseProvider);
  return TripBookingViewModel(ref,usecase);
  });

final addVehicleViewModelProvider =
  StateNotifierProvider<AddVehicleViewModel, AddVehicleState>((ref) {
  final usecase = ref.watch(addVehicleUseCaseProvider);
  return AddVehicleViewModel(ref, usecase);
});