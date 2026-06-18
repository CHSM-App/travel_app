
import 'dart:io';

import 'package:vego/domain/models/booking_info.dart';
import 'package:vego/domain/models/fueltype.dart';
import 'package:vego/domain/models/ledger_entry.dart';
import 'package:vego/domain/models/services.dart';
import 'package:vego/domain/models/status.dart';
import 'package:vego/domain/models/vehicles.dart';
import 'package:vego/domain/models/vehicletype.dart';

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

  Future<List<LedgerEntry>> getVehicleReport(String agencyId);
    Future<dynamic> deleteVehicle(int vehicleid);

  Future<dynamic> updateService(int serviceId, Services services);

  Future<dynamic> deleteService(int serviceId);


}