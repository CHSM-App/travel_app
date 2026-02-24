
import 'dart:io';

import 'package:travel_agency_app/domain/models/booking_info.dart';
import 'package:travel_agency_app/domain/models/fueltype.dart';
import 'package:travel_agency_app/domain/models/services.dart';
import 'package:travel_agency_app/domain/models/status.dart';
import 'package:travel_agency_app/domain/models/vehicles.dart';
import 'package:travel_agency_app/domain/models/vehicletype.dart';

abstract class Addvehiclerepository {
  Future<dynamic> addVehicle(Vehicles vehicle);
  Future<dynamic> updateVehicle(Vehicles vehicle);

  Future<List<VehicleType>> getVehicleTypes();
  Future<List<Fueltype>> getVehicleFuelTypes();
  Future<List<Status>> getVehicleStatuses();

  Future<List<BookingInfo>> getTripsByVehicle(int vehicleId);
  Future<dynamic> uploadVehicleDocument(File rcDocuments, String vehicleId, String agencyId);

  Future<dynamic> addService(Services service);

  Future<List<Services>> getServiceRecords(String agencyId, int vehicleId);
    Future<dynamic> deleteVehicle(int vehicleid);

}