
import 'dart:io';

import 'package:travel_agency_app/domain/models/booking_info.dart';
import 'package:travel_agency_app/domain/models/drivers.dart';

abstract class Adddriverrepository {
  Future<dynamic> addDriver(Drivers driver);

  Future<dynamic> updateDriver(Drivers driver);

  Future<dynamic> uploadDriverDocument(
    File licenceDocument,
    String driverId,
    String agencyId,
  );

  Future<List<BookingInfo>> fetchDriverHistory(int driverId);
}
