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
  Future<List<Drivers>> driverList() {
    return repository.driverList();
  }
  Future<List<Vehicles>> vehicleList() {
    return repository.vehicleList();
  }

  Future<List<Customer>> customerList() {
    return repository.customerList();
  }

  Future<List<BookingInfo>> upcomingTrip() {
    return repository.upcomingTrip();
  }

  Future<List<BookingInfo>> historyTrip() {
    return repository.historyTrip();
  }

  Future<List<BookingInfo>> unpaidTrip() {
    return repository.unpaidTrip();
  }

  Future<List<BookingInfo>> activeTrip() {
    return repository.activeTrip();
  }

  Future<List<BookingInfo>> cancelledTrip(){
    return repository.cancelledTrip();
  }

}