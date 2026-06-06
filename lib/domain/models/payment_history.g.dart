// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_history.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaymentHistory _$PaymentHistoryFromJson(Map<String, dynamic> json) =>
    PaymentHistory(
      PaymentId: (json['PaymentId'] as num?)?.toInt(),
      TripId: (json['TripId'] as num?)?.toInt(),
      Amount: (json['Amount'] as num?)?.toDouble(),
      PaymentMode: json['PaymentMode'] as String?,
      PaymentDate: json['PaymentDate'] == null
          ? null
          : DateTime.parse(json['PaymentDate'] as String),
    );

Map<String, dynamic> _$PaymentHistoryToJson(PaymentHistory instance) =>
    <String, dynamic>{
      'PaymentId': instance.PaymentId,
      'TripId': instance.TripId,
      'Amount': instance.Amount,
      'PaymentMode': instance.PaymentMode,
      'PaymentDate': instance.PaymentDate?.toIso8601String(),
    };
