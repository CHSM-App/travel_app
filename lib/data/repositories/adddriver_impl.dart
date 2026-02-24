import 'dart:io';

 import 'package:travel_agency_app/data/api/api_service.dart';
import 'package:travel_agency_app/domain/models/booking_info.dart';
import 'package:travel_agency_app/domain/models/drivers.dart';
import 'package:travel_agency_app/domain/repository/adddriverRepository.dart';

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
 Future<dynamic> deleteDriver(int driverId) {
    return apiService.deleteDriver(driverId);
  }



}
