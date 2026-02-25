import 'dart:io';

import 'package:travel_agency_app/domain/models/booking_info.dart';
import 'package:travel_agency_app/domain/models/fueltype.dart';
import 'package:travel_agency_app/domain/models/services.dart';
import 'package:travel_agency_app/domain/models/status.dart';
import 'package:travel_agency_app/domain/models/vehicles.dart';
import 'package:travel_agency_app/domain/models/vehicletype.dart';
import 'package:travel_agency_app/domain/repository/AddVehicleRepository.dart';

class AddVehicleUseCase {
  final Addvehiclerepository addvehiclerepository;

  AddVehicleUseCase(this.addvehiclerepository);
  Future<dynamic> addVehicle(Vehicles vehicle) {
    return addvehiclerepository.addVehicle(vehicle);
  }

  Future<List<VehicleType>> getVehicleTypes() {
    return addvehiclerepository.getVehicleTypes();
  }

  Future<List<Fueltype>> getVehicleFuelTypes() {
    return addvehiclerepository.getVehicleFuelTypes();
  }

  Future<List<Status>> getVehicleStatuses() {
    return addvehiclerepository.getVehicleStatuses();
  }

  Future<dynamic> updateVehicle(Vehicles vehicle) {
    return addvehiclerepository.updateVehicle(vehicle);
  }

  Future<dynamic> uploadVehicleDocument(
    File rcDocuments,
    String vehicleId,
    String agencyId,
  ) {
    return addvehiclerepository.uploadVehicleDocument(
      rcDocuments,
      vehicleId,
      agencyId,
    );
  }

  Future<List<BookingInfo>> getTripsByVehicle(int vehicleId) {
    return addvehiclerepository.getTripsByVehicle(vehicleId);
  }

  Future<dynamic> addService(Services service) async {
    return addvehiclerepository.addService(service);
  }

  Future<List<Services>> getServiceRecords(
    String agencyId,
    int vehicleId,
  ) async {
    return addvehiclerepository.getServiceRecords(agencyId, vehicleId);
  }

  Future<dynamic> updateService(int serviceId, Services services) async {
    return addvehiclerepository.updateService(serviceId, services);
  }

  Future<dynamic> deleteVehicle(int vehicleid) {
    return addvehiclerepository.deleteVehicle(vehicleid);
  }
}
