
import 'package:travel_agency_app/domain/models/vehicles.dart';

abstract class Addvehiclerepository {
  Future<dynamic> addVehicle(Vehicles vehicle);
}