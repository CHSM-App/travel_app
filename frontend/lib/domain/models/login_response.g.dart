// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'login_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoginResponse _$LoginResponseFromJson(Map<String, dynamic> json) =>
    LoginResponse(
      success: (json['success'] as num).toInt(),
      message: json['message'] as String,
      adminId: (json['admin_id'] as num?)?.toInt(),
      name: json['name'] as String?,
      email: json['email'] as String?,
      mobile: json['mobile'] as String?,
      agencyId: json['agency_id'] as String?,
      imageUrl: json['image_url'] as String?,
      perKmCharge: (json['per_km_charge'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$LoginResponseToJson(LoginResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'admin_id': instance.adminId,
      'name': instance.name,
      'email': instance.email,
      'mobile': instance.mobile,
      'agency_id': instance.agencyId,
      'image_url': instance.imageUrl,
      'per_km_charge': instance.perKmCharge,
    };
