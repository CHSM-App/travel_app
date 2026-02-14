import 'package:travel_agency_app/domain/models/booking_info.dart';
import 'package:travel_agency_app/domain/models/customers.dart';

abstract class CustomerRepository {
 // Future<dynamic> addcustomer(Customer customer);

  Future<List<Customer>> customerList();

  Future<List<BookingInfo>> customerhist(int customer_id);
 
 

}