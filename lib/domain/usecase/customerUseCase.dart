import 'package:travel_agency_app/domain/models/customers.dart';
import 'package:travel_agency_app/domain/repository/CustomerRepository.dart';
class customerUseCase {
  // Add your use case methods here
  final Customerrepository customerrepository;
  customerUseCase(this.customerrepository);

  Future<dynamic> addCustomer(Customer customer) {
    return customerrepository.customerList();
  }                                                                                                                                                                               
//   Future<List<Customer>> getCustomers() {
//     return customerrepository.getCustomers();
//   }
//   Future<dynamic> updateCustomer(Customer customer) {
//     return customerrepository.updateCustomer(customer);
// }
} 