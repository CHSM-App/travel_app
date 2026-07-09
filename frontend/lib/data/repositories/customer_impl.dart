import 'dart:io';

import 'package:vego/data/api/api_service.dart';
import 'package:vego/domain/models/booking_info.dart';
import 'package:vego/domain/models/customers.dart';
import 'package:vego/domain/repository/CustomerRepository.dart';

class CustomerImpl implements CustomerRepository {
  final ApiService apiService;

  CustomerImpl(this.apiService); 

  @override
  Future<List<Customer>> customerList(String agencyId) {
    return apiService.customerList(agencyId);
  }

  @override
  Future<List<Customer>> deletedCustomerList(String agencyId) {
    return apiService.deletedCustomerList(agencyId);
  }

  @override
  Future<List<BookingInfo>> customerhist(int customer_id) {
    return apiService.customerhist(customer_id);
  }
  
  
  @override
  Future<dynamic> addcustomer(Customer customer) {
    return apiService.addCustomer(customer);
  }
      
  @override
  Future<dynamic> updatecustomer(Customer customer) {
    return apiService.updateCustomer(customer);
  }
    
  @override
  Future uploadCustomerDocument(File document, String customerId, String agencyId) {
     return apiService.uploadCustomerDocument(document,customerId, agencyId);
  }


   @override
  Future<dynamic> deleteCustomer(customerId) {
    return apiService.deleteCustomer(customerId);
  }

}
