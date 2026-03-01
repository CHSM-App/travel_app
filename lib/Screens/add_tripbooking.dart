import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:travel_agency_app/domain/models/booking_info.dart';
import 'package:travel_agency_app/domain/models/tripbooking_info.dart';
import 'package:travel_agency_app/presentation/providers/viewmodel_provider.dart';

class TripBookingForm extends ConsumerStatefulWidget {
  final BookingInfo? booking;
  const TripBookingForm({super.key, this.booking});

  @override
  ConsumerState<TripBookingForm> createState() => _TripBookingFormState();
}

class _TripBookingFormState extends ConsumerState<TripBookingForm>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final pickup = TextEditingController();
  final drop = TextEditingController();
  final distance = TextEditingController();
  final fuelRequired = TextEditingController();
  final tripCharges = TextEditingController();
  final startDate = TextEditingController();
  final endDate = TextEditingController();

  DateTime? startDateValue;
  DateTime? endDateValue;

  int? selectedVehicleId;
  int? selectedDriverId;
  int? selectedCustomerId;

  bool _isSaving = false;

  // ── Design tokens ────────────────────────────────────────────────────────────
  static const _primary = Color(0xFF4361EE);
  static const _primaryDark = Color(0xFF3A0CA3);
  static const _surface = Color(0xFFF7F8FC);
  static const _cardBg = Colors.white;
  static const _textDark = Color(0xFF1A1A2E);
  static const _textMid = Color(0xFF6B7280);

  // @override
  // void initState() {
  //   super.initState();
  //   Future.microtask(() {
  //     final notifier = ref.read(tripBookingViewModelProvider.notifier);
  //     final agencyId = ref.read(loginViewModelProvider).agencyId ?? "";
  //     // notifier.driverList(agencyId);
  //     // notifier.vehicleList(agencyId);
  //     notifier.customerList(agencyId);
  //   });

  //    if (widget.booking != null) {
  //     final b = widget.booking!;
  //     pickup.text = b.pickupLocation ?? "";
  //     drop.text = b.dropLocation ?? "";
  //     distance.text = b.distance?.toString() ?? "";
  //     fuelRequired.text = b.fuelRequired?.toString() ?? "";
  //     tripCharges.text = b.amountApprove?.toString() ?? "";
  //     selectedVehicleId = b.vehicleId;
  //     selectedDriverId = b.driverId;
  //     selectedCustomerId = b.customerId;
  //     startDateValue = b.startDateTime;
  //     endDateValue = b.endDateTime;

  //      // 🔥 Strip UTC/timezone by converting to local and rebuilding clean DateTime
  // if (b.startDateTime != null) {
  //   final s = b.startDateTime!.toLocal();
  //   startDateValue = DateTime(s.year, s.month, s.day, s.hour, s.minute);
  //   startDate.text = DateFormat("MMM dd, yyyy • hh:mm a").format(startDateValue!);
  // }

  // if (b.endDateTime != null) {
  //   final e = b.endDateTime!.toLocal();
  //   endDateValue = DateTime(e.year, e.month, e.day, e.hour, e.minute);
  //   endDate.text = DateFormat("MMM dd, yyyy • hh:mm a").format(endDateValue!);
  // }
  //   }

  //     // 🔥 Edit mode: dates already set, fetch immediately
  //   if (widget.booking != null &&
  //       widget.booking!.startDateTime != null &&
  //       widget.booking!.endDateTime != null) {
  //         final notifier = ref.read(tripBookingViewModelProvider.notifier);
  //     notifier.fetchAvailableVehicles(
  //       ref.read(loginViewModelProvider).agencyId?? '',
  //       widget.booking!.startDateTime!,
  //       widget.booking!.endDateTime!,
  //     );
  //     notifier.fetchAvailableDrivers(
  //       ref.read(loginViewModelProvider).agencyId?? '',
  //       widget.booking!.startDateTime!,
  //       widget.booking!.endDateTime!,
  //     );
  //   }

  // }

  @override
  void initState() {
    super.initState();

    if (widget.booking != null) {
      final b = widget.booking!;
      pickup.text = b.pickupLocation ?? "";
      drop.text = b.dropLocation ?? "";
      distance.text = b.distance?.toString() ?? "";
      fuelRequired.text = b.fuelRequired?.toString() ?? "";
      tripCharges.text = b.amountApprove?.toString() ?? "";
      selectedVehicleId = b.vehicleId;
      selectedDriverId = b.driverId;
      selectedCustomerId = b.customerId;

      // 🔥 Clean datetime (removes UTC Z)
      if (b.startDateTime != null) {
        final s = b.startDateTime!;
        startDateValue = DateTime(s.year, s.month, s.day, s.hour, s.minute);
        startDate.text = DateFormat(
          "MMM dd, yyyy • hh:mm a",
        ).format(startDateValue!);
      }

      if (b.endDateTime != null) {
        final e = b.endDateTime!;
        endDateValue = DateTime(e.year, e.month, e.day, e.hour, e.minute);
        endDate.text = DateFormat(
          "MMM dd, yyyy • hh:mm a",
        ).format(endDateValue!);
      }
    }

    Future.microtask(() {
      final notifier = ref.read(tripBookingViewModelProvider.notifier);
      final agencyId = ref.read(loginViewModelProvider).agencyId ?? "";

      notifier.customerList(agencyId);

      // 🔥 Use cleaned startDateValue/endDateValue NOT widget.booking!.startDateTime
      if (widget.booking != null &&
          startDateValue != null &&
          endDateValue != null) {
        notifier.fetchAvailableVehicles(
          agencyId,
          startDateValue!,
          endDateValue!,
          widget.booking!.tripId!,
        );
        notifier.fetchAvailableDrivers(
          agencyId,
          startDateValue!,
          endDateValue!,
          widget.booking?.tripId,
        );
      }
    });
  }

  // Future<void> _pickDateTime(bool isStart) async {
  //   final date = await showDatePicker(
  //     context: context,
  //     firstDate: DateTime(2020),
  //     lastDate: DateTime(2035),
  //     initialDate: DateTime.now(),
  //     builder: (ctx, child) => Theme(
  //       data: Theme.of(ctx).copyWith(
  //         colorScheme: const ColorScheme.light(
  //           primary: _primary,
  //           onPrimary: Colors.white,
  //           surface: _cardBg,
  //         ),
  //       ),
  //       child: child!,
  //     ),
  //   );
  //   if (date == null) return;

  //   final time = await showTimePicker(
  //     context: context,
  //     initialTime: TimeOfDay.now(),
  //     builder: (ctx, child) => Theme(
  //       data: Theme.of(ctx).copyWith(
  //         colorScheme: const ColorScheme.light(primary: _primary),
  //       ),
  //       child: child!,
  //     ),
  //   );
  //   if (time == null) return;

  //   final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
  //   setState(() {
  //     if (isStart) {
  //       startDateValue = dt;
  //       startDate.text = DateFormat("MMM dd, yyyy • hh:mm a").format(dt);
  //     } else {
  //       endDateValue = dt;
  //       endDate.text = DateFormat("MMM dd, yyyy • hh:mm a").format(dt);
  //     }
  //   });
  // }

  Future<void> _pickDateTime(bool isStart) async {
    final date = await await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      initialDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _primary,
            onPrimary: Colors.white,
            surface: _cardBg,
          ),
        ),
        child: child!,
      ),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(
          ctx,
        ).copyWith(colorScheme: const ColorScheme.light(primary: _primary)),
        child: child!,
      ),
    );
    if (time == null) return;

    final dt = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    setState(() {
      if (isStart) {
        startDateValue = dt;
        startDate.text = DateFormat("MMM dd, yyyy • hh:mm a").format(dt);
      } else {
        endDateValue = dt;
        endDate.text = DateFormat("MMM dd, yyyy • hh:mm a").format(dt);
      }
    });

    // 🔥 IMPORTANT: Only fetch when BOTH dates selected
    if (startDateValue != null && endDateValue != null) {
      _loadAvailableResources();
    }
  }

  void _loadAvailableResources() {
    final agencyId = ref.read(loginViewModelProvider).agencyId ?? "";
    final notifier = ref.read(tripBookingViewModelProvider.notifier);

    // setState(() {
    //   selectedVehicleId = null;
    //   selectedDriverId = null;
    // });

    notifier.fetchAvailableVehicles(
      agencyId,
      startDateValue!,
      endDateValue!,
      null,
    );

    notifier.fetchAvailableDrivers(
      agencyId,
      startDateValue!,
      endDateValue!,
      null,
    );
  }

  Future<void> _saveTrip() async {
    if (!_formKey.currentState!.validate()) return;

    if (startDateValue == null || endDateValue == null) {
      _showSnack("Please select start and end date & time");
      return;
    }

    if (selectedVehicleId == null ||
        selectedDriverId == null ||
        selectedCustomerId == null) {
      _showSnack("Please select vehicle, driver and customer");
      return;
    }

    setState(() => _isSaving = true);

    final booking = TripBooking(
      tripId: widget.booking?.tripId, // 🔥 IMPORTANT
      vehicleid: selectedVehicleId!,
      driverid: selectedDriverId!,
      customerid: selectedCustomerId!,
      pickuplocation: pickup.text,
      droplocation: drop.text,
      distance: double.parse(distance.text),
      fuelrequired: double.parse(fuelRequired.text),
      tripcharges: double.parse(tripCharges.text),
      startDateTime: startDateValue,
      endDateTime: endDateValue,
      status: widget.booking?.status ?? 3,
      bookingdate: widget.booking?.bookingDate ?? DateTime.now(),
      agencyId: ref.read(loginViewModelProvider).agencyId ?? "",
    );

    final notifier = ref.read(tripBookingViewModelProvider.notifier);

    if (widget.booking != null) {
      // 🔥 EDIT MODE
      await notifier.updateTripBooking(widget.booking?.tripId ?? 0, booking);
    } else {
      // ADD MODEj
      await notifier.addTripBooking(booking);
    }

    setState(() => _isSaving = false);

    if (mounted) Navigator.pop(context);
  }

  // ── Shared input decoration ──────────────────────────────────────────────────
  InputDecoration _inputDeco(String label, IconData icon, {String? prefix}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: _textMid, fontSize: 13.5),
      prefixIcon: Icon(icon, size: 18, color: _textMid),
      prefixText: prefix,
      prefixStyle: const TextStyle(
        fontWeight: FontWeight.w700,
        color: _primary,
        fontSize: 14,
      ),
      filled: true,
      fillColor: _surface,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _primary, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE63946)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE63946), width: 1.6),
      ),
    );
  }

  // ── Section card wrapper ─────────────────────────────────────────────────────
  Widget _card({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.07),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icon, size: 16, color: color),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  // ── Text field helper ────────────────────────────────────────────────────────
  Widget _field({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType? keyboardType,
    String? prefix,
    List<TextInputFormatter>? formatters,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
      inputFormatters: formatters,
      style: const TextStyle(
        color: _textDark,
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
      validator: (v) =>
          (v == null || v.isEmpty) ? "This field is required" : null,
      decoration: _inputDeco(label, icon, prefix: prefix),
    );
  }

  // ── Dropdown helper ──────────────────────────────────────────────────────────
  Widget _dropdown<T>({
    required String label,
    required IconData icon,
    required Color color,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value, // 🔥 was: initialValue: value
      items: items,
      onChanged: onChanged,
      validator: (v) => v == null ? "Please select an option" : null,
      icon: Icon(Icons.keyboard_arrow_down_rounded, color: color),
      dropdownColor: _cardBg,
      style: const TextStyle(
        color: _textDark,
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
      decoration: _inputDeco(label, icon),
    );
  }

  Widget _disabledDropdown(
    String label,
    IconData icon, {
    String hint = "Select start & end date first",
  }) {
    return IgnorePointer(
      child: DropdownButtonFormField<int>(
        initialValue: null,
        items: const [],
        onChanged: null,
        hint: Text(
          hint,
          style: const TextStyle(fontSize: 13, color: Color(0xFFAAAAAA)),
        ),
        icon: const Icon(
          Icons.keyboard_arrow_down_rounded,
          color: Color(0xFFAAAAAA),
        ),
        decoration: _inputDeco(label, icon),
      ),
    );
  }

  Widget _emptyField(String label, IconData icon, String msg) {
    return IgnorePointer(
      child: DropdownButtonFormField<int>(
        initialValue: null,
        items: const [],
        onChanged: null,
        hint: Text(
          msg,
          style: const TextStyle(
            fontSize: 13,
            color: Color.fromARGB(255, 204, 44, 44),
          ),
        ),
        icon: const Icon(
          Icons.keyboard_arrow_down_rounded,
          color: Color(0xFFAAAAAA),
        ),
        decoration: _inputDeco(label, icon),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tripBookingViewModelProvider);
    final isEdit = widget.booking != null;
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 600;
    final hPad = isWide ? 24.0 : 16.0;

    return Scaffold(
      backgroundColor: _surface,
      body: CustomScrollView(
        slivers: [
          // ── HERO APP BAR ─────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            backgroundColor: _primary,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_primaryDark, _primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                isEdit
                                    ? Icons.edit_road_outlined
                                    : Icons.add_road_outlined,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isEdit ? "Edit Booking" : "New Booking",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                Text(
                                  isEdit
                                      ? "Update your trip details"
                                      : "Fill in the trip details below",
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── FORM BODY ────────────────────────────────────────────────────────
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              hPad,
              20,
              hPad,
              100 + MediaQuery.of(context).padding.bottom,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // ── ROUTE ───────────────────────────────────────────────
                      _card(
                        title: "Route Details",
                        icon: Icons.route_rounded,
                        color: _primary,
                        children: [
                          _field(
                            label: "Pickup Location",
                            controller: pickup,
                            icon: Icons.trip_origin,
                          ),
                          const SizedBox(height: 12),
                          // Route line visual connector
                          Row(
                            children: [
                              const SizedBox(width: 8),
                              Column(
                                children: [
                                  Container(
                                    width: 2,
                                    height: 12,
                                    color: Colors.grey.shade200,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          _field(
                            label: "Drop Location",
                            controller: drop,
                            icon: Icons.location_on_outlined,
                          ),
                          const SizedBox(height: 14),
                          // Distance + Fuel side by side on wide, stacked on small
                          isWide
                              ? Row(
                                  children: [
                                    Expanded(
                                      child: _field(
                                        label: "Distance (KM)",
                                        controller: distance,
                                        icon: Icons.straighten,
                                        keyboardType: TextInputType.number,
                                        formatters: [
                                          FilteringTextInputFormatter.allow(
                                            RegExp(r'^\d+\.?\d*'),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _field(
                                        label: "Fuel Required (L)",
                                        controller: fuelRequired,
                                        icon: Icons.local_gas_station_outlined,
                                        keyboardType: TextInputType.number,
                                        formatters: [
                                          FilteringTextInputFormatter.allow(
                                            RegExp(r'^\d+\.?\d*'),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  children: [
                                    _field(
                                      label: "Distance (KM)",
                                      controller: distance,
                                      icon: Icons.straighten,
                                      keyboardType: TextInputType.number,
                                      formatters: [
                                        FilteringTextInputFormatter.allow(
                                          RegExp(r'^\d+\.?\d*'),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    _field(
                                      label: "Fuel Required (L)",
                                      controller: fuelRequired,
                                      icon: Icons.local_gas_station_outlined,
                                      keyboardType: TextInputType.number,
                                      formatters: [
                                        FilteringTextInputFormatter.allow(
                                          RegExp(r'^\d+\.?\d*'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                          const SizedBox(height: 12),
                          _field(
                            label: "Trip Charges",
                            controller: tripCharges,
                            icon: Icons.currency_rupee,
                            prefix: "₹ ",
                            keyboardType: TextInputType.number,
                            formatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d+\.?\d*'),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // ── SCHEDULE ─────────────────────────────────────────────
                      _card(
                        title: "Trip Schedule",
                        icon: Icons.calendar_month_outlined,
                        color: const Color(0xFF7209B7),
                        children: [
                          isWide
                              ? Row(
                                  children: [
                                    Expanded(
                                      child: _field(
                                        label: "Start Date & Time",
                                        controller: startDate,
                                        icon: Icons.play_circle_outline,
                                        readOnly: true,
                                        onTap: () => _pickDateTime(true),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _field(
                                        label: "End Date & Time",
                                        controller: endDate,
                                        icon: Icons.stop_circle_outlined,
                                        readOnly: true,
                                        onTap: () => _pickDateTime(false),
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  children: [
                                    _field(
                                      label: "Start Date & Time",
                                      controller: startDate,
                                      icon: Icons.play_circle_outline,
                                      readOnly: true,
                                      onTap: () => _pickDateTime(true),
                                    ),
                                    const SizedBox(height: 12),
                                    _field(
                                      label: "End Date & Time",
                                      controller: endDate,
                                      icon: Icons.stop_circle_outlined,
                                      readOnly: true,
                                      onTap: () => _pickDateTime(false),
                                    ),
                                  ],
                                ),

                          // Duration preview
                          if (startDateValue != null &&
                              endDateValue != null) ...[
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF7209B7,
                                ).withOpacity(0.07),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(
                                    0xFF7209B7,
                                  ).withOpacity(0.2),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.timelapse,
                                    size: 15,
                                    color: Color(0xFF7209B7),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Duration: ${_formatDuration(startDateValue!, endDateValue!)}",
                                    style: const TextStyle(
                                      color: Color(0xFF7209B7),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 16),

                      // ───────────────────────── ASSIGNMENTS ────────────────────────────
                      _card(
                        title: "Assignments",
                        icon: Icons.groups_2_outlined,
                        color: const Color(0xFF06D6A0),
                        children: [
                          // // Vehicle
                          // state.availableVehicles.when(
                          //   data: (vehicles) => _dropdown<int>(
                          //     label: "Vehicle",
                          //     icon: Icons.directions_car_outlined,
                          //     color: const Color(0xFF06D6A0),
                          //     value: selectedVehicleId,
                          //     items: vehicles
                          //         .map((e) => DropdownMenuItem<int>(
                          //               value: e.vehicleId,
                          //               child: Text(e.name ?? ""),
                          //             ))
                          //         .toList(),
                          //     onChanged: (v) =>
                          //         setState(() => selectedVehicleId = v),
                          //   ),
                          //   loading: () => _loadingField("Loading vehicles..."),
                          //   error: (e, _) => _errorField("Failed to load vehicles"),
                          // ),

                          // const SizedBox(height: 12),

                          // // Driver
                          // state.availableDrivers.when(
                          //   data: (drivers) => _dropdown<int>(
                          //     label: "Driver",
                          //     icon: Icons.drive_eta_outlined,
                          //     color: const Color(0xFF06D6A0),
                          //     value: selectedDriverId,
                          //     items: drivers
                          //         .map((e) => DropdownMenuItem<int>(
                          //               value: e.driverId,
                          //               child: Text(e.name ?? ""),
                          //             ))
                          //         .toList(),
                          //     onChanged: (v) =>
                          //         setState(() => selectedDriverId = v),
                          //   ),
                          //   loading: () => _loadingField("Loading drivers..."),
                          //   error: (e, _) => _errorField("Failed to load drivers"),
                          // ),

                          // Vehicle
                          if (startDateValue == null || endDateValue == null)
                            _disabledDropdown(
                              "Vehicle",
                              Icons.directions_car_outlined,
                              hint:
                                  "Enter trip schedule to see available vehicles",
                            )
                          else
                            state.availableVehicles.when(
                              data: (vehicles) {
                                if (vehicles.isEmpty) {
                                  return _emptyField(
                                    "Vehicle",
                                    Icons.directions_car_outlined,
                                    "No vehicle available for selected schedule",
                                  );
                                }
                                // 🔥 Guard: reset if selected value not in new list
                                final validVehicleId =
                                    vehicles.any(
                                      (e) => e.vehicleId == selectedVehicleId,
                                    )
                                    ? selectedVehicleId
                                    : null;

                                return _dropdown<int>(
                                  label: "Vehicle",
                                  icon: Icons.directions_car_outlined,
                                  color: const Color(0xFF06D6A0),
                                  value: validVehicleId,
                                  items: vehicles
                                      .map(
                                        (e) => DropdownMenuItem<int>(
                                          value: e.vehicleId,
                                          child: Text(
                                            "${e.name ?? ""} - ${e.number ?? "No Vehicle"}",
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (v) =>
                                      setState(() => selectedVehicleId = v),
                                );
                              },
                              loading: () => _loadingField(
                                "Fetching available vehicles...",
                              ),
                              error: (e, _) =>
                                  _errorField("Failed to load vehicles"),
                            ),

                          const SizedBox(height: 12),

                          // Driver
                          if (startDateValue == null || endDateValue == null)
                            _disabledDropdown(
                              "Driver",
                              Icons.person_pin_rounded,
                              hint:
                                  "Enter trip schedule to see available drivers",
                            )
                          else
                            state.availableDrivers.when(
                              data: (drivers) {
                                if (drivers.isEmpty) {
                                  return _emptyField(
                                    "Driver",
                                    Icons.drive_eta_outlined,
                                    "No driver available for selected schedule",
                                  );
                                }
                                final validDriverId =
                                    drivers.any(
                                      (e) => e.driverId == selectedDriverId,
                                    )
                                    ? selectedDriverId
                                    : null;

                                return _dropdown<int>(
                                  label: "Driver",
                                  icon: Icons.drive_eta_outlined,
                                  color: const Color(0xFF06D6A0),
                                  value: validDriverId,
                                  items: drivers
                                      .map(
                                        (e) => DropdownMenuItem<int>(
                                          value: e.driverId,
                                          child: Text(e.name ?? ""),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (v) =>
                                      setState(() => selectedDriverId = v),
                                );
                              },
                              loading: () => _loadingField(
                                "Fetching available drivers...",
                              ),
                              error: (e, _) =>
                                  _errorField("Failed to load drivers"),
                            ),

                          const SizedBox(height: 12),

                          // Customer
                          state.fetchCustomerList.when(
                            data: (customers) {
                              // MATCH AFTER API LOAD
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (widget.booking != null &&
                                    selectedCustomerId != null) {
                                  final exists = customers.any(
                                    (c) => c.customerId == selectedCustomerId,
                                  );

                                  if (!exists) {
                                    setState(() {
                                      selectedCustomerId = null;
                                    });
                                  } else {
                                    setState(() {});
                                  }
                                }
                              });

                              return _dropdown<int>(
                                label: "Customer",
                                icon: Icons.person_outline_rounded,
                                color: const Color(0xFF06D6A0),
                                value:
                                    customers.any(
                                      (c) => c.customerId == selectedCustomerId,
                                    )
                                    ? selectedCustomerId
                                    : null,
                                items: customers
                                    .map(
                                      (e) => DropdownMenuItem<int>(
                                        value: e.customerId,
                                        child: Text(e.name ?? ""),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => selectedCustomerId = v),
                              );
                            },
                            loading: () =>
                                _loadingField("Loading customers..."),
                            error: (e, _) =>
                                _errorField("Failed to load customers"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),

      // ── STICKY BOTTOM SAVE BUTTON ───────────────────────────────────────────
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
          hPad,
          12,
          hPad,
          16 + MediaQuery.of(context).padding.bottom,
        ),
        decoration: BoxDecoration(
          color: _cardBg,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: GestureDetector(
          onTap: _isSaving ? null : _saveTrip,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: _isSaving
                  ? LinearGradient(
                      colors: [Colors.grey.shade400, Colors.grey.shade300],
                    )
                  : const LinearGradient(
                      colors: [_primaryDark, _primary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: _isSaving
                  ? []
                  : [
                      BoxShadow(
                        color: _primary.withOpacity(0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 5),
                      ),
                    ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isSaving)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                else
                  Icon(
                    isEdit ? Icons.update_rounded : Icons.check_circle_outline,
                    color: Colors.white,
                    size: 20,
                  ),
                const SizedBox(width: 10),
                Text(
                  _isSaving
                      ? "Saving..."
                      : isEdit
                      ? "Update Trip"
                      : "Save Trip",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFE63946),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String _formatDuration(DateTime start, DateTime end) {
    final diff = end.difference(start);
    if (diff.isNegative) return "Invalid range";
    final h = diff.inHours;
    final m = diff.inMinutes.remainder(60);
    if (h == 0) return "${m}m";
    return "${h}h ${m}m";
  }

  Widget _loadingField(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _errorField(String msg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F0),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE63946).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 16, color: Color(0xFFE63946)),
          const SizedBox(width: 10),
          Text(
            msg,
            style: const TextStyle(
              color: Color(0xFFE63946),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
