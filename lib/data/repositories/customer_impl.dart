import 'package:travel_agency_app/data/api/api_service.dart';
import 'package:travel_agency_app/domain/models/booking_info.dart';
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
  Future<List<BookingInfo>> customerhist(int customer_id) {
    return apiService.customerhist(customer_id);
  }


}