// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'services.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Services _$ServicesFromJson(Map<String, dynamic> json) => Services(
  vehicleId: (json['vehicle_id'] as num?)?.toInt(),
  serviceName: json['service_name'] as String?,
  serviceCost: (json['service_cost'] as num?)?.toDouble(),
  serviceDate: json['service_date'] == null
      ? null
      : DateTime.parse(json['service_date'] as String),
  description: json['description'] as String?,
  agencyId: json['agency_id'] as String?,
);

Map<String, dynamic> _$ServicesToJson(Services instance) => <String, dynamic>{
  'vehicle_id': instance.vehicleId,
  'service_name': instance.serviceName,
  'service_cost': instance.serviceCost,
  'service_date': instance.serviceDate?.toIso8601String(),
  'description': instance.description,
  'agency_id': instance.agencyId,
};
