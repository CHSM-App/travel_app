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

  @JsonKey(name: 'active_status')
  final String? activeStatus;

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
    this.activeStatus
  });

  factory Drivers.fromJson(Map<String, dynamic> json) => Drivers(
        driverId: _readFirstInt(json, const ['driverId', 'DriverId', 'driver_id', 'id']),
        name: json['name'] as String?,
        phone: json['phone'] as String?,
        address: json['address'] as String?,
        licenceNo: _readFirstString(json, const ['LicenceNo', 'licenceNo', 'LicenseNo']),
        licenceExpiry: _dateFromJson(
          _readFirstString(json, const ['LicenceExpiry', 'licenceExpiry', 'LicenseExpiry']),
        ),
        vehicleId: _readFirstInt(json, const ['vehicleId', 'VehicleId', 'vehicle_id']),
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

  Map<String, dynamic> toJson() => <String, dynamic>{
        'driverId': driverId,
        'DriverId': driverId,
        'driver_id': driverId,
        'name': name,
        'Name': name,
        'phone': phone,
        'Phone': phone,
        'address': address,
        'Address': address,
        'LicenceNo': licenceNo,
        'licenceNo': licenceNo,
        'LicenseNo': licenceNo,
        'LicenceExpiry': _dateToJson(licenceExpiry),
        'licenceExpiry': _dateToJson(licenceExpiry),
        'LicenseExpiry': _dateToJson(licenceExpiry),
        'vehicleId': vehicleId,
        'VehicleId': vehicleId,
        'vehicle_id': vehicleId,
        'photo': photo,
        'Photo': photo,
        'document': photo,
        'documents': photo,
        'driverDocument': photo,
        'agency_id': agencyId,
        'agencyId': agencyId,
      };

  /// ✅ Convert String → DateTime
  static DateTime? _dateFromJson(String? date) {
    if (date == null) return null;
    final value = date.trim();
    if (value.isEmpty || value.toLowerCase() == 'null') return null;

    final iso = DateTime.tryParse(value);
    if (iso != null) return iso;

    final dmy =
        RegExp(r'^(\d{1,2})[-/](\d{1,2})[-/](\d{4})$').firstMatch(value);
    if (dmy != null) {
      final day = int.parse(dmy.group(1)!);
      final month = int.parse(dmy.group(2)!);
      final year = int.parse(dmy.group(3)!);
      return DateTime(year, month, day);
    }

    final ymd =
        RegExp(r'^(\d{4})[-/](\d{1,2})[-/](\d{1,2})$').firstMatch(value);
    if (ymd != null) {
      final year = int.parse(ymd.group(1)!);
      final month = int.parse(ymd.group(2)!);
      final day = int.parse(ymd.group(3)!);
      return DateTime(year, month, day);
    }

    return null;
  }

  /// ✅ Convert DateTime → String (SQL format)
  static String? _dateToJson(DateTime? date) {
    if (date == null) return null;
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

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

  static int? _readFirstInt(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) continue;
      if (value is int) return value;
      if (value is num) return value.toInt();
      final parsed = int.tryParse(value.toString().trim());
      if (parsed != null) return parsed;
    }
    return null;
  }

}
