import 'package:json_annotation/json_annotation.dart';
part 'drivers.g.dart';

@JsonSerializable()
class Drivers {

  @JsonKey(name: 'driverId')
  final int? driverId;

  @JsonKey(name: 'name')
  final String? name;

  @JsonKey(name: 'phone')
  final String? phone;

  @JsonKey(name: 'address')
  final String? address;

  @JsonKey(name: 'LicenceNo')
  final String? licenceNo;

  // ✅ FIX HERE
  @JsonKey(
    name: 'LicenceExpiry',
    fromJson: _dateFromJson,
    toJson: _dateToJson,
  )
  final DateTime? licenceExpiry;

  @JsonKey(name: 'vehicleId')
  final int? vehicleId;

  @JsonKey(name: 'photo')
  final String? photo;

  @JsonKey(name: 'agency_id')
  final String? agencyId;

  Drivers({
    this.driverId,
    this.name,
    this.phone,
    this.address,
    this.licenceNo,
    this.licenceExpiry,
    this.vehicleId,
    this.photo,
    this.agencyId,
  });

  factory Drivers.fromJson(Map<String, dynamic> json) =>
      _$DriversFromJson(json);

  Map<String, dynamic> toJson() =>
      _$DriversToJson(this);

  /// ✅ Convert String → DateTime
  static DateTime? _dateFromJson(String? date) =>
      date == null ? null : DateTime.parse(date);

  /// ✅ Convert DateTime → String (SQL format)
  static String? _dateToJson(DateTime? date) =>
      date == null ? null : date.toIso8601String();

}
