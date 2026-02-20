
import 'dart:io';

import 'package:travel_agency_app/domain/models/fueltype.dart';
import 'package:travel_agency_app/domain/models/status.dart';
import 'package:travel_agency_app/domain/models/vehicles.dart';
import 'package:travel_agency_app/domain/models/vehicletype.dart';

abstract class Addvehiclerepository {
  Future<dynamic> addVehicle(Vehicles vehicle);
  Future<dynamic> updateVehicle(Vehicles vehicle);

  Future<List<VehicleType>> getVehicleTypes();
  Future<List<Fueltype>> getVehicleFuelTypes();
  Future<List<Status>> getVehicleStatuses();
  Future<dynamic> uploadVehicleDocument(File rcDocuments, int vehicleId, String agencyId);
  

}