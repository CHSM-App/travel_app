import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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

  
  Future<int> addcustomer(Customer customer) async {
    state=state.copyWith(
      isLoading: true,
      error: null,
      data:null,
    );

   try{
    final result=await usecase.addCustomer(customer);
    final customerId = _extractCustomerId(result);
    
    state=state.copyWith(
      isLoading: false,
      data: result is Map<String, dynamic>
          ? result
          : <String, dynamic>{'CustomerId': customerId},
      error: null,
    );
    return customerId;
   }on DioException catch(e){
    final serverMessage=e.response?.data?['message'];
    state=state.copyWith(
      isLoading: false,
      error: serverMessage?? 'Server error',
    );

   debugPrint("Server Error: $serverMessage");
   rethrow;
   }catch(e){
    state=state.copyWith(
      isLoading: false,
      error: e.toString(),
    );
    rethrow;
   }

   }

   
Future<void> updateCustomer(Customer customer) async {
  state = state.copyWith(isLoading: true, error: null);

  try {
    final result = await usecase.updateCustomer(customer);
    state = state.copyWith(isLoading: false, data: result);
  } on DioException catch (e) {
    final serverMessage = e.response?.data?['message']?.toString();
    state = state.copyWith(
      isLoading: false,
      error: serverMessage ?? 'Server error',
    );
    rethrow;
  } catch (e) {
    state = state.copyWith(isLoading: false, error: e.toString());
    rethrow;
  }
}


  Future<dynamic> uploadCustomerDocument(
    File document,
    int customerId,
    String agencyId,
  ) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await usecase.uploadCustomerDocument(
        document,
        customerId.toString(),
        agencyId,
      );
      state = state.copyWith(isLoading: false);
      return response;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  int _extractCustomerId(dynamic result) {
    final id = _findIdRecursive(result);
    if (id != null) return id;
    throw Exception(
      'Unable to extract customer ID from API response. '
      'Response type: ${result.runtimeType}',
    );
  }

  int? _findIdRecursive(dynamic node) {
    if (node == null) return null;

    if (node is int) return node;
    if (node is num) return node.toInt();

    if (node is String) {
      final direct = int.tryParse(node.trim());
      if (direct != null) return direct;
      final firstDigits = RegExp(r'\d+').firstMatch(node)?.group(0);
      if (firstDigits != null) return int.tryParse(firstDigits);
      return null;
    }

    if (node is Map) {
      const candidateKeys = <String>[
        'CustomerId',
        'customerId',
        'customer_id',
        'CustomerID',
        'id',
        'ID',
        'insertId',
        'InsertId',
        'insertedId',
        'InsertedId',
      ];

      for (final key in candidateKeys) {
        if (node.containsKey(key)) {
          final found = _findIdRecursive(node[key]);
          if (found != null) return found;
        }
      }

      for (final value in node.values) {
        final found = _findIdRecursive(value);
        if (found != null) return found;
      }
      return null;
    }

    if (node is Iterable) {
      for (final item in node) {
        final found = _findIdRecursive(item);
        if (found != null) return found;
      }
      return null;
    }

    return null;
  }

  
   
Future<Map<String, dynamic>> deleteCustomer(int customerId) async {
  state = state.copyWith(isLoading: true, error: null);

  try {
    final result = await usecase.deleteCustomer(customerId);
    state = state.copyWith(isLoading: false);
    final status = result['status'];
    final isSuccess = status == 1 || status == '1' || status == true;

    if (isSuccess) {
      return {'success': true, 'message': result['message'] ?? 'Deleted successfully'};
    } else {
      return {'success': false, 'message': result['message'] ?? 'Delete failed'};
    }
  } on DioException catch (e) {
    final message = e.response?.data?['message'] ?? "Server error";
    state = state.copyWith(isLoading: false, error: message);
    return {'success': false, 'message': message};
  } catch (e) {
    final message = e.toString();
    state = state.copyWith(isLoading: false, error: message);
    return {'success': false, 'message': message};
  }
}
   

}
