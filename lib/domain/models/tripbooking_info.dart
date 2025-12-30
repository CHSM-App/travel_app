import 'package:json_annotation/json_annotation.dart';

part 'tripbooking_info.g.dart';

@JsonSerializable()
class TripBooking {
  final int? vehicleid;
  final int? driverid;
  final String? pickuplocation;
  final String? droplocation;
  final double? distance;
  final double? fuelrequired;
  final double? tollcharges;
  final double? repairingcharges;
  final double? drivercharges;
  final DateTime? startDateTime;
  final DateTime? endDateTime;
  final String? status;
  final int? customerid;
  final double? tripcharges;
  final DateTime? bookingdate;

  TripBooking({
    this.vehicleid,
    this.driverid,
    this.pickuplocation,
    this.droplocation,
    this.distance,
    this.fuelrequired,
    this.tollcharges,
    this.repairingcharges,
    this.drivercharges,
    this.startDateTime,
    this.endDateTime,
    this.status,
    this.customerid,
    this.tripcharges,
    this.bookingdate,
  });

  /// REQUIRED for json_serializable
  factory TripBooking.fromJson(Map<String, dynamic> json) =>
      _$TripBookingFromJson(json);

  /// REQUIRED so Dio can encode
  Map<String, dynamic> toJson() => _$TripBookingToJson(this);
}
