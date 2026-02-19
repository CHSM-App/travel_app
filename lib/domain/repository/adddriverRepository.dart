
import 'package:travel_agency_app/domain/models/drivers.dart';

abstract class Adddriverrepository {
  Future<dynamic> addDriver(Drivers driver);

  Future<dynamic> updateDriver(Drivers driver);
}
