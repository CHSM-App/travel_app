import 'package:travel_agency_app/data/api/api_service.dart';
import 'package:travel_agency_app/domain/models/booking_info.dart';
import 'package:travel_agency_app/domain/models/customers.dart';
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
  @override
  Future<List<Drivers>> driverList() {
    return apiService.driverList();
  }

  @override
  Future<List<Vehicles>> vehicleList() {
    return apiService.vehicleList();
  }

  @override
  Future<List<Customer>> customerList() {
    return apiService.customerList();
  }
    
  
  
  @override
  Future<List<BookingInfo>> historyTrip() {
    return apiService.historyTrip();
  }
  
  @override
  Future<List<BookingInfo>> unpaidTrip() {
    return apiService.unpaidtrip();
    
  }
  
  @override
  Future<List<BookingInfo>> upcomingTrip() {
    return apiService.upcomingTrip();
  }

  @override
  Future<List<BookingInfo>> activeTrip() {
    return apiService.activeTrip();
  }

  @override
  Future<List<BookingInfo>> cancelledTrip() {
    return apiService.cancelledTrip();
  }
  
  
  

}