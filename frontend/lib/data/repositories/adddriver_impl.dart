import 'dart:io';

import 'package:vego/data/api/api_service.dart';
import 'package:vego/domain/models/booking_info.dart';
import 'package:vego/domain/models/drivers.dart';
import 'package:vego/domain/repository/adddriverRepository.dart';

class AddDriverImpl implements Adddriverrepository {
  final ApiService apiService;

  AddDriverImpl(this.apiService);

  @override
  Future<dynamic> addDriver(Drivers driver) {
    return apiService.AddDriver(driver);
  }

  @override
  Future<dynamic> updateDriver(Drivers driver) {
    return apiService.updateDriver(driver);
  }

  @override
  Future<dynamic> uploadDriverDocument(
    File licenceDocument,
    String driverId,
    String agencyId,
  ) {
    return apiService.uploadDriverDocument(licenceDocument, driverId, agencyId);
  }

  @override
  Future<List<BookingInfo>> fetchDriverHistory(int driverId) {
    return apiService.fetchDriverHistory(driverId);
  }

  @override
  Future<Map<String, dynamic>> deleteDriver(int driverId) async {
    final response = await apiService.deleteDriver(driverId);
    if (response is Map<String, dynamic>) {
      return response;
    }
    if (response is Map) {
      return response.map((key, value) => MapEntry(key.toString(), value));
    }
    throw Exception(
      'Invalid delete driver response type: ${response.runtimeType}',
    );
  }
}
