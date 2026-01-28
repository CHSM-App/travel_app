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
      startDateTime: json['start_datetime'] == null
          ? null
          : DateTime.parse(json['start_datetime'] as String),
      endDateTime: json['end_datetime'] == null
          ? null
          : DateTime.parse(json['end_datetime'] as String),
      status: (json['status'] as num?)?.toInt(),
      purpose: json['purpose'] as String?,
      amountApprove: (json['amount_approve'] as num?)?.toDouble(),
      amountReceived: (json['amount_received'] as num?)?.toDouble(),
      customerId: (json['customer_id'] as num?)?.toInt(),
      vehicle_info: json['Vehicle_info'] as String?,
      customer_name: json['Customer_name'] as String?,
      driver_name: json['Driver_name'] as String?,
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
      'start_datetime': instance.startDateTime?.toIso8601String(),
      'end_datetime': instance.endDateTime?.toIso8601String(),
      'status': instance.status,
      'purpose': instance.purpose,
      'amount_approve': instance.amountApprove,
      'amount_received': instance.amountReceived,
      'customer_id': instance.customerId,
      'Vehicle_info': instance.vehicle_info,
      'Customer_name': instance.customer_name,
      'Driver_name': instance.driver_name,
    };
