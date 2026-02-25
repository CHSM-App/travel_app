import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_agency_app/Screens/add_tripbooking.dart';
import 'package:travel_agency_app/domain/models/booking_info.dart';
import 'package:travel_agency_app/presentation/providers/viewmodel_provider.dart';

class TripCard extends StatelessWidget {
  final BookingInfo bookinginfo;
  final WidgetRef ref;
  final String tripType; // 'active', 'upcoming', 'Paid', 'unpaid', 'cancelled'

  const TripCard({
    super.key,
    required this.bookinginfo,
    required this.ref,
    required this.tripType,
  });

  // ── Palette (matches CustomerHist light theme) ─────────────────────
  static const Color _accent = Color(0xFF3D5AFE);
  static const Color _accentSoft = Color(0xFFEEF1FF);
  static const Color _textPrimary = Color(0xFF1A1D2E);
  static const Color _textSec = Color(0xFF7B82A0);
  static const Color _divider = Color(0xFFE4E8F0);
  static const Color _success = Color(0xFF2DB976);
  static const Color _successSoft = Color(0xFFE8F8F1);
  static const Color _warning = Color(0xFFE67E22);
  static const Color _warningSoft = Color(0xFFFEF0E6);
  static const Color _danger = Color(0xFFE53935);
  static const Color _dangerSoft = Color(0xFFFFEBEE);

  String _formatDate(DateTime? date) {
    if (date == null) return '--';
    return "${date.day}/${date.month}/${date.year}";
  }

  String _formatTime(DateTime? date) {
    if (date == null) return '--';
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return "$hour:$minute $period";
  }

  String get paymentStatus {
    final approved = bookinginfo.amountApprove ?? 0;
    final received = bookinginfo.amountReceived ?? 0;
    if (received == 0) return "Unpaid";
    if (received < approved) return "Partial";
    return "Paid";
  }

