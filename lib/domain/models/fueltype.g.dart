// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fueltype.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Fueltype _$FueltypeFromJson(Map<String, dynamic> json) => Fueltype(
  FuelTypeId: (json['FuelTypeId'] as num?)?.toInt(),
  FuelType: json['FuelType'] as String?,
);

Map<String, dynamic> _$FueltypeToJson(Fueltype instance) => <String, dynamic>{
  'FuelTypeId': instance.FuelTypeId,
  'FuelType': instance.FuelType,
};
