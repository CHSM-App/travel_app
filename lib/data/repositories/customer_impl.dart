import 'package:travel_agency_app/data/api/api_service.dart';
import 'package:travel_agency_app/domain/models/customers.dart';
import 'package:travel_agency_app/domain/repository/CustomerRepository.dart';

class CustomerImpl implements CustomerRepository {
  final ApiService apiService;

  CustomerImpl(this.apiService);

  @override
  Future<List<Customer>> customerList() {
    return apiService.customerList();
  }

    @override
  Future<dynamic> addCustomer(Customer customer) {
    return apiService.addCustomer(customer);
  }
}