// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customers.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Customer _$CustomerFromJson(Map<String, dynamic> json) => Customer(
  customerId: (json['CustomerId'] as num?)?.toInt(),
  name: json['name'] as String?,
  phone: json['phone'] as String?,
  address: json['address'] as String?,
  licenceNo: json['LicenceNo'] as String?,
  licenceExpiry: json['LicenceExpiry'] == null
      ? null
      : DateTime.parse(json['LicenceExpiry'] as String),
  documents: json['documents'] as String?,
  agencyId: json['agency_id'] as String?,
  pendingAmount: (json['pending_amount'] as num?)?.toDouble(),
);

Map<String, dynamic> _$CustomerToJson(Customer instance) => <String, dynamic>{
  'CustomerId': instance.customerId,
  'name': instance.name,
  'phone': instance.phone,
  'address': instance.address,
  'LicenceNo': instance.licenceNo,
  'LicenceExpiry': instance.licenceExpiry?.toIso8601String(),
  'documents': instance.documents,
  'agency_id': instance.agencyId,
  'pending_amount': instance.pendingAmount,
};
