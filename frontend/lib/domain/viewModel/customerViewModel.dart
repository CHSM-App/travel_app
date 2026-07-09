import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vego/core/network/error_messages.dart';
import 'package:vego/domain/models/booking_info.dart';
import 'package:vego/domain/models/customers.dart';
import 'package:vego/domain/usecase/customerUseCase.dart';

class CustomerState {

  final bool isLoading;
  final Map<String, dynamic>? data;
  final String? error;
  final AsyncValue<List<Customer>> customerList;
  final int? adminId;
    final AsyncValue<List<BookingInfo>> customerHist;
  final AsyncValue<List<Customer>> deletedCustomerList;

  const CustomerState({
   this.isLoading = false,
     this.data ,
    this.error,
    this.customerList = const AsyncValue.loading(),
    this.adminId,
    this.customerHist= const AsyncValue.loading(),
    this.deletedCustomerList = const AsyncValue.loading(),
  });

  //AsyncValue<List<BookingInfo>>? get customerHist => null; 

  CustomerState copyWith({
   bool? isLoading,
    Map<String, dynamic>? data,
    String? error,
    AsyncValue<List<Customer>>? customerList,
    int? adminId,
    AsyncValue<List<BookingInfo>>? customerHist,
    AsyncValue<List<Customer>>? deletedCustomerList,

  }) {
    return CustomerState(
       isLoading: isLoading ?? this.isLoading,
      data: data ?? this.data,
      error: error ?? this.error,
      customerList: customerList ?? this.customerList,
      adminId: adminId ?? this.adminId,
      customerHist: customerHist ?? this.customerHist,
      deletedCustomerList: deletedCustomerList ?? this.deletedCustomerList,
    );
  }
}
class CustomerViewModel extends StateNotifier<CustomerState> {
  final customerUseCase usecase;

  CustomerViewModel(this.usecase) : super(const CustomerState());

 

  Future<void> fetchCustomerslist(String agencyId) async {
    state = state.copyWith(customerList: const AsyncValue.loading());
    try {
      final result = await usecase.customerList(agencyId);
      state = state.copyWith(customerList: AsyncValue.data(result));
    } catch (e, st) {
      state = state.copyWith(customerList: AsyncValue.error(e, st));
    }
  }

  Future<void> fetchDeletedCustomerList(String agencyId) async {
    state = state.copyWith(deletedCustomerList: const AsyncValue.loading());
    try {
      final result = await usecase.deletedCustomerList(agencyId);
      state = state.copyWith(deletedCustomerList: AsyncValue.data(result));
    } catch (e, st) {
      state = state.copyWith(deletedCustomerList: AsyncValue.error(e, st));
    }
  }

  Future<void> fetchCustomershist( int customer_id) async {
    state = state.copyWith(customerHist: const AsyncValue.loading());
    try {
      final result = await usecase.customerhist(customer_id);
      state = state.copyWith(customerHist: AsyncValue.data(result));
    } catch (e, st) {
      state = state.copyWith(customerHist: AsyncValue.error(e, st));
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

    // Some deployments still return HTTP 200 even when the stored procedure
    // rejected the row (e.g. duplicate phone). Treat that as a real failure
    // and surface the SP's message instead of falling through to a generic
    // "Something went wrong".
    final spMsg = _spFailureMessage(result);
    if (spMsg != null) throw AppException(spMsg);

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
    final message = friendlyErrorMessage(e);
    state=state.copyWith(
      isLoading: false,
      error: message,
    );

   debugPrint("Server Error: $message");
   rethrow;
   }catch(e){
    state=state.copyWith(
      isLoading: false,
      error: friendlyErrorMessage(e),
    );
    rethrow;
   }

   }

   
Future<void> updateCustomer(Customer customer) async {
  state = state.copyWith(isLoading: true, error: null);

  try {
    final result = await usecase.updateCustomer(customer);
    final spMsg = _spFailureMessage(result);
    if (spMsg != null) throw AppException(spMsg);
    state = state.copyWith(isLoading: false, data: result);
  } on DioException catch (e) {
    state = state.copyWith(
      isLoading: false,
      error: friendlyErrorMessage(e),
    );
    rethrow;
  } catch (e) {
    state = state.copyWith(isLoading: false, error: friendlyErrorMessage(e));
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
      state = state.copyWith(isLoading: false, error: friendlyErrorMessage(e));
      rethrow;
    }
  }

  /// Returns a human-readable message if the API response actually represents
  /// a stored-procedure failure (HTTP 200 but `success=false` somewhere in
  /// the body, e.g. duplicate phone). Returns null when the response is a
  /// legitimate success so the caller proceeds normally.
  String? _spFailureMessage(dynamic result) {
    if (result is! Map) return null;

    bool? readBoolish(dynamic v) {
      if (v == null) return null;
      if (v is bool) return v;
      if (v is num) return v == 1;
      if (v is String) {
        final s = v.toLowerCase().trim();
        if (s == 'true' || s == '1') return true;
        if (s == 'false' || s == '0') return false;
      }
      return null;
    }

    final topSuccess = readBoolish(result['success']);
    final inner = result['data'];
    final innerSuccess =
        (inner is Map) ? readBoolish(inner['success']) : null;

    // Treat as failure only when something explicitly says so.
    final failed = topSuccess == false || innerSuccess == false;
    if (!failed) return null;

    final innerMsg = (inner is Map) ? inner['message'] : null;
    final outerMsg = result['message'];
    final msg = (innerMsg is String && innerMsg.trim().isNotEmpty)
        ? innerMsg
        : (outerMsg is String && outerMsg.trim().isNotEmpty)
            ? outerMsg
            : 'Could not save customer';
    return msg.toString().trim();
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
    final message = friendlyErrorMessage(e);
    state = state.copyWith(isLoading: false, error: message);
    return {'success': false, 'message': message};
  } catch (e) {
    final message = friendlyErrorMessage(e);
    state = state.copyWith(isLoading: false, error: message);
    return {'success': false, 'message': message};
  }
}
   

}
