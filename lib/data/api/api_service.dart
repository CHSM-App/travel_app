
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:travel_agency_app/core/storage/constant.dart';
import 'package:travel_agency_app/domain/models/customers.dart';
import 'package:travel_agency_app/domain/models/drivers.dart';
import 'package:travel_agency_app/domain/models/tripbooking_info.dart';
import 'package:travel_agency_app/domain/models/vehicles.dart';

part 'api_service.g.dart';

@RestApi(baseUrl: baseUrl)
abstract class ApiService {
  factory ApiService(Dio dio, {String baseUrl}) = _ApiService;
  @GET('/')
  Future<HttpResponse> checkHealth(); 


    @POST("insert/Addtripbooking")
  Future<dynamic> addTripBooking(@Body() TripBooking tripBooking); 

  
  @GET("users/driverList")
  Future<List<Drivers>> driverList();

  @GET("users/VehicleList")
  Future<List<Vehicles>> vehicleList();

  @GET("users/customerList")
  Future<List<Customer>> customerList();

  @POST("insert/Addvehicle")
  Future<dynamic> addVehicle(@Body() Vehicles vehicle);


}
