import 'package:travel_agency_app/domain/models/customers.dart';

abstract class Customerrepository {
 // Future<dynamic> addcustomer(Customer customer);

  Future<List<Customer>> customerList();
 
 

}