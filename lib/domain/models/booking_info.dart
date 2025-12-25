import 'package:json_annotation/json_annotation.dart';
part 'booking_info.g.dart';
            
@JsonSerializable()
class BookingInfo {
  final int? tripId;
  final int vehicleId;
  final int driverId;
  final String pickupLocation;
  final String dropLocation;
  final double distance;
  final double fuelRequired;
  final double tollCharges;
  final double repairingCharges;
  final double driverCharges;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final String status;
  final String purpose;
  final double amountApprove;
  final double amountReceived;
  final int customerId;

  BookingInfo({
    this.tripId,
    required this.vehicleId,
    required this.driverId,
    required this.pickupLocation,
    required this.dropLocation,
    required this.distance,
    required this.fuelRequired,
    required this.tollCharges,
    required this.repairingCharges,
    required this.driverCharges,
    required this.startDateTime,
    required this.endDateTime,
    required this.status,
    required this.purpose,
    required this.amountApprove,
    required this.amountReceived,
    required this.customerId
  });

  factory BookingInfo.fromJson(Map<String, dynamic> json) =>
      _$BookingInfoFromJson(json);  

  Map<String, dynamic> toJson() => _$BookingInfoToJson(this); 
}


