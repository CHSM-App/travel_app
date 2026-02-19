import 'package:json_annotation/json_annotation.dart';

part 'login_response.g.dart';

@JsonSerializable()
class LoginResponse {

  @JsonKey(name: 'success')
  final int success;

  @JsonKey(name: 'message')
  final String message;

  @JsonKey(name: 'admin_id')
  final int? adminId;

  @JsonKey(name: 'name')
  final String? name;

  @JsonKey(name: 'email')
  final String? email;

  @JsonKey(name: 'mobile')
  final String? mobile;

  @JsonKey(name: 'agency_id')
  final String? agencyId;

  LoginResponse({
    required this.success,
    required this.message,
    this.adminId,
    this.name,
    this.email,
    this.mobile,
    this.agencyId,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json)
      => _$LoginResponseFromJson(json);

  Map<String, dynamic> toJson()
      => _$LoginResponseToJson(this);
}
