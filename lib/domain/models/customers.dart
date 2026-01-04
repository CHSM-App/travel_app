
import 'package:json_annotation/json_annotation.dart';
part 'customers.g.dart';
            
@JsonSerializable()
class Customer {
  int? CustomerId;
   String? name;
   String? phone;
   String? address;
   String? licenceNo;
   DateTime? licenceExpiry;

  Customer({
  this.CustomerId,
    this.name,
     this.phone,
     this.address,
    this.licenceNo,
    this.licenceExpiry,
  });
  factory Customer.fromJson(Map<String, dynamic> json) => _$CustomerFromJson(json);
   Map<String, dynamic> toJson() => _$CustomerToJson(this);
 
}