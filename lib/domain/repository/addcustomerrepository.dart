

import 'package:travel_agency_app/domain/models/customers.dart';

abstract class Addcustomerrepository {
  Future<dynamic> addcustomer(Customer customer);
}
