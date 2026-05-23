import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:travel_agency_app/Screens/add_driver.dart';
import 'package:travel_agency_app/Screens/add_vehicle.dart';
import 'package:travel_agency_app/core/theme/app_colors.dart';
import 'package:travel_agency_app/domain/models/booking_info.dart';
import 'package:travel_agency_app/domain/models/customers.dart';
import 'package:travel_agency_app/domain/models/route_fare_suggestion.dart';
import 'package:travel_agency_app/domain/models/tripbooking_info.dart';
import 'package:travel_agency_app/presentation/providers/viewmodel_provider.dart';

// ─── Design Tokens ─────────────────────────────────────────────────────────
class _C {
  static const bg = Color(0xFFF2F4F8);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceLight = Color(0xFFF0F3FA);
  static const accent = AppColors.brandPrimary;
  static const accentSoft = AppColors.brandSoft;
  static const accentDark = AppColors.brandPrimaryDark;
  static const text1 = Color(0xFF1A1D2E);
  static const text2 = Color(0xFF7B82A0);
  static const divider = Color(0xFFE4E8F0);
  static const green = Color(0xFF2DB976);
  static const greenSoft = Color(0xFFE8F8F1);
  static const red = Color(0xFFE53935);
  static const redSoft = Color(0xFFFFEBEE);
  static const orange = Color(0xFFE67E22);
  static const orangeSoft = Color(0xFFFEF0E6);
  static const purple = Color(0xFF7C3AED);
  static const purpleSoft = Color(0xFFEDE9FE);
}

// ─── Custom Dropdown Item Model ────────────────────────────────────────────
class _DropItem<T> {
  final T value;
  final String label;
  final String? subtitle;
  final IconData? icon;
  final Color? color;
  _DropItem({
    required this.value,
    required this.label,
    this.subtitle,
    this.icon,
    this.color,
  });
}

class TripBookingForm extends ConsumerStatefulWidget {
  final BookingInfo? booking;
  const TripBookingForm({super.key, this.booking});

  @override
  ConsumerState<TripBookingForm> createState() => _TripBookingFormState();
}

