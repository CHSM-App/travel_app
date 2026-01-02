import 'package:travel_agency_app/domain/models/drivers.dart';
import 'package:travel_agency_app/domain/models/tripbooking_info.dart';
import 'package:travel_agency_app/domain/models/vehicles.dart';
import 'package:travel_agency_app/domain/repository/tripbookingrepository.dart';

class TripbookingUsecase {
  final Tripbookingrepository repository;

  TripbookingUsecase(this.repository);
  Future<dynamic> addTripBooking(TripBooking tripBooking) {
    return repository.addTripBooking(tripBooking);
  }
  Future<List<Drivers>> driverList() {
    return repository.driverList();
  }
  Future<List<Vehicles>> vehicleList() {
    return repository.vehicleList();
  }
}