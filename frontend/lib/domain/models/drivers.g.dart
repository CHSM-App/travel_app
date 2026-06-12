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
  licenceNo: json['LicenceNo'] as String?,
  licenceExpiry: Drivers._dateFromJson(json['LicenceExpiry'] as String?),
  vehicleId: (json['vehicleId'] as num?)?.toInt(),
  photo: json['photo'] as String?,
  agencyId: json['agency_id'] as String?,
  activeStatus: json['active_status'] as String?,
);

Map<String, dynamic> _$DriversToJson(Drivers instance) => <String, dynamic>{
  'driverId': instance.driverId,
  'name': instance.name,
  'phone': instance.phone,
  'address': instance.address,
  'LicenceNo': instance.licenceNo,
  'LicenceExpiry': Drivers._dateToJson(instance.licenceExpiry),
  'vehicleId': instance.vehicleId,
  'photo': instance.photo,
  'agency_id': instance.agencyId,
  'active_status': instance.activeStatus,
};
