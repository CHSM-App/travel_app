import 'package:travel_agency_app/domain/models/booking_info.dart';
import 'package:travel_agency_app/domain/models/customers.dart';
import 'package:travel_agency_app/domain/models/drivers.dart';
import 'package:travel_agency_app/domain/models/tripbooking_info.dart';
import 'package:travel_agency_app/domain/models/vehicles.dart';

abstract class Tripbookingrepository {
  Future<dynamic> addTripBooking(TripBooking tripBooking);

  Future<List<Drivers>> driverList(String agencyId);

  Future<List<Drivers>> deletedDriverList(String agencyId);

  Future<List<Vehicles>> vehicleList(String agencyId);

  Future<List<Vehicles>> deletedVehicleList(String agencyId);

  Future<List<Customer>> customerList(String agencyId);

  Future<List<BookingInfo>> upcomingTrip(String agencyId);

  Future<List<BookingInfo>> historyTrip(String agencyId);

  Future<List<BookingInfo>> unpaidTrip(String agencyId);

  Future<List<BookingInfo>> activeTrip(String agencyId);

  Future<List<BookingInfo>> cancelledTrip(String agencyId);

  Future<dynamic> updatePaymentStatus(BookingInfo tripbooking);

  Future<dynamic> endTrip(BookingInfo tripbooking);

  Future<dynamic> updateTripBooking(int tripId, TripBooking booking);

  Future<dynamic> cancelTrip(int trip_id);

  Future<List<Vehicles>> fetchAvailableVehicles(String agencyId, DateTime start, DateTime end, int? tripId);

  Future<List<Drivers>> fetchAvailableDrivers(String agencyId, DateTime start, DateTime end, int? tripId);
  
}