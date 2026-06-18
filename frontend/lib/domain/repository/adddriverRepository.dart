
import 'dart:io';

import 'package:vego/domain/models/booking_info.dart';
import 'package:vego/domain/models/drivers.dart';

abstract class Adddriverrepository {
  Future<dynamic> addDriver(Drivers driver);

  Future<dynamic> updateDriver(Drivers driver);

  Future<dynamic> uploadDriverDocument(
    File licenceDocument,
    String driverId,
    String agencyId,
  );

  Future<List<BookingInfo>> fetchDriverHistory(int driverId);
  Future<Map<String, dynamic>> deleteDriver(int driverId);
}
