// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vehicletype.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VehicleType _$VehicleTypeFromJson(Map<String, dynamic> json) => VehicleType(
      TypeId: (json['TypeId'] as num?)?.toInt(),
      type: json['type'] as String?,
    );

Map<String, dynamic> _$VehicleTypeToJson(VehicleType instance) =>
    <String, dynamic>{
      'TypeId': instance.TypeId,
      'type': instance.type,
    };
