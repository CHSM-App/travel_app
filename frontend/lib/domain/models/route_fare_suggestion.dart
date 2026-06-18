import 'package:vego/domain/models/booking_info.dart';

/// Derived from a customer's past trips: what we charged this customer the
/// last time they travelled the same Pickup → Drop route, plus the average
/// and how many times that route was billed. Used to auto-suggest the Trip
/// Charges field so the operator doesn't re-key a fare they've quoted before.
class RouteFareSuggestion {
  final double lastCharge;
  final double averageCharge;
  final int tripCount;
  final DateTime? lastTripDate;

  const RouteFareSuggestion({
    required this.lastCharge,
    required this.averageCharge,
    required this.tripCount,
    this.lastTripDate,
  });

  /// Pickup/drop are free-text in the DB, so normalize before matching:
  /// trim, lowercase, and collapse repeated whitespace. "Mumbai ",
  /// "mumbai" and "Mumbai" all resolve to the same route key.
  static String _norm(String? s) =>
      (s ?? '').trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  /// Builds a suggestion from a customer's trip history for the given route.
  /// Returns null when the route is incomplete or there's no prior billed trip
  /// on it. When [vehicleId] is provided, only trips made with that vehicle are
  /// considered, so the suggested fare reflects the selected vehicle.
  static RouteFareSuggestion? fromHistory(
    List<BookingInfo> history, {
    required String pickup,
    required String drop,
    int? vehicleId,
  }) {
    final p = _norm(pickup);
    final d = _norm(drop);
    if (p.isEmpty || d.isEmpty) return null;

    final matches = history.where((t) {
      final amount = t.amountApprove ?? 0;
      return amount > 0 &&
          (vehicleId == null || t.vehicleId == vehicleId) &&
          _norm(t.pickupLocation) == p &&
          _norm(t.dropLocation) == d;
    }).toList();

    if (matches.isEmpty) return null;

    DateTime? keyOf(BookingInfo t) => t.bookingDate ?? t.startDateTime;

    // Most recent trip first so [lastCharge] is the latest quoted fare.
    matches.sort((a, b) {
      final da = keyOf(a);
      final db = keyOf(b);
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return db.compareTo(da);
    });

    final last = matches.first;
    final total =
        matches.fold<double>(0, (sum, t) => sum + (t.amountApprove ?? 0));

    return RouteFareSuggestion(
      lastCharge: last.amountApprove ?? 0,
      averageCharge: total / matches.length,
      tripCount: matches.length,
      lastTripDate: keyOf(last),
    );
  }
}
