// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vehicles.dart';

Vehicles _$VehiclesFromJson(Map<String, dynamic> json) {
  int? readInt(List<String> keys) {
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

  String? readString(List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty && text.toLowerCase() != 'null') return text;
    }
    return null;
  }

  return Vehicles(
    vehicleId: readInt(['vehicleId', 'VehicleId', 'vehicle_id']),
    name: readString(['name', 'Name']),
    number: readString(['number', 'Number']),
    TypeId: readInt(['TypeId', 'typeId', 'type_id']),
    capacity: readInt(['capacity', 'Capacity']),
    FuelTypeId: readInt(['FuelTypeId', 'fuelTypeId', 'fuel_type_id']),
    mileage: readString(['mileage', 'Mileage']),
    StatusId: readInt(['StatusId', 'statusId', 'status_id']),
    rcdocuments: readString([
      'rcdocument',
      'rcDocument',
      'RCDocument',
      'RCdocument',
      'rcdocuments',
      'rcDocuments',
      'RcDocuments',
      'RCDocuments',
      'RCdocuments',
      'document',
      'Document',
    ]),
    FuelType: readString(['FuelType', 'fuelType']),
    Type: readString(['Type', 'type']),
    StatusName: readString(['StatusName', 'statusName']),
    agencyId: readString(['agency_id', 'agencyId']),
  );
}

Map<String, dynamic> _$VehiclesToJson(Vehicles instance) => <String, dynamic>{
      'vehicleId': instance.vehicleId,
      'name': instance.name,
      'number': instance.number,
      'TypeId': instance.TypeId,
      'capacity': instance.capacity,
      'FuelTypeId': instance.FuelTypeId,
      'mileage': instance.mileage,
      'StatusId': instance.StatusId,
      'rcdocuments': instance.rcdocuments,
      'FuelType': instance.FuelType,
      'Type': instance.Type,
      'StatusName': instance.StatusName,
      'agency_id': instance.agencyId,
    };
