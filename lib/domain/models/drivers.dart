import 'package:json_annotation/json_annotation.dart';
part 'drivers.g.dart';
            
@JsonSerializable()
class Drivers {
  @JsonKey(name: 'driverId')
  final int? driverId;

  @JsonKey(name: 'name')
  final String? name;

  @JsonKey(name: 'phone')
  final String? phone;

  @JsonKey(name: 'address')
  final String? address;

  @JsonKey(name: 'LicenceNo')
  final String? licenceNo;

  @JsonKey(name: 'LicenceExpiry')
  final DateTime? licenceExpiry;

  @JsonKey(name: 'vehicleId')
  final int? vehicleId;

  @JsonKey(name: 'photo')
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


