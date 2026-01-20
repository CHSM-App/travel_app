import 'package:travel_agency_app/domain/models/customers.dart';

abstract class CustomerRepository {
 // Future<dynamic> addcustomer(Customer customer);

  Future<List<Customer>> customerList();
 
 

}