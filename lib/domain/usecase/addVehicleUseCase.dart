
import 'package:travel_agency_app/domain/models/vehicles.dart';
import 'package:travel_agency_app/domain/repository/AddVehicleRepository.dart';

class AddVehicleUseCase {
  final Addvehiclerepository addvehiclerepository;

  AddVehicleUseCase(this.addvehiclerepository);
  Future<dynamic> addVehicle(Vehicles vehicle) {
    return addvehiclerepository.addVehicle(vehicle);
  }
}