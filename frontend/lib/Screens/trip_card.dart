import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vego/Screens/add_tripbooking.dart';
import 'package:vego/core/notifications/ringtone_picker.dart';
import 'package:vego/core/notifications/trip_alarm_service.dart';
import 'package:vego/core/theme/app_colors.dart';
import 'package:vego/domain/models/booking_info.dart';
import 'package:vego/presentation/providers/viewmodel_provider.dart';

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
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return "$hour:$minute $period";
  }

  // "31 May, 9:14 AM" — compact day + short month + time, as in the card design.
  static const List<String> _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  String _prettyDateTime(DateTime? date) {
    if (date == null) return '--';
    return "${date.day} ${_months[date.month - 1]}, ${_formatTime(date)}";
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

  // Trip lifecycle status derived from bookinginfo.status — mirrors the pill
  // shown in the detail sheet header (1=Active, 2=Unpaid, 3=Upcoming,
  // 4=Complete, 5=Cancelled).
  ({Color color, IconData icon, String label}) get _tripStatusStyle {
    switch (bookinginfo.status) {
      case 1:
        return (
          color: const Color.fromARGB(255, 76, 137, 235),
          icon: Icons.directions_car,
          label: "Active",
        );
      case 2:
        // Trip is finished; payment state is shown by the separate payment
        // badge, so the lifecycle badge reads "Complete" (same as status 4).
        return (
          color: const Color(0xFF2ECC71),
          icon: Icons.check_circle,
          label: "Complete",
        );
      case 3:
        return (
          color: const Color(0xFF9B6DE0),
          icon: Icons.upcoming_outlined,
          label: "Upcoming",
        );
      case 4:
        return (
          color: const Color(0xFF2ECC71),
          icon: Icons.check_circle,
          label: "Complete",
        );
      case 5:
        return (
          color: const Color.fromARGB(255, 231, 95, 107),
          icon: Icons.cancel_outlined,
          label: "Cancelled",
        );
      default:
        return (
          color: const Color(0xFFADB5BD),
          icon: Icons.info_outline,
          label: "Unknown",
        );
    }
  }

  /// Public entry point so other screens (e.g. the Transactions daybook) can
  /// open this trip's detail sheet without rendering/tapping the card itself.
  void showDetailSheet(BuildContext context, WidgetRef ref) =>
      _showTripDetail(context, ref);

  void _showTripDetail(BuildContext context, WidgetRef ref) {
    print(
      "DEBUG status: ${bookinginfo.status} | type: ${bookinginfo.status.runtimeType}",
    );
    final bool isEditable = bookinginfo.status == 2;
    final bool isCancelled = bookinginfo.status == 5;

    // Use tripType passed from the tab — same logic as active tab, no API status guessing
    final bool isActiveOrUpcoming =
        bookinginfo.status == 1 || // Active
        bookinginfo.status == 3; // Upcoming

    final tollController = TextEditingController(
      text: bookinginfo.tollCharges?.toString() ?? "",
    );
    final repairController = TextEditingController(
      text: bookinginfo.repairingCharges?.toString() ?? "",
    );
    final driverController = TextEditingController(
      text: bookinginfo.driverCharges?.toString() ?? "",
    );
    final fuelController = TextEditingController(
      text: bookinginfo.fuelCharges?.toString() ?? "",
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

    const List<String> paymentModes = [
      'Cash',
      'UPI',
      'Net Banking',
      'Credit Card',
      'Debit Card',
      'Cheque',
      'Bank Transfer',
      'Other',
    ];
    final paymentModeNotifier = ValueNotifier<String?>(
      bookinginfo.paymentMode?.isNotEmpty == true
          ? bookinginfo.paymentMode
          : null,
    );

    // Kick off the payment-history load for this trip; the sheet's Consumer
    // reads it from TripPageViewModel's state.paymentHistory.
    if (bookinginfo.tripId != null) {
      ref
          .read(tripPageViewModelProvider.notifier)
          .paymentHistory(bookinginfo.tripId!);
    }

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
                        fuelController,
                        "Fuel Charges",
                        Icons.local_gas_station_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
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
                if (paymentStatus != "Paid") ...[
                const SizedBox(height: 10),
                ValueListenableBuilder<String?>(
                  valueListenable: paymentModeNotifier,
                  builder: (_, selectedMode, __) =>
                      DropdownButtonFormField<String>(
                        value: selectedMode,
                        decoration: InputDecoration(
                          labelText: "Payment Mode *",
                          labelStyle: TextStyle(
                            fontSize: isSmall ? 11.5 : 12.5,
                            color: AppColors.brandPrimary,
                          ),
                          prefixIcon: Icon(
                            Icons.payment_outlined,
                            size: isSmall ? 15 : 17,
                            color: AppColors.brandPrimary,
                          ),
                          filled: true,
                          fillColor: AppColors.brandPrimary.withOpacity(0.04),
                          contentPadding: EdgeInsets.symmetric(
                            vertical: fieldVertPad,
                            horizontal: 14,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.brandPrimary.withOpacity(0.3),
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
                        items: paymentModes
                            .map(
                              (mode) => DropdownMenuItem(
                                value: mode,
                                child: Text(
                                  mode,
                                  style: TextStyle(
                                    fontSize: isSmall ? 13 : 14,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1A1A2E),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (val) => paymentModeNotifier.value = val,
                      ),
                ),
                ],
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
                fuelController,
                "Fuel Charges",
                Icons.local_gas_station_outlined,
              ),
              const SizedBox(height: 10),
              amountField(
                receivedController,
                "Amount Received",
                Icons.account_balance_wallet_outlined,
                highlight: true,
              ),
              if (paymentStatus != "Paid") ...[
              const SizedBox(height: 10),
              ValueListenableBuilder<String?>(
                valueListenable: paymentModeNotifier,
                builder: (_, selectedMode, __) =>
                    DropdownButtonFormField<String>(
                      value: selectedMode,
                      decoration: InputDecoration(
                        labelText: "Payment Mode *",
                        labelStyle: TextStyle(
                          fontSize: isSmall ? 11.5 : 12.5,
                          color: AppColors.brandPrimary,
                        ),
                        prefixIcon: Icon(
                          Icons.payment_outlined,
                          size: isSmall ? 15 : 17,
                          color: AppColors.brandPrimary,
                        ),
                        filled: true,
                        fillColor: AppColors.brandPrimary.withOpacity(0.04),
                        contentPadding: EdgeInsets.symmetric(
                          vertical: fieldVertPad,
                          horizontal: 14,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppColors.brandPrimary.withOpacity(0.3),
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
                      items: paymentModes
                          .map(
                            (mode) => DropdownMenuItem(
                              value: mode,
                              child: Text(
                                mode,
                                style: TextStyle(
                                  fontSize: isSmall ? 13 : 14,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1A1A2E),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (val) => paymentModeNotifier.value = val,
                    ),
              ),
              ],
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
                        color: AppColors.brandHeader,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.brandHeader.withOpacity(0.32),
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
                              String pillLabel;

                              switch (bookinginfo.status) {
                                case 1:
                                  pillColor = const Color.fromARGB(255, 118, 166, 245);
                                  pillLabel = "Active";
                                  break;
                                case 2:
                                  pillColor = const Color(0xFFFF6B00);
                                  pillLabel = "Unpaid";
                                  break;
                                case 3:
                                  pillColor = const Color.fromARGB(255, 211, 183, 252);
                                  pillLabel = "Upcoming";
                                  break;
                                case 4:
                                  pillColor = const Color(0xFF2ECC71);
                                  pillLabel = "Complete";
                                  break;
                                case 5:
                                  pillColor = const Color.fromARGB(255, 231, 95, 107);
                                  pillLabel = "Cancelled";
                                  break;
                                default:
                                  pillColor = const Color(0xFFADB5BD);
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
                                child: Text(
                                  pillLabel,
                                  style: TextStyle(
                                    color: pillColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 6),
                          // ✏️ Edit Button
                          if (bookinginfo.status == 1 ||
                              bookinginfo.status == 2 ||
                              bookinginfo.status == 3)
                            GestureDetector(
                              onTap: () {
                                Navigator.pop(ctx);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        TripBookingForm(booking: bookinginfo),
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
                          bottom: MediaQuery.of(
                            ctx,
                          ).viewInsets.bottom, // ✅ KEYBOARD SPACE
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
                                            color: const Color(0xFFD8F3DC),
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
                                                  color: const Color(
                                                    0xFF1B4332,
                                                  ),
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: isSmall ? 15 : 18,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (paymentStatus ==
                                            "Partially Paid") ...[
                                          const SizedBox(height: 12),

                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const Text(
                                                    "Paid Amount",
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  Text(
                                                    "₹$received",
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: Colors.green,
                                                    ),
                                                  ),
                                                ],
                                              ),

                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.end,
                                                children: [
                                                  const Text(
                                                    "Pending Amount",
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  Text(
                                                    "₹$pending",
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w700,
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
                                        if (!isActiveOrUpcoming &&
                                            !isCancelled) ...[
                                          SizedBox(height: isSmall ? 10 : 12),
                                          paymentFields(),
                                          // ── Submit Payment (below payment mode) ──
                                          const SizedBox(height: 16),
                                          if (isEditable ||
                                              paymentStatus == "Partially Paid")
                                            GestureDetector(
                                              onTap: () async {
                                                if (paymentModeNotifier.value ==
                                                    null) {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        "Please select a payment mode",
                                                      ),
                                                      backgroundColor:
                                                          Colors.red,
                                                    ),
                                                  );
                                                  return;
                                                }

                                                final updated = BookingInfo(
                                                  tripId: bookinginfo.tripId,
                                                  tollCharges:
                                                      double.tryParse(
                                                        tollController.text,
                                                      ) ??
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
                                                  fuelCharges:
                                                      double.tryParse(
                                                        fuelController.text,
                                                      ) ??
                                                      0,
                                                  amountReceived:
                                                      double.tryParse(
                                                        receivedController.text,
                                                      ) ??
                                                      0,
                                                  paymentMode:
                                                      paymentModeNotifier.value,
                                                );
                                                final err = await ref
                                                    .read(
                                                      tripPageViewModelProvider
                                                          .notifier,
                                                    )
                                                    .updatePaymentStatus(
                                                      updated,
                                                    );
                                                if (err != null) {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        "Payment not saved: $err",
                                                      ),
                                                      backgroundColor:
                                                          Colors.red,
                                                    ),
                                                  );
                                                  return;
                                                }
                                                if (bookinginfo.tripId !=
                                                    null) {
                                                  await ref
                                                      .read(
                                                        tripPageViewModelProvider
                                                            .notifier,
                                                      )
                                                      .paymentHistory(
                                                        bookinginfo.tripId!,
                                                      );
                                                }
                                                if (onTripUpdated != null) {
                                                  await onTripUpdated!();
                                                }
                                                Navigator.pop(ctx);
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      "Payment details updated successfully!",
                                                    ),
                                                    backgroundColor:
                                                        Colors.green,
                                                  ),
                                                );
                                              },
                                              child: Container(
                                                width: double.infinity,
                                                padding: EdgeInsets.symmetric(
                                                  vertical: isSmall ? 14 : 16,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.brandPrimary,
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: AppColors
                                                          .brandPrimary
                                                          .withOpacity(0.4),
                                                      blurRadius: 14,
                                                      offset: const Offset(
                                                        0,
                                                        5,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons
                                                          .check_circle_outline,
                                                      color: Colors.white,
                                                      size: isSmall ? 18 : 20,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      "Submit Payment",
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        fontSize: isSmall
                                                            ? 14
                                                            : 15,
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
                                                  borderRadius:
                                                      BorderRadius.circular(30),
                                                  border: Border.all(
                                                    color:
                                                        Colors.green.shade200,
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.verified_rounded,
                                                      color:
                                                          Colors.green.shade600,
                                                      size: isSmall ? 15 : 18,
                                                    ),
                                                    SizedBox(
                                                      width: isSmall ? 6 : 8,
                                                    ),
                                                    Text(
                                                      "Payment done",
                                                      style: TextStyle(
                                                        color: Colors
                                                            .green
                                                            .shade700,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: isSmall
                                                            ? 12
                                                            : 14,
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

                            // ── Payment History (installments) ─────────────────
                            // Lists every installment recorded against this trip.
                            // Loaded via TripPageViewModel.paymentHistory(tripId)
                            // (triggered when the sheet opens) and read from its
                            // state's paymentHistory AsyncValue.
                            if (bookinginfo.tripId != null) ...[
                              SizedBox(height: sectionGap),
                              Consumer(
                                builder: (context, innerRef, _) {
                                  final async = innerRef.watch(
                                    tripPageViewModelProvider.select(
                                      (s) => s.paymentHistory,
                                    ),
                                  );

                                  Widget shell(Widget body) {
                                    return Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(
                                          cardRadius,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.05,
                                            ),
                                            blurRadius: 10,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: double.infinity,
                                            padding: EdgeInsets.fromLTRB(
                                              14,
                                              isSmall ? 10 : 12,
                                              14,
                                              isSmall ? 8 : 10,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _accentSoft,
                                              borderRadius:
                                                  BorderRadius.vertical(
                                                    top: Radius.circular(
                                                      cardRadius,
                                                    ),
                                                  ),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.receipt_long_rounded,
                                                  size: isSmall ? 13 : 15,
                                                  color: _accent,
                                                ),
                                                const SizedBox(width: 7),
                                                Text(
                                                  "PAYMENT HISTORY",
                                                  style: TextStyle(
                                                    color: _accent,
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: labelFontSize,
                                                    letterSpacing: 0.5,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.fromLTRB(
                                              14,
                                              8,
                                              14,
                                              isSmall ? 10 : 12,
                                            ),
                                            child: body,
                                          ),
                                        ],
                                      ),
                                    );
                                  }

                                  Widget centered(Widget child) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    child: Center(child: child),
                                  );

                                  return async.when(
                                    loading: () => shell(
                                      centered(
                                        SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.2,
                                            color: _accent,
                                          ),
                                        ),
                                      ),
                                    ),
                                    error: (e, _) => shell(
                                      centered(
                                        Column(
                                          children: [
                                            Icon(
                                              Icons.error_outline_rounded,
                                              color: _danger,
                                              size: 22,
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              "Couldn't load payment history",
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: _textSec,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            GestureDetector(
                                              onTap: () => innerRef
                                                  .read(
                                                    tripPageViewModelProvider
                                                        .notifier,
                                                  )
                                                  .paymentHistory(
                                                    bookinginfo.tripId!,
                                                  ),
                                              child: Text(
                                                "Retry",
                                                style: TextStyle(
                                                  fontSize: 12.5,
                                                  fontWeight: FontWeight.w700,
                                                  color: _accent,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    data: (payments) {
                                      if (payments.isEmpty) {
                                        return shell(
                                          centered(
                                            Column(
                                              children: [
                                                Icon(
                                                  Icons
                                                      .history_toggle_off_rounded,
                                                  color: _textSec,
                                                  size: 24,
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  "No payments recorded yet",
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: _textSec,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }

                                      final total = payments.fold<double>(
                                        0,
                                        (sum, p) => sum + (p.Amount ?? 0),
                                      );

                                      return shell(
                                        Column(
                                          children: [
                                            for (
                                              int i = 0;
                                              i < payments.length;
                                              i++
                                            ) ...[
                                              if (i > 0)
                                                Divider(
                                                  height: 14,
                                                  color: Colors.grey.shade100,
                                                ),
                                              Row(
                                                children: [
                                                  Container(
                                                    width: isSmall ? 34 : 38,
                                                    height: isSmall ? 34 : 38,
                                                    decoration: BoxDecoration(
                                                      color: _successSoft,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10,
                                                          ),
                                                    ),
                                                    child: Icon(
                                                      Icons
                                                          .account_balance_wallet_rounded,
                                                      size: isSmall ? 16 : 18,
                                                      color: _success,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          payments[i]
                                                                      .PaymentMode
                                                                      ?.isNotEmpty ==
                                                                  true
                                                              ? payments[i]
                                                                    .PaymentMode!
                                                              : "Payment",
                                                          style: TextStyle(
                                                            fontSize: isSmall
                                                                ? 12.5
                                                                : 13.5,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            color: _textPrimary,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          height: 2,
                                                        ),
                                                        Text(
                                                          _prettyDateTime(
                                                            payments[i]
                                                                .PaymentDate,
                                                          ),
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            color: _textSec,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Text(
                                                    "₹${(payments[i].Amount ?? 0).toStringAsFixed(0)}",
                                                    style: TextStyle(
                                                      fontSize: isSmall
                                                          ? 14
                                                          : 15.5,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      color: _success,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                            Divider(
                                              height: 18,
                                              color: Colors.grey.shade200,
                                            ),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  "Total Paid",
                                                  style: TextStyle(
                                                    fontSize: isSmall
                                                        ? 12.5
                                                        : 13.5,
                                                    fontWeight: FontWeight.w700,
                                                    color: _textPrimary,
                                                  ),
                                                ),
                                                Text(
                                                  "₹${total.toStringAsFixed(0)}",
                                                  style: TextStyle(
                                                    fontSize: isSmall
                                                        ? 15
                                                        : 16.5,
                                                    fontWeight: FontWeight.w800,
                                                    color: _accent,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ],

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
                                    color: const Color(0xFF2DB976),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF2DB976,
                                        ).withOpacity(0.35),
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
                                          child: const Text(
                                            "Yes, Cancel",
                                            style: TextStyle(color: Colors.white),
                                          ),
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
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text("Invalid Trip ID"),
                                        ),
                                      );
                                      return;
                                    }

                                    final cancelErr = await ref
                                        .read(
                                          tripPageViewModelProvider.notifier,
                                        )
                                        .cancelTrip(trip_id);
                                    if (cancelErr != null) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            "Trip not cancelled: $cancelErr",
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                      return;
                                    }
                                    // Drop any pending reminder for a trip that
                                    // is no longer happening.
                                    await TripAlarmService.cancel(trip_id);
                                    if (onTripUpdated != null) {
                                      await onTripUpdated!();
                                    }
                                    Navigator.pop(ctx);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "Trip cancelled successfully!",
                                        ),
                                        backgroundColor: Colors.green,
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
                                  "Booked",
                                  _formatDate(bookinginfo.bookingDate),
                                  Icons.event_note_rounded,
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
                                rowDivider(),
                                detailRow(
                                  "Fuel Req.",
                                  bookinginfo.fuelRequired != null
                                      ? "${bookinginfo.fuelRequired} L"
                                      : "--",
                                  Icons.local_gas_station_outlined,
                                  AppColors.brandPrimary,
                                ),
                                rowDivider(),
                                detailRow(
                                  "Trip Type",
                                  bookinginfo.isReturnTrip == 1
                                      ? "Round Trip"
                                      : "One Way",
                                  bookinginfo.isReturnTrip == 1
                                      ? Icons.sync_alt_rounded
                                      : Icons.trending_flat_rounded,
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
    final istNow = DateTime.now().toUtc().add(
      const Duration(hours: 5, minutes: 30),
    );
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
    final fuelCtrl = TextEditingController(
      text: bookinginfo.fuelCharges?.toString() ?? "",
    );
    final receivedCtrl = TextEditingController(
      text: approved == 0 ? "" : approved.toStringAsFixed(0),
    );
    String? endTripPaymentMode;
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
                  prefixStyle: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                  prefixIcon: Icon(icon, size: 18, color: accent),
                  isDense: true,
                  filled: true,
                  fillColor: highlight
                      ? AppColors.brandSoft.withOpacity(0.5)
                      : Colors.grey.shade50,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 12,
                  ),
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

            Widget summaryRow(
              String label,
              String value, {
              Color? color,
              bool bold = false,
            }) => Padding(
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
                initialEntryMode: TimePickerEntryMode.input,
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
              if (endTripPaymentMode == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Please select a payment mode"),
                    backgroundColor: Colors.red,
                  ),
                );
                setSheet(() => submitting = false);
                return;
              }
              final updated = BookingInfo(
                tripId: tripId,
                endDateTime: endSel,
                tollCharges: double.tryParse(tollCtrl.text) ?? 0,
                repairingCharges: double.tryParse(repairCtrl.text) ?? 0,
                driverCharges: double.tryParse(driverCtrl.text) ?? 0,
                fuelCharges: double.tryParse(fuelCtrl.text) ?? 0,
                amountReceived: double.tryParse(receivedCtrl.text) ?? 0,
                paymentMode: endTripPaymentMode,
              );
              final err = await ref
                  .read(tripPageViewModelProvider.notifier)
                  .endTrip(updated);
              if (err != null) {
                setSheet(() => submitting = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Trip not ended: $err"),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              await ref
                  .read(tripPageViewModelProvider.notifier)
                  .paymentHistory(tripId);
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
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(26),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── Gradient header ──────────────────────────────────
                      Container(
                        padding: const EdgeInsets.fromLTRB(18, 12, 14, 18),
                        decoration: const BoxDecoration(
                          color: AppColors.brandHeader,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(26),
                          ),
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
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
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
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
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
                                    money(
                                      tollCtrl,
                                      "Toll Charges",
                                      Icons.toll_rounded,
                                    ),
                                    const SizedBox(height: 10),
                                    money(
                                      repairCtrl,
                                      "Repair Charges",
                                      Icons.build_rounded,
                                    ),
                                    const SizedBox(height: 10),
                                    money(
                                      driverCtrl,
                                      "Driver Charges",
                                      Icons.payments_rounded,
                                    ),
                                    const SizedBox(height: 10),
                                    money(
                                      fuelCtrl,
                                      "Fuel Charges",
                                      Icons.local_gas_station_rounded,
                                    ),
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
                                    const SizedBox(height: 10),
                                    DropdownButtonFormField<String>(
                                      value: endTripPaymentMode,
                                      decoration: InputDecoration(
                                        labelText: "Payment Mode *",
                                        labelStyle: const TextStyle(
                                          fontSize: 12.5,
                                          color: AppColors.brandPrimary,
                                        ),
                                        prefixIcon: const Icon(
                                          Icons.payment_outlined,
                                          size: 18,
                                          color: AppColors.brandPrimary,
                                        ),
                                        isDense: true,
                                        filled: true,
                                        fillColor: AppColors.brandSoft
                                            .withOpacity(0.5),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              vertical: 14,
                                              horizontal: 12,
                                            ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide(
                                            color: AppColors.brandPrimary
                                                .withOpacity(0.35),
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: const BorderSide(
                                            color: AppColors.brandPrimary,
                                            width: 1.5,
                                          ),
                                        ),
                                      ),
                                      items:
                                          const [
                                                'Cash',
                                                'UPI',
                                                'Net Banking',
                                                'Credit Card',
                                                'Debit Card',
                                                'Cheque',
                                                'Bank Transfer',
                                                'Other',
                                              ]
                                              .map(
                                                (mode) => DropdownMenuItem(
                                                  value: mode,
                                                  child: Text(
                                                    mode,
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: _textPrimary,
                                                    ),
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                      onChanged: (val) => setSheet(
                                        () => endTripPaymentMode = val,
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    summaryRow(
                                      "Approved fare",
                                      "₹${approved.toStringAsFixed(0)}",
                                    ),
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
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                payIcon,
                                                size: 13,
                                                color: payColor,
                                              ),
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
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2DB976),
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
    final String rawVehicle = (bookinginfo.vehicle_info ?? 'Vehicle N/A');
    String vehicleName = rawVehicle;
    String? vehicleReg;
    // final int spaceIdx = rawVehicle.lastIndexOf(' ');
    // if (spaceIdx > 0) {
    //   final last = rawVehicle.substring(spaceIdx + 1);
    //   if (RegExp(r'\d').hasMatch(last)) {
    //     vehicleName = rawVehicle.substring(0, spaceIdx);
    //     vehicleReg = last;
    //   }
    // }

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
                // Container(
                //   width: 38,
                //   height: 38,
                //   decoration: BoxDecoration(
                //     color: _accentSoft,
                //     borderRadius: BorderRadius.circular(10),
                //   ),
                //   child: Icon(
                //     Icons.directions_car_rounded,
                //     color: _accent,
                //     size: 20,
                //   ),
                // ),
                // const SizedBox(width: 10),
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
                // Reminder bell — only meaningful for upcoming/active trips.
                if (bookinginfo.status == 1 || bookinginfo.status == 3)
                  _TripReminderBell(booking: bookinginfo),
                const SizedBox(width: 8),
                // Status pills: trip lifecycle status + payment status
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Trip status pill (Active / Upcoming / Complete / …)
                    Builder(
                      builder: (_) {
                        final ts = _tripStatusStyle;
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: ts.color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: ts.color.withOpacity(0.45),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(ts.icon, size: 11, color: ts.color),
                              const SizedBox(width: 3),
                              Text(
                                ts.label,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: ts.color,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 4),
                    // Payment status pill (Paid / Unpaid / Partially Paid)
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

// ── Reminder bell ────────────────────────────────────────────────────────────
// Small tappable bell on the trip card. Filled/coloured when a reminder is set,
// outline when not. Tapping opens the reminder sheet; it rebuilds itself when
// the alarm is set/removed so the icon reflects the new state immediately.
class _TripReminderBell extends StatefulWidget {
  final BookingInfo booking;
  const _TripReminderBell({required this.booking});

  @override
  State<_TripReminderBell> createState() => _TripReminderBellState();
}

class _TripReminderBellState extends State<_TripReminderBell> {
  @override
  Widget build(BuildContext context) {
    final hasAlarm = TripAlarmService.hasAlarm(widget.booking.tripId);
    return GestureDetector(
      onTap: () => _openTripReminderSheet(
        context,
        widget.booking,
        () {
          if (mounted) setState(() {});
        },
      ),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: hasAlarm
              ? AppColors.brandPrimary.withOpacity(0.12)
              : Colors.grey.shade100,
          shape: BoxShape.circle,
        ),
        child: Icon(
          hasAlarm
              ? Icons.notifications_active_rounded
              : Icons.notifications_none_rounded,
          size: 16,
          color: hasAlarm ? AppColors.brandPrimary : const Color(0xFF7B82A0),
        ),
      ),
    );
  }
}

// Format like "12 Jun 2026, 7:00 PM" for the reminder sheet.
const List<String> _reminderMonths = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];
String _fmtReminder(DateTime d) {
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final m = d.minute.toString().padLeft(2, '0');
  final ap = d.hour >= 12 ? 'PM' : 'AM';
  return "${d.day} ${_reminderMonths[d.month - 1]} ${d.year}, $h:$m $ap";
}

// Bottom sheet to set / change / remove a trip's offline reminder alarm.
Future<void> _openTripReminderSheet(
  BuildContext context,
  BookingInfo booking,
  VoidCallback onChanged,
) async {
  final tripId = booking.tripId;
  final start = booking.startDateTime;
  if (tripId == null || start == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("This trip has no start time to remind about")),
    );
    return;
  }

  const accent = AppColors.brandPrimary;
  const textSec = Color(0xFF7B82A0);
  const danger = Color(0xFFE53935);

  final route = "${booking.pickupLocation ?? '--'} → ${booking.dropLocation ?? '--'}";
  final reminderTitle = "Trip Reminder";
  String reminderBody() =>
      "Upcoming trip: $route — starts ${_fmtReminder(start)}";

  Future<void> doSchedule(DateTime fireAt) async {
    final ok = await TripAlarmService.schedule(
      tripId: tripId,
      fireAt: fireAt,
      title: reminderTitle,
      body: reminderBody(),
    );
    if (!context.mounted) return;
    Navigator.pop(context);
    onChanged();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? "Reminder set for ${_fmtReminder(fireAt)}"
              : "That time has already passed — pick a later time",
        ),
        backgroundColor: ok ? const Color(0xFF2DB976) : danger,
      ),
    );
  }

  await showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final hasAlarm = TripAlarmService.hasAlarm(tripId);
      final existing = TripAlarmService.alarmTime(tripId);
      final defaultTime = TripAlarmService.defaultReminderFor(start);

      Widget tile({
        required IconData icon,
        required Color color,
        required String title,
        String? subtitle,
        required VoidCallback onTap,
      }) {
        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 20, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1D2E),
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: const TextStyle(fontSize: 12, color: textSec),
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: textSec),
              ],
            ),
          ),
        );
      }

      return StatefulBuilder(
        builder: (ctx, setSheet) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF7F8FC),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 6),
                child: Row(
                  children: [
                    const Icon(Icons.notifications_active_rounded,
                        color: accent, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Trip Reminder",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1A1D2E),
                            ),
                          ),
                          Text(
                            hasAlarm && existing != null
                                ? "Set for ${_fmtReminder(existing)}"
                                : "No reminder set",
                            style: const TextStyle(fontSize: 12, color: textSec),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              tile(
                icon: Icons.schedule_rounded,
                color: accent,
                title: "Default — 7:00 PM, day before",
                subtitle: _fmtReminder(defaultTime),
                onTap: () => doSchedule(defaultTime),
              ),
              tile(
                icon: Icons.edit_calendar_rounded,
                color: const Color(0xFF7C3AED),
                title: "Custom date & time",
                subtitle: "Pick when you want to be reminded",
                onTap: () async {
                  final now = DateTime.now();
                  final d = await showDatePicker(
                    context: ctx,
                    initialDate: defaultTime.isAfter(now) ? defaultTime : now,
                    firstDate: now,
                    lastDate: DateTime(2100),
                  );
                  if (d == null) return;
                  if (!ctx.mounted) return;
                  final t = await showTimePicker(
                    context: ctx,
                    initialTime: const TimeOfDay(hour: 19, minute: 0),
                  );
                  if (t == null) return;
                  await doSchedule(
                    DateTime(d.year, d.month, d.day, t.hour, t.minute),
                  );
                },
              ),
              Divider(height: 1, color: Colors.grey.shade200, indent: 16, endIndent: 16),
              tile(
                icon: Icons.music_note_rounded,
                color: const Color(0xFF2DB976),
                title: "Alarm sound",
                subtitle:
                    TripAlarmService.currentSoundTitle ?? "Default alarm tone",
                onTap: () async {
                  final choice = await RingtonePicker.pick(
                    current: TripAlarmService.currentSoundUri,
                  );
                  if (choice == null) return;
                  await TripAlarmService.setSound(choice);
                  // If this trip already has an alarm, re-apply it so the new
                  // sound takes effect now (channel sound is fixed at schedule).
                  final cur = TripAlarmService.alarmTime(tripId);
                  if (cur != null) {
                    await TripAlarmService.schedule(
                      tripId: tripId,
                      fireAt: cur,
                      title: reminderTitle,
                      body: reminderBody(),
                    );
                  }
                  setSheet(() {});
                },
              ),
              if (hasAlarm)
                tile(
                  icon: Icons.notifications_off_rounded,
                  color: danger,
                  title: "Remove reminder",
                  onTap: () async {
                    await TripAlarmService.cancel(tripId);
                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                    onChanged();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Reminder removed")),
                    );
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
        ),
      );
    },
  );
}
