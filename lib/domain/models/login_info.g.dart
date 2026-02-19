// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'login_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoginInfo _$LoginInfoFromJson(Map<String, dynamic> json) => LoginInfo(
  adminId: (json['admin_id'] as num?)?.toInt(),
  name: json['name'] as String?,
  email: json['email'] as String?,
  mobile: json['mobile'] as String?,
  password: json['password'] as String?,
  address: json['address'] as String?,
  agencyName: json['agency_name'] as String?,
  city: json['city'] as String?,
  agencyId: json['agency_id'] as String?,
);

Map<String, dynamic> _$LoginInfoToJson(LoginInfo instance) => <String, dynamic>{
  'admin_id': instance.adminId,
  'name': instance.name,
  'email': instance.email,
  'mobile': instance.mobile,
  'password': instance.password,
  'address': instance.address,
  'agency_name': instance.agencyName,
  'agency_id': instance.agencyId,
  'city': instance.city,
};
