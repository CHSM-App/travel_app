// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tripbooking_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TripBooking _$TripBookingFromJson(Map<String, dynamic> json) => TripBooking(
  vehicleid: (json['vehicleid'] as num?)?.toInt(),
  driverid: (json['driverid'] as num?)?.toInt(),
  pickuplocation: json['pickuplocation'] as String?,
  droplocation: json['droplocation'] as String?,
  distance: (json['distance'] as num?)?.toDouble(),
  fuelrequired: (json['fuelrequired'] as num?)?.toDouble(),
  tollcharges: (json['tollcharges'] as num?)?.toDouble(),
  repairingcharges: (json['repairingcharges'] as num?)?.toDouble(),
  drivercharges: (json['drivercharges'] as num?)?.toDouble(),
  startDateTime: json['startdatetime'] == null
      ? null
      : DateTime.parse(json['startdatetime'] as String),
  endDateTime: json['enddatetime'] == null
      ? null
      : DateTime.parse(json['enddatetime'] as String),
  status: (json['status'] as num?)?.toInt(),
  customerid: (json['Customerid'] as num?)?.toInt(),
  tripcharges: (json['tripcharges'] as num?)?.toDouble(),
  bookingdate: json['bookingdate'] == null
      ? null
      : DateTime.parse(json['bookingdate'] as String),
);

Map<String, dynamic> _$TripBookingToJson(TripBooking instance) =>
    <String, dynamic>{
      'vehicleid': instance.vehicleid,
      'driverid': instance.driverid,
      'pickuplocation': instance.pickuplocation,
      'droplocation': instance.droplocation,
      'distance': instance.distance,
      'fuelrequired': instance.fuelrequired,
      'tollcharges': instance.tollcharges,
      'repairingcharges': instance.repairingcharges,
      'drivercharges': instance.drivercharges,
      'startdatetime': instance.startDateTime?.toIso8601String(),
      'enddatetime': instance.endDateTime?.toIso8601String(),
      'status': instance.status,
      'Customerid': instance.customerid,
      'tripcharges': instance.tripcharges,
      'bookingdate': instance.bookingdate?.toIso8601String(),
    };
