import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vego/data/repositories/adddriver_impl.dart';
import 'package:vego/data/repositories/addvehicle_impl.dart';
import 'package:vego/data/repositories/auth_impl.dart';
import 'package:vego/data/repositories/customer_impl.dart';
import 'package:vego/data/repositories/login_impl.dart';
import 'package:vego/data/repositories/report_impl.dart';
import 'package:vego/data/repositories/tripbooking_impl.dart';
import 'package:vego/domain/repository/AddVehicleRepository.dart';
import 'package:vego/domain/repository/CustomerRepository.dart';
import 'package:vego/domain/repository/adddriverRepository.dart';
import 'package:vego/domain/repository/auth_repo.dart';
import 'package:vego/domain/repository/login_repo.dart';
import 'package:vego/domain/repository/report_repo.dart';
import 'package:vego/domain/repository/tripbookingrepository.dart';
import '../../core/network/dio_provider.dart';
import '../../data/api/api_service.dart';


// Shared ApiService instance (used by PushService for device-token registration).
final apiServiceProvider = Provider<ApiService>((ref) {
  final dio = ref.watch(dioProvider);
  return ApiService(dio);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
   final dio = ref.watch(dioProvider);
  final api = ApiService(dio);
  return AuthImpl(api);
});


 final loginRepositoryProvider = Provider<LoginRepo>((ref) {
   final dio = ref.watch(dioProvider);
  final api = ApiService(dio);
  return LoginImpl(api);
});

final tripBookingRepositoryProvider = Provider<Tripbookingrepository>((ref) {
   final dio = ref.watch(dioProvider);
  final api = ApiService(dio);
  return TripBookingImpl(api);
});

final addVehicleRepositoryProvider = Provider<Addvehiclerepository>((ref) {
   final dio = ref.watch(dioProvider);
  final api = ApiService(dio);
  return AddvehicleImpl(api);
});

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
   final dio = ref.watch(dioProvider);
  final api = ApiService(dio);
  return CustomerImpl(api);
});

final AdddriverrepositoryProvider=Provider<Adddriverrepository>((ref){
  final dio=ref.watch(dioProvider);
  final api=ApiService(dio);
  return AddDriverImpl(api);
});

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
   final dio = ref.watch(dioProvider);
  final api = ApiService(dio);
  return ReportImpl(api);
});


