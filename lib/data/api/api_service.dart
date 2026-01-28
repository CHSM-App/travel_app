
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:travel_agency_app/core/storage/constant.dart';
import 'package:travel_agency_app/domain/models/booking_info.dart';
import 'package:travel_agency_app/domain/models/customers.dart';
import 'package:travel_agency_app/domain/models/drivers.dart';
import 'package:travel_agency_app/domain/models/fueltype.dart';
import 'package:travel_agency_app/domain/models/status.dart';
import 'package:travel_agency_app/domain/models/tripbooking_info.dart';
import 'package:travel_agency_app/domain/models/vehicles.dart';
import 'package:travel_agency_app/domain/models/vehicletype.dart';

part 'api_service.g.dart';
abstract class ParseErrorLogger {
  void logError(
    Object error,
    StackTrace stackTrace,
    RequestOptions requestOptions,
  );
}

@RestApi(baseUrl: baseUrl)
abstract class ApiService {
  factory ApiService(Dio dio, {String baseUrl}) = _ApiService;
  @GET('/')
  Future<HttpResponse> checkHealth(); 

  //POST API CALL
  @POST("insert/Addtripbooking")
  Future<dynamic> addTripBooking(@Body() TripBooking tripBooking); 
 
  
  @POST("insert/Addvehicle")
  Future<dynamic> addVehicle(@Body() Vehicles vehicle);
  

 //------------------------------------------------------------------------------------------/
 

  //GET API CALL
  @GET("users/driverList")
  Future<List<Drivers>> driverList();

  @GET("users/VehicleList")
  Future<List<Vehicles>> vehicleList();

  @GET("users/customerList")
  Future<List<Customer>> customerList();

  @GET("users/VehicleTypeList")
  Future<List<VehicleType>> vehicleTypeList();

  @GET("users/StatusList")
  Future<List<Status>> statusList();
  
  @GET("users/FuelTypeList")
  Future<List<Fueltype>> fuelTypeList();

  @GET("users//UpcomingTrip")
  Future<List<BookingInfo>> upcomingTrip();

  @GET("users/HistoryTrip")
  Future<List<BookingInfo>> historyTrip();

  @GET("users/Unpaidtrip")
  Future<List<BookingInfo>> unpaidtrip();


}  
