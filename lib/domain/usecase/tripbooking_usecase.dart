import 'package:travel_agency_app/domain/models/booking_info.dart';
import 'package:travel_agency_app/domain/models/customers.dart';
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
  Future<List<Drivers>> driverList(String agencyId) {
    return repository.driverList(agencyId);
  }
  Future<List<Vehicles>> vehicleList(String agencyId) {
    return repository.vehicleList(agencyId);
  }

  Future<List<Customer>> customerList(String agencyId) {
    return repository.customerList(agencyId);
  }

  Future<List<BookingInfo>> upcomingTrip(String agencyId) {
    return repository.upcomingTrip(agencyId);
  }

  Future<List<BookingInfo>> historyTrip(String agencyId) {
    return repository.historyTrip(agencyId);
  }

  Future<List<BookingInfo>> unpaidTrip(String agencyId) {
    return repository.unpaidTrip(agencyId);
  }

  Future<List<BookingInfo>> activeTrip(String agencyId) {
    return repository.activeTrip(agencyId);
  }

  Future<List<BookingInfo>> cancelledTrip(String agencyId){
    return repository.cancelledTrip(agencyId);
  }

  Future<dynamic> updatePaymentStatus(BookingInfo tripbooking){
     return repository.updatePaymentStatus(tripbooking);
  }

}