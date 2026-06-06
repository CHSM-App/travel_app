import 'package:json_annotation/json_annotation.dart';

part 'payment_history.g.dart';

@JsonSerializable()
class PaymentHistory {
  final int? PaymentId;
  final int? TripId;
  final double? Amount;
  final String? PaymentMode;
  final DateTime? PaymentDate;

  PaymentHistory({
    this.PaymentId,
    this.TripId,
    this.Amount,
    this.PaymentMode,
    this.PaymentDate,
  });

  factory PaymentHistory.fromJson(Map<String, dynamic> json) =>
      _$PaymentHistoryFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentHistoryToJson(this);
}
