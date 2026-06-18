import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vego/domain/usecase/addVehicleUseCase.dart';
import 'package:vego/domain/usecase/adddriverUseCase.dart';
import 'package:vego/domain/usecase/auth_use_case.dart';
import 'package:vego/domain/usecase/customerUseCase.dart';
import 'package:vego/domain/usecase/login_usecase.dart';
import 'package:vego/domain/usecase/report_usecase.dart';
import 'package:vego/domain/usecase/tripbooking_usecase.dart';

import 'repository_provider.dart';

final authUseCaseProvider= Provider<AuthUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthUseCase(repository);
}) ;


final loginUseCaseProvider= Provider<LoginUseCase>((ref) {
  final repository = ref.watch(loginRepositoryProvider);
  return LoginUseCase(repository);
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

final reportUseCaseProvider= Provider<ReportUsecase>((ref) {
  final repository = ref.watch(reportRepositoryProvider);
  return ReportUsecase(repository);
}) ;

