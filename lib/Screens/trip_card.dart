import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_agency_app/Screens/add_tripbooking.dart';
import 'package:travel_agency_app/core/theme/app_colors.dart';
import 'package:travel_agency_app/domain/models/booking_info.dart';
import 'package:travel_agency_app/presentation/providers/viewmodel_provider.dart';

class TripCard extends ConsumerWidget {
  final BookingInfo bookinginfo;
  final int status; // 'active', 'upcoming', 'Paid', 'unpaid', 'cancelled'
  final Future<void> Function()? onTripUpdated;

  const TripCard({
    super.key,
    required this.bookinginfo,
    required this.status,
    this.onTripUpdated,
  });

  // ── Palette (matches CustomerHist light theme) ─────────────────────
  static const Color _accent = AppColors.brandPrimary;
  static const Color _accentSoft = AppColors.brandSoft;
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
    final minute = date.minute.toString().padLeft(2,'0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return "$hour:$minute $period";
  }

  // "31 May, 9:14 AM" — compact day + short month + time, as in the card design.
  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  String _prettyDateTime(DateTime? date) {
    if (date == null) return '--';
    return "${date.day} ${_months[date.month - 1]}, ${_formatTime(date)}";
  }

  // Initials for the customer avatar (e.g. "Akshit Raut" → "AR").
  String _initials(String? name) {
    if (name == null || name.trim().isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

String get paymentStatus {
  final approved = bookinginfo.amountApprove ?? 0;
  final received = bookinginfo.amountReceived ?? 0;

  if (received == 0) {
    return "Unpaid";
  } else if (received < approved) {
    return "Partially Paid";
  } else {
    return "Paid";
  }
}
Color _paymentColor(String status) {
  switch (status.toLowerCase()) {
    case 'paid':
      return _success;
    case 'unpaid':
      return _danger;
    case 'partially paid':
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
    case 'partially paid':
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
    case 'partially paid':
      return Icons.timelapse_rounded;
    default:
      return Icons.info_rounded;
  }
}

  String get tripPaymentStatus {
    final approved = bookinginfo.amountApprove ?? 0;
    final received = bookinginfo.amountReceived ?? 0;
    if (received == 0) return "Unpaid";
    if (received < approved) return "Unpaid";
    return "Paid";
  }

  void _showTripDetail(BuildContext context, WidgetRef ref) {
       print("DEBUG status: ${bookinginfo.status} | type: ${bookinginfo.status.runtimeType}");
    final bool isEditable = bookinginfo.status==2;
    final bool isCancelled = bookinginfo.status == 5;

    // Use tripType passed from the tab — same logic as active tab, no API status guessing
    final bool isActiveOrUpcoming =
    bookinginfo.status == 1 || // Active
    bookinginfo.status == 3;   // Upcoming

    final tollController = TextEditingController(
      text: bookinginfo.tollCharges?.toString() ?? "",
    );
    final repairController = TextEditingController(
      text: bookinginfo.repairingCharges?.toString() ?? "",
    );
    final driverController = TextEditingController(
      text: bookinginfo.driverCharges?.toString() ?? "",
    );
final approved = bookinginfo.amountApprove ?? 0;
final received = bookinginfo.amountReceived ?? 0;
final pending = approved - received;
final receivedController = TextEditingController(
  text: paymentStatus == "Partially Paid"
      ? pending.toString()
      : received == 0
          ? approved.toString()
          : received.toString(),
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
        final sectionGap = isSmall ? 8.0 : 10.0;
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
            padding: EdgeInsets.symmetric(vertical: isSmall ? 4 : 5),
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
              ? AppColors.brandPrimary
              : const Color(0xFF6B7280);
          return TextField(
            controller: ctrl,
    readOnly: !(isEditable || paymentStatus == "Partially Paid"),
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
                  ? AppColors.brandPrimary.withOpacity(0.04)
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
                      ? AppColors.brandPrimary.withOpacity(0.3)
                      : Colors.grey.shade200,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.brandPrimary,
                  width: 1.5,
                ),
              ),
            ),
          );
        }