class _TripBookingFormState extends ConsumerState<TripBookingForm>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final pickup = TextEditingController();
  final drop = TextEditingController();
  final pickupFocus = FocusNode();
  final dropFocus = FocusNode();
  final distance = TextEditingController();
  final fuelReq = TextEditingController();
  final charges = TextEditingController();
  final startDate = TextEditingController();
  final endDate = TextEditingController();

  DateTime? startDt, endDt;
  int? selVehicle, selDriver, selCustomer;
  bool _saving = false;

  String? selVehicleLabel, selDriverLabel;

  // Inline customer form (replaces the customer dropdown).
  // `selCustomer` is set when an existing customer is picked from autocomplete;
  // it gets cleared the moment the admin edits any of these fields, so the
  // save path knows to create a new customer instead of reusing one.
  final customerName = TextEditingController();
  final customerPhone = TextEditingController();
  final customerAddress = TextEditingController();
  final customerNameFocus = FocusNode();
  final customerPhoneFocus = FocusNode();
  bool _suppressCustomerFieldListener = false;

  late AnimationController _staggerCtrl;
  late List<Animation<double>> _anims;

  @override
  void initState() {
    super.initState();

    _staggerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _anims = List.generate(
      5,
      (i) => CurvedAnimation(
        parent: _staggerCtrl,
        curve: Interval(
          i * 0.12,
          (i * 0.12 + 0.5).clamp(0, 1),
          curve: Curves.easeOutCubic,
        ),
      ),
    );

    if (widget.booking != null) {
      final b = widget.booking!;
      pickup.text = b.pickupLocation ?? '';
      drop.text = b.dropLocation ?? '';
      distance.text = b.distance?.toString() ?? '';
      fuelReq.text = b.fuelRequired?.toString() ?? '';
      charges.text = b.amountApprove?.toString() ?? '';
      selVehicle = b.vehicleId;
      selDriver = b.driverId;
      selCustomer = b.customerId;
      if (b.startDateTime != null) {
        final s = b.startDateTime!;
        startDt = DateTime(s.year, s.month, s.day, s.hour, s.minute);
        startDate.text = DateFormat(
          "MMM dd, yyyy  •  hh:mm a",
        ).format(startDt!);
      }
      if (b.endDateTime != null) {
        final e = b.endDateTime!;
        endDt = DateTime(e.year, e.month, e.day, e.hour, e.minute);
        endDate.text = DateFormat("MMM dd, yyyy  •  hh:mm a").format(endDt!);
      }
    }

    // Recompute the fare suggestion whenever the route text changes.
    pickup.addListener(_onRouteChanged);
    drop.addListener(_onRouteChanged);

    // Detach from the picked customer the moment the admin edits any of the
    // autofilled fields — saving will then create a new customer instead.
    customerName.addListener(_onCustomerFieldChanged);
    customerPhone.addListener(_onCustomerFieldChanged);
    customerAddress.addListener(_onCustomerFieldChanged);

    Future.microtask(() {
      final n = ref.read(tripBookingViewModelProvider.notifier);
      final aid = ref.read(loginViewModelProvider).agencyId ?? '';
      n.customerList(aid);
      n.loadRouteHistory(aid);
      if (widget.booking != null && startDt != null && endDt != null) {
        n.fetchAvailableVehicles(
          aid,
          startDt!,
          endDt!,
          widget.booking!.tripId!,
        );
        n.fetchAvailableDrivers(aid, startDt!, endDt!, widget.booking?.tripId);
      }
    });
  }

  @override
  void dispose() {
    pickup.removeListener(_onRouteChanged);
    drop.removeListener(_onRouteChanged);
    customerName.removeListener(_onCustomerFieldChanged);
    customerPhone.removeListener(_onCustomerFieldChanged);
    customerAddress.removeListener(_onCustomerFieldChanged);
    customerName.dispose();
    customerPhone.dispose();
    customerAddress.dispose();
    pickupFocus.dispose();
    dropFocus.dispose();
    customerNameFocus.dispose();
    customerPhoneFocus.dispose();
    _staggerCtrl.dispose();
    super.dispose();
  }

  // Rebuild so the fare-suggestion chip reflects the current route text.
  void _onRouteChanged() {
    if (mounted) setState(() {});
  }

  // Autofill all three customer fields from a picked suggestion. The listener
  // suppression flag prevents the field-change handler from immediately
  // clearing selCustomer in response to our own writes.
  void _applyCustomer(Customer c) {
    _suppressCustomerFieldListener = true;
    customerName.text = c.name ?? '';
    customerPhone.text = c.phone ?? '';
    customerAddress.text = c.address ?? '';
    _suppressCustomerFieldListener = false;
    setState(() => selCustomer = c.customerId);
  }

  void _onCustomerFieldChanged() {
    if (_suppressCustomerFieldListener) return;
    if (selCustomer == null) return;
    // Any manual edit after an autofill detaches us from the linked customer:
    // saving will create a NEW customer with the typed values.
    setState(() => selCustomer = null);
  }

  // RawAutocomplete-backed input that searches the customer list and, on
  // selection, autofills every customer field via [_applyCustomer]. Both the
  // name field and the phone field use this — the difference is the matcher.
  Widget _customerAutocompleteField({
    required TextEditingController ctrl,
    required FocusNode focusNode,
    required String label,
    required IconData icon,
    required List<Customer> customers,
    required bool Function(Customer c, String query) matcher,
    String? Function(String?)? validator,
    TextInputType? keyboard,
    List<TextInputFormatter>? fmt,
  }) {
    return RawAutocomplete<Customer>(
      textEditingController: ctrl,
      focusNode: focusNode,
      displayStringForOption: (c) =>
          (label.toLowerCase().contains('phone') ||
                  label.toLowerCase().contains('mobile'))
              ? (c.phone ?? '')
              : (c.name ?? ''),
      optionsBuilder: (value) {
        final q = value.text.trim().toLowerCase();
        if (q.isEmpty) return const Iterable<Customer>.empty();
        return customers.where((c) => matcher(c, q)).take(8);
      },
      onSelected: (c) {
        _applyCustomer(c);
        focusNode.unfocus();
      },
      fieldViewBuilder: (context, fieldCtrl, fieldFocus, onSubmit) {
        return _inputField(
          label: label,
          ctrl: fieldCtrl,
          icon: icon,
          iconColor: _C.orange,
          iconBg: _C.orangeSoft,
          focusNode: fieldFocus,
          keyboard: keyboard,
          fmt: fmt,
          validator: validator,
          onFieldSubmitted: (_) => onSubmit(),
          suffixIcon: GestureDetector(
            onTap: () {
              if (!fieldFocus.hasFocus) {
                fieldFocus.requestFocus();
              }
            },
            child: const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(
                Icons.search_rounded,
                size: 18,
                color: _C.text2,
              ),
            ),
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(12),
            color: _C.surface,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240),
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: options.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: _C.divider),
                itemBuilder: (_, i) {
                  final c = options.elementAt(i);
                  return InkWell(
                    onTap: () => onSelected(c),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: _C.orangeSoft,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.person_rounded,
                              size: 14,
                              color: _C.orange,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c.name ?? '—',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: _C.text1,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.phone_rounded,
                                      size: 11,
                                      color: _C.text2,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      c.phone ?? '—',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: _C.text2,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                if ((c.address ?? '').trim().isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Padding(
                                        padding: EdgeInsets.only(top: 1),
                                        child: Icon(
                                          Icons.location_on_rounded,
                                          size: 11,
                                          color: _C.text2,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          c.address!.trim(),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: _C.text2,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.north_west_rounded,
                            size: 14,
                            color: _C.text2,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  // Whole rupees when integral, else 2 decimals (kept parseable for the field).
  String _money(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  // Dedup pickup/drop strings case-insensitively, keeping the original
  // casing of the FIRST occurrence and preserving order from the history.
  List<String> _distinctLocations(Iterable<String?> input) {
    final seen = <String>{};
    final result = <String>[];
    for (final raw in input) {
      final s = raw?.trim();
      if (s == null || s.isEmpty) continue;
      final key = s.toLowerCase();
      if (seen.add(key)) result.add(s);
    }
    return result;
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  FARE MEMORY CHIP  ← suggests last/avg charge for this customer + route
  // ══════════════════════════════════════════════════════════════════════════
  Widget _fareChip(RouteFareSuggestion? fare) {
    if (fare == null) return const SizedBox.shrink();
    final last = _money(fare.lastCharge);
    final avg = _money(fare.averageCharge);
    final n = fare.tripCount;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: GestureDetector(
        onTap: () => setState(() => charges.text = _money(fare.lastCharge)),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: _C.purpleSoft,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _C.purple.withOpacity(0.25)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _C.purple.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.history_rounded,
                  size: 14,
                  color: _C.purple,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Last fare ₹$last for this route",
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: _C.text1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Avg ₹$avg  ·  $n past trip${n == 1 ? '' : 's'} on this route",
                      style: const TextStyle(fontSize: 11, color: _C.text2),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _C.purple,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "Use",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── DateTime Picker ────────────────────────────────────────────────────────
  Future<void> _pickDt(bool isStart) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Block past dates. End date additionally can't be before the picked start.
    final earliest = isStart
        ? today
        : (startDt != null && startDt!.isAfter(today))
            ? DateTime(startDt!.year, startDt!.month, startDt!.day)
            : today;
    final existing = isStart ? startDt : endDt;
    final initial = (existing != null && !existing.isBefore(earliest))
        ? existing
        : earliest;
    final date = await showDatePicker(
      context: context,
      firstDate: earliest,
      lastDate: DateTime(2035),
      initialDate: initial,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _C.accent,
            onPrimary: Colors.white,
            surface: _C.surface,
            onSurface: _C.text1,
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
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _C.accent,
            onPrimary: Colors.white,
            surface: _C.surface,
          ),
        ),
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
        startDt = dt;
        startDate.text = DateFormat("MMM dd, yyyy  •  hh:mm a").format(dt);
      } else {
        endDt = dt;
        endDate.text = DateFormat("MMM dd, yyyy  •  hh:mm a").format(dt);
      }
    });
    if (startDt != null && endDt != null) _fetch();
  }

  void _fetch() {
    final aid = ref.read(loginViewModelProvider).agencyId ?? '';
    final n = ref.read(tripBookingViewModelProvider.notifier);
    n.fetchAvailableVehicles(aid, startDt!, endDt!, null);
    n.fetchAvailableDrivers(aid, startDt!, endDt!, null);
  }

  Future<void> _goAddVehicle() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddVehiclePage()),
    );

    if (mounted && startDt != null && endDt != null) {
      _fetch();
    }
  }

  Future<void> _goAddDriver() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddDriverPage()),
    );

    if (mounted && startDt != null && endDt != null) {
      _fetch();
    }
  }

  // ── Save ───────────────────────────────────────────────────────────────────
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (startDt == null || endDt == null) {
      _snack("Select start & end date/time");
      return;
    }
    if (selVehicle == null || selDriver == null) {
      _snack("Select vehicle & driver");
      return;
    }
    setState(() => _saving = true);
    final agencyId = ref.read(loginViewModelProvider).agencyId ?? '';

    // selCustomer is null when the admin typed fresh customer details (either
    // skipping the autocomplete entirely or editing autofilled values). Create
    // the customer in the DB first so we have a real customerId for the trip.
    int? customerId = selCustomer;
    if (customerId == null) {
      final newCustomer = Customer(
        customerId: 0,
        name: customerName.text.trim(),
        phone: customerPhone.text.trim(),
        address: customerAddress.text.trim(),
        agencyId: agencyId,
      );
      try {
        customerId = await ref
            .read(customerViewModelProvider.notifier)
            .addcustomer(newCustomer);
      } catch (e) {
        if (!mounted) return;
        setState(() => _saving = false);
        _snack("Failed to save customer");
        return;
      }
      // Refresh the cached customer list so subsequent searches see the new one.
      try {
        await ref
            .read(tripBookingViewModelProvider.notifier)
            .customerList(agencyId);
      } catch (_) {}
    }

    if (customerId == 0) {
      if (!mounted) return;
      setState(() => _saving = false);
      _snack("Failed to save customer");
      return;
    }

    final bk = TripBooking(
      tripId: widget.booking?.tripId,
      vehicleid: selVehicle!,
      driverid: selDriver!,
      customerid: customerId,
      pickuplocation: pickup.text,
      droplocation: drop.text,
      distance: double.parse(distance.text),
      fuelrequired: double.parse(fuelReq.text),
      tripcharges: double.parse(charges.text),
      startDateTime: startDt,
      endDateTime: endDt,
      status: widget.booking?.status ?? 3,
      bookingdate: widget.booking?.bookingDate ?? DateTime.now(),
      agencyId: agencyId,
    );
    final n = ref.read(tripBookingViewModelProvider.notifier);
    if (widget.booking != null)
      await n.updateTripBooking(widget.booking?.tripId ?? 0, bk);
    else
      await n.addTripBooking(bk);
    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.pop(context);
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tripBookingViewModelProvider);
    final isEdit = widget.booking != null;
    final pb = MediaQuery.of(context).padding.bottom;

    // Fare memory: last/avg charge billed for this exact route on any past
    // (completed) trip, regardless of which customer it was.
    final history =
        state.routeHistory.asData?.value ?? const <BookingInfo>[];
    final fare = RouteFareSuggestion.fromHistory(
      history,
      pickup: pickup.text,
      drop: drop.text,
    );

    // Location suggestions sourced from past pickup/drop strings in history.
    final pickupOptions =
        _distinctLocations(history.map((t) => t.pickupLocation));
    final dropOptions =
        _distinctLocations(history.map((t) => t.dropLocation));

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: _C.bg,
      body: SafeArea(
        child: Column(
          children: [
            _topBar(isEdit),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + pb),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // ── 01  CUSTOMER ─────────────────────────────────────────
                      _FadeSlide(
                        anim: _anims[0],
                        child: _sectionCard(
                          icon: Icons.person_outline_rounded,
                          label: "Customer Details",
                          iconColor: _C.orange,
                          iconBg: _C.orangeSoft,
                          badge: "01",
                          child: state.fetchCustomerList.when(
                            loading: () =>
                                _loadingTile("Loading customers..."),
                            error: (_, __) =>
                                _errorTile("Failed to load customers"),
                            data: (customers) {
                              // Edit mode: hydrate the inline fields from the
                              // booking's customer once the list loads.
                              if (widget.booking != null &&
                                  widget.booking!.customerId != null &&
                                  selCustomer == null &&
                                  customerName.text.isEmpty &&
                                  customerPhone.text.isEmpty) {
                                final match = customers.where(
                                  (c) =>
                                      c.customerId ==
                                      widget.booking!.customerId,
                                );
                                if (match.isNotEmpty) {
                                  WidgetsBinding.instance
                                      .addPostFrameCallback((_) {
                                        if (mounted) {
                                          _applyCustomer(match.first);
                                        }
                                      });
                                }
                              }

                              return Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  _customerAutocompleteField(
                                    ctrl: customerPhone,
                                    focusNode: customerPhoneFocus,
                                    label: "Mobile Number",
                                    icon: Icons.phone_rounded,
                                    customers: customers,
                                    keyboard: TextInputType.phone,
                                    fmt: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(10),
                                    ],
                                    matcher: (c, q) =>
                                        (c.phone ?? '').contains(q),
                                    validator: (v) {
                                      final t = v?.trim() ?? '';
                                      if (t.isEmpty) {
                                        return "Phone number is required";
                                      }
                                      if (t.length != 10) {
                                        return "Must be 10 digits";
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 10),
                                  _customerAutocompleteField(
                                    ctrl: customerName,
                                    focusNode: customerNameFocus,
                                    label: "Customer Name",
                                    icon: Icons.person_outline_rounded,
                                    customers: customers,
                                    matcher: (c, q) => (c.name ?? '')
                                        .toLowerCase()
                                        .contains(q),
                                    validator: (v) =>
                                        (v == null || v.trim().isEmpty)
                                            ? "Customer name is required"
                                            : null,
                                  ),
                                  const SizedBox(height: 10),
                                  _inputField(
                                    label: "Customer Address",
                                    ctrl: customerAddress,
                                    icon: Icons.location_on_rounded,
                                    iconColor: _C.orange,
                                    iconBg: _C.orangeSoft,
                                  ),
                                  if (selCustomer != null) ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      children: const [
                                        Icon(
                                          Icons.check_circle_rounded,
                                          size: 13,
                                          color: _C.green,
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          "Existing customer linked",
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            color: _C.green,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              );
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ── 02  ROUTE ────────────────────────────────────────────
                      _FadeSlide(
                        anim: _anims[1],
                        child: _sectionCard(
                          icon: Icons.route_rounded,
                          label: "Route Details",
                          iconColor: _C.accent,
                          iconBg: _C.accentSoft,
                          badge: "02",
                          child: Column(
                            children: [
                              _locationAutocomplete(
                                label: "Pickup Location",
                                ctrl: pickup,
                                focusNode: pickupFocus,
                                icon: Icons.trip_origin_rounded,
                                iconColor: _C.green,
                                iconBg: _C.greenSoft,
                                options: pickupOptions,
                              ),
                              _routeConnector(),
                              _locationAutocomplete(
                                label: "Drop Location",
                                ctrl: drop,
                                focusNode: dropFocus,
                                icon: Icons.location_on_rounded,
                                iconColor: _C.red,
                                iconBg: _C.redSoft,
                                options: dropOptions,
                              ),
                              _divider(),
                              _inputField(
                                label: "Distance (KM)",
                                ctrl: distance,
                                icon: Icons.straighten_rounded,
                                iconColor: _C.accent,
                                iconBg: _C.accentSoft,
                                keyboard: const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                fmt: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'[\d.]'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              _inputField(
                                label: "Fuel Required (L)",
                                ctrl: fuelReq,
                                icon: Icons.local_gas_station_rounded,
                                iconColor: _C.orange,
                                iconBg: _C.orangeSoft,
                                keyboard: const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                fmt: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'[\d.]'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              _inputField(
                                label: "Trip Charges",
                                ctrl: charges,
                                icon: Icons.currency_rupee_rounded,
                                iconColor: _C.purple,
                                iconBg: _C.purpleSoft,
                                prefix: "₹  ",
                                keyboard: const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                fmt: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'[\d.]'),
                                  ),
                                ],
                              ),
                              _fareChip(fare),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ── 03  SCHEDULE ─────────────────────────────────────────
                      _FadeSlide(
                        anim: _anims[2],
                        child: _sectionCard(
                          icon: Icons.calendar_month_rounded,
                          label: "Trip Schedule",
                          iconColor: _C.purple,
                          iconBg: _C.purpleSoft,
                          badge: "03",
                          child: Column(
                            children: [
                              _dateTile(
                                label: "Start Date & Time",
                                ctrl: startDate,
                                icon: Icons.play_circle_rounded,
                                color: _C.green,
                                bg: _C.greenSoft,
                                onTap: () => _pickDt(true),
                              ),
                              const SizedBox(height: 10),
                              _dateTile(
                                label: "End Date & Time",
                                ctrl: endDate,
                                icon: Icons.stop_circle_rounded,
                                color: _C.red,
                                bg: _C.redSoft,
                                onTap: () => _pickDt(false),
                              ),
                              if (startDt != null && endDt != null) ...[
                                const SizedBox(height: 12),
                                _durationBanner(),
                              ],
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ── 04  ASSIGNMENTS ──────────────────────────────────────
                      _FadeSlide(
                        anim: _anims[3],
                        child: _sectionCard(
                          icon: Icons.groups_2_rounded,
                          label: "Assignments",
                          iconColor: _C.green,
                          iconBg: _C.greenSoft,
                          badge: "04",
                          child: Column(
                            children: [
                              // ── Vehicle ──────────────────────────────────────────
                              _assignLabel("Vehicle"),
                              const SizedBox(height: 6),
                              if (startDt == null || endDt == null)
                                _lockedTile(
                                  "Vehicle",
                                  Icons.directions_car_rounded,
                                  "Set trip schedule to unlock vehicles",
                                )
                              else
                                state.availableVehicles.when(
                                  data: (list) {
                                    // ── Edit mode: auto-set label from loaded list ──
                                    if (selVehicle != null &&
                                        selVehicleLabel == null) {
                                      final match = list.where(
                                        (e) => e.vehicleId == selVehicle,
                                      );
                                      if (match.isNotEmpty) {
                                        WidgetsBinding.instance
                                            .addPostFrameCallback((_) {
                                              if (mounted)
                                                setState(
                                                  () => selVehicleLabel =
                                                      match.first.name ?? '',
                                                );
                                            });
                                      }
                                    }

                                    if (list.isEmpty)
                                      return _emptyWithAddTile(
                                        message:
                                            "No vehicles available for this schedule",
                                        icon: Icons.directions_car_rounded,
                                        addLabel: "Add Vehicle",
                                        onAdd: _goAddVehicle,
                                        color: _C.accent,
                                        bg: _C.accentSoft,
                                      );

                                    return _customDropTile<int>(
                                      selected: selVehicle,
                                      selectedLabel: selVehicleLabel,
                                      placeholder: "Select Vehicle",
                                      icon: Icons.directions_car_rounded,
                                      color: _C.accent,
                                      bg: _C.accentSoft,
                                      onAdd: (_) => _goAddVehicle(),
                                      addLabel: "Add Vehicle",
                                      items: list
                                          .map(
                                            (e) => _DropItem(
                                              value: e.vehicleId!,
                                              label:
                                                  "${e.name ?? ''} (${e.number ?? ''})",
                                              subtitle: "Vehicle",
                                              icon:
                                                  Icons.directions_car_rounded,
                                              color: _C.accent,
                                            ),
                                          )
                                          .toList(),
                                      onSelect: (val, label) => setState(() {
                                        selVehicle = val;
                                        selVehicleLabel = label;
                                      }),
                                      hasError: selVehicle == null,
                                    );
                                  },
                                  loading: () => _loadingTile(
                                    "Fetching available vehicles...",
                                  ),
                                  error: (_, __) =>
                                      _errorTile("Failed to load vehicles"),
                                ),

                              const SizedBox(height: 14),

                              // ── Driver ───────────────────────────────────────────
                              _assignLabel("Driver"),
                              const SizedBox(height: 6),
                              if (startDt == null || endDt == null)
                                _lockedTile(
                                  "Driver",
                                  Icons.person_pin_circle_rounded,
                                  "Set trip schedule to unlock drivers",
                                )
                              else
                                state.availableDrivers.when(
                                  data: (list) {
                                    // ── Edit mode: auto-set label from loaded list ──
                                    if (selDriver != null &&
                                        selDriverLabel == null) {
                                      final match = list.where(
                                        (e) => e.driverId == selDriver,
                                      );
                                      if (match.isNotEmpty) {
                                        WidgetsBinding.instance
                                            .addPostFrameCallback((_) {
                                              if (mounted)
                                                setState(
                                                  () => selDriverLabel =
                                                      match.first.name ?? '',
                                                );
                                            });
                                      }
                                    }
                                    if (list.isEmpty)
                                      return _emptyWithAddTile(
                                        message:
                                            "No drivers available for this schedule",
                                        icon: Icons.person_pin_circle_rounded,
                                        addLabel: "Add Driver",
                                        onAdd: _goAddDriver,
                                        color: _C.purple,
                                        bg: _C.purpleSoft,
                                      );
                                    return _customDropTile<int>(
                                      selected: selDriver,
                                      selectedLabel: selDriverLabel,
                                      placeholder: "Select Driver",
                                      icon: Icons.person_pin_circle_rounded,
                                      color: _C.purple,
                                      bg: _C.purpleSoft,
                                      onAdd: (_) => _goAddDriver(),
                                      addLabel: "Add Driver",
                                      items: list
                                          .map(
                                            (e) => _DropItem(
                                              value: e.driverId!,
                                              label: e.name ?? '',
                                              subtitle: e.phone ?? 'Driver',
                                              icon: Icons
                                                  .person_pin_circle_rounded,
                                              color: _C.purple,
                                            ),
                                          )
                                          .toList(),
                                      onSelect: (val, label) => setState(() {
                                        selDriver = val;
                                        selDriverLabel = label;
                                      }),
                                      hasError: selDriver == null,
                                    );
                                  },
                                  loading: () => _loadingTile(
                                    "Fetching available drivers...",
                                  ),
                                  error: (_, __) =>
                                      _errorTile("Failed to load drivers"),
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
            _saveBar(isEdit, pb),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  TOP BAR
  // ══════════════════════════════════════════════════════════════════════════
  Widget _topBar(bool isEdit) {
    return Container(
      color: _C.surface,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _C.surfaceLight,
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(color: _C.divider),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: _C.text2,
                      size: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEdit ? "Edit Booking" : "New Booking",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: _C.text1,
                          letterSpacing: -0.4,
                        ),
                      ),
                      Text(
                        isEdit
                            ? "Update trip details"
                            : "Fill in all trip details",
                        style: const TextStyle(fontSize: 12, color: _C.text2),
                      ),
                    ],
                  ),
                ),
                // Container(
                //   width: 40, height: 40,
                //   decoration: BoxDecoration(
                //     gradient: const LinearGradient(
                //       colors: [AppColors.brandPrimaryLight, _C.accent],
                //       begin: Alignment.topLeft, end: Alignment.bottomRight),
                //     borderRadius: BorderRadius.circular(11),
                //     boxShadow: [BoxShadow(color: _C.accent.withOpacity(0.3),
                //         blurRadius: 8, offset: const Offset(0, 3))],
                //   ),
                //   child: Icon(isEdit ? Icons.edit_road_rounded : Icons.add_road_rounded,
                //       color: Colors.white, size: 18),
                // ),
              ],
            ),
          ),
          const Divider(height: 1, color: _C.divider),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  SECTION CARD
  // ══════════════════════════════════════════════════════════════════════════
  Widget _sectionCard({
    required IconData icon,
    required String label,
    required Color iconColor,
    required Color iconBg,
    required String badge,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.divider),
        boxShadow: [
          BoxShadow(
            color: _C.accent.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 13, 14, 12),
            child: Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [iconColor.withOpacity(0.85), iconColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: iconColor.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      badge,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 14, color: iconColor),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _C.text1,
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: _C.divider),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
            child: child,
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  INPUT FIELD
  // ══════════════════════════════════════════════════════════════════════════
  // ══════════════════════════════════════════════════════════════════════════
  //  LOCATION AUTOCOMPLETE  ← suggests past pickup/drop locations
  // ══════════════════════════════════════════════════════════════════════════
  Widget _locationAutocomplete({
    required String label,
    required TextEditingController ctrl,
    required FocusNode focusNode,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required List<String> options,
  }) {
    return RawAutocomplete<String>(
      textEditingController: ctrl,
      focusNode: focusNode,
      optionsBuilder: (TextEditingValue value) {
        final q = value.text.trim().toLowerCase();
        if (q.isEmpty) {
          // Field focused but empty: show up to 6 recent unique locations.
          return options.take(6);
        }
        return options
            .where((s) {
              final lower = s.toLowerCase();
              return lower.contains(q) && lower != q;
            })
            .take(8);
      },
      onSelected: (String selection) {
        ctrl.text = selection;
        ctrl.selection = TextSelection.fromPosition(
          TextPosition(offset: selection.length),
        );
        focusNode.unfocus();
      },
      fieldViewBuilder: (context, fieldCtrl, fieldFocus, onFieldSubmitted) {
        return _inputField(
          label: label,
          ctrl: fieldCtrl,
          icon: icon,
          iconColor: iconColor,
          iconBg: iconBg,
          focusNode: fieldFocus,
          onFieldSubmitted: (_) => onFieldSubmitted(),
        );
      },
      optionsViewBuilder: (context, onSelected, displayedOptions) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(12),
            color: _C.surface,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: displayedOptions.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: _C.divider),
                itemBuilder: (_, i) {
                  final option = displayedOptions.elementAt(i);
                  return InkWell(
                    onTap: () => onSelected(option),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: iconBg,
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: Icon(
                              Icons.location_on_rounded,
                              size: 12,
                              color: iconColor,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              option,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _C.text1,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.north_west_rounded,
                            size: 14,
                            color: _C.text2,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _inputField({
    required String label,
    required TextEditingController ctrl,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    String? prefix,
    TextInputType? keyboard,
    List<TextInputFormatter>? fmt,
    FocusNode? focusNode,
    void Function(String)? onFieldSubmitted,
    String? Function(String?)? validator,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: ctrl,
      focusNode: focusNode,
      onFieldSubmitted: onFieldSubmitted,
      keyboardType: keyboard,
      inputFormatters: fmt,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: _C.text1,
      ),
      validator:
          validator ?? (v) => (v == null || v.isEmpty) ? "Required" : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _C.text2, fontSize: 13),
        prefixText: prefix,
        prefixStyle: TextStyle(
          color: iconColor,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.all(10),
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: iconColor),
          ),
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: _C.surfaceLight,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _C.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _C.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _C.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _C.red, width: 1.5),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  DATE TILE
  // ══════════════════════════════════════════════════════════════════════════
  Widget _dateTile({
    required String label,
    required TextEditingController ctrl,
    required IconData icon,
    required Color color,
    required Color bg,
    required VoidCallback onTap,
  }) {
    final has = ctrl.text.isNotEmpty;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: has ? color.withOpacity(0.05) : _C.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: has ? color.withOpacity(0.4) : _C.divider,
            width: has ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: has ? color : bg,
                borderRadius: BorderRadius.circular(10),
                boxShadow: has
                    ? [
                        BoxShadow(
                          color: color.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Icon(icon, size: 17, color: has ? Colors.white : color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(color: _C.text2, fontSize: 11.5),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    has ? ctrl.text : "Tap to select",
                    style: TextStyle(
                      color: has ? _C.text1 : _C.text2.withOpacity(0.45),
                      fontWeight: has ? FontWeight.w700 : FontWeight.w400,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: (has ? color : _C.text2).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: has ? color : _C.text2.withOpacity(0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  DURATION BANNER
  // ══════════════════════════════════════════════════════════════════════════
  Widget _durationBanner() {
    final diff = endDt!.difference(startDt!);
    final inv = diff.isNegative;
    final h = diff.inHours;
    final m = diff.inMinutes.remainder(60);
    final dur = inv ? "Invalid range" : (h == 0 ? "${m}m" : "${h}h ${m}m");
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: inv ? _C.redSoft : _C.greenSoft,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: (inv ? _C.red : _C.green).withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(
            inv ? Icons.warning_amber_rounded : Icons.timelapse_rounded,
            size: 15,
            color: inv ? _C.red : _C.green,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              inv ? "End must be after start" : "Trip Duration",
              style: TextStyle(
                color: inv ? _C.red : _C.text2,
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (!inv)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _C.green,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: _C.green.withOpacity(0.3), blurRadius: 8),
                ],
              ),
              child: Text(
                dur,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  EMPTY WITH ADD REDIRECT TILE  ← NEW
  // ══════════════════════════════════════════════════════════════════════════
  Widget _emptyWithAddTile({
    required String message,
    required IconData icon,
    required String addLabel,
    required VoidCallback onAdd,
    required Color color,
    required Color bg,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: bg.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          // Empty state message row
          Padding(
            padding: const EdgeInsets.fromLTRB(13, 13, 13, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 15, color: color.withOpacity(0.7)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message,
                    style: TextStyle(
                      color: color,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Container(height: 1, color: color.withOpacity(0.15)),

          // Add button
          GestureDetector(
            onTap: onAdd,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 13),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color.withOpacity(0.85), color],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    addLabel,
                    style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 11,
                    color: color.withOpacity(0.6),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  CUSTOM DROPDOWN TILE
  // ══════════════════════════════════════════════════════════════════════════
  Widget _customDropTile<T>({
    required T? selected,
    required String? selectedLabel,
    required String placeholder,
    required IconData icon,
    required Color color,
    required Color bg,
    required List<_DropItem<T>> items,
    required Function(T, String) onSelect,
    bool hasError = false,
    void Function(String query)? onAdd,
    String addLabel = "Add New",
  }) {
    final hasVal = selected != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => _showDropSheet(
            items,
            selected,
            onSelect,
            color,
            bg,
            onAdd: onAdd,
            addLabel: addLabel,
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: hasVal ? color.withOpacity(0.05) : _C.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasError && !hasVal
                    ? _C.red.withOpacity(0.5)
                    : hasVal
                    ? color.withOpacity(0.35)
                    : _C.divider,
                width: hasVal ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: hasVal
                        ? LinearGradient(
                            colors: [color.withOpacity(0.8), color],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: hasVal ? null : bg,
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: hasVal
                        ? [
                            BoxShadow(
                              color: color.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    icon,
                    size: 17,
                    color: hasVal ? Colors.white : color,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasVal ? placeholder : placeholder,
                        style: const TextStyle(color: _C.text2, fontSize: 11.5),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hasVal
                            ? (selectedLabel ?? placeholder)
                            : "Tap to select",
                        style: TextStyle(
                          color: hasVal ? _C.text1 : _C.text2.withOpacity(0.45),
                          fontWeight: hasVal
                              ? FontWeight.w700
                              : FontWeight.w400,
                          fontSize: 13.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: (hasVal ? color : _C.text2).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    hasVal
                        ? Icons.check_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: hasVal ? color : _C.text2.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  BOTTOM SHEET DROPDOWN
  // ══════════════════════════════════════════════════════════════════════════
  void _showDropSheet<T>(
    List<_DropItem<T>> items,
    T? selected,
    Function(T, String) onSelect,
    Color color,
    Color bg, {
    void Function(String query)? onAdd,
    String addLabel = "Add New",
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _DropSheet<T>(
        items: items,
        selected: selected,
        onSelect: (val, label) {
          onSelect(val, label);
          Navigator.pop(ctx);
        },
        color: color,
        bg: bg,
        onAdd: onAdd == null
            ? null
            : (query) {
                Navigator.pop(ctx);
                onAdd(query);
              },
        addLabel: addLabel,
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  STATE TILES
  // ══════════════════════════════════════════════════════════════════════════
  Widget _assignLabel(String label) => Text(
    label,
    style: const TextStyle(
      fontSize: 12.5,
      fontWeight: FontWeight.w700,
      color: _C.text2,
      letterSpacing: 0.2,
    ),
  );

  Widget _lockedTile(String label, IconData icon, String msg) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: _C.surfaceLight,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _C.divider),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: _C.divider,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: _C.text2.withOpacity(0.4)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            msg,
            style: TextStyle(color: _C.text2.withOpacity(0.55), fontSize: 12.5),
          ),
        ),
        const Icon(Icons.lock_outline_rounded, size: 14, color: _C.text2),
      ],
    ),
  );

  Widget _loadingTile(String msg) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: _C.surfaceLight,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _C.divider),
    ),
    child: Row(
      children: [
        SizedBox(
          width: 15,
          height: 15,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: _C.accent,
            backgroundColor: _C.accent.withOpacity(0.1),
          ),
        ),
        const SizedBox(width: 12),
        Text(msg, style: const TextStyle(color: _C.text2, fontSize: 13)),
      ],
    ),
  );

  Widget _errorTile(String msg) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: _C.redSoft,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _C.red.withOpacity(0.2)),
    ),
    child: Row(
      children: [
        const Icon(Icons.cloud_off_rounded, size: 15, color: _C.red),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            msg,
            style: const TextStyle(
              color: _C.red,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _routeConnector() => Padding(
    padding: const EdgeInsets.only(left: 22, top: 4, bottom: 4),
    child: Column(
      children: List.generate(
        3,
        (_) => Container(
          width: 1.5,
          height: 5,
          margin: const EdgeInsets.symmetric(vertical: 2),
          color: _C.divider,
        ),
      ),
    ),
  );

  Widget _divider() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Container(height: 1, color: _C.divider),
  );

  // ══════════════════════════════════════════════════════════════════════════
  //  SAVE BAR
  // ══════════════════════════════════════════════════════════════════════════
  Widget _saveBar(bool isEdit, double pb) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + pb),
      decoration: BoxDecoration(
        color: _C.surface,
        border: const Border(top: BorderSide(color: _C.divider)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 16,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Row(
        children: [
          // GestureDetector(
          //   onTap: () => Navigator.pop(context),
          //   child: Container(width: 48, height: 48,
          //     decoration: BoxDecoration(color: _C.surfaceLight,
          //         borderRadius: BorderRadius.circular(13),
          //         border: Border.all(color: _C.divider)),
          //     child: const Icon(Icons.close_rounded, color: _C.text2, size: 20)),
          // ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: _saving ? null : _save,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 48,
                decoration: BoxDecoration(
                  gradient: _saving
                      ? LinearGradient(
                          colors: [Colors.grey.shade300, Colors.grey.shade400],
                        )
                      : const LinearGradient(
                          colors: [AppColors.brandPrimaryLight, _C.accent],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: _saving
                      ? []
                      : [
                          BoxShadow(
                            color: _C.accent.withOpacity(0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_saving)
                      const SizedBox(
                        width: 17,
                        height: 17,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    else
                      Icon(
                        isEdit
                            ? Icons.update_rounded
                            : Icons.check_circle_rounded,
                        color: Colors.white,
                        size: 19,
                      ),
                    const SizedBox(width: 9),
                    Text(
                      _saving
                          ? "Saving..."
                          : isEdit
                          ? "Update Trip"
                          : "Save Booking",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.white,
              size: 17,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                msg,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: _C.red,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  BOTTOM SHEET DROPDOWN
// ════════════════════════════════════════════════════════════════════════════
class _DropSheet<T> extends StatefulWidget {
  final List<_DropItem<T>> items;
  final T? selected;
  final Function(T, String) onSelect;
  final Color color;
  final Color bg;
  // Receives the current search query so callers can pre-fill an "add new"
  // form with what the user just typed (e.g. a phone or name that didn't match).
  final void Function(String query)? onAdd;
  final String addLabel;
  const _DropSheet({
    required this.items,
    required this.selected,
    required this.onSelect,
    required this.color,
    required this.bg,
    this.onAdd,
    this.addLabel = "Add New",
  });

  @override
  State<_DropSheet<T>> createState() => _DropSheetState<T>();
}

class _DropSheetState<T> extends State<_DropSheet<T>> {
  final _searchCtrl = TextEditingController();
  late List<_DropItem<T>> _filtered;

  @override
  void initState() {
    super.initState();
    _filtered = widget.items;
    _searchCtrl.addListener(() {
      final q = _searchCtrl.text.toLowerCase();
      setState(() {
        _filtered = q.isEmpty
            ? widget.items
            : widget.items.where((e) {
                final inLabel = e.label.toLowerCase().contains(q);
                final inSubtitle =
                    e.subtitle?.toLowerCase().contains(q) ?? false;
                return inLabel || inSubtitle;
              }).toList();
      });
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    final pb = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: _C.divider,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: widget.bg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    widget.items.first.icon ?? Icons.list_rounded,
                    size: 16,
                    color: widget.color,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  "Select Option",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _C.text1,
                  ),
                ),
                const Spacer(),
                Text(
                  "${widget.items.length} available",
                  style: const TextStyle(fontSize: 12, color: _C.text2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(
                fontSize: 14,
                color: _C.text1,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: "Search...",
                hintStyle: const TextStyle(color: _C.text2, fontSize: 13),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: _C.text2,
                  size: 18,
                ),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? GestureDetector(
                        onTap: () => _searchCtrl.clear(),
                        child: const Icon(
                          Icons.cancel_rounded,
                          color: _C.text2,
                          size: 16,
                        ),
                      )
                    : null,
                filled: true,
                fillColor: _C.surfaceLight,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _C.divider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: widget.color, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: _C.divider),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.45,
            ),
            child: _filtered.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: const BoxDecoration(
                            color: _C.accentSoft,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.search_off_rounded,
                            color: _C.accent,
                            size: 26,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          "No results found",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _C.text1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _searchCtrl.text.isEmpty
                              ? "Try a different search term"
                              : "No match for \"${_searchCtrl.text}\"",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12,
                            color: _C.text2,
                          ),
                        ),
                        if (widget.onAdd != null &&
                            _searchCtrl.text.trim().isNotEmpty) ...[
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: () => widget.onAdd!(_searchCtrl.text.trim()),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 11,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    widget.color.withOpacity(0.85),
                                    widget.color,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(11),
                                boxShadow: [
                                  BoxShadow(
                                    color: widget.color.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.add_rounded,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${widget.addLabel} with "${_searchCtrl.text.trim()}"',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, indent: 66, color: _C.divider),
                    itemBuilder: (_, i) {
                      final item = _filtered[i];
                      final isSelected = item.value == widget.selected;
                      return InkWell(
                        onTap: () => widget.onSelect(item.value, item.label),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          color: isSelected
                              ? widget.color.withOpacity(0.06)
                              : Colors.transparent,
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  gradient: isSelected
                                      ? LinearGradient(
                                          colors: [
                                            widget.color.withOpacity(0.8),
                                            widget.color,
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        )
                                      : const LinearGradient(
                                          colors: [
                                            AppColors.brandPrimaryLight,
                                            _C.accent,
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          (isSelected
                                                  ? widget.color
                                                  : _C.accent)
                                              .withOpacity(0.25),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child:
                                      item.icon == Icons.directions_car_rounded
                                      ? Icon(
                                          item.icon,
                                          color: Colors.white,
                                          size: 18,
                                        )
                                      : Text(
                                          _initials(item.label),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 14,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.label,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: isSelected
                                            ? widget.color
                                            : _C.text1,
                                      ),
                                    ),
                                    if (item.subtitle != null) ...[
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Icon(
                                            item.subtitle!.startsWith('0') ||
                                                    item.subtitle!.startsWith(
                                                      '+',
                                                    )
                                                ? Icons.phone_rounded
                                                : Icons.badge_rounded,
                                            size: 11,
                                            color: _C.text2,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            item.subtitle!,
                                            style: const TextStyle(
                                              fontSize: 11.5,
                                              color: _C.text2,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? widget.color
                                      : _C.surfaceLight,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected
                                        ? widget.color
                                        : _C.divider,
                                  ),
                                ),
                                child: Icon(
                                  isSelected
                                      ? Icons.check_rounded
                                      : Icons.chevron_right_rounded,
                                  size: 15,
                                  color: isSelected
                                      ? Colors.white
                                      : _C.text2.withOpacity(0.4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          // ── Add New Button ─────────────────────────────────────────────────
          if (widget.onAdd != null) ...[
            const Divider(height: 1, color: _C.divider),
            GestureDetector(
              onTap: () => widget.onAdd!(_searchCtrl.text.trim()),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 20,
                ),
                color: widget.color.withOpacity(0.04),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [widget.color.withOpacity(0.8), widget.color],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(7),
                        boxShadow: [
                          BoxShadow(
                            color: widget.color.withOpacity(0.35),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        size: 15,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      widget.addLabel,
                      style: TextStyle(
                        color: widget.color,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 12,
                      color: widget.color.withOpacity(0.55),
                    ),
                  ],
                ),
              ),
            ),
          ],
          SizedBox(height: pb + 16),
        ],
      ),
    );
  }
}


// ════════════════════════════════════════════════════════════════════════════
//  FADE + SLIDE ANIMATION
// ════════════════════════════════════════════════════════════════════════════
class _FadeSlide extends StatelessWidget {
  final Animation<double> anim;
  final Widget child;
  const _FadeSlide({required this.anim, required this.child});

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: anim,
    builder: (_, __) => Opacity(
      opacity: anim.value.clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(0, 20 * (1 - anim.value)),
        child: child,
      ),
    ),
  );
}
