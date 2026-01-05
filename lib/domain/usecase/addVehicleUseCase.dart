
import 'package:travel_agency_app/domain/models/fueltype.dart';
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

}