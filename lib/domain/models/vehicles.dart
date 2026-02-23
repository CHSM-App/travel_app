import 'package:json_annotation/json_annotation.dart';
part 'vehicles.g.dart';

@JsonSerializable()
class Vehicles {
  final int? vehicleId;
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

  Vehicles({
    required this.vehicleId,
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
  });

  factory Vehicles.fromJson(Map<String, dynamic> json) => Vehicles(
        vehicleId: _readInt(json, const ['vehicleId', 'VehicleId', 'id']),
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
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'vehicleId': vehicleId,
        'name': name,
        'number': number,
        'TypeId': TypeId,
        'capacity': capacity,
        'FuelTypeId': FuelTypeId,
        'mileage': mileage,
        'StatusId': StatusId,
        'rcdocuments': rcdocuments,
        'FuelType': FuelType,
        'Type': Type,
        'StatusName': StatusName,
        'agency_id': agencyId,
      };

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
}
