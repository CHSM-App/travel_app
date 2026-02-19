import 'package:travel_agency_app/domain/models/booking_info.dart';
import 'package:travel_agency_app/domain/models/customers.dart';

abstract class CustomerRepository {
 
  Future<dynamic> addCustomer(Customer customer);

  Future<List<Customer>> customerList(String agencyId);

  Future<List<BookingInfo>> customerhist(int customer_id);



}