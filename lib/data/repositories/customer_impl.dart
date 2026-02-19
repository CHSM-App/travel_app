import 'package:travel_agency_app/data/api/api_service.dart';
import 'package:travel_agency_app/domain/models/booking_info.dart';
import 'package:travel_agency_app/domain/models/customers.dart';
import 'package:travel_agency_app/domain/repository/CustomerRepository.dart';

class CustomerImpl implements CustomerRepository {
  final ApiService apiService;

  CustomerImpl(this.apiService); 

  @override
  Future<List<Customer>> customerList(String agencyId) {
    return apiService.customerList(agencyId);
  }

  @override
  Future<List<BookingInfo>> customerhist(int customer_id) {
    return apiService.customerhist(customer_id);
  }

  @override
  Future<dynamic> addCustomer(Customer customer) {
    return apiService.addCustomer(customer);
  }
}
