
import 'package:json_annotation/json_annotation.dart';

part 'tripbooking_info.g.dart';

@JsonSerializable()
class TripBooking {
  final int? tripId;
  final int? vehicleid;
  final int? driverid;
  final String? pickuplocation;
  final String? droplocation;
  final double? distance;
  final double? fuelrequired;
  final double? tollcharges;
  final double? repairingcharges;
  final double? drivercharges;
  final double? fuelcharges;

  // @JsonKey(name: 'startdatetime')
  // final DateTime? startDateTime;

  // @JsonKey(name: 'enddatetime')
  // final DateTime? endDateTime;
  @JsonKey(
  name: 'startdatetime',
  toJson: _dateToJson,
  fromJson: _dateFromJson,
)
final DateTime? startDateTime;

@JsonKey(
  name: 'enddatetime',
  toJson: _dateToJson,
  fromJson: _dateFromJson,
)
final DateTime? endDateTime;

@JsonKey(
  name: 'bookingdate',
  toJson: _dateToJson,
  fromJson: _dateFromJson,
)
final DateTime? bookingdate;

  final int? status;

  @JsonKey(name: 'Customerid')
  final int? customerid;

  final double? tripcharges;

  @JsonKey(name: 'agency_id')
  final String? agencyId;

  // 1 when the trip is a round trip (charged ×2), 0 for one-way (charged ×1.5
  // — base + half the return leg). Stored as an int so the toggle restores.
  @JsonKey(name: 'is_return_trip')
  final int? isreturntrip;

  // @JsonKey(name: 'customerid')
  // final int

  // @JsonKey(name: 'bookingdate')
  // final DateTime? bookingdate;

  TripBooking({
    this.tripId,
    this.vehicleid,
    this.driverid,
    this.pickuplocation,
    this.droplocation,
    this.distance,
    this.fuelrequired,
    this.tollcharges,
    this.repairingcharges,
    this.drivercharges,
    this.fuelcharges,
    this.startDateTime,
    this.endDateTime,
    this.status,
    this.customerid,
    this.tripcharges,
    this.bookingdate,
    this.agencyId,
    this.isreturntrip,
  });

  factory TripBooking.fromJson(Map<String, dynamic> json) =>
      _$TripBookingFromJson(json);

  Map<String, dynamic> toJson() => _$TripBookingToJson(this);
static String? _dateToJson(DateTime? date) {
  if (date == null) return null;

  final local = date.toLocal();

  return "${local.year.toString().padLeft(4, '0')}-"
      "${local.month.toString().padLeft(2, '0')}-"
      "${local.day.toString().padLeft(2, '0')} "
      "${local.hour.toString().padLeft(2, '0')}:"
      "${local.minute.toString().padLeft(2, '0')}:"
      "${local.second.toString().padLeft(2, '0')}";
}
static DateTime? _dateFromJson(String? date) {
  if (date == null) return null;
  return DateTime.parse(date);
}
}
