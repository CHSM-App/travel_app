import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_agency_app/domain/usecase/addVehicleUseCase.dart';
import 'package:travel_agency_app/domain/usecase/adddriverUseCase.dart';
import 'package:travel_agency_app/domain/usecase/auth_use_case.dart';
import 'package:travel_agency_app/domain/usecase/customerUseCase.dart';
import 'package:travel_agency_app/domain/usecase/tripbooking_usecase.dart';

import 'repository_provider.dart';

final authUseCaseProvider= Provider<AuthUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthUseCase(repository);
}) ;

final tripBookingUseCaseProvider= Provider<TripbookingUsecase>((ref) {
  final repository = ref.watch(tripBookingRepositoryProvider);
  return TripbookingUsecase(repository);
}) ;

final addVehicleUseCaseProvider= Provider<AddVehicleUseCase>((ref) {
  final repository = ref.watch(addVehicleRepositoryProvider);
  return AddVehicleUseCase(repository);
}) ;

final customerUseCaseProvider= Provider<customerUseCase>((ref) {
  final repository = ref.watch(customerRepositoryProvider);
  return customerUseCase(repository);
}) ;

final addDriverUseCaseProvider= Provider<AddDeiverUseCase>((ref) {
  final repository = ref.watch(AdddriverrepositoryProvider);
  return AddDeiverUseCase(repository);
}) ;
