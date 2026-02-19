// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vehicles.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Vehicles _$VehiclesFromJson(Map<String, dynamic> json) => Vehicles(
  vehicleId: (json['vehicleId'] as num?)?.toInt(),
  name: json['name'] as String?,
  number: json['number'] as String?,
  TypeId: (json['TypeId'] as num?)?.toInt(),
  capacity: (json['capacity'] as num?)?.toInt(),
  FuelTypeId: (json['FuelTypeId'] as num?)?.toInt(),
  mileage: json['mileage'] as String?,
  StatusId: (json['StatusId'] as num?)?.toInt(),
  rcdocuments: json['rcdocuments'] as String?,
  FuelType: json['FuelType'] as String?,
  Type: json['Type'] as String?,
  StatusName: json['StatusName'] as String?,
  agencyId: json['agency_id'] as String?,
);

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
