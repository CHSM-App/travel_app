// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BookingInfo _$BookingInfoFromJson(Map<String, dynamic> json) => BookingInfo(
  tripId: (json['trip_id'] as num?)?.toInt(),
  vehicleId: (json['vehicle_id'] as num?)?.toInt(),
  driverId: (json['driver_id'] as num?)?.toInt(),
  pickupLocation: json['pickup_location'] as String?,
  dropLocation: json['drop_location'] as String?,
  distance: (json['distance'] as num?)?.toDouble(),
  fuelRequired: (json['fuel_required'] as num?)?.toDouble(),
  tollCharges: (json['toll_charges'] as num?)?.toDouble(),
  repairingCharges: (json['repairing_charges'] as num?)?.toDouble(),
  driverCharges: (json['driver_charges'] as num?)?.toDouble(),
  fuelCharges: (json['fuel_charges'] as num?)?.toDouble(),
  bookingDate: json['booking_date'] == null
      ? null
      : DateTime.parse(json['booking_date'] as String),
  startDateTime: json['start_datetime'] == null
      ? null
      : DateTime.parse(json['start_datetime'] as String),
  endDateTime: json['end_datetime'] == null
      ? null
      : DateTime.parse(json['end_datetime'] as String),
  status: (json['trip_status_id'] as num?)?.toInt(),
  purpose: json['purpose'] as String?,
  amountApprove: (json['amount_approve'] as num?)?.toDouble(),
  amountReceived: (json['amount_received'] as num?)?.toDouble(),
  customerId: (json['CustomerId'] as num?)?.toInt(),
  vehicle_info: json['Vehicle_info'] as String?,
  customer_name: json['Customer_name'] as String?,
  customer_phone: json['customer_phone'] as String?,
  customerAddress: json['Customer_address'] as String?,
  driver_name: json['Driver_name'] as String?,
  payment_status: json['payment_status'] as String?,
  tripStatus: json['TripStatus'] as String?,
  driverLicenceNo: json['driver_LicenceNo'] as String?,
  driverPhone: json['driver_phone'] as String?,
  mileage: json['mileage'] as String?,
  fuelType: json['FuelType'] as String?,
  capacity: (json['capacity'] as num?)?.toInt(),
  pendingAmount: (json['pending_amount'] as num?)?.toDouble(),
  paymentDate: json['payment_date'] == null
      ? null
      : DateTime.parse(json['payment_date'] as String),
  paymentMode: json['payment_mode'] as String?,
);

Map<String, dynamic> _$BookingInfoToJson(BookingInfo instance) =>
    <String, dynamic>{
      'trip_id': instance.tripId,
      'vehicle_id': instance.vehicleId,
      'driver_id': instance.driverId,
      'pickup_location': instance.pickupLocation,
      'drop_location': instance.dropLocation,
      'distance': instance.distance,
      'fuel_required': instance.fuelRequired,
      'toll_charges': instance.tollCharges,
      'repairing_charges': instance.repairingCharges,
      'driver_charges': instance.driverCharges,
      'fuel_charges': instance.fuelCharges,
      'booking_date': instance.bookingDate?.toIso8601String(),
      'start_datetime': instance.startDateTime?.toIso8601String(),
      'end_datetime': instance.endDateTime?.toIso8601String(),
      'trip_status_id': instance.status,
      'purpose': instance.purpose,
      'amount_approve': instance.amountApprove,
      'amount_received': instance.amountReceived,
      'CustomerId': instance.customerId,
      'Vehicle_info': instance.vehicle_info,
      'Customer_name': instance.customer_name,
      'customer_phone': instance.customer_phone,
      'Customer_address': instance.customerAddress,
      'TripStatus': instance.tripStatus,
      'Driver_name': instance.driver_name,
      'driver_LicenceNo': instance.driverLicenceNo,
      'driver_phone': instance.driverPhone,
      'mileage': instance.mileage,
      'FuelType': instance.fuelType,
      'capacity': instance.capacity,
      'payment_status': instance.payment_status,
      'pending_amount': instance.pendingAmount,
      'payment_date': instance.paymentDate?.toIso8601String(),
      'payment_mode': instance.paymentMode,
    };
