import 'package:json_annotation/json_annotation.dart';
part 'vehicles.g.dart';
            
@JsonSerializable()
class Vehicles {
  final int? vehicleId;
  final String? name;
  final String? number;
  final int? type;
  final int? capacity;
  final int? fueltype;
  final String? mileage;
  final int? status;
  final String? rcdocuments;

  Vehicles({
    required this.vehicleId,
    required this.name,
    required this.number,
    this.type,
    required this.capacity,
    required this.fueltype,
    this.mileage,
    this.status,
    this.rcdocuments
  });

  factory Vehicles.fromJson(Map<String, dynamic> json) =>
      _$VehiclesFromJson(json);  
  Map<String, dynamic> toJson() => _$VehiclesToJson(this); 
}


