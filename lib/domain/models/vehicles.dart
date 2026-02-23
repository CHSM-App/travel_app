import 'package:json_annotation/json_annotation.dart';

part 'vehicles.g.dart';

@JsonSerializable()
class Vehicles {

  final String? Vehicle_info;
  final int? vehicleId;
  final String? name;
  final String? number;
  final int? TypeId;
  final int? capacity;
  final int? FuelTypeId;
  final String? mileage;
  final int? StatusId;
  final String? rcdocuments;
  final String? FuelType;
  final String? Type;
  final String? StatusName;
  final String? agencyId;

  Vehicles({
    this.Vehicle_info,
    required this.vehicleId,
    required this.name,
    required this.number,
    this.TypeId,
     this.capacity,
     this.FuelTypeId,
    this.mileage,
    this.StatusId,
    this.rcdocuments,
    this.FuelType,
    this.Type,
    this.StatusName,
      this.agencyId,
  });

  factory Vehicles.fromJson(Map<String, dynamic> json) =>
      _$VehiclesFromJson(json);

  Map<String, dynamic> toJson() => _$VehiclesToJson(this);
}

