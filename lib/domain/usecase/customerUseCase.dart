import 'package:travel_agency_app/domain/models/customers.dart';
import 'package:travel_agency_app/domain/repository/CustomerRepository.dart';
class customerUseCase {
  // Add your use case methods here
  final CustomerRepository customerrepository;
  customerUseCase(this.customerrepository);

  Future<dynamic> customerList() {
    return customerrepository.customerList();
  }      

//   Future<List<Customer>> getCustomers() {
//     return customerrepository.getCustomers();
//   }
//   Future<dynamic> updateCustomer(Customer customer) {
//     return customerrepository.updateCustomer(customer);
// }
} 