import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_agency_app/domain/usecase/auth_use_case.dart';

import 'repository_provider.dart';

final authUseCaseProvider= Provider<AuthUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthUseCase(repository);
}) ;