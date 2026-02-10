import 'package:json_annotation/json_annotation.dart';
part 'drivers.g.dart';
            
@JsonSerializable()
class Drivers {
  final int? driverId;
  final String? name;
  final String? phone;
  final String? address;
  final String? licenceNo;
  final DateTime? licenceExpiry;
  final int? vehicleId;
  final String? photo;

  Drivers({
     this.driverId,
     this.name,
     this.phone,
    this.address,
     this.licenceNo,
     this.licenceExpiry,
    this.vehicleId,
    this.photo,
  });

  factory Drivers.fromJson(Map<String, dynamic> json) =>
      _$DriversFromJson(json);  
  Map<String, dynamic> toJson() => _$DriversToJson(this); 
}


