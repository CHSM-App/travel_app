// lib/models/logininfo.dart
import 'package:json_annotation/json_annotation.dart';

part 'login_info.g.dart';

@JsonSerializable()
class LoginInfo {
  @JsonKey(name: 'admin_id')
  final int? adminId;

  @JsonKey(name: 'name')
  final String? name;

  @JsonKey(name: 'email')
  final String? email;

  @JsonKey(name: 'mobile')
  final String? mobile;

  @JsonKey(name: 'password')
  final String? password;

  @JsonKey(name: 'address')
  final String? address;

  @JsonKey(name: 'agency_name')
  final String? agencyName;

  @JsonKey(name: 'agency_id')
  final String? agencyId;

  @JsonKey(name: 'city')
  final String? city;
  @JsonKey(name: 'image_url')
  final String? imageUrl;

  /// Default charge per kilometre for this agency, captured at signup and used
  /// to auto-fill the Trip Charges field (distance × rate) when booking.
  @JsonKey(name: 'per_km_charge')
  final double? perKmCharge;

  LoginInfo({
    this.adminId,
     this.name,
     this.email,
    this.mobile,
     this.password,
    this.address,
    this.agencyName,
    this.city,
    this.agencyId,
    this.imageUrl,
    this.perKmCharge,
  });
  factory LoginInfo.fromJson(Map<String, dynamic> json) =>
      _$LoginInfoFromJson(json);
  Map<String, dynamic> toJson() => _$LoginInfoToJson(this);

}
