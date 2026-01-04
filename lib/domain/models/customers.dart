
import 'package:json_annotation/json_annotation.dart';
part 'customers.g.dart';
            
@JsonSerializable()
class Customer {
   int? customerId;
   String? name;
   String? phone;
   String? address;
   String? licenceNo;
   DateTime? licenceExpiry;

  Customer({
    this.customerId,
    this.name,
    this.phone,
    this.address,
    this.licenceNo,
    this.licenceExpiry,
  });
}