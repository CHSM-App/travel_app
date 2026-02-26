import 'package:json_annotation/json_annotation.dart';
part 'booking_info.g.dart';

@JsonSerializable()
class BookingInfo {
  @JsonKey(name: 'trip_id')
  final int? tripId;

  @JsonKey(name: 'vehicle_id')
  final int? vehicleId;

  @JsonKey(name: 'driver_id')
  final int? driverId;

  @JsonKey(name: 'pickup_location')
  final String? pickupLocation;

  @JsonKey(name: 'drop_location')
  final String? dropLocation;

  @JsonKey(name: 'distance')
  final double? distance;

  @JsonKey(name: 'fuel_required')
  final double? fuelRequired;

  @JsonKey(name: 'toll_charges')
  final double? tollCharges;

  @JsonKey(name: 'repairing_charges')
  final double? repairingCharges;

  @JsonKey(name: 'driver_charges')
  final double? driverCharges;

   @JsonKey(name: 'booking_date')
  final DateTime? bookingDate;

  @JsonKey(name: 'start_datetime')
  final DateTime? startDateTime;

  @JsonKey(name: 'end_datetime')
  final DateTime? endDateTime;

  @JsonKey(name: 'trip_status_id')
  final int? status;

  @JsonKey(name: 'purpose')
  final String? purpose;

  @JsonKey(name: 'amount_approve')
  final double? amountApprove;

  @JsonKey(name: 'amount_received')
  final double? amountReceived;

  @JsonKey(name: 'CustomerId')
  final int? customerId;

  @JsonKey(name: 'Vehicle_info')
  final String? vehicle_info;

  @JsonKey(name: 'Customer_name')
  final String? customer_name;

  @JsonKey(name: 'customer_phone')
  final String? customer_phone;

  @JsonKey(name: 'Customer_address')
  final String? customerAddress;

  @JsonKey(name: 'TripStatus')
  final String? tripStatus;

  @JsonKey(name: 'Driver_name')
  final String? driver_name;

  @JsonKey(name: 'driver_LicenceNo')
  final String? driverLicenceNo;

  @JsonKey(name: 'driver_phone')
  final String? driverPhone;

  @JsonKey(name: 'mileage')
  final String? mileage;

  @JsonKey(name: 'FuelType')
  final String? fuelType;

  @JsonKey(name: 'capacity')
  final int? capacity;

 @JsonKey(name: 'payment_status')
  final String? payment_status;


  BookingInfo({
    this.tripId,
    this.vehicleId,
    this.driverId,
    this.pickupLocation,
    this.dropLocation,
    this.distance,
    this.fuelRequired,
    this.tollCharges,
    this.repairingCharges,
    this.driverCharges,
    this.bookingDate,
    this.startDateTime,
    this.endDateTime,
    this.status,
    this.purpose,
    this.amountApprove,
    this.amountReceived,
    this.customerId,
    this.vehicle_info,
    this.customer_name,
    this.customer_phone,
    this.customerAddress,
    this.driver_name,
    this.payment_status,
    this.tripStatus,
    this.driverLicenceNo,
    this.driverPhone,
    this.mileage,
    this.fuelType,
    this.capacity,
  });


  

  factory BookingInfo.fromJson(Map<String, dynamic> json) =>
      _$BookingInfoFromJson(json);

  Map<String, dynamic> toJson() => _$BookingInfoToJson(this);
}
