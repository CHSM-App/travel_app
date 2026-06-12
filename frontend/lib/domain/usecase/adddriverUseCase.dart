import 'dart:io';

import 'package:travel_agency_app/domain/models/booking_info.dart';
import 'package:travel_agency_app/domain/models/drivers.dart';
import 'package:travel_agency_app/domain/repository/adddriverRepository.dart';

class AddDeiverUseCase {
  final Adddriverrepository adddriverrepository;

  AddDeiverUseCase(this.adddriverrepository);
  Future<dynamic> addDriver(Drivers driver) {
    return adddriverrepository.addDriver(driver);
  }

  Future<dynamic> updateDriver(Drivers driver) {
    return adddriverrepository.updateDriver(driver);
  }

  Future<dynamic> uploadDriverDocument(
    File licenceDocument,
    String driverId,
    String agencyId,
  ) {
    return adddriverrepository.uploadDriverDocument(
      licenceDocument,
      driverId,
      agencyId,
    );
  }

  Future<List<BookingInfo>> fetchDriverHistory(int driverId) {
    return adddriverrepository.fetchDriverHistory(driverId);
  }
Future<Map<String, dynamic>> deleteDriver(int driverId) {
    return adddriverrepository.deleteDriver(driverId);
  }
}
