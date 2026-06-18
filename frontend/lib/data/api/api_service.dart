import 'dart:io';

import 'package:dio/dio.dart';
import 'package:vego/core/storage/constant.dart';
import 'package:vego/domain/models/booking_info.dart';
import 'package:vego/domain/models/customers.dart';
import 'package:vego/domain/models/drivers.dart';
import 'package:vego/domain/models/fueltype.dart';
import 'package:vego/domain/models/login_info.dart';
import 'package:vego/domain/models/login_response.dart';
import 'package:vego/domain/models/otp_response.dart';
import 'package:vego/domain/models/reports_data.dart';
import 'package:vego/domain/models/services.dart';
import 'package:vego/domain/models/status.dart';
import 'package:vego/domain/models/token_response.dart';
import 'package:vego/domain/models/tripbooking_info.dart';
import 'package:vego/domain/models/vehicles.dart';
import 'package:vego/domain/models/vehicletype.dart';
import 'package:vego/domain/models/payment_history.dart';
import 'package:vego/domain/models/ledger_entry.dart';
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

  // OTP (WhatsApp) — body: { mobile, purpose } / { mobile, otp, purpose }
  // purpose is 'register' | 'forgot_pin'
  @POST("login/sendOtp")
  Future<OtpResponse> sendOtp(@Body() Map<String, dynamic> body);

  @POST("login/verifyOtp")
  Future<OtpResponse> verifyOtp(@Body() Map<String, dynamic> body);

  // Records a user-initiated account-deletion request (OTP-verified). The
  // server soft-records it; the account is removed within 30 days. Body:
  // { mobile, otp, reason? }. Returns { success, message, scheduled_for }.
  @POST("login/deleteAccount")
  Future<dynamic> deleteAccount(@Body() Map<String, dynamic> body);

  // Push notifications — register/remove this device's FCM token.
  // body: { admin_id, agency_id, fcm_token, platform } / { fcm_token }
  @POST("users/registerDeviceToken")
  Future<dynamic> registerDeviceToken(@Body() Map<String, dynamic> body);

  @POST("users/removeDeviceToken")
  Future<dynamic> removeDeviceToken(@Body() Map<String, dynamic> body);

  //----------------------------POST API CALL----------------------------------------------

  @POST("insert/Addtripbooking")
  Future<dynamic> addTripBooking(@Body() TripBooking tripBooking);

  @POST("insert/updateTripbooking/{trip_id}")
  Future<dynamic> updateTripBooking(@Path("trip_id") int tripId, @Body() TripBooking tripBooking);

  @POST("insert/Addvehicle")
  Future<dynamic> addVehicle(@Body() Vehicles vehicle);

  @POST("insert/AddDriver")
  Future<dynamic> AddDriver(@Body() Drivers driver);

  @POST("insert/AddCustomer")
  Future<dynamic> addCustomer(@Body() Customer customer);

  @POST("insert/AddAdmin")
  Future<LoginResponse> addAdmin(@Body() LoginInfo logininfo);
  
  @POST("insert/addService/")
  Future<dynamic> addService(@Body() Services service);

  @POST("insert/cancelTrip/{trip_id}")
  Future<dynamic> cancelTrip(@Path("trip_id") int trip_id);

   
  //Update

  @POST("insert/Updatevehicle")
  Future<dynamic> updateVehicle(@Body() Vehicles vehicle);

  @POST("insert/Updatedriver")
  Future<dynamic> updateDriver(@Body() Drivers driver);

  @POST("insert/UpdateCustomer")
  Future<dynamic> updateCustomer(@Body() Customer customer);

  @POST("insert/updatePaymentStatus")
  Future<dynamic> updatePaymentStatus(@Body() BookingInfo tripbooking);

  @POST("insert/endTrip")
  Future<dynamic> endTrip(@Body() BookingInfo tripbooking);

  @POST("insert/updateService/{service_id}")
  Future<dynamic> updateService(@Path("service_id") int serviceId, @Body() Services service);
  
  @POST("insert/DeleteAdminProfile")
  Future<dynamic> deleteAdminProfile(@Body() Map<String, String> body);


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

    @GET("users/deletedDriverList/{agency_id}")
  Future<List<Drivers>> deletedDriverList(@Path("agency_id") String agencyId);

  @GET("users/VehicleList/{agency_id}")
  Future<List<Vehicles>> vehicleList(@Path("agency_id") String agencyId);

  @GET("users/deletedVehicleList/{agency_id}")
  Future<List<Vehicles>> deletedVehicleList(@Path("agency_id") String agencyId);

  @GET("users/customerList/{agency_id}")
  Future<List<Customer>> customerList(@Path("agency_id") String agencyId);

  @GET("users/VehicleTypeList")
  Future<List<VehicleType>> vehicleTypeList();

  @GET("users/StatusList")
  Future<List<Status>> statusList();

  @GET("users/FuelTypeList")
  Future<List<Fueltype>> fuelTypeList();

  @GET("users/UpcomingTrip/{agency_id}")
  Future<List<BookingInfo>> upcomingTrip(@Path("agency_id") String agencyId);

  @GET("users/HistoryTrip/{agency_id}")
  Future<List<BookingInfo>> historyTrip(@Path("agency_id") String agencyId);

  @GET("users/Unpaidtrip/{agency_id}")
  Future<List<BookingInfo>> unpaidtrip(@Path("agency_id") String agencyId);

  @GET("users/activeTrip/{agency_id}")
  Future<List<BookingInfo>> activeTrip(@Path("agency_id") String agencyId);

  @GET("users/cancelledTrip/{agency_id}")
  Future<List<BookingInfo>> cancelledTrip(@Path("agency_id") String agencyId);

  @GET("users/Customerhistory/{customer_id}")
  Future<List<BookingInfo>> customerhist(@Path("customer_id") int customerId);

  @GET("users/AdminProfile/{admin_id}")
  Future<List<LoginInfo>> adminProfile(@Path("admin_id") int adminId);

  @GET("users/VehicleHistory/{vehicle_id}")
  Future<List<BookingInfo>> getTripsByVehicle(
    @Path("vehicle_id") int vehicleid,
  );

  @GET("users/driverHistory/{driver_id}")
  Future<List<BookingInfo>> fetchDriverHistory(@Path("driver_id") int driverId);

  @GET("users/serviceRecord/{agency_id}/{vehicle_id}")
  Future<List<Services>> getServiceRecords(
    @Path("agency_id") String agencyId,
    @Path("vehicle_id") int vehicleId,
  );

    @GET("users/paymentHistory/{trip_id}")
  Future<List<PaymentHistory>> getPaymentHistory(@Path("trip_id") int tripId);



  @GET("users/report/{agency_id}/{report_type}")
  Future<List<ReportData>> getReport(
    @Path("agency_id") String agencyId,
    @Path("report_type") String reportType,
  );

  // Per-vehicle financial ledger for the whole agency (one row per dated event:
  // NEW_BOOKING / PAYMENT_RECEIVED / TRIP_EXPENSE / MAINTENANCE). Fetched once,
  // filtered in the UI by date + vehicle.
  @GET("users/VehicleReport/{agency_id}")
  Future<List<LedgerEntry>> getVehicleReport(
    @Path("agency_id") String agencyId,
  );

  @GET("users/fetchAvailableVehicles/{agency_id}/{start_datetime}/{end_datetime}/{trip_id}")
  Future<List<Vehicles>> fetchAvailableVehicles(
    @Path("agency_id") String agencyId,
    @Path("start_datetime") DateTime start,
    @Path('end_datetime') DateTime end,
    @Path("trip_id") int? tripId
  );

    @GET("users/fetchAvailableDrivers/{agency_id}/{start_datetime}/{end_datetime}/{trip_id}")
  Future<List<Drivers>> fetchAvailableDrivers(
    @Path("agency_id") String agencyId,
    @Path("start_datetime") DateTime start,
    @Path('end_datetime') DateTime end,
    @Path('trip_id') int?tripId
  );





  //---------------------DELETE API ----------------------------------------
  @DELETE("index/deleteVehicles/{vehicleid}")
  Future<dynamic> deleteVehicle(@Path("vehicleid") int vehicleid);

  @DELETE("index/deleteDrivers/{driverId}")
  Future<dynamic>  deleteDriver(@Path("driverId") int driverId);

  @DELETE("index/deleteCustomers/{customer_id}")
  Future<dynamic> deleteCustomer(@Path("customer_id") int customerId);

  @DELETE("index/deleteService/{service_id}")
  Future<dynamic> deleteService(@Path("service_id") int serviceId);

  
}
