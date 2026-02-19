import 'package:dio/dio.dart';
import 'package:travel_agency_app/core/storage/constant.dart';
import 'package:travel_agency_app/domain/models/booking_info.dart';
import 'package:travel_agency_app/domain/models/customers.dart';
import 'package:travel_agency_app/domain/models/drivers.dart';
import 'package:travel_agency_app/domain/models/fueltype.dart';
import 'package:travel_agency_app/domain/models/login_info.dart';
import 'package:travel_agency_app/domain/models/login_response.dart';
import 'package:travel_agency_app/domain/models/status.dart';
import 'package:travel_agency_app/domain/models/token_response.dart';
import 'package:travel_agency_app/domain/models/tripbooking_info.dart';
import 'package:travel_agency_app/domain/models/vehicles.dart';
import 'package:travel_agency_app/domain/models/vehicletype.dart';
import 'package:retrofit/retrofit.dart';

part 'api_service.g.dart';
abstract class ParseErrorLogger {
  void logError(
    Object error,
    StackTrace stackTrace,
    // RequestOptions requestOptions,
     RequestOptions requestOptions, {
    Response? response,
  });
}

@RestApi(baseUrl: baseUrl)
abstract class ApiService {
  factory ApiService(Dio dio, {String baseUrl}) = _ApiService;
  @GET('/')
  Future<HttpResponse> checkHealth(); 

//Login Api call

  @POST("login/CreateLogin")
  Future<TokenResponse> createLogin(@Body() TokenResponse tokenResponse);

  @POST("login/refreshAccessToken")
  Future<TokenResponse> refreshAccessToken(@Body() TokenResponse tokenResponse);


    
  @POST("login/Adminlogin")
  Future<LoginResponse> login(@Body() LoginInfo logininfo);

    
  @POST("login/forgotPassword")
  Future<LoginResponse> forgotPassword(@Body() LoginInfo logininfo);
  



  //POST API CALL
  @POST("insert/Addtripbooking")
  Future<dynamic> addTripBooking(@Body() TripBooking tripBooking); 
 
  
  @POST("insert/Addvehicle")
  Future<dynamic> addVehicle(@Body() Vehicles vehicle);

  @POST("insert/AddDriver")
  Future<dynamic> AddDriver(@Body() Drivers driver);

  @POST("insert/addCustomer")
  Future<dynamic> addCustomer(@Body() Customer customer);
  
  @POST("insert/AddCustomer")
  Future<dynamic> addcustomer(@Body() Customer customer);

  @POST("insert/Updatevehicle")
  Future<dynamic> updateVehicle(@Body() Vehicles vehicle);

    @POST("insert/Updatedriver")
  Future<dynamic> updateDriver(@Body() Drivers driver);

  @POST("insert/updatePaymentStatus/")
  Future<dynamic> updatePaymentStatus(@Body() BookingInfo tripbooking);
  


  @POST("insert/AddAdmin")
  Future<LoginResponse> addAdmin(@Body() LoginInfo logininfo);

  
 //------------------------------------------------------------------------------------------/
 

  //GET API CALL
  @GET("users/driverList/{agency_id}/{agency_id}")
  Future<List<Drivers>> driverList(@Path("agency_id") String agencyId);
  

  @GET("users/VehicleList/{agency_id}/{agency_id}")
  Future<List<Vehicles>> vehicleList(@Path("agency_id") String agencyId);

  @GET("users/customerList/{agency_id}/{agency_id}")
  Future<List<Customer>> customerList(@Path("agency_id") String agencyId);

  @GET("users/VehicleTypeList")
  Future<List<VehicleType>> vehicleTypeList();

  @GET("users/StatusList")
  Future<List<Status>> statusList();
  
  @GET("users/FuelTypeList")
  Future<List<Fueltype>> fuelTypeList();

  @GET("users/UpcomingTrip")
  Future<List<BookingInfo>> upcomingTrip();

  @GET("users/HistoryTrip")
  Future<List<BookingInfo>> historyTrip();

  @GET("users/Unpaidtrip")
  Future<List<BookingInfo>> unpaidtrip();

  @GET("users/activeTrip")
  Future<List<BookingInfo>> activeTrip();

  @GET("users/cancelledTrip")
  Future<List<BookingInfo>> cancelledTrip();




  //------------------------ Get for Selected

  @GET("users/Customerhistory/{customer_id}")
  Future<List<BookingInfo>> customerhist(@Path("customer_id") int customerId);

  
  @GET("users/AdminProfile/{admin_id}")
  Future<List<LoginInfo>> adminProfile(@Path("admin_id") int adminId);


}  
