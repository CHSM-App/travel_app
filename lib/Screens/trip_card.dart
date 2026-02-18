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



void _showTripDetails(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(
              maxHeight: 650,
              maxWidth: 500,
            ),
            child: Column(
              children: [
                // Modern Header with Gradient
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.indigo.shade700,
                        Colors.indigo.shade500,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.info_outline_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          "Trip Details",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                // Scrollable Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Vehicle Section
                        _sectionHeader("Vehicle Information", Icons.directions_car_rounded),
                        const SizedBox(height: 12),
                        _modernCard([
                          _detailRow("Vehicle", bookinginfo.vehicle_info ?? "--", Icons.local_shipping_rounded),
                          _detailRow("Capacity", bookinginfo.capacity?.toString() ?? "--", Icons.people_rounded),
                          _detailRow("Fuel Type", bookinginfo.fuelType ?? "--", Icons.local_gas_station_rounded),
                          _detailRow("Mileage", bookinginfo.mileage ?? "--", Icons.speed_rounded),
                        ]),

                        const SizedBox(height: 20),

                        // Driver Section
                        _sectionHeader("Driver Information", Icons.person_rounded),
                        const SizedBox(height: 12),
                        _modernCard([
                          _detailRow("Driver Name", bookinginfo.driver_name ?? "--", Icons.badge_rounded),
                          _detailRow("Phone", bookinginfo.driverPhone ?? "--", Icons.phone_rounded),
                          _detailRow("Licence No", bookinginfo.driverLicenceNo ?? "--", Icons.credit_card_rounded),
                        ]),

                        const SizedBox(height: 20),

                        // Trip Section
                        _sectionHeader("Trip Information", Icons.route_rounded),
                        const SizedBox(height: 12),
                        _modernCard([
                          _detailRow("Pickup", bookinginfo.pickupLocation ?? "--", Icons.location_on_rounded),
                          _detailRow("Drop", bookinginfo.dropLocation ?? "--", Icons.flag_rounded),
                          _detailRow("Start Date", _formatDate(bookinginfo.startDateTime), Icons.calendar_today_rounded),
                          _detailRow("End Date", _formatDate(bookinginfo.endDateTime), Icons.event_rounded),
                          _detailRow("Distance", bookinginfo.distance?.toString() ?? "--", Icons.straighten_rounded),
                        ]),

                        const SizedBox(height: 20),

                        // Charges Section
                        _sectionHeader("Charges & Expenses", Icons.attach_money_rounded),
                        const SizedBox(height: 12),
                        _modernCard([
                          _detailRow("Fuel Required", bookinginfo.fuelRequired?.toString() ?? "--", Icons.local_gas_station_rounded),
                          _detailRow("Toll Charges", bookinginfo.tollCharges?.toString() ?? "--", Icons.toll_rounded),
                          _detailRow("Repairing", bookinginfo.repairingCharges?.toString() ?? "--", Icons.build_rounded),
                          _detailRow("Driver Charges", bookinginfo.driverCharges?.toString() ?? "--", Icons.payments_rounded),
                        ]),

                        const SizedBox(height: 20),

                        // Customer Section
                        _sectionHeader("Customer Information", Icons.account_circle_rounded),
                        const SizedBox(height: 12),
                        _modernCard([
                          _detailRow("Customer Name", bookinginfo.customer_name ?? "--", Icons.person_outline_rounded),
                          _detailRow("Phone", bookinginfo.customer_phone ?? "--", Icons.phone_rounded),
                        ]),

                        const SizedBox(height: 20),

                        // Payment Section
                        _sectionHeader("Payment Status", Icons.account_balance_wallet_rounded),
                        const SizedBox(height: 12),
                        _modernCard([
                          _detailRow("Trip Status", bookinginfo.tripStatus ?? "--", Icons.info_rounded, 
                            valueColor: _getStatusColor(bookinginfo.tripStatus)),
                          _detailRow("Amount Approved", "₹${bookinginfo.amountApprove?.toString() ?? "0"}", Icons.check_circle_rounded,
                            valueColor: Colors.green.shade700),
                          _detailRow("Amount Received", "₹${bookinginfo.amountReceived?.toString() ?? "0"}", Icons.account_balance_rounded,
                            valueColor: Colors.blue.shade700),
                        ]),

                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.indigo.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 18,
            color: Colors.indigo.shade700,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.indigo.shade700,
          ),
        ),
      ],
    );
  }

  Widget _modernCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

 
  Widget _detailRow(String label, String value, IconData icon, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: Colors.grey.shade600,
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: valueColor ?? Colors.black87,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    if (status == null) return Colors.grey;
    
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green.shade700;
      case 'completed':
        return Colors.blue.shade700;
      case 'cancelled':
        return Colors.red.shade700;
      case 'upcoming':
        return Colors.orange.shade700;
      case 'unpaid':
        return Colors.amber.shade800;
      default:
        return Colors.grey.shade700;
    }
  }

 

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showTripDetails(context),

      child: Card(
        elevation: 6,
        color: Colors.white,
        margin: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              /// Top Summary
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      bookinginfo.vehicle_info ?? 'Vehicle not available',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  Text(
                    "₹${bookinginfo.amountApprove ?? 0}",
                    style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),

              const Divider(),

              Row(
                children: [
                  const Icon(Icons.location_on, size: 16),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      "${bookinginfo.pickupLocation} → ${bookinginfo.dropLocation}",
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),
                Row(
                children: [
                  const Icon(Icons.people_outlined, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    "${(bookinginfo.customer_name)}",
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.date_range, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    "${_formatDate(bookinginfo.startDateTime)} → ${_formatDate(bookinginfo.endDateTime)}",
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
