import 'dart:io';

import 'package:travel_agency_app/data/api/api_service.dart';
import 'package:travel_agency_app/domain/models/customers.dart';
import 'package:travel_agency_app/domain/repository/addcustomerrepository.dart';

class AddCustomerImpl implements Addcustomerrepository {
 final ApiService apiService;

  AddCustomerImpl(this.apiService);
  
  
  @override
  Future<dynamic> addcustomer(Customer customer) {
    return apiService.addcustomer(customer);
  }
    
  @override
  Future uploadCustomerDocument(File document, String customerId, String agencyId) {
     return apiService.uploadCustomerDocument(document,customerId, agencyId);
  }


  
 
}