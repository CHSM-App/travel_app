import 'dart:io';

import 'package:vego/domain/models/customers.dart';
import 'package:vego/domain/repository/CustomerRepository.dart';
class customerUseCase {
  // Add your use case methods here
  final CustomerRepository customerrepository;
  customerUseCase(this.customerrepository);

  Future<dynamic> customerList(String agencyId) {
    return customerrepository.customerList(agencyId);
  }


 Future<dynamic> customerhist(int customer_id) {
    return customerrepository.customerhist(customer_id);
  }   


  Future<dynamic> addCustomer(Customer customer) {
    return customerrepository.addcustomer(customer);
  }

  Future<dynamic> updateCustomer(Customer customer) {
    return customerrepository.updatecustomer(customer);
  }
  
  Future<dynamic> uploadCustomerDocument(
  File document, String customerId, String agencyId
  ) {
    return customerrepository.uploadCustomerDocument(
      document,
      customerId,
      agencyId,
    );
  }
  Future<dynamic> deleteCustomer(customerId) {
    return customerrepository.deleteCustomer(customerId);
  }

} 