import 'package:travel_agency_app/domain/repository/CustomerRepository.dart';
class customerUseCase {
  // Add your use case methods here
  final CustomerRepository customerrepository;
  customerUseCase(this.customerrepository);

  Future<dynamic> customerList() {
    return customerrepository.customerList();
  }

  Future<dynamic> addCustomer(Customer customer) {
    return customerrepository.addCustomer(customer);
  }      

 Future<dynamic> customerhist(int customer_id) {
    return customerrepository.customerhist(customer_id);
  }   
} 