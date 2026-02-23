import 'dart:io';

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

  //-------------------------------------Login Api call---------------------------------------------

  @POST("login/CreateLogin")
  Future<TokenResponse> createLogin(@Body() TokenResponse tokenResponse);

  @POST("login/refreshAccessToken")
  Future<TokenResponse> refreshAccessToken(@Body() TokenResponse tokenResponse);
  
    @POST("login/logout")
  Future<TokenResponse> logout(@Body() TokenResponse tokenResponse);

  @POST("login/Adminlogin")
  Future<LoginResponse> login(@Body() LoginInfo logininfo);

  @POST("login/forgotPassword")
  Future<LoginResponse> forgotPassword(@Body() LoginInfo logininfo);

  //----------------------------POST API CALL----------------------------------------------
  @POST("insert/Addtripbooking")
  Future<dynamic> addTripBooking(@Body() TripBooking tripBooking);

  @POST("insert/Addvehicle")
  Future<dynamic> addVehicle(@Body() Vehicles vehicle);

  @POST("insert/AddDriver")
  Future<dynamic> AddDriver(@Body() Drivers driver);

  @POST("insert/AddCustomer")
  Future<dynamic> addCustomer(@Body() Customer customer);



  @POST("insert/Updatevehicle")
  Future<dynamic> updateVehicle(@Body() Vehicles vehicle);

  @POST("insert/Updatedriver")
  Future<dynamic> updateDriver(@Body() Drivers driver);
  
    @POST("insert/UpdateCustomer")
  Future<dynamic> updateCustomer(@Body() Customer customer);

  @POST("insert/updatePaymentStatus/")
  Future<dynamic> updatePaymentStatus(@Body() BookingInfo tripbooking);

  @POST("insert/AddAdmin")
  Future<LoginResponse> addAdmin(@Body() LoginInfo logininfo);

  //---------------------UPLOAD PHOTOS AND DOCUMENTS----------------------------------------
  @MultiPart()
  @POST("upload/AdminImage")
  Future<dynamic> updateAdminProfile(
    @Part(name: "image") File imageUrl,
    @Part(name: "admin_id") String adminId,
    @Part(name: "agency_id") String agencyId,
  );
  @MultiPart()
  @POST("upload/VehicleDocuments")
  Future<dynamic> uploadVehicleDocument(
    @Part(name: "document") File rcDocument,
    @Part(name: "vehicleId") String vehicleId,
    @Part(name: "agency_id") String agencyId,
  );

  @MultiPart()
  @POST("upload/DriverDocuments")
  Future<dynamic> uploadDriverDocument(
    @Part(name: "document") File licenceDocument,
    @Part(name: "driverId") String driverId,
    @Part(name: "agency_id") String agencyId,
  );

  @MultiPart()
  @POST("upload/CustomerDocuments")
  Future<dynamic> uploadCustomerDocument(
    @Part(name: "document") File document,
    @Part(name: "CustomerId") String customerId,
    @Part(name: "agency_id") String agencyId,
  );

  //------------------------------------------GET API CALL------------------------------
  @GET("users/driverList/{agency_id}")
  Future<List<Drivers>> driverList(@Path("agency_id") String agencyId);

  @GET("users/VehicleList/{agency_id}")
  Future<List<Vehicles>> vehicleList(@Path("agency_id") String agencyId);

  @GET("users/customerList/{agency_id}")
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

  @GET("users/Customerhistory/{customer_id}")
  Future<List<BookingInfo>> customerhist(@Path("customer_id") int customerId);

  @GET("users/AdminProfile/{admin_id}")
  Future<List<LoginInfo>> adminProfile(@Path("admin_id") int adminId);

  @GET("users/VehicleHistory/{vehicle_id}")
  Future<List<BookingInfo>> getTripsByVehicle(@Path("vehicle_id") int vehicleid);
}  
