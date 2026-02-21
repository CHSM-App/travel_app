import 'dart:io';

import 'package:travel_agency_app/data/api/api_service.dart';
import 'package:travel_agency_app/domain/models/fueltype.dart';
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
  Future uploadVehicleDocument(File rcDocuments, int vehicleId, String agencyId) {
     return apiService.uploadVehicleDocument(rcDocuments,vehicleId, agencyId);
  }



}

 
  
