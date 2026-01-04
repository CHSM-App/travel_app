// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customers.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Customer _$CustomerFromJson(Map<String, dynamic> json) => Customer(
      CustomerId: (json['CustomerId'] as num?)?.toInt(),
      name: json['name'] as String?,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      licenceNo: json['licenceNo'] as String?,
      licenceExpiry: json['licenceExpiry'] == null
          ? null
          : DateTime.parse(json['licenceExpiry'] as String),
    );

Map<String, dynamic> _$CustomerToJson(Customer instance) => <String, dynamic>{
      'CustomerId': instance.CustomerId,
      'name': instance.name,
      'phone': instance.phone,
      'address': instance.address,
      'licenceNo': instance.licenceNo,
      'licenceExpiry': instance.licenceExpiry?.toIso8601String(),
    };
