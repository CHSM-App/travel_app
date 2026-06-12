// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reports_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReportData _$ReportDataFromJson(Map<String, dynamic> json) => ReportData(
  bookingDate: _toDateTimeNull(json['booking_date']),
  tripId: (json['trip_id'] as num?)?.toInt(),
  customerName: json['customer_name'] as String?,
  driverName: json['driver_name'] as String?,
  vehicleName: json['vehicle_name'] as String?,
  pickupLocation: json['pickup_location'] as String?,
  dropLocation: json['drop_location'] as String?,
  amountReceived: _toDoubleNull(json['amount_received']),
  totalExpense: _toDoubleNull(json['total_expense']),
  profit: _toDoubleNull(json['profit']),
  loss: _toDoubleNull(json['loss']),
  netResult: _toDoubleNull(json['net_result']),
  vehicleId: (json['vehicleId'] as num?)?.toInt(),
  vehicleNumber: json['vehicle_number'] as String?,
  driverId: (json['driverId'] as num?)?.toInt(),
  driverPhone: json['driver_phone'] as String?,
  customerId: (json['CustomerId'] as num?)?.toInt(),
  customerPhone: json['customer_phone'] as String?,
  totalTrips: (json['total_trips'] as num?)?.toInt(),
  totalIncome: _toDoubleNull(json['total_income']),
  totalProfit: _toDoubleNull(json['total_profit']),
  totalLoss: _toDoubleNull(json['total_loss']),
  netRevenue: _toDoubleNull(json['net_revenue']),
);

Map<String, dynamic> _$ReportDataToJson(ReportData instance) =>
    <String, dynamic>{
      'booking_date': instance.bookingDate?.toIso8601String(),
      'trip_id': instance.tripId,
      'customer_name': instance.customerName,
      'driver_name': instance.driverName,
      'vehicle_name': instance.vehicleName,
      'pickup_location': instance.pickupLocation,
      'drop_location': instance.dropLocation,
      'amount_received': instance.amountReceived,
      'total_expense': instance.totalExpense,
      'profit': instance.profit,
      'loss': instance.loss,
      'net_result': instance.netResult,
      'vehicleId': instance.vehicleId,
      'vehicle_number': instance.vehicleNumber,
      'driverId': instance.driverId,
      'driver_phone': instance.driverPhone,
      'CustomerId': instance.customerId,
      'customer_phone': instance.customerPhone,
      'total_trips': instance.totalTrips,
      'total_income': instance.totalIncome,
      'total_profit': instance.totalProfit,
      'total_loss': instance.totalLoss,
      'net_revenue': instance.netRevenue,
    };
