// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fueltype.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Fueltype _$FueltypeFromJson(Map<String, dynamic> json) => Fueltype(
      fuelTypeId: (json['fuelTypeId'] as num?)?.toInt(),
      fuelType: json['fuelType'] as String?,
    );

Map<String, dynamic> _$FueltypeToJson(Fueltype instance) => <String, dynamic>{
      'fuelTypeId': instance.fuelTypeId,
      'fuelType': instance.fuelType,
    };
