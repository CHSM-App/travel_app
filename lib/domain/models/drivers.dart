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

  factory Drivers.fromJson(Map<String, dynamic> json) => Drivers(
        driverId: (json['driverId'] as num?)?.toInt(),
        name: json['name'] as String?,
        phone: json['phone'] as String?,
        address: json['address'] as String?,
        licenceNo: json['LicenceNo'] as String?,
        licenceExpiry: _dateFromJson(json['LicenceExpiry'] as String?),
        vehicleId: (json['vehicleId'] as num?)?.toInt(),
        photo: _readFirstString(json, const [
          'photo',
          'Photo',
          'documents',
          'Documents',
          'document',
          'Document',
          'driverDocument',
          'DriverDocument',
          'licenceDocument',
          'LicenceDocument',
          'licenseDocument',
          'LicenseDocument',
        ]),
        agencyId: (json['agency_id'] ?? json['agencyId'])?.toString(),
      );

  Map<String, dynamic> toJson() =>
      _$DriversToJson(this);

  /// ✅ Convert String → DateTime
  static DateTime? _dateFromJson(String? date) =>
      date == null ? null : DateTime.parse(date);

  /// ✅ Convert DateTime → String (SQL format)
  static String? _dateToJson(DateTime? date) =>
      date == null ? null : date.toIso8601String();

  static String? _readFirstString(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty && text.toLowerCase() != 'null') {
        return text;
      }
    }
    return null;
  }

}
