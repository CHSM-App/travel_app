
import 'package:json_annotation/json_annotation.dart';
part 'customers.g.dart';
            
@JsonSerializable()
class Customer {
   String name;
   String phone;
   String address;
   String licenceNo;
   DateTime licenceExpiry;

  Customer({
    required this.name,
    required this.phone,
    required this.address,
    required this.licenceNo,
    required this.licenceExpiry,
  });
}