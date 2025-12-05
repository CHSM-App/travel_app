import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_agency_app/data/repositories/auth_impl.dart';
import 'package:travel_agency_app/domain/repository/auth_repo.dart';
import '../../core/network/dio_provider.dart';
import '../../data/api/api_service.dart';


final authRepositoryProvider = Provider<AuthRepository>((ref) {
   final dio = ref.watch(dioProvider);
  final api = ApiService(dio);
  return AuthImpl(api);
});