        Widget customerDriverRow() {
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
          rowDivider(),
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
                          colors: [AppColors.brandPrimary, AppColors.brandPrimaryDark],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.brandPrimary.withOpacity(0.32),
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
                          // ── Status pill: based on bookinginfo.status ──
                          Builder(
                            builder: (_) {
                              Color pillColor;
                              IconData pillIcon;
                              String pillLabel;

                              switch (bookinginfo.status) {
                                case 1:
                                  pillColor = const Color.fromARGB(
                                    255,
                                    118,
                                    166,
                                    245,
                                  ); // Blue
                                  pillIcon = Icons.directions_car;
                                  pillLabel = "Active";
                                  break;

                                case 2:
                                  pillColor = const Color(
                                    0xFFFF6B00,
                                  ); // Deep Orange
                                  pillIcon = Icons.schedule;
                                  pillLabel = "Unpaid";
                                  break;

                                case 3:
                                  pillColor = const Color.fromARGB(255, 211, 183, 252); // Purple
                                  pillIcon = Icons.upcoming_outlined;
                                  pillLabel = "Upcoming";
                                  break;

                                case 4:
                                  pillColor = const Color(0xFF2ECC71); // Green
                                  pillIcon = Icons.check_circle;
                                  pillLabel = "Complete";
                                  break;

                                case 5:
                                  pillColor = const Color.fromARGB(255, 231, 95, 107); // Red
                                  pillIcon = Icons.cancel_outlined;
                                  pillLabel = "Cancelled";
                                  break;

                                default:
                                  pillColor = const Color(0xFFADB5BD); // Grey
                                  pillIcon = Icons.info_outline;
                                  pillLabel = "Unknown";
                              }

                              return Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isSmall ? 8 : 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: pillColor.withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: pillColor.withOpacity(0.55),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(pillIcon, size: 11, color: pillColor),
                                    if (!isSmall) ...[
                                      const SizedBox(width: 4),
                                      Text(
                                        pillLabel,
                                        style: TextStyle(
                                          color: pillColor,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 6),
                          // ✏️ Edit Button
                          if(bookinginfo.status == 1 || bookinginfo.status == 2 || bookinginfo.status == 3)
                            GestureDetector(
                            onTap: () {
                              Navigator.pop(ctx);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TripBookingForm(booking:bookinginfo ),
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
  child: Padding(
    padding: EdgeInsets.only(
      bottom: MediaQuery.of(ctx).viewInsets.bottom, // ✅ KEYBOARD SPACE
    ),
    child: ListView(
      controller: scrollCtrl,
      keyboardDismissBehavior:
          ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(
        hPad,
        14,
        hPad,
        32 + MediaQuery.of(ctx).padding.bottom,
      ),
                        children: [
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
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
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
                                                  color: const Color(
                                                    0xFF2D6A4F,
                                                  ),
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
                                      if (paymentStatus == "Partially Paid") ...[
  const SizedBox(height: 12),

  Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [

      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Paid Amount",
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          Text(
            "₹$received",
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Colors.green,
            ),
          ),
        ],
      ),

      Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Text(
            "Pending Amount",
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          Text(
            "₹$pending",
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Colors.red,
            ),
          ),
        ],
      ),

    ],
  ),
],
  const SizedBox(height: 12),
                                      // ── Input fields: hidden for active/upcoming unpaid ──
                                      if (!isActiveOrUpcoming && !isCancelled) ...[
                                        SizedBox(height: isSmall ? 10 : 12),
                                        paymentFields(),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // ── End Trip Button (Only for Active) ──
                          // Closes out an in-progress trip: stamps the end time
                          // and records payment in one step, then moves it to
                          // unpaid / paid. This is how open-ended (no end set)
                          // trips get completed.
                          if (bookinginfo.status == 1) ...[
                            const SizedBox(height: 20),
                            GestureDetector(
                              onTap: () {
                                Navigator.pop(ctx);
                                _showEndTripSheet(context, ref);
                              },
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF2DB976), Color(0xFF1E9E5F)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF2DB976).withOpacity(0.35),
                                      blurRadius: 14,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.flag_circle_rounded,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      "End Trip",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],

                          // ── Cancel Trip Button (Only for Active / Upcoming) ──
                          if (isActiveOrUpcoming) ...[
                            const SizedBox(height: 20),
                            GestureDetector(
                              onTap: () async {
                                // Confirmation Dialog
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text("Cancel Trip"),
                                    content: const Text(
                                      "Are you sure you want to cancel this trip?",
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text("No"),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                        ),
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text("Yes, Cancel"),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirm == true) {
                                  // final updated = BookingInfo(
                                  //   tripId: bookinginfo.tripId,
                                  //   status: 5, // 🔥 Cancelled
                                  // );

                                  final trip_id = bookinginfo.tripId;
                                  if (trip_id == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text("Invalid Trip ID"),
                                      ),
                                    );
                                    return;
                                  }

                                  await ref
                                      .read(tripPageViewModelProvider.notifier)
                                      .cancelTrip(trip_id);
                                  if (onTripUpdated != null) {
                                    await onTripUpdated!();
                                  }
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Trip cancelled successfully!",
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE63946),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.cancel_outlined,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      "Cancel Trip",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],

                          // ── Submit / Done: hidden for active/upcoming unpaid ──
                          if (!isActiveOrUpcoming && !isCancelled) ...[
                            const SizedBox(height: 24),
                       if (isEditable || paymentStatus == "Partially Paid")
                              GestureDetector(
                                onTap: () async {
                                  
                                  final updated = BookingInfo(
                                    tripId: bookinginfo.tripId,
                                    tollCharges:
                                        double.tryParse(tollController.text) ??
                                        0,
                                    repairingCharges:
                                        double.tryParse(
                                          repairController.text,
                                        ) ??
                                        0,
                                    driverCharges:
                                        double.tryParse(
                                          driverController.text,
                                        ) ??
                                        0,
                                    amountReceived:
                                        double.tryParse(
                                          receivedController.text,
                                        ) ??
                                        0,
                                  );
                                  await ref
                                      .read(tripPageViewModelProvider.notifier)
                                      .updatePaymentStatus(updated);
                                  if (onTripUpdated != null) {
                                    await onTripUpdated!();
                                  }
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
                                        AppColors.brandPrimary,
                                        AppColors.brandPrimaryDark,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.brandPrimary.withOpacity(0.4),
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
                                        "Payment done",
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

                          SizedBox(height: sectionGap),
                          // ── Trip Info ──────────────────────────────────────
                          infoBlock(
                            label: "TRIP INFO",
                            icon: Icons.route_rounded,
                            color: AppColors.brandPrimary,
                            rows: [
                              detailRow(
                                "Pickup",
                                bookinginfo.pickupLocation ?? "--",
                                Icons.trip_origin,
                                AppColors.brandPrimary,
                              ),
                              rowDivider(),
                              detailRow(
                                "Drop",
                                bookinginfo.dropLocation ?? "--",
                                Icons.location_on,
                                AppColors.brandPrimary,
                              ),
                              rowDivider(),
                              detailRow(
                                "Start",
                                "${_formatDate(bookinginfo.startDateTime)}  ${_formatTime(bookinginfo.startDateTime)}",
                                Icons.calendar_today_outlined,
                                AppColors.brandPrimary,
                              ),
                              rowDivider(),
                              detailRow(
                                "End",
                                "${_formatDate(bookinginfo.endDateTime)}  ${_formatTime(bookinginfo.endDateTime)}",
                                Icons.calendar_today_outlined,
                                AppColors.brandPrimary,
                              ),
                              rowDivider(),
                              detailRow(
                                "Distance",
                                "${bookinginfo.distance?.toString() ?? "--"} km",
                                Icons.straighten,
                                AppColors.brandPrimary,
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
                        ],
                      ),
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

  // ── End Trip bottom sheet ──────────────────────────────────────────────
  // One focused step to close out an active trip: confirm when it ended
  // (defaults to now) and record what was collected. Status is derived on the
  // backend from amount received vs the approved fare.
  void _showEndTripSheet(BuildContext context, WidgetRef ref) {
    // End datetime must be on the IST timeline regardless of device timezone.
    // Build a wall-clock DateTime from UTC + 5:30, so the value shown and sent
    // is always IST. It serializes without a timezone marker, so the backend
    // stores the exact IST wall-clock (same as start_datetime).
    final istNow =
        DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
    DateTime endSel = DateTime(
      istNow.year,
      istNow.month,
      istNow.day,
      istNow.hour,
      istNow.minute,
    );
    final approved = bookinginfo.amountApprove ?? 0;
    final tollCtrl = TextEditingController(
      text: bookinginfo.tollCharges?.toString() ?? "",
    );
    final repairCtrl = TextEditingController(
      text: bookinginfo.repairingCharges?.toString() ?? "",
    );
    final driverCtrl = TextEditingController(
      text: bookinginfo.driverCharges?.toString() ?? "",
    );
    final receivedCtrl = TextEditingController(
      text: approved == 0 ? "" : approved.toStringAsFixed(0),
    );
    bool submitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            final screenH = MediaQuery.of(ctx).size.height;

            // Live figures recomputed on every keystroke (fields call setSheet).
            final received = double.tryParse(receivedCtrl.text) ?? 0;
            final balanceRaw = approved - received;
            final balance = balanceRaw < 0 ? 0.0 : balanceRaw;

            // Live payment-status preview — mirrors the backend rule
            // (received >= approved → Paid, else partial / unpaid).
            late final String payLabel;
            late final Color payColor;
            late final Color payBg;
            late final IconData payIcon;
            if (approved > 0 && received >= approved) {
              payLabel = "Paid";
              payColor = _success;
              payBg = _successSoft;
              payIcon = Icons.check_circle_rounded;
            } else if (received > 0) {
              payLabel = "Partially Paid";
              payColor = _warning;
              payBg = _warningSoft;
              payIcon = Icons.timelapse_rounded;
            } else {
              payLabel = "Unpaid";
              payColor = _danger;
              payBg = _dangerSoft;
              payIcon = Icons.cancel_rounded;
            }

            Widget money(
              TextEditingController c,
              String label,
              IconData icon, {
              bool highlight = false,
            }) {
              final accent = highlight ? AppColors.brandPrimary : _textSec;
              return TextField(
                controller: c,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => setSheet(() {}),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: _textPrimary,
                ),
                decoration: InputDecoration(
                  labelText: label,
                  labelStyle: TextStyle(fontSize: 12.5, color: accent),
                  prefixText: "₹ ",
                  prefixStyle:
                      TextStyle(fontWeight: FontWeight.w700, color: accent),
                  prefixIcon: Icon(icon, size: 18, color: accent),
                  isDense: true,
                  filled: true,
                  fillColor: highlight
                      ? AppColors.brandSoft.withOpacity(0.5)
                      : Colors.grey.shade50,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: highlight
                          ? AppColors.brandPrimary.withOpacity(0.35)
                          : _divider,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.brandPrimary,
                      width: 1.5,
                    ),
                  ),
                ),
              );
            }

            Widget sectionLabel(String t) => Padding(
                  padding: const EdgeInsets.only(left: 2, bottom: 8),
                  child: Text(
                    t,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: _textSec,
                    ),
                  ),
                );

            Widget card({required Widget child}) => Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _divider),
                  ),
                  child: child,
                );

            Widget summaryRow(String label, String value,
                    {Color? color, bool bold = false}) =>
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: _textSec,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: 13.5,
                          color: color ?? _textPrimary,
                          fontWeight: bold ? FontWeight.w800 : FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                );

