import 'dart:io';

import 'package:vego/domain/models/booking_info.dart';
import 'package:vego/domain/models/customers.dart';

abstract class CustomerRepository {
 

  Future<List<Customer>> customerList(String agencyId);

  Future<List<BookingInfo>> customerhist(int customer_id);
 Future<dynamic> addcustomer(Customer customer);
   Future<dynamic> updatecustomer(Customer customer);
   
    Future<dynamic> uploadCustomerDocument(
   File document, String customerId, String agencyId
  );
  Future<dynamic> deleteCustomer(customerId);




}