  Color _paymentColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return _success;
      case 'unpaid':
        return _danger;
      case 'partial':
        return _warning;
      default:
        return _textSec;
    }
  }

  Color _paymentBg(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return _successSoft;
      case 'unpaid':
        return _dangerSoft;
      case 'partial':
        return _warningSoft;
      default:
        return _accentSoft;
    }
  }

  IconData _paymentIcon(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Icons.check_circle_rounded;
      case 'unpaid':
        return Icons.cancel_rounded;
      case 'partial':
        return Icons.timelapse_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  String get tripPaymentStatus {
    final approved = bookinginfo.amountApprove ?? 0;
    final received = bookinginfo.amountReceived ?? 0;
    if (received == 0) return "Unpaid";
    if (received < approved) return "Partial";
    return "Paid";
  }

  void _showTripDetail(BuildContext context) {

    final bool isEditable = paymentStatus.toLowerCase() == "unpaid" && bookinginfo.status == 2;

    // Use tripType passed from the tab — same logic as active tab, no API status guessing
    final bool isActiveOrUpcoming =
        tripType == 'active' || tripType == 'upcoming';

    final tollController = TextEditingController(
      text: bookinginfo.tollCharges?.toString() ?? "",
    );
    final repairController = TextEditingController(
      text: bookinginfo.repairingCharges?.toString() ?? "",
    );
    final driverController = TextEditingController(
      text: bookinginfo.driverCharges?.toString() ?? "",
    );
    final receivedController = TextEditingController(
      text: bookinginfo.amountReceived?.toString() ?? "",
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (ctx) {
        final screenWidth = MediaQuery.of(ctx).size.width;
        final screenHeight = MediaQuery.of(ctx).size.height;
        final isSmall = screenWidth < 400;
        final isLarge = screenWidth > 600;

        final sheetMaxWidth = isLarge ? 580.0 : double.infinity;

        final hPad = isSmall ? 14.0 : (isLarge ? 24.0 : 18.0);
        final cardRadius = isSmall ? 14.0 : 18.0;
        final headerFontSize = isSmall ? 15.0 : 17.0;
        final labelFontSize = isSmall ? 11.0 : 12.0;
        final valueFontSize = isSmall ? 12.0 : 12.5;
        final iconSize = isSmall ? 13.0 : 14.0;
        final labelWidth = isSmall ? 60.0 : 68.0;
        final sectionGap = isSmall ? 10.0 : 14.0;
        final fieldVertPad = isSmall ? 11.0 : 13.0;

        Widget infoBlock({
          required String label,
          required IconData icon,
          required Color color,
          required List<Widget> rows,
        }) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(cardRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.fromLTRB(
                    14,
                    isSmall ? 10 : 12,
                    14,
                    isSmall ? 8 : 10,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.07),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(cardRadius),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(icon, size: isSmall ? 13 : 15, color: color),
                      const SizedBox(width: 7),
                      Text(
                        label,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w700,
                          fontSize: labelFontSize,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(14, 4, 14, isSmall ? 10 : 12),
                  child: Column(children: rows),
                ),
              ],
            ),
          );
        }

        Widget detailRow(String lbl, String val, IconData icon, Color color) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: isSmall ? 6 : 7),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: iconSize, color: color.withOpacity(0.55)),
                const SizedBox(width: 7),
                SizedBox(
                  width: labelWidth,
                  child: Text(
                    lbl,
                    style: TextStyle(
                      fontSize: isSmall ? 10.5 : 11.5,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    val,
                    style: TextStyle(
                      fontSize: valueFontSize,
                      color: const Color(0xFF1A1A2E),
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }

        Widget rowDivider() => Divider(height: 1, color: Colors.grey.shade100);

        Widget amountField(
          TextEditingController ctrl,
          String label,
          IconData icon, {
          bool highlight = false,
        }) {
          final color = highlight
              ? const Color(0xFF4361EE)
              : const Color(0xFF6B7280);
          return TextField(
            controller: ctrl,
            readOnly: !isEditable,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: isSmall ? 13 : 14,
              color: !isEditable
                  ? Colors.grey.shade600
                  : const Color(0xFF1A1A2E),
            ),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(
                fontSize: isSmall ? 11.5 : 12.5,
                color: color,
              ),
              prefixIcon: Icon(icon, size: isSmall ? 15 : 17, color: color),
              prefixText: "₹ ",
              prefixStyle: TextStyle(fontWeight: FontWeight.w700, color: color),
              filled: true,
              fillColor: !isEditable
                  ? Colors.grey.shade50
                  : highlight
                  ? const Color(0xFF4361EE).withOpacity(0.04)
                  : Colors.grey.shade50,
              contentPadding: EdgeInsets.symmetric(
                vertical: fieldVertPad,
                horizontal: 14,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: !isEditable
                      ? Colors.grey.shade200
                      : highlight
                      ? const Color(0xFF4361EE).withOpacity(0.3)
                      : Colors.grey.shade200,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF4361EE),
                  width: 1.5,
                ),
              ),
            ),
          );
        }

        Widget customerDriverRow() {
          if (isSmall) {
            return Column(
              children: [
                infoBlock(
                  label: "CUSTOMER",
                  icon: Icons.person_outline_rounded,
                  color: const Color(0xFF7209B7),
                  rows: [
                    detailRow(
                      "Name",
                      bookinginfo.customer_name ?? "--",
                      Icons.badge_outlined,
                      const Color(0xFF7209B7),
                    ),
                    rowDivider(),
                    detailRow(
                      "Phone",
                      bookinginfo.customer_phone ?? "--",
                      Icons.phone_outlined,
                      const Color(0xFF7209B7),
                    ),
                    detailRow(
                      "Address",
                      bookinginfo.customerAddress ?? "--",
                      Icons.home,
                      const Color(0xFF7209B7),
                    ),
                  ],
                ),
                SizedBox(height: sectionGap),
                infoBlock(
                  label: "DRIVER",
                  icon: Icons.drive_eta_outlined,
                  color: const Color(0xFF3A86FF),
                  rows: [
                    detailRow(
                      "Name",
                      bookinginfo.driver_name ?? "--",
                      Icons.badge_outlined,
                      const Color(0xFF3A86FF),
                    ),
                    rowDivider(),
                    detailRow(
                      "Phone",
                      bookinginfo.driverPhone ?? "--",
                      Icons.phone_outlined,
                      const Color(0xFF3A86FF),
                    ),
                    rowDivider(),
                    detailRow(
                      "Licence",
                      bookinginfo.driverLicenceNo ?? "--",
                      Icons.credit_card_outlined,
                      const Color(0xFF3A86FF),
                    ),
                  ],
                ),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: infoBlock(
                  label: "CUSTOMER",
                  icon: Icons.person_outline_rounded,
                  color: const Color(0xFF7209B7),
                  rows: [
                    detailRow(
                      "Name",
                      bookinginfo.customer_name ?? "--",
                      Icons.badge_outlined,
                      const Color(0xFF7209B7),
                    ),
                    rowDivider(),
                    detailRow(
                      "Phone",
                      bookinginfo.customer_phone ?? "--",
                      Icons.phone_outlined,
                      const Color(0xFF7209B7),
                    ),
                    detailRow(
                      "Address",
                      bookinginfo.customerAddress ?? "--",
                      Icons.home,
                      const Color(0xFF7209B7),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: infoBlock(
                  label: "DRIVER",
                  icon: Icons.drive_eta_outlined,
                  color: const Color(0xFF3A86FF),
                  rows: [
                    detailRow(
                      "Name",
                      bookinginfo.driver_name ?? "--",
                      Icons.badge_outlined,
                      const Color(0xFF3A86FF),
                    ),
                    rowDivider(),
                    detailRow(
                      "Phone",
                      bookinginfo.driverPhone ?? "--",
                      Icons.phone_outlined,
                      const Color(0xFF3A86FF),
                    ),
                    rowDivider(),
                    detailRow(
                      "Licence",
                      bookinginfo.driverLicenceNo ?? "--",
                      Icons.credit_card_outlined,
                      const Color(0xFF3A86FF),
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        Widget paymentFields() {
          if (isLarge) {
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: amountField(
                        tollController,
                        "Toll Charges",
                        Icons.toll,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: amountField(
                        repairController,
                        "Repair Charges",
                        Icons.build_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: amountField(
                        driverController,
                        "Driver Charges",
                        Icons.payments_outlined,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: amountField(
                        receivedController,
                        "Amount Received",
                        Icons.account_balance_wallet_outlined,
                        highlight: true,
                      ),
                    ),
                  ],
                ),
              ],
            );
          }

          return Column(
            children: [
              amountField(tollController, "Toll Charges", Icons.toll),
              const SizedBox(height: 10),
              amountField(
                repairController,
                "Repair Charges",
                Icons.build_outlined,
              ),
              const SizedBox(height: 10),
              amountField(
                driverController,
                "Driver Charges",
                Icons.payments_outlined,
              ),
              const SizedBox(height: 10),
              amountField(
                receivedController,
                "Amount Received",
                Icons.account_balance_wallet_outlined,
                highlight: true,
              ),
            ],
          );
        }

        final initialSize = screenHeight < 700 ? 0.97 : 0.92;

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: sheetMaxWidth),
            child: DraggableScrollableSheet(
              initialChildSize: initialSize,
              minChildSize: 0.4,
              maxChildSize: 0.97,
              builder: (_, scrollCtrl) => Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF7F8FC),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  children: [
                    // ── Drag handle ──────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.only(top: 12, bottom: 4),
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // ── HEADER ────────────────────────────────────────────────
                    Container(
                      margin: EdgeInsets.fromLTRB(hPad, 6, hPad, 4),
                      padding: EdgeInsets.all(isSmall ? 14 : 18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4361EE), Color(0xFF3A0CA3)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4361EE).withOpacity(0.32),
                            blurRadius: 18,
                            offset: const Offset(0, 7),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: isSmall ? 38 : 44,
                            height: isSmall ? 38 : 44,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.directions_car_filled,
                              color: Colors.white,
                              size: isSmall ? 18 : 22,
                            ),
                          ),
                          SizedBox(width: isSmall ? 10 : 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Trip Details",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: headerFontSize,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // ── Status pill: hidden for active/upcoming unpaid ──
                          if (!isActiveOrUpcoming) ...[
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isSmall ? 8 : 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: isEditable
                                    ? const Color(0xFFFFBE0B).withOpacity(0.18)
                                    : Colors.green.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isEditable
                                      ? const Color(0xFFFFBE0B).withOpacity(0.55)
                                      : Colors.greenAccent.withOpacity(0.55),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isEditable
                                        ? Icons.schedule
                                        : Icons.check_circle,
                                    size: 11,
                                    color: isEditable
                                        ? const Color(0xFFFFBE0B)
                                        : Colors.greenAccent,
                                  ),
                                  if (!isSmall) ...[
                                    const SizedBox(width: 4),
                                    Text(
                                      isEditable ? "Unpaid" : "Paid",
                                      style: TextStyle(
                                        color: isEditable
                                            ? const Color(0xFFFFBE0B)
                                            : Colors.greenAccent,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],

                          // ✏️ Edit Button
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(ctx);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TripBookingForm(),
                                ),
                              );
                            },
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.edit,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),

                          const SizedBox(width: 6),

                          // ❌ Close Button
                          GestureDetector(
                            onTap: () => Navigator.pop(ctx),
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── SCROLLABLE BODY ────────────────────────────────────────
                    Expanded(
                      child: ListView(
                        controller: scrollCtrl,
                        padding: EdgeInsets.fromLTRB(
                          hPad,
                          14,
                          hPad,
                          32 + MediaQuery.of(ctx).padding.bottom,
                        ),
                        children: [
                          // ── Trip Info ──────────────────────────────────────
                          infoBlock(
                            label: "TRIP INFO",
                            icon: Icons.route_rounded,
                            color: const Color(0xFF4361EE),
                            rows: [
                              detailRow(
                                "Pickup",
                                bookinginfo.pickupLocation ?? "--",
                                Icons.trip_origin,
                                const Color(0xFF4361EE),
                              ),
                              rowDivider(),
                              detailRow(
                                "Drop",
                                bookinginfo.dropLocation ?? "--",
                                Icons.location_on,
                                const Color(0xFF4361EE),
                              ),
                              rowDivider(),
                              detailRow(
                                "Start",
                                "${_formatDate(bookinginfo.startDateTime)}  ${_formatTime(bookinginfo.startDateTime)}",
                                Icons.calendar_today_outlined,
                                const Color(0xFF4361EE),
                              ),
                              rowDivider(),
                              detailRow(
                                "End",
                                "${_formatDate(bookinginfo.endDateTime)}  ${_formatTime(bookinginfo.endDateTime)}",
                                Icons.calendar_today_outlined,
                                const Color(0xFF4361EE),
                              ),
                              rowDivider(),
                              detailRow(
                                "Distance",
                                "${bookinginfo.distance?.toString() ?? "--"} km",
                                Icons.straighten,
                                const Color(0xFF4361EE),
                              ),
                            ],
                          ),

                          SizedBox(height: sectionGap),

                          // ── Customer + Driver ──────────────────────────────
                          customerDriverRow(),

                          SizedBox(height: sectionGap),

                          // ── Vehicle Info ───────────────────────────────────
                          infoBlock(
                            label: "VEHICLE",
                            icon: Icons.directions_car_outlined,
                            color: const Color(0xFF06D6A0),
                            rows: [
                              detailRow(
                                "Vehicle",
                                bookinginfo.vehicle_info ?? "--",
                                Icons.local_shipping_outlined,
                                const Color(0xFF06D6A0),
                              ),
                              rowDivider(),
                              detailRow(
                                "Capacity",
                                bookinginfo.capacity?.toString() ?? "--",
                                Icons.group_outlined,
                                const Color(0xFF06D6A0),
                              ),
                              rowDivider(),
                              detailRow(
                                "Fuel",
                                bookinginfo.fuelType ?? "--",
                                Icons.local_gas_station_outlined,
                                const Color(0xFF06D6A0),
                              ),
                              rowDivider(),
                              detailRow(
                                "Mileage",
                                bookinginfo.mileage ?? "--",
                                Icons.speed_outlined,
                                const Color(0xFF06D6A0),
                              ),
                            ],
                          ),

                          SizedBox(height: sectionGap),

                          // ── Payment & Charges ──────────────────────────────
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(cardRadius),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: EdgeInsets.fromLTRB(
                                    14,
                                    isSmall ? 10 : 12,
                                    14,
                                    isSmall ? 8 : 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF0F3),
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(cardRadius),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.account_balance_wallet_outlined,
                                        size: 14,
                                        color: Color(0xFFE63946),
                                      ),
                                      const SizedBox(width: 7),
                                      Text(
                                        "PAYMENT & CHARGES",
                                        style: TextStyle(
                                          color: const Color(0xFFE63946),
                                          fontWeight: FontWeight.w700,
                                          fontSize: labelFontSize,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.all(isSmall ? 12 : 16),
                                  child: Column(
                                    children: [
                                      // Approved amount highlight — always shown
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: isSmall ? 12 : 16,
                                          vertical: isSmall ? 12 : 14,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFFD8F3DC),
                                              Color(0xFFB7E4C7),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.verified_rounded,
                                              color: const Color(0xFF2D6A4F),
                                              size: isSmall ? 17 : 20,
                                            ),
                                            SizedBox(width: isSmall ? 8 : 10),
                                            Expanded(
                                              child: Text(
                                                "Approved Amount",
                                                style: TextStyle(
                                                  color: const Color(0xFF2D6A4F),
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: isSmall ? 12 : 13,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              "₹${bookinginfo.amountApprove ?? 0}",
                                              style: TextStyle(
                                                color: const Color(0xFF1B4332),
                                                fontWeight: FontWeight.w800,
                                                fontSize: isSmall ? 15 : 18,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // ── Input fields: hidden for active/upcoming unpaid ──
                                      if (!isActiveOrUpcoming) ...[
                                        SizedBox(height: isSmall ? 10 : 12),
                                        paymentFields(),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // ── Submit / Done: hidden for active/upcoming unpaid ──
                          if (!isActiveOrUpcoming) ...[
                            const SizedBox(height: 24),
                            if (isEditable)
                              GestureDetector(
                                onTap: () async {
                                  final updated = BookingInfo(
                                    tripId: bookinginfo.tripId,
                                    tollCharges:
                                        double.tryParse(tollController.text) ?? 0,
                                    repairingCharges:
                                        double.tryParse(repairController.text) ?? 0,
                                    driverCharges:
                                        double.tryParse(driverController.text) ?? 0,
                                    amountReceived:
                                        double.tryParse(receivedController.text) ?? 0,
                                  );
                                  await ref
                                      .read(TripPageViewModelProvider.notifier)
                                      .updatePaymentStatus(updated);
                                  Navigator.pop(ctx);

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        "Payment details updated successfully!",
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                },
                                child: Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.symmetric(
                                    vertical: isSmall ? 14 : 16,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF4361EE),
                                        Color(0xFF3A0CA3),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF4361EE).withOpacity(0.4),
                                        blurRadius: 14,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.check_circle_outline,
                                        color: Colors.white,
                                        size: isSmall ? 18 : 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        "Submit Payment",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: isSmall ? 14 : 15,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              Center(
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isSmall ? 18 : 24,
                                    vertical: isSmall ? 10 : 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(
                                      color: Colors.green.shade200,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.verified_rounded,
                                        color: Colors.green.shade600,
                                        size: isSmall ? 15 : 18,
                                      ),
                                      SizedBox(width: isSmall ? 6 : 8),
                                      Text(
                                        "Payment Already done",
                                        style: TextStyle(
                                          color: Colors.green.shade700,
                                          fontWeight: FontWeight.w600,
                                          fontSize: isSmall ? 12 : 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // BUILD — Compact Attractive Card
  @override
  Widget build(BuildContext context) {
    final status = bookinginfo.payment_status ?? paymentStatus;
    final statusColor = _paymentColor(status);
    final statusBg = _paymentBg(status);
    final statusIcon = _paymentIcon(status);
    final screenW = MediaQuery.of(context).size.width;
    final isSmall = screenW < 360;

    return GestureDetector(
      onTap: () {
        _showTripDetail(context);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _divider, width: 1),
          boxShadow: [
            BoxShadow(
              color: _accent.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── ROW 1: Vehicle · Route · Amount ───────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: _accent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.directions_car_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        bookinginfo.vehicle_info ?? 'Vehicle N/A',
                        style: TextStyle(
                          fontSize: isSmall ? 12 : 13,
                          fontWeight: FontWeight.w800,
                          color: _textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 9, color: _accent),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              bookinginfo.pickupLocation ?? '--',
                              style: TextStyle(
                                fontSize: isSmall ? 10 : 11,
                                color: _textSec,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              size: 9,
                              color: _textSec,
                            ),
                          ),
                          Flexible(
                            child: Text(
                              bookinginfo.dropLocation ?? '--',
                              style: TextStyle(
                                fontSize: isSmall ? 10 : 11,
                                color: _textSec,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                Text(
                  "₹${bookinginfo.amountApprove ?? 0}",
                  style: TextStyle(
                    fontSize: isSmall ? 13 : 14,
                    fontWeight: FontWeight.w900,
                    color: _success,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 7),

            Divider(height: 1, color: _divider),

            const SizedBox(height: 7),

            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // const SizedBox(width: 38),

                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.person_rounded, size: 12, color: _accent),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          bookinginfo.customer_name ?? '--',
                          style: TextStyle(
                            fontSize: isSmall ? 10 : 11,
                            fontWeight: FontWeight.w600,
                            color: _textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Container(
                          width: 3,
                          height: 3,
                          decoration: BoxDecoration(
                            color: _divider,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),

                      Icon(
                        Icons.calendar_today_rounded,
                        size: 11,
                        color: _warning,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          "${_formatDate(bookinginfo.startDateTime)} ${_formatTime(bookinginfo.startDateTime)}",
                          style: TextStyle(
                            fontSize: isSmall ? 10 : 11,
                            color: _textSec,
                            fontWeight: FontWeight.w500,
                          ),
                          softWrap: true,
                          maxLines: 2, // allow 2 lines
                          overflow: TextOverflow.visible,
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 10, color: statusColor),
                      const SizedBox(width: 3),
                      Text(
                        status,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ],
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