// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'drivers.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Drivers _$DriversFromJson(Map<String, dynamic> json) => Drivers(
  driverId: (json['driverId'] as num?)?.toInt(),
  name: json['name'] as String?,
  phone: json['phone'] as String?,
  address: json['address'] as String?,
  licenceNo: json['licenceNo'] as String?,
  licenceExpiry: json['licenceExpiry'] == null
      ? null
      : DateTime.parse(json['licenceExpiry'] as String),
  vehicleId: (json['vehicleId'] as num?)?.toInt(),
  photo: json['photo'] as String?,
);

Map<String, dynamic> _$DriversToJson(Drivers instance) => <String, dynamic>{
  'driverId': instance.driverId,
  'name': instance.name,
  'phone': instance.phone,
  'address': instance.address,
  'licenceNo': instance.licenceNo,
  'licenceExpiry': instance.licenceExpiry?.toIso8601String(),
  'vehicleId': instance.vehicleId,
  'photo': instance.photo,
};
