import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_agency_app/domain/models/customers.dart';
import 'package:travel_agency_app/domain/usecase/addCustomerUseCase.dart';

@immutable

class addCustomerState{
  final bool isLoading;
  final Map<String,dynamic>? data;
  final String? error;

  addCustomerState( {
    this.isLoading=false, 
    this.data,
    this.error
  });

  addCustomerState copyWith({
  bool? isLoading,
  Map<String,dynamic>? data,
  String? error
  }){
    return addCustomerState(
      isLoading: isLoading?? this.isLoading,
      data:data?? this.data,
      error:error?? this.error
    );
  }
}

class AddcustomerViewmodel extends StateNotifier<addCustomerState> {
  final Ref ref;
  final AddCustomerUseCase useCase;

  AddcustomerViewmodel(this.ref,this.useCase)
  :super(addCustomerState());

  Future<void> addcustomer(Customer customer) async {
    state=state.copyWith(
      isLoading: true,
      error: null,
      data:null,
    );

   try{
    final result=await useCase.addCustomer(customer);
    
    state=state.copyWith(
      isLoading: false,
      data:{
        "success":true,
        "message":"Customer Added",
      },
      error: null,
    );
   }on DioException catch(e){
    final serverMessage=e.response?.data?['message'];
    state=state.copyWith(
      isLoading: false,
      error: serverMessage?? 'Server error',
    );

   debugPrint("Server Error: $serverMessage");
   }catch(e){
    state=state.copyWith(
      isLoading: false,
      error: e.toString(),
    );
   }

   }

  }
 