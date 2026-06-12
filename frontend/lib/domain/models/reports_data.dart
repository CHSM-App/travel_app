import 'package:json_annotation/json_annotation.dart';

part 'reports_data.g.dart';

@JsonSerializable(explicitToJson: true)
class ReportData {

  @JsonKey(name: 'booking_date', fromJson: _toDateTimeNull)
  final DateTime? bookingDate;

  @JsonKey(name: 'trip_id')
  final int? tripId;

  @JsonKey(name: 'customer_name')
  final String? customerName;

  @JsonKey(name: 'driver_name')
  final String? driverName;

  @JsonKey(name: 'vehicle_name')
  final String? vehicleName;

  @JsonKey(name: 'pickup_location')
  final String? pickupLocation;

  @JsonKey(name: 'drop_location')
  final String? dropLocation;

  @JsonKey(name: 'amount_received', fromJson: _toDoubleNull)
  final double? amountReceived;

  @JsonKey(name: 'total_expense', fromJson: _toDoubleNull)
  final double? totalExpense;

  @JsonKey(name: 'profit', fromJson: _toDoubleNull)
  final double? profit;

  @JsonKey(name: 'loss', fromJson: _toDoubleNull)
  final double? loss;

  @JsonKey(name: 'net_result', fromJson: _toDoubleNull)
  final double? netResult;

  // ── Vehicle fields ──────────────────────────────────────────
  // ✅ FIX: int? — API returns {vehicleId: 1} not "1"
  @JsonKey(name: 'vehicleId')
  final int? vehicleId;

  @JsonKey(name: 'vehicle_number')
  final String? vehicleNumber;

  // ── Driver fields ───────────────────────────────────────────
  // ✅ FIX: int? — API returns {driverId: 1} not "1"
  @JsonKey(name: 'driverId')
  final int? driverId;

  @JsonKey(name: 'driver_phone')
  final String? driverPhone;

  // ── Customer fields ─────────────────────────────────────────
  // ✅ FIX: int? — API returns {CustomerId: 1} not "1"
  @JsonKey(name: 'CustomerId')
  final int? customerId;

  @JsonKey(name: 'customer_phone')
  final String? customerPhone;

  // ── Aggregated fields ───────────────────────────────────────
  @JsonKey(name: 'total_trips')
  final int? totalTrips;

  @JsonKey(name: 'total_income', fromJson: _toDoubleNull)
  final double? totalIncome;

  @JsonKey(name: 'total_profit', fromJson: _toDoubleNull)
  final double? totalProfit;

  @JsonKey(name: 'total_loss', fromJson: _toDoubleNull)
  final double? totalLoss;

  @JsonKey(name: 'net_revenue', fromJson: _toDoubleNull)
  final double? netRevenue;

  const ReportData({
    this.bookingDate,
    this.tripId,
    this.customerName,
    this.driverName,
    this.vehicleName,
    this.pickupLocation,
    this.dropLocation,
    this.amountReceived,
    this.totalExpense,
    this.profit,
    this.loss,
    this.netResult,
    this.vehicleId,
    this.vehicleNumber,
    this.driverId,
    this.driverPhone,
    this.customerId,
    this.customerPhone,
    this.totalTrips,
    this.totalIncome,
    this.totalProfit,
    this.totalLoss,
    this.netRevenue,
  });

  factory ReportData.fromJson(Map<String, dynamic> json) =>
      _$ReportDataFromJson(json);

  Map<String, dynamic> toJson() => _$ReportDataToJson(this);

  // ── Safe date (fallback to now if null) ─────────────────────
  DateTime get safeDate => bookingDate ?? DateTime.now();

  // ── Computed getters ────────────────────────────────────────
  double get income    => amountReceived ?? totalIncome ?? 0.0;
  double get expense   => totalExpense   ?? 0.0;
  double get net       => netResult      ?? netRevenue  ?? 0.0;
  double get profitVal => profit         ?? totalProfit ?? 0.0;
  double get lossVal   => loss           ?? totalLoss   ?? 0.0;
  int    get tripsCount => totalTrips    ?? 1;
}

// ── Parse helpers ───────────────────────────────────────────────
double? _toDoubleNull(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

DateTime? _toDateTimeNull(dynamic v) {
  if (v == null) return null;
  if (v is String) return DateTime.tryParse(v);
  return null;
}