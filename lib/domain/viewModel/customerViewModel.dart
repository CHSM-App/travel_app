import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_agency_app/domain/models/booking_info.dart';
import 'package:travel_agency_app/domain/models/customers.dart';
import 'package:travel_agency_app/domain/usecase/customerUseCase.dart';

class CustomerState {

  final bool isLoading;
  final Map<String, dynamic>? data;
  final String? error;
  final AsyncValue<List<Customer>> CustomerList;
  final int? adminId;
    final AsyncValue<List<BookingInfo>> Customerhist;

  const CustomerState({
   this.isLoading = false,
     this.data ,
    this.error,
    this.CustomerList = const AsyncValue.loading(),
    this.adminId,
    this.Customerhist= const AsyncValue.loading(),
  });

  //AsyncValue<List<BookingInfo>>? get customerHist => null; 

  CustomerState copyWith({
   bool? isLoading,
    Map<String, dynamic>? data,
    String? error,
    AsyncValue<List<Customer>>? CustomerList,
    int? adminId,
    AsyncValue<List<BookingInfo>>? Customerhist,

  }) {
    return CustomerState(
       isLoading: isLoading ?? this.isLoading,
      data: data ?? this.data,
      error: error ?? this.error,
      CustomerList: CustomerList ?? this.CustomerList,
      adminId: adminId ?? this.adminId,
      Customerhist: Customerhist ?? this.Customerhist,
    );
  } 
}
class CustomerViewModel extends StateNotifier<CustomerState> {
  final customerUseCase usecase;

  CustomerViewModel(this.usecase) : super(const CustomerState());

  /// Fetch customers
  // Future<void> addcustomer(Customer customer) async {
  //   state = state.copyWith(isLoading: true, error: null);

  //   try {
  //     final result = await usecase.addCustomer(customer);
  //     state = state.copyWith(
  //       isLoading: false,
  //       data: {
  //         'customers': result,
  //       },
  //     );
  //   } on DioException catch (e) {
  //     state = state.copyWith(
  //       isLoading: false,
  //       error: e.response?.data?['message'] ?? 'Server error',
  //     );
  //   } catch (e) {
  //     state = state.copyWith(
  //       isLoading: false,
  //       error: e.toString(),
  //     );
  //   }
  // }

//     Future<int> addEmployee(Customer customer) async {
//   state = state.copyWith(isLoading: true, error: null);
//   try {
    
//     final response = await usecase.addCostomer(customer);
//     // Extract CustomerId from response map
//     final int newCustomerId = response['CustomerId'] as int;

//     state = state.copyWith(isLoading: false);
//     return newCustomerId;
//   } catch (e) {
//     state = state.copyWith(isLoading: false, error: e.toString());
//     rethrow;
//   }
// }

  Future<int> addCustomer(Customer customer) async {
  state = state.copyWith(isLoading: true, error: null);

  try {
    final response = await usecase.addCustomer(customer);

    // Extract customer_id from response
    final int newCustomerId = response['customer_id'] as int;

    // Refresh customer list (if needed)
    // await fetchCustomerslist();

    state = state.copyWith(isLoading: false);

    return newCustomerId;
  } catch (e) {
    state = state.copyWith(
      isLoading: false,
      error: e.toString(),
    );
    rethrow;
  }
}



  Future<void> fetchCustomerslist(String agencyId) async {
    state = state.copyWith(CustomerList: const AsyncValue.loading());
    try {
      final result = await usecase.customerList(agencyId);
      state = state.copyWith(CustomerList: AsyncValue.data(result));
    } catch (e, st) {
      state = state.copyWith(CustomerList: AsyncValue.error(e, st));
    }
  }

  Future<void> fetchCustomershist( int customer_id) async {
    state = state.copyWith(Customerhist: const AsyncValue.loading());
    try {
      final result = await usecase.customerhist(customer_id);
      state = state.copyWith(Customerhist: AsyncValue.data(result));
    } catch (e, st) {
      state = state.copyWith(Customerhist: AsyncValue.error(e, st));
    }
  }
   
   

}
