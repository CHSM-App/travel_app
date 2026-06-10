import 'package:json_annotation/json_annotation.dart';

part 'payment_history.g.dart';

@JsonSerializable()
class PaymentHistory {
  @JsonKey(name: 'payment_id')
  final int? PaymentId;
  @JsonKey(name: 'trip_id')
  final int? TripId;
  @JsonKey(name: 'amount')
  final double? Amount;
  @JsonKey(name: 'payment_mode')
  final String? PaymentMode;
  @JsonKey(name: 'payment_date')
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
