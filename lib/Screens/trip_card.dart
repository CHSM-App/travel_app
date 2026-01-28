
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
    return Card(
      elevation: 6,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Vehicle + Amount
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    bookinginfo.vehicle_info?.isNotEmpty == true
                        ? bookinginfo.vehicle_info!
                        : 'Vehicle not available',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  "₹${bookinginfo.amountApprove ?? 0}",
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Driver
            Text(
              "Driver: ${bookinginfo.driver_name ?? 'Not assigned'}",
            ),

            const Divider(),

            // Locations
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on, size: 16),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    bookinginfo.pickupLocation ?? 'Pickup not available',
                  ),
                ),
                const Icon(Icons.arrow_right_alt),
                Expanded(
                  child: Text(
                    bookinginfo.dropLocation ?? 'Drop not available',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Dates
            Row(
              children: [
                const Icon(Icons.date_range, size: 16),
                const SizedBox(width: 4),
                Text(
                  "${_formatDate(bookinginfo.startDateTime)} → "
                  "${_formatDate(bookinginfo.endDateTime)}",
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
