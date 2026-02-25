import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_agency_app/data/repositories/adddriver_impl.dart';
import 'package:travel_agency_app/data/repositories/addvehicle_impl.dart';
import 'package:travel_agency_app/data/repositories/auth_impl.dart';
import 'package:travel_agency_app/data/repositories/customer_impl.dart';
import 'package:travel_agency_app/data/repositories/login_impl.dart';
import 'package:travel_agency_app/data/repositories/tripbooking_impl.dart';
import 'package:travel_agency_app/domain/repository/AddVehicleRepository.dart';
import 'package:travel_agency_app/domain/repository/CustomerRepository.dart';
import 'package:travel_agency_app/domain/repository/adddriverRepository.dart';
import 'package:travel_agency_app/domain/repository/auth_repo.dart';
import 'package:travel_agency_app/domain/repository/login_repo.dart';
import 'package:travel_agency_app/domain/repository/tripbookingrepository.dart';
import '../../core/network/dio_provider.dart';
import '../../data/api/api_service.dart';


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
