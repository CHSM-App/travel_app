import 'package:json_annotation/json_annotation.dart';
part 'customers.g.dart';

@JsonSerializable()
class Customer {
  @JsonKey(name: 'CustomerId')
  int? customerId;

  @JsonKey(name: 'name')
  String? name;

  @JsonKey(name: 'phone')
  String? phone;

  @JsonKey(name: 'address')
  String? address;

  @JsonKey(name: 'LicenceNo')
  String? licenceNo;

  @JsonKey(name: 'LicenceExpiry')
  DateTime? licenceExpiry;

  Customer({
    this.customerId,
    this.name,
    this.phone,
    this.address,
    this.licenceNo,
    this.licenceExpiry,
  });
  factory Customer.fromJson(Map<String, dynamic> json) =>
      _$CustomerFromJson(json);
  Map<String, dynamic> toJson() => _$CustomerToJson(this);
}
