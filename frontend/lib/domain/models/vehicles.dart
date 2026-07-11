import 'package:json_annotation/json_annotation.dart';
part 'vehicles.g.dart';

@JsonSerializable()
class Vehicles {

  final String? Vehicle_info;
  final int? vehicleId;
  final int ?driverId;
  final String? name;
  final String? number;
  final int? TypeId;
  final int? capacity;
  final int? FuelTypeId;
  final String? mileage;
  final int? StatusId;
  final String? rcdocuments;
  final String? FuelType;
  final String? Type;
  final String? StatusName;
  final String? agencyId;

  /// Per-kilometre charge for this vehicle, used to auto-fill the Trip Charges
  /// field (distance × rate) when booking. Null when not set.
  @JsonKey(name: 'per_km_charge')
  final double? perKmCharge;

   @JsonKey(name: 'active_status')
  final int? activeStatus;

  /// PUC (Pollution Under Control) certificate expiry date, captured at
  /// registration. Null when not provided.
  @JsonKey(name: 'puc_expiry')
  final DateTime? pucExpiry;

  /// Insurance policy expiry date, captured at registration. Null when not
  /// provided.
  @JsonKey(name: 'insurance_expiry')
  final DateTime? insuranceExpiry;

  Vehicles({
    this.Vehicle_info,
    required this.vehicleId,
    this.driverId,
    required this.name,
    required this.number,
    this.TypeId,
     this.capacity,
     this.FuelTypeId,
    this.mileage,
    this.StatusId,
    this.rcdocuments,
    this.FuelType,
    this.Type,
    this.StatusName,
      this.agencyId,
      this.perKmCharge,
      this.activeStatus,
      this.pucExpiry,
      this.insuranceExpiry,
  });

  /// True when either the PUC or insurance has already lapsed, or lapses
  /// within [withinDays] days (default 7). Used to drive the expiry-reminder
  /// popup shown on app open.
  bool isDocumentExpiringSoon({int withinDays = 7}) {
    final threshold = DateTime.now().add(Duration(days: withinDays));
    bool dueSoon(DateTime? d) => d != null && d.isBefore(threshold);
    return dueSoon(pucExpiry) || dueSoon(insuranceExpiry);
  }

  factory Vehicles.fromJson(Map<String, dynamic> json) => Vehicles(
        vehicleId: _readInt(
          json,
          const ['vehicleId', 'VehicleId', 'vehicle_id', 'vehicleID', 'id'],
        ),
        driverId: _readInt(
          json,
          const ['driverId', 'DriverId', 'driver_id', 'driverID'],
        ),
        name: _readString(json, const ['name', 'Name']),
        number: _readString(
            json, const ['number', 'Number', 'vehicleNo', 'VehicleNo']),
        TypeId: _readInt(json, const ['TypeId', 'typeId', 'VehicleTypeId']),
        capacity: _readInt(json, const ['capacity', 'Capacity', 'seats', 'Seats']),
        FuelTypeId: _readInt(json, const ['FuelTypeId', 'fuelTypeId']),
        mileage: _readString(json, const ['mileage', 'Mileage']),
        StatusId: _readInt(json, const ['StatusId', 'statusId']),
        rcdocuments: _readString(json, const [
          'rcdocument',
          'Rcdocument',
          'RCdocument',
          'rcDocument',
          'RCDocument',
          'rcdocuments',
          'rcDocuments',
          'RCDocuments',
          'RCdocuments',
          'RcDocuments',
          'document',
          'documents',
          'vehicleDocument',
          'VehicleDocument',
          'photo',
          'Photo',
        ]),
        FuelType: _readString(json, const ['FuelType', 'fuelType']),
        Type: _readString(json, const ['Type', 'type']),
        StatusName: _readString(json, const ['StatusName', 'statusName']),
        agencyId: _readString(json, const ['agencyId', 'agency_id']),
        perKmCharge: _readDouble(
            json, const ['per_km_charge', 'perKmCharge', 'PerKmCharge']),
        pucExpiry: _readDate(json, const [
          'puc_expiry',
          'pucExpiry',
          'PucExpiry',
          'PUCExpiry',
          'pucExpiryDate',
          'puc_expiry_date',
        ]),
        insuranceExpiry: _readDate(json, const [
          'insurance_expiry',
          'insuranceExpiry',
          'InsuranceExpiry',
          'insuranceExpiryDate',
          'insurance_expiry_date',
        ]),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'vehicleId': vehicleId,
        'VehicleId': vehicleId,
        'vehicle_id': vehicleId,
        'name': name,
        'Name': name,
        'number': number,
        'Number': number,
        'vehicleNo': number,
        'VehicleNo': number,
        'TypeId': TypeId,
        'typeId': TypeId,
        'VehicleTypeId': TypeId,
        'capacity': capacity,
        'Capacity': capacity,
        'seats': capacity,
        'FuelTypeId': FuelTypeId,
        'fuelTypeId': FuelTypeId,
        'mileage': mileage,
        'Mileage': mileage,
        'StatusId': StatusId,
        'statusId': StatusId,
        'rcdocuments': rcdocuments,
        'rcDocuments': rcdocuments,
        'document': rcdocuments,
        'documents': rcdocuments,
        'vehicleDocument': rcdocuments,
        'photo': rcdocuments,
        'FuelType': FuelType,
        'Type': Type,
        'StatusName': StatusName,
        'agency_id': agencyId,
        'agencyId': agencyId,
        'per_km_charge': perKmCharge,
        'puc_expiry': _formatDate(pucExpiry),
        'pucExpiry': _formatDate(pucExpiry),
        'insurance_expiry': _formatDate(insuranceExpiry),
        'insuranceExpiry': _formatDate(insuranceExpiry),
      };

  /// Formats a date as `yyyy-MM-dd` (date-only) for the API, or null when unset.
  static String? _formatDate(DateTime? d) {
    if (d == null) return null;
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  static int? _readInt(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) continue;
      if (value is int) return value;
      if (value is num) return value.toInt();
      final parsed = int.tryParse(value.toString());
      if (parsed != null) return parsed;
    }
    return null;
  }

  static String? _readString(Map<String, dynamic> json, List<String> keys) {
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

  static DateTime? _readDate(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) continue;
      if (value is DateTime) return value;
      final text = value.toString().trim();
      if (text.isEmpty || text.toLowerCase() == 'null') continue;
      final parsed = DateTime.tryParse(text);
      if (parsed != null) return parsed;
    }
    return null;
  }

  static double? _readDouble(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) continue;
      if (value is num) return value.toDouble();
      final parsed = double.tryParse(value.toString());
      if (parsed != null) return parsed;
    }
    return null;
  }
}
