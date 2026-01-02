// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vehicles.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Vehicles _$VehiclesFromJson(Map<String, dynamic> json) => Vehicles(
      vehicleId: (json['vehicleId'] as num?)?.toInt(),
      name: json['name'] as String?,
      number: json['number'] as String?,
      type: (json['type'] as num?)?.toInt(),
      capacity: (json['capacity'] as num?)?.toInt(),
      fueltype: (json['fueltype'] as num?)?.toInt(),
      mileage: json['mileage'] as String?,
      status: (json['status'] as num?)?.toInt(),
      rcdocuments: json['rcdocuments'] as String?,
    );

Map<String, dynamic> _$VehiclesToJson(Vehicles instance) => <String, dynamic>{
      'vehicleId': instance.vehicleId,
      'name': instance.name,
      'number': instance.number,
      'type': instance.type,
      'capacity': instance.capacity,
      'fueltype': instance.fueltype,
      'mileage': instance.mileage,
      'status': instance.status,
      'rcdocuments': instance.rcdocuments,
    };