            Future<void> pickEnd() async {
              final d = await showDatePicker(
                context: ctx,
                initialDate: endSel,
                firstDate: bookinginfo.startDateTime ?? DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (d == null) return;
              final t = await showTimePicker(
                context: ctx,
                initialTime: TimeOfDay.fromDateTime(endSel),
              );
              if (t == null) return;
              setSheet(() {
                endSel = DateTime(d.year, d.month, d.day, t.hour, t.minute);
              });
            }

            Future<void> submit() async {
              final tripId = bookinginfo.tripId;
              if (tripId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Invalid Trip ID")),
                );
                return;
              }
              setSheet(() => submitting = true);
              final updated = BookingInfo(
                tripId: tripId,
                endDateTime: endSel,
                tollCharges: double.tryParse(tollCtrl.text) ?? 0,
                repairingCharges: double.tryParse(repairCtrl.text) ?? 0,
                driverCharges: double.tryParse(driverCtrl.text) ?? 0,
                amountReceived: double.tryParse(receivedCtrl.text) ?? 0,
              );
              await ref
                  .read(tripPageViewModelProvider.notifier)
                  .endTrip(updated);
              if (onTripUpdated != null) await onTripUpdated!();
              if (ctx.mounted) Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Trip ended — marked as $payLabel"),
                  backgroundColor: _success,
                ),
              );
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: screenH * 0.92),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF7F8FC),
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(26)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── Gradient header ──────────────────────────────────
                      Container(
                        padding: const EdgeInsets.fromLTRB(18, 12, 14, 18),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.brandPrimary,
                              AppColors.brandPrimaryDark,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(26)),
                        ),
                        child: Column(
                          children: [
                            Center(
                              child: Container(
                                width: 40,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.4),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.18),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.flag_circle_rounded,
                                    color: Colors.white,
                                    size: 26,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "End Trip",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        "${bookinginfo.pickupLocation ?? '--'}  →  ${bookinginfo.dropLocation ?? '--'}",
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.85),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => Navigator.pop(ctx),
                                  child: Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.18),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // ── Scrollable body ──────────────────────────────────
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              sectionLabel("WHEN DID IT END?"),
                              GestureDetector(
                                onTap: pickEnd,
                                child: card(
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: AppColors.brandSoft,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: const Icon(
                                          Icons.event_available_rounded,
                                          size: 20,
                                          color: AppColors.brandPrimary,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Trip ended at",
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: _textSec,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              "${_formatDate(endSel)}  •  ${_formatTime(endSel)}",
                                              style: const TextStyle(
                                                fontSize: 14.5,
                                                fontWeight: FontWeight.w800,
                                                color: _textPrimary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.brandSoft,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.edit_calendar_rounded,
                                              size: 14,
                                              color: AppColors.brandPrimary,
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              "Change",
                                              style: TextStyle(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.brandPrimary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),

                              sectionLabel("CHARGES"),
                              card(
                                child: Column(
                                  children: [
                                    money(tollCtrl, "Toll Charges",
                                        Icons.toll_rounded),
                                    const SizedBox(height: 10),
                                    money(repairCtrl, "Repair Charges",
                                        Icons.build_rounded),
                                    const SizedBox(height: 10),
                                    money(driverCtrl, "Driver Charges",
                                        Icons.payments_rounded),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 18),

                              sectionLabel("PAYMENT"),
                              card(
                                child: Column(
                                  children: [
                                    money(
                                      receivedCtrl,
                                      "Amount Received",
                                      Icons.account_balance_wallet_rounded,
                                      highlight: true,
                                    ),
                                    const SizedBox(height: 14),
                                    summaryRow("Approved fare",
                                        "₹${approved.toStringAsFixed(0)}"),
                                    summaryRow(
                                      "Received",
                                      "₹${received.toStringAsFixed(0)}",
                                      color: _success,
                                    ),
                                    Divider(height: 18, color: _divider),
                                    summaryRow(
                                      "Balance due",
                                      "₹${balance.toStringAsFixed(0)}",
                                      color: balance > 0 ? _danger : _success,
                                      bold: true,
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Text(
                                          "Trip will be marked",
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            color: _textSec,
                                          ),
                                        ),
                                        const Spacer(),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: payBg,
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(payIcon,
                                                  size: 13, color: payColor),
                                              const SizedBox(width: 5),
                                              Text(
                                                payLabel,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                  color: payColor,
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
                              const SizedBox(height: 22),

                              GestureDetector(
                                onTap: submitting ? null : submit,
                                child: Container(
                                  width: double.infinity,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF2DB976),
                                        Color(0xFF1E9E5F),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _success.withOpacity(0.3),
                                        blurRadius: 14,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: submitting
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.check_circle_rounded,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                              SizedBox(width: 8),
                                              Text(
                                                "Confirm & End Trip",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 15,
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: MediaQuery.of(ctx).padding.bottom + 8,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // BUILD — Compact Attractive Card
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = bookinginfo.payment_status ?? paymentStatus;
    final statusColor = _paymentColor(status);
    final statusBg = _paymentBg(status);
    final statusIcon = _paymentIcon(status);
    final screenW = MediaQuery.of(context).size.width;
    final isSmall = screenW < 360;

    // Pending balance, shown only for unpaid trips (status 2 = the Unpaid tab).
    final bool isUnpaidTab = bookinginfo.status == 2;
    final double pendingAmt =
        (bookinginfo.amountApprove ?? 0) - (bookinginfo.amountReceived ?? 0);
    final String pendingText = pendingAmt == pendingAmt.roundToDouble()
        ? pendingAmt.toStringAsFixed(0)
        : pendingAmt.toStringAsFixed(2);

    // Split "Ertiga MH07A1245" → name + registration plate (last token with a
    // digit). Falls back to showing the whole string as the name.
    final String rawVehicle = (bookinginfo.vehicle_info ?? 'Vehicle N/A').trim();
    String vehicleName = rawVehicle;
    String? vehicleReg;
    final int spaceIdx = rawVehicle.lastIndexOf(' ');
    if (spaceIdx > 0) {
      final last = rawVehicle.substring(spaceIdx + 1);
      if (RegExp(r'\d').hasMatch(last)) {
        vehicleName = rawVehicle.substring(0, spaceIdx);
        vehicleReg = last;
      }
    }

    return GestureDetector(
      onTap: () {
        _showTripDetail(context, ref);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
            // ─ HEADER: Vehicle icon · name/reg · route · status · menu ─
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: _accentSoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.directions_car_rounded,
                    color: _accent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Vehicle name · registration
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Flexible(
                            child: Text(
                              vehicleName,
                              style: TextStyle(
                                fontSize: isSmall ? 14 : 15,
                                fontWeight: FontWeight.w800,
                                color: _textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (vehicleReg != null) ...[
                            Text(
                              "  ·  ",
                              style: TextStyle(
                                fontSize: isSmall ? 11 : 12,
                                color: _textSec,
                              ),
                            ),
                            Flexible(
                              child: Text(
                                vehicleReg,
                                style: TextStyle(
                                  fontSize: isSmall ? 11 : 12,
                                  fontWeight: FontWeight.w600,
                                  color: _textSec,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      // Route
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              bookinginfo.pickupLocation ?? '--',
                              style: TextStyle(
                                fontSize: isSmall ? 11 : 12,
                                color: _textSec,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              size: 11,
                              color: _textSec,
                            ),
                          ),
                          Flexible(
                            child: Text(
                              bookinginfo.dropLocation ?? '--',
                              style: TextStyle(
                                fontSize: isSmall ? 11 : 12,
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
                // Status pill + overflow
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
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
                          Icon(statusIcon, size: 11, color: statusColor),
                          const SizedBox(width: 3),
                          Text(
                            status,
                            style: TextStyle(
                              fontSize: 10.5,
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

            const SizedBox(height: 10),

            Divider(height: 1, color: _divider),

            const SizedBox(height: 10),

            // ─ FOOTER: Customer avatar/name/date · Total/Due ─────
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _accentSoft,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    _initials(bookinginfo.customer_name),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: _accent,
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                // Name + date
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        bookinginfo.customer_name ?? '--',
                        style: TextStyle(
                          fontSize: isSmall ? 12 : 13,
                          fontWeight: FontWeight.w700,
                          color: _textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _prettyDateTime(bookinginfo.startDateTime),
                        style: TextStyle(
                          fontSize: isSmall ? 10.5 : 11.5,
                          color: _textSec,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Total
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Total",
                      style: TextStyle(
                        fontSize: 9.5,
                        color: _textSec,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      "₹${bookinginfo.amountApprove ?? 0}",
                      style: TextStyle(
                        fontSize: isSmall ? 13 : 14.5,
                        fontWeight: FontWeight.w800,
                        color: _textPrimary,
                      ),
                    ),
                  ],
                ),
                // Due (only when there's a pending balance)
                if (isUnpaidTab && pendingAmt > 0) ...[
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Due",
                        style: TextStyle(
                          fontSize: 9.5,
                          color: _textSec,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        "₹$pendingText",
                        style: TextStyle(
                          fontSize: isSmall ? 13 : 14.5,
                          fontWeight: FontWeight.w800,
                          color: _danger,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
