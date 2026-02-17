
import 'package:flutter/material.dart';
import 'package:travel_agency_app/domain/models/booking_info.dart';

class TripCard extends StatelessWidget {
  final BookingInfo bookinginfo;

  const TripCard({
    super.key,
    required this.bookinginfo,
  });

  String _formatDate(DateTime? date) {
    if (date == null) return '--';
    return "${date.day}/${date.month}/${date.year}";
  }

@override
Widget build(BuildContext context) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [
          Color(0xFF2196F3),
          Color(0xFF00BCD4),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(22),
      boxShadow: [
        BoxShadow(
          color: Colors.blueAccent.withOpacity(0.35),
          blurRadius: 15,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(22),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// 🚗 Vehicle + Amount
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  bookinginfo.vehicle_info?.isNotEmpty == true
                      ? bookinginfo.vehicle_info!
                      : 'Vehicle not available',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D47A1),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF00C853),
                      Color(0xFF00E676),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  "₹${bookinginfo.amountApprove ?? 0}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          /// 💳 PAYMENT STATUS (NEW SECTION)
          Row(
            children: [
              const Icon(Icons.payment, color: Color(0xFF7B1FA2), size: 20),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: (bookinginfo.payment_status == "PAID")
                      ? Colors.green.shade100
                      : Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  bookinginfo.payment_status ?? "UNPAID",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: (bookinginfo.payment_status == "PAID")
                        ? Colors.green.shade800
                        : Colors.orange.shade800,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          /// 👤 Driver
          Row(
            children: [
              const Icon(Icons.person,
                  size: 20, color: Color(0xFF00ACC1)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  bookinginfo.driver_name ?? 'Not assigned',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(thickness: 1.2),

          /// 📍 Locations
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on,
                  size: 20, color: Color(0xFF0288D1)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  bookinginfo.pickupLocation ?? 'Pickup not available',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              const Icon(Icons.arrow_forward,
                  color: Color(0xFF00BCD4)),
              Expanded(
                child: Text(
                  bookinginfo.dropLocation ?? 'Drop not available',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          /// 📅 Dates
          Row(
            children: [
              const Icon(Icons.date_range,
                  size: 20, color: Color(0xFF1565C0)),
              const SizedBox(width: 8),
              Text(
                "${_formatDate(bookinginfo.startDateTime)} → "
                "${_formatDate(bookinginfo.endDateTime)}",
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
}