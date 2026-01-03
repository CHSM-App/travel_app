import 'package:travel_agency_app/domain/models/customers.dart';
import 'package:travel_agency_app/domain/models/drivers.dart';
import 'package:travel_agency_app/domain/models/tripbooking_info.dart';
import 'package:travel_agency_app/domain/models/vehicles.dart';

abstract class Tripbookingrepository {
  Future<dynamic> addTripBooking(TripBooking tripBooking);

  Future<List<Drivers>> driverList();

  Future<List<Vehicles>> vehicleList();

  Future<List<Customer>> customerList();
} 