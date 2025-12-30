import 'package:travel_agency_app/domain/models/tripbooking_info.dart';

abstract class Tripbookingrepository {
  Future<dynamic> addTripBooking(TripBooking tripBooking);

  
} 