import 'dart:io';

import 'package:travel_agency_app/data/api/api_service.dart';
import 'package:travel_agency_app/domain/models/booking_info.dart';
import 'package:travel_agency_app/domain/models/fueltype.dart';
import 'package:travel_agency_app/domain/models/services.dart';
import 'package:travel_agency_app/domain/models/status.dart';
import 'package:travel_agency_app/domain/models/vehicles.dart';
import 'package:travel_agency_app/domain/models/vehicletype.dart';
import 'package:travel_agency_app/domain/repository/AddVehicleRepository.dart';

class AddvehicleImpl implements Addvehiclerepository {
  final ApiService apiService;

  AddvehicleImpl(this.apiService);
  @override
  Future<dynamic> addVehicle(Vehicles vehicle) {
    return apiService.addVehicle(vehicle);
  }

  @override
  Future<List<VehicleType>> getVehicleTypes() {
    return apiService.vehicleTypeList();
  }

  @override
  Future<List<Status>> getVehicleStatuses() {
    return apiService.statusList();
  }

  @override
  Future<List<Fueltype>> getVehicleFuelTypes() {
    return apiService.fuelTypeList();
  }

  @override
  Future<dynamic> updateVehicle(Vehicles vehicle) {
    return apiService.updateVehicle(vehicle);
  }

  @override
  Future uploadVehicleDocument(
    File rcDocuments,
    String vehicleId,
    String agencyId,
  ) {
    return apiService.uploadVehicleDocument(rcDocuments, vehicleId, agencyId);
  }

  @override
  Future<List<BookingInfo>> getTripsByVehicle(int vehicleId) {
    return apiService.getTripsByVehicle(vehicleId);
  }

  @override
  Future<dynamic> addService(Services service) {
    return apiService.addService(service);
  }

  @override
  Future<List<Services>> getServiceRecords(String agencyId, int vehicleId) {
    return apiService.getServiceRecords(agencyId, vehicleId);
  }

   @override
  Future<dynamic> deleteVehicle(vehicleid) {
    return apiService.deleteVehicle(vehicleid);
  }


  @override
  Future<dynamic> updateService(int serviceId, Services service) {
    return apiService.updateService(serviceId, service);
  }

    @override
  Future<dynamic> deleteService(int serviceId) {
    return apiService.deleteService(serviceId);
  }
}
