import 'package:travel_agency_app/data/api/api_service.dart';
import 'package:travel_agency_app/domain/models/drivers.dart';
import 'package:travel_agency_app/domain/models/tripbooking_info.dart';
import 'package:travel_agency_app/domain/models/vehicles.dart';
import 'package:travel_agency_app/domain/repository/tripbookingrepository.dart';

class TripBookingImpl implements Tripbookingrepository {
  final ApiService apiService;

  TripBookingImpl(this.apiService);
  @override

  Future<dynamic> addTripBooking(TripBooking tripBooking) {
    return apiService.addTripBooking(tripBooking);
  }
  Future<List<Drivers>> driverList() {
    return apiService.driverList();
  }

  Future<List<Vehicles>> vehicleList() {
    return apiService.VehicleList();
  }

    

}