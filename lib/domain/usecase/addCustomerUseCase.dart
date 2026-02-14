import 'package:travel_agency_app/domain/models/customers.dart';
import 'package:travel_agency_app/domain/repository/addcustomerrepository.dart';

class AddCustomerUseCase {
  final Addcustomerrepository addcustomerrepository;

  AddCustomerUseCase(this.addcustomerrepository);
  Future<dynamic> addCustomer(Customer customer) {
    return addcustomerrepository.addcustomer(customer);
  }
}