import 'package:json_annotation/json_annotation.dart';

part 'services.g.dart';

@JsonSerializable()
class Services {
  @JsonKey(name: 'service_id')
  final int? serviceId;

  @JsonKey(name: 'vehicle_id')
  final int? vehicleId;

  @JsonKey(name: 'service_name')
  final String? serviceName;

  @JsonKey(name: 'service_cost')
  final double? serviceCost;

  @JsonKey(name: 'service_date')
  final DateTime? serviceDate;

  @JsonKey(name: 'description')
  final String? description;

  @JsonKey(name: 'agency_id')
  final String? agencyId;

  Services({
    this.serviceId,
    this.vehicleId,
    this.serviceName,
    this.serviceCost,
    this.serviceDate,
    this.description,
    this.agencyId,
  });

  factory Services.fromJson(Map<String, dynamic> json) =>
      _$ServicesFromJson(json);
  Map<String, dynamic> toJson() => _$ServicesToJson(this);
}
