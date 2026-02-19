import 'package:travel_agency_app/domain/models/booking_info.dart';
import 'package:travel_agency_app/domain/models/customers.dart';
import 'package:travel_agency_app/domain/models/drivers.dart';
import 'package:travel_agency_app/domain/models/tripbooking_info.dart';
import 'package:travel_agency_app/domain/models/vehicles.dart';

abstract class Tripbookingrepository {
  Future<dynamic> addTripBooking(TripBooking tripBooking);

  Future<List<Drivers>> driverList(String agencyId);

  Future<List<Vehicles>> vehicleList(String agencyId);

  Future<List<Customer>> customerList(String agencyId);

  Future<List<BookingInfo>> upcomingTrip();

  Future<List<BookingInfo>> historyTrip();

  Future<List<BookingInfo>> unpaidTrip();

  Future<List<BookingInfo>> activeTrip();

  Future<List<BookingInfo>> cancelledTrip();
  
}