// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BookingInfo _$BookingInfoFromJson(Map<String, dynamic> json) => BookingInfo(
      tripId: (json['tripId'] as num?)?.toInt(),
      vehicleId: (json['vehicleId'] as num).toInt(),
      driverId: (json['driverId'] as num).toInt(),
      pickupLocation: json['pickupLocation'] as String,
      dropLocation: json['dropLocation'] as String,
      distance: (json['distance'] as num).toDouble(),
      fuelRequired: (json['fuelRequired'] as num).toDouble(),
      tollCharges: (json['tollCharges'] as num).toDouble(),
      repairingCharges: (json['repairingCharges'] as num).toDouble(),
      driverCharges: (json['driverCharges'] as num).toDouble(),
      startDateTime: DateTime.parse(json['startDateTime'] as String),
      endDateTime: DateTime.parse(json['endDateTime'] as String),
      status: json['status'] as String,
      purpose: json['purpose'] as String,
      amountApprove: (json['amountApprove'] as num).toDouble(),
      amountReceived: (json['amountReceived'] as num).toDouble(),
      customerId: (json['customerId'] as num).toInt(),
    );

Map<String, dynamic> _$BookingInfoToJson(BookingInfo instance) =>
    <String, dynamic>{
      'tripId': instance.tripId,
      'vehicleId': instance.vehicleId,
      'driverId': instance.driverId,
      'pickupLocation': instance.pickupLocation,
      'dropLocation': instance.dropLocation,
      'distance': instance.distance,
      'fuelRequired': instance.fuelRequired,
      'tollCharges': instance.tollCharges,
      'repairingCharges': instance.repairingCharges,
      'driverCharges': instance.driverCharges,
      'startDateTime': instance.startDateTime.toIso8601String(),
      'endDateTime': instance.endDateTime.toIso8601String(),
      'status': instance.status,
      'purpose': instance.purpose,
      'amountApprove': instance.amountApprove,
      'amountReceived': instance.amountReceived,
      'customerId': instance.customerId,
    };
