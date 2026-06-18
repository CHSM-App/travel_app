import 'package:vego/data/api/api_service.dart';
import 'package:vego/domain/models/booking_info.dart';
import 'package:vego/domain/models/customers.dart';
import 'package:vego/domain/models/drivers.dart';
import 'package:vego/domain/models/payment_history.dart';
import 'package:vego/domain/models/tripbooking_info.dart';
import 'package:vego/domain/models/vehicles.dart';
import 'package:vego/domain/repository/tripbookingrepository.dart';

class TripBookingImpl implements Tripbookingrepository {
  final ApiService apiService;

  TripBookingImpl(this.apiService);
  @override

  Future<dynamic> addTripBooking(TripBooking tripBooking) {
    return apiService.addTripBooking(tripBooking);
  }
  
  @override
  Future<List<Drivers>> driverList(String agencyId) {
    return apiService.driverList(agencyId);
  }

    @override
  Future<List<Drivers>> deletedDriverList(String agencyId) {
    return apiService.deletedDriverList(agencyId);
  }

  @override
  Future<List<Vehicles>> vehicleList(String agencyId) {
    return apiService.vehicleList(agencyId);
  }

  @override
  Future<List<Vehicles>> deletedVehicleList(String agencyId) {
    return apiService.deletedVehicleList(agencyId);
  }

  @override
  Future<List<Customer>> customerList(String agencyId) {
    return apiService.customerList(agencyId);
  }

  @override
  Future<List<BookingInfo>> historyTrip(String agencyId) {
    return apiService.historyTrip(agencyId);
  }
  
  @override
  Future<List<BookingInfo>> unpaidTrip(String agencyId) {
    return apiService.unpaidtrip(agencyId);
    
  }
  
  @override
  Future<List<BookingInfo>> upcomingTrip(String agencyId) {
    return apiService.upcomingTrip(agencyId);
  }

  @override
  Future<List<BookingInfo>> activeTrip(String agencyId) {
    return apiService.activeTrip(agencyId);
  }


  @override
  Future<List<BookingInfo>> cancelledTrip(String agencyId) {
    return apiService.cancelledTrip(agencyId);
  }
  
   @override
  Future<dynamic> updatePaymentStatus(BookingInfo tripbooking) {
    return apiService.updatePaymentStatus(tripbooking);
  }

  @override
  Future<List<PaymentHistory>> getPaymentHistory(int tripId) {
    return apiService.getPaymentHistory(tripId);
  }

  @override
  Future<dynamic> endTrip(BookingInfo tripbooking) {
    return apiService.endTrip(tripbooking);
  }
  
  @override
  Future<dynamic> updateTripBooking(int tripId, TripBooking booking) {
    return apiService.updateTripBooking(tripId, booking);
  }

     @override
  Future<dynamic> cancelTrip(int trip_id) {
    return apiService.cancelTrip(trip_id);
  }

   @override
  Future<List<Vehicles>> fetchAvailableVehicles(String agencyId, DateTime start, DateTime end, int? tripId) {
    return apiService.fetchAvailableVehicles(agencyId, start, end, tripId);
  }

  @override
  Future<List<Drivers>> fetchAvailableDrivers(String agencyId, DateTime start, DateTime end, int? tripId) {
    return apiService.fetchAvailableDrivers(agencyId, start, end, tripId);
  }


}