// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_history.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaymentHistory _$PaymentHistoryFromJson(Map<String, dynamic> json) =>
    PaymentHistory(
      PaymentId: (json['payment_id'] as num?)?.toInt(),
      TripId: (json['trip_id'] as num?)?.toInt(),
      Amount: (json['amount'] as num?)?.toDouble(),
      PaymentMode: json['payment_mode'] as String?,
      PaymentDate: json['payment_date'] == null
          ? null
          : DateTime.parse(json['payment_date'] as String),
    );

Map<String, dynamic> _$PaymentHistoryToJson(PaymentHistory instance) =>
    <String, dynamic>{
      'payment_id': instance.PaymentId,
      'trip_id': instance.TripId,
      'amount': instance.Amount,
      'payment_mode': instance.PaymentMode,
      'payment_date': instance.PaymentDate?.toIso8601String(),
    };
