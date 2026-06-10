/// One dated financial event for a vehicle, as returned by the
/// `GET users/VehicleReport/{agency_id}` endpoint (the `vw_vehicle_report_ledger`
/// SQL view). The whole agency is fetched once and filtered in the UI — by
/// [entryDate] for the period chips, and by [vehicleId] when a single vehicle's
/// detail is opened.
///
/// Exactly one money field is non-zero per row, decided by [entryType]:
///  - NEW_BOOKING      → [bookingAmount]  (quoted fare, dated by booking_date)
///  - PAYMENT_RECEIVED → [revenue]        (one installment, dated by payment_date)
///  - TRIP_EXPENSE     → [tripExpense]    (toll+repair+driver+fuel, dated by trip date)
///  - MAINTENANCE      → [maintenance]    (one service, dated by service_date)
class LedgerEntry {
  final int? vehicleId;
  final String? vehicleName;
  final String? vehicleNumber;
  final String? agencyId;
  final String? entryType;
  final DateTime? entryDate;
  final int? tripId;
  final double? bookingAmount;
  final double? revenue;
  final double? tripExpense;
  final double? maintenance;

  const LedgerEntry({
    this.vehicleId,
    this.vehicleName,
    this.vehicleNumber,
    this.agencyId,
    this.entryType,
    this.entryDate,
    this.tripId,
    this.bookingAmount,
    this.revenue,
    this.tripExpense,
    this.maintenance,
  });

  bool get isBooking => entryType == 'NEW_BOOKING';
  bool get isPayment => entryType == 'PAYMENT_RECEIVED';
  bool get isTripExpense => entryType == 'TRIP_EXPENSE';
  bool get isMaintenance => entryType == 'MAINTENANCE';

  factory LedgerEntry.fromJson(Map<String, dynamic> json) => LedgerEntry(
        vehicleId: _toInt(json['vehicle_id']),
        vehicleName: _toStr(json['vehicle_name']),
        vehicleNumber: _toStr(json['vehicle_number']),
        agencyId: _toStr(json['agency_id']),
        entryType: _toStr(json['entry_type']),
        entryDate: _toDate(json['entry_date']),
        tripId: _toInt(json['trip_id']),
        bookingAmount: _toDouble(json['booking_amount']),
        revenue: _toDouble(json['revenue']),
        tripExpense: _toDouble(json['trip_expense']),
        maintenance: _toDouble(json['maintenance']),
      );

  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  static String? _toStr(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    if (s.isEmpty || s.toLowerCase() == 'null') return null;
    return s;
  }

  static DateTime? _toDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    final s = v.toString().trim();
    if (s.isEmpty || s.toLowerCase() == 'null') return null;
    return DateTime.tryParse(s);
  }
}
