import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart' show PointerScrollEvent;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:travel_agency_app/Screens/add_driver.dart';
import 'package:travel_agency_app/Screens/add_vehicle.dart';
import 'package:travel_agency_app/core/network/distance_service.dart';
import 'package:travel_agency_app/core/network/places_service.dart';
import 'package:travel_agency_app/core/theme/app_colors.dart';
import 'package:travel_agency_app/domain/models/booking_info.dart';
import 'package:travel_agency_app/domain/models/customers.dart';
import 'package:travel_agency_app/domain/models/vehicles.dart';
import 'package:travel_agency_app/domain/models/route_fare_suggestion.dart';
import 'package:travel_agency_app/domain/models/tripbooking_info.dart';
import 'package:travel_agency_app/presentation/providers/viewmodel_provider.dart';

// ─── Design Tokens ─────────────────────────────────────────────────────────
class _C {
  static const bg = Color(0xFFF0F4FF);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceLight = Color(0xFFF3F5FB);
  static const accent = AppColors.brandPrimary;
  static const accentSoft = AppColors.brandSoft;
  static const accentDark = AppColors.brandPrimaryDark;
  static const text1 = Color(0xFF1A1D2E);
  static const text2 = Color(0xFF7B82A0);
  static const divider = Color(0xFFE8ECF4);
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

  // Debounce for the Google Places lookup so we don't fire a (billed) request
  // on every keystroke. Only one location field is focused at a time, so a
  // single shared timer is enough.
  Timer? _placesDebounce;
  final distance = TextEditingController();
  final fuelReq = TextEditingController();
  final charges = TextEditingController();
  final startDate = TextEditingController();
  final endDate = TextEditingController();

  // Completion fields — only used/shown when the trip is back-dated (start in
  // the past), i.e. the operator is logging a trip that already happened.
  final tollCharges = TextEditingController();
  final repairCharges = TextEditingController();
  final driverCharges = TextEditingController();
  final fuelCharges = TextEditingController();
  final amountReceived = TextEditingController();

  DateTime? startDt, endDt;

  // True when the selected start date is before today — the trip already
  // happened, so we collect final charges + amount received and save it as a
  // completed trip rather than an upcoming booking.
  bool get _isCompletedTrip {
    if (startDt == null) return false;
    final now = DateTime.now();
    return startDt!.isBefore(DateTime(now.year, now.month, now.day));
  }
  int? selVehicle, selDriver, selCustomer;
  // Round trip → charged ×2. One-way → charged ×1.5 (base + half return leg).
  bool _isReturnTrip = false;
  bool _saving = false;
  bool _fetchingDistance = false;
  String? _routeDistanceText; // e.g. "173 km"
  String? _routeDurationText; // e.g. "3 hours 46 mins"
  int? _routeDurationMinutes; // numeric one-way estimate, doubled in the chip
  // Remembers the last route we fetched distance for, so we don't re-call the
  // API for a route that hasn't actually changed.
  String? _lastDistanceRoute;
  // FuelTypeId → name (e.g. 1 → "Petrol"). The available-vehicles API returns
  // only the id, so we map it to a readable name using the fuel-type list.
  Map<int, String> _fuelTypeNames = {};

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
      _isReturnTrip = (b.isReturnTrip ?? 0) == 1;
      selVehicle = b.vehicleId;
      selDriver = b.driverId;
      selCustomer = b.customerId;
      // Prefill the inline customer fields straight from the booking so edit
      // mode shows the customer immediately, without waiting on the customer
      // list to load or relying on a customerId match. These listeners aren't
      // attached yet, so writing here won't clear selCustomer.
      customerName.text = b.customer_name ?? '';
      customerPhone.text = b.customer_phone ?? '';
      customerAddress.text = b.customerAddress ?? '';
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
      // Pre-fill completion charges when editing an already-recorded trip.
      tollCharges.text = b.tollCharges?.toString() ?? '';
      repairCharges.text = b.repairingCharges?.toString() ?? '';
      driverCharges.text = b.driverCharges?.toString() ?? '';
      fuelCharges.text = b.fuelCharges?.toString() ?? '';
      amountReceived.text = b.amountReceived?.toString() ?? '';
    }

    // Recompute the fare suggestion whenever the route text changes.
    pickup.addListener(_onRouteChanged);
    drop.addListener(_onRouteChanged);

    // RawAutocomplete only opens its overlay when the TEXT changes, never on a
    // plain focus gain — so an empty field shows no "recent locations" until you
    // type. Re-assigning the controller value on focus nudges it to recompute
    // and open the overlay. Distance is NOT fetched on focus loss — it's only
    // calculated when the operator taps the Distance field.
    pickupFocus.addListener(() {
      if (pickupFocus.hasFocus) _nudgeAutocomplete(pickup);
    });
    dropFocus.addListener(() {
      if (dropFocus.hasFocus) _nudgeAutocomplete(drop);
    });

    // Detach from the picked customer the moment the admin edits any of the
    // autofilled fields — saving will then create a new customer instead.
    // Phone gets its own handler that ALSO wipes name/address, so re-searching
    // by a different number starts from a clean slate.
    customerName.addListener(_onCustomerFieldChanged);
    customerPhone.addListener(_onCustomerPhoneChanged);
    customerAddress.addListener(_onCustomerFieldChanged);

    // Keep the completion summary (balance / payment status) live as the
    // operator types the charges and amount received for a back-dated trip.
    charges.addListener(_onCompletionAmountChanged);
    tollCharges.addListener(_onCompletionAmountChanged);
    repairCharges.addListener(_onCompletionAmountChanged);
    driverCharges.addListener(_onCompletionAmountChanged);
    fuelCharges.addListener(_onCompletionAmountChanged);
    amountReceived.addListener(_onCompletionAmountChanged);

    Future.microtask(() async {
      final n = ref.read(tripBookingViewModelProvider.notifier);
      var aid = ref.read(loginViewModelProvider).agencyId ?? '';
      // On a cold start (app reopened) the agencyId may not be in memory yet —
      // hydrate it from storage so route history/suggestions actually load.
      if (aid.isEmpty) {
        await ref.read(loginViewModelProvider.notifier).loadFromStorage();
        aid = ref.read(loginViewModelProvider).agencyId ?? '';
      }
      n.customerList(aid);
      n.loadRouteHistory(aid);
      // Pull active + upcoming trips too so location autocomplete can suggest
      // routes from in-flight bookings, not just completed ones.
      final tn = ref.read(tripPageViewModelProvider.notifier);
      tn.activeList(aid);
      tn.upcomingList(aid);
      tn.unpaidList(aid);
      tn.cancelledList(aid);
      // Load fuel-type names so the vehicle dropdown can show Petrol/Diesel/etc.
      ref.read(addVehicleViewModelProvider.notifier).fetchVehicleFuelTypeList();
      if (widget.booking != null && startDt != null) {
        // End is optional; fall back to a 24h window for the conflict query.
        final effectiveEnd = endDt ?? startDt!.add(const Duration(hours: 24));
        n.fetchAvailableVehicles(
          aid,
          startDt!,
          effectiveEnd,
          widget.booking!.tripId!,
        );
        n.fetchAvailableDrivers(
          aid,
          startDt!,
          effectiveEnd,
          widget.booking?.tripId,
        );
      }
    });
  }

  @override
  void dispose() {
    _placesDebounce?.cancel();
    pickup.removeListener(_onRouteChanged);
    drop.removeListener(_onRouteChanged);
    customerName.removeListener(_onCustomerFieldChanged);
    customerPhone.removeListener(_onCustomerPhoneChanged);
    customerAddress.removeListener(_onCustomerFieldChanged);
    charges.removeListener(_onCompletionAmountChanged);
    tollCharges.removeListener(_onCompletionAmountChanged);
    repairCharges.removeListener(_onCompletionAmountChanged);
    driverCharges.removeListener(_onCompletionAmountChanged);
    fuelCharges.removeListener(_onCompletionAmountChanged);
    amountReceived.removeListener(_onCompletionAmountChanged);
    customerName.dispose();
    customerPhone.dispose();
    customerAddress.dispose();
    tollCharges.dispose();
    repairCharges.dispose();
    driverCharges.dispose();
    fuelCharges.dispose();
    amountReceived.dispose();
    pickupFocus.dispose();
    dropFocus.dispose();
    customerNameFocus.dispose();
    customerPhoneFocus.dispose();
    _staggerCtrl.dispose();
    super.dispose();
  }

  // Rebuild so the fare-suggestion chip + autocomplete reflect the current
  // route text. The road-distance API is NOT fetched here — distance is only
  // calculated when the operator taps the Distance field after finishing the
  // pickup/drop entry.
  void _onRouteChanged() {
    if (mounted) setState(() {});
  }

  // Forces RawAutocomplete to recompute + open its overlay even when the field
  // is empty (it normally only reacts to text edits, not focus). Re-assigning
  // the same value notifies the controller's listeners without changing text.
  void _nudgeAutocomplete(TextEditingController ctrl) {
    ctrl.value = ctrl.value.copyWith();
  }

  // Debounced Google Places lookup (via our backend), used ONLY as a fallback
  // when no past trip matches the typed route. Waits 300 ms after the last
  // keystroke; if a newer query arrives first this future is abandoned and
  // RawAutocomplete keeps only the latest result. Returns [] on any error.
  Future<List<String>> _placeSuggestions(String query) {
    _placesDebounce?.cancel();
    final completer = Completer<List<String>>();
    _placesDebounce = Timer(const Duration(milliseconds: 300), () async {
      final results = await PlacesService.autocomplete(query);
      if (!completer.isCompleted) completer.complete(results);
    });
    return completer.future;
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

  // Rebuilds the completion summary (balance / payment-status preview) as the
  // charges or received amount change. Only relevant for back-dated trips.
  void _onCompletionAmountChanged() {
    if (mounted) setState(() {});
  }

  void _onCustomerFieldChanged() {
    if (_suppressCustomerFieldListener) return;
    if (selCustomer == null) return;
    // Any manual edit after an autofill detaches us from the linked customer:
    // saving will create a NEW customer with the typed values.
    setState(() => selCustomer = null);
  }

  // Editing the phone after picking a customer means the admin is searching for
  // (or entering) a different person — wipe the autofilled name/address too so
  // the form is a clean slate, not a mix of two customers' data.
  void _onCustomerPhoneChanged() {
    if (_suppressCustomerFieldListener) return;
    if (selCustomer == null) return;
    _suppressCustomerFieldListener = true;
    customerName.clear();
    customerAddress.clear();
    _suppressCustomerFieldListener = false;
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
            borderRadius: BorderRadius.circular(14),
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
    // Past dates are allowed so the operator can log a trip that already
    // happened (a completed trip). The end date still can't precede the start.
    final earliest = isStart
        ? DateTime(now.year - 5)
        : (startDt != null
            ? DateTime(startDt!.year, startDt!.month, startDt!.day)
            : DateTime(now.year - 5));
    final existing = isStart ? startDt : endDt;
    final initial = (existing != null && !existing.isBefore(earliest))
        ? existing
        : (isStart ? now : (startDt ?? now));

    final dt = await _showDateTimeSheet(
      earliest: earliest,
      initial: initial,
      title: isStart ? "Start Date & Time" : "End Date & Time",
      accent: isStart ? _C.green : _C.red,
    );
    if (dt == null) return;
    setState(() {
      if (isStart) {
        startDt = dt;
        startDate.text = DateFormat("MMM dd, yyyy  •  hh:mm a").format(dt);
      } else {
        endDt = dt;
        endDate.text = DateFormat("MMM dd, yyyy  •  hh:mm a").format(dt);
      }
    });
    if (startDt != null) _fetch();
  }

  // Combined date + time picker in one bottom sheet. The calendar drives the
  // day; the hour/minute spinners + AM/PM toggle drive the time. Confirm
  // commits the merged DateTime; cancel/dismiss returns null.
  Future<DateTime?> _showDateTimeSheet({
    required DateTime earliest,
    required DateTime initial,
    required String title,
    required Color accent,
  }) {
    DateTime selectedDate =
        DateTime(initial.year, initial.month, initial.day);
    int selectedHour = initial.hour;
    int selectedMinute = initial.minute;

    return showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSt) {
            final displayHour =
                selectedHour % 12 == 0 ? 12 : selectedHour % 12;
            final isPm = selectedHour >= 12;
            return Container(
              decoration: const BoxDecoration(
                color: _C.surface,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 12,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _C.divider,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: accent.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.calendar_month_rounded,
                            color: accent,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: _C.text1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Theme(
                    data: Theme.of(ctx).copyWith(
                      colorScheme: ColorScheme.light(
                        primary: accent,
                        onPrimary: Colors.white,
                        surface: _C.surface,
                        onSurface: _C.text1,
                      ),
                    ),
                    child: SizedBox(
                      height: 320,
                      child: CalendarDatePicker(
                        initialDate: selectedDate,
                        firstDate: earliest,
                        lastDate: DateTime(2035),
                        onDateChanged: (d) =>
                            setSt(() => selectedDate = d),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: _C.surfaceLight,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _C.divider),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 18,
                            color: accent,
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            "Time",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _C.text2,
                            ),
                          ),
                          const Spacer(),
                          _ScrollTypeTimeField(
                            value: displayHour,
                            min: 1,
                            max: 12,
                            accent: accent,
                            onChanged: (h) => setSt(() {
                              // Preserve the current AM/PM while mapping the
                              // 1–12 display value back to 24-hour.
                              final pm = selectedHour >= 12;
                              final base = h % 12; // 12 → 0
                              selectedHour = pm ? base + 12 : base;
                            }),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              ":",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: _C.text1,
                              ),
                            ),
                          ),
                          _ScrollTypeTimeField(
                            value: selectedMinute,
                            min: 0,
                            max: 59,
                            pad2: true,
                            accent: accent,
                            onChanged: (m) =>
                                setSt(() => selectedMinute = m),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: () => setSt(() {
                              selectedHour = (selectedHour + 12) % 24;
                            }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: accent.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: accent.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                isPm ? "PM" : "AM",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: accent,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.pop(ctx),
                            child: Container(
                              height: 46,
                              decoration: BoxDecoration(
                                color: _C.surfaceLight,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: _C.divider),
                              ),
                              child: const Center(
                                child: Text(
                                  "Cancel",
                                  style: TextStyle(
                                    color: _C.text2,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              final dt = DateTime(
                                selectedDate.year,
                                selectedDate.month,
                                selectedDate.day,
                                selectedHour,
                                selectedMinute,
                              );
                              Navigator.pop(ctx, dt);
                            },
                            child: Container(
                              height: 46,
                              decoration: BoxDecoration(
                                color: accent,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: accent.withOpacity(0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Text(
                                  "Confirm",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }


  void _fetch() {
    final aid = ref.read(loginViewModelProvider).agencyId ?? '';
    final n = ref.read(tripBookingViewModelProvider.notifier);
    // End datetime is optional. For the availability/conflict check we still
    // need an end bound, so when it's not set we assume a 24h window from the
    // start. This only affects the conflict query — the stored end stays null.
    final effectiveEnd = endDt ?? startDt!.add(const Duration(hours: 24));
    n.fetchAvailableVehicles(aid, startDt!, effectiveEnd, null);
    n.fetchAvailableDrivers(aid, startDt!, effectiveEnd, null);
  }

  // Calls our backend for the road distance when BOTH locations are filled,
  // fills the Distance field, stores the pretty distance/duration text for the
  // info chip, then recomputes fuel.
  Future<void> _maybeFetchDistance() async {
    final from = pickup.text.trim();
    final to = drop.text.trim();
    if (from.isEmpty || to.isEmpty) return;
    if (_fetchingDistance) return;

    // Skip if we already have a distance for this exact route (avoids the
    // debounce + focus-loss both firing the same call).
    final route = "${from.toLowerCase()}→${to.toLowerCase()}";
    if (route == _lastDistanceRoute && distance.text.trim().isNotEmpty) return;

    setState(() => _fetchingDistance = true);
    try {
      final result = await DistanceService.getDistance(from, to);
      if (!mounted) return;
      if (result != null) {
        // Round trip covers the route both ways, so the billed distance is ×2.
        final km = _isReturnTrip ? result.km * 2 : result.km;
        distance.text = km.toStringAsFixed(1);
        _routeDistanceText = result.distanceText;
        _routeDurationText = result.durationText;
        _routeDurationMinutes = result.durationMinutes;
        _lastDistanceRoute = route;
        _recalcFuel();
        _recalcCharges();
      } else {
        _snack("Couldn't find road distance for this route");
      }
    } catch (_) {
      if (mounted) _snack("Failed to fetch distance");
    } finally {
      if (mounted) setState(() => _fetchingDistance = false);
    }
  }

  // Fuel (litres) for ONE vehicle at the current distance, or null if it can't
  // be computed (no distance yet, or the vehicle's mileage is missing/invalid).
  double? _fuelFor(Vehicles v) {
    final dist = double.tryParse(distance.text.trim());
    if (dist == null) return null;
    final mileage = double.tryParse(v.mileage ?? '');
    if (mileage == null || mileage <= 0) return null;
    return dist / mileage; // litres = km / (km per litre)
  }

  // Vehicles sorted by fuel required ascending (most economical first).
  // Vehicles whose fuel can't be computed (no distance/mileage) sink to the end.
  List<Vehicles> _vehiclesByFuelAsc(List<Vehicles> list) {
    final sorted = List<Vehicles>.from(list);
    sorted.sort((a, b) {
      final fa = _fuelFor(a);
      final fb = _fuelFor(b);
      if (fa == null && fb == null) return 0;
      if (fa == null) return 1; // a goes after b
      if (fb == null) return -1; // a goes before b
      return fa.compareTo(fb);
    });
    return sorted;
  }

  // Dropdown subtitle shown under each vehicle name: its fuel type plus, once a
  // distance is known, the estimated fuel required. Returns null only when
  // neither piece of info is available.
  // Resolves a vehicle's fuel-type name (API value, else id → name fallback).
  String _fuelTypeName(Vehicles v) {
    var type = (v.FuelType ?? '').trim();
    if (type.isEmpty && v.FuelTypeId != null) {
      type = _fuelTypeNames[v.FuelTypeId] ?? '';
    }
    return type;
  }

  // CNG is dispensed by weight (kg); everything else (petrol/diesel) by litres.
  String _fuelUnit(String type) =>
      type.toLowerCase().contains('cng') ? 'kg' : 'L';

  // Unit for the currently selected vehicle, used by the Fuel Required field.
  String _selectedFuelUnit() {
    final vehicles =
        ref.read(tripBookingViewModelProvider).availableVehicles.value ??
            const <Vehicles>[];
    final match = vehicles.where((e) => e.vehicleId == selVehicle);
    if (match.isEmpty) return 'L';
    return _fuelUnit(_fuelTypeName(match.first));
  }

  String? _fuelLabelFor(Vehicles v) {
    final type = _fuelTypeName(v);
    final fuel = _fuelFor(v);
    if (type.isEmpty && fuel == null) return null;
    if (fuel == null) {
      // No distance yet — show only the fuel type.
      return "Fuel  •  $type";
    }
    final amount = "${fuel.toStringAsFixed(2)} ${_fuelUnit(type)}";
    return type.isEmpty
        ? "Fuel Required  •  $amount"
        : "Fuel Required  •  $amount  ·  $type";
  }

  // Auto-fill Trip Charges from the SELECTED vehicle's per-km rate:
  // charge = distance × rate. The field stays editable so the admin can adjust
  // for discounts; this just seeds a sensible default when the route or the
  // chosen vehicle changes.
  void _recalcCharges() {
    final dist = double.tryParse(distance.text.trim());
    if (dist == null) return;

    final vehicles =
        ref.read(tripBookingViewModelProvider).availableVehicles.value ??
            const <Vehicles>[];
    final match = vehicles.where((e) => e.vehicleId == selVehicle);
    if (match.isEmpty) return; // no vehicle chosen yet

    final rate = match.first.perKmCharge;
    if (rate == null || rate <= 0) return;
    final base = dist * rate;
    // The Distance field already holds the round-trip distance (×2) when it's a
    // return trip, so charge it straight; one-way adds half for the empty
    // return leg (×1.5).
    final total = _isReturnTrip ? base : base * 1.5;
    charges.text = total == total.roundToDouble()
        ? total.toStringAsFixed(0)
        : total.toStringAsFixed(2);
  }

  // Compact "₹26/km × 50 km" breakdown shown beside the Trip Charges field so
  // the admin can see how the auto-filled amount was derived. Returns an empty
  // box when there's no rate/distance yet. Text wraps (never ellipsised) so it
  // stays fully visible on narrow screens.
  Widget _chargeBreakdown() {
    final vehicles =
        ref.read(tripBookingViewModelProvider).availableVehicles.value ??
            const <Vehicles>[];
    final match = vehicles.where((e) => e.vehicleId == selVehicle);
    final rate = match.isEmpty ? null : match.first.perKmCharge;
    final dist = double.tryParse(distance.text.trim());
    if (rate == null || rate <= 0 || dist == null || dist <= 0) {
      return const SizedBox.shrink();
    }

    String fmt(double v) =>
        v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

    return Flexible(
      child: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: _C.purpleSoft,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _C.purple.withOpacity(0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.calculate_rounded, size: 14, color: _C.purple),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  "₹${fmt(rate)}/km × ${fmt(dist)} km${_isReturnTrip ? ' (round trip)' : ' × 1.5 (one-way)'}",
                  softWrap: true,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _C.purple,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Fill the Fuel Required field from the SELECTED vehicle (this is the value
  // saved to the DB). Each vehicle has its own estimate in the dropdown.
  void _recalcFuel() {
    final vehicles =
        ref.read(tripBookingViewModelProvider).availableVehicles.value ??
            const <Vehicles>[];
    final match = vehicles.where((e) => e.vehicleId == selVehicle);
    if (match.isEmpty) return; // no vehicle chosen yet

    final fuel = _fuelFor(match.first);
    if (fuel == null) return;
    fuelReq.text = fuel.toStringAsFixed(2);
  }

  // Read-only chip showing the estimated drive time for the fetched route.
  // Always shown doubled: the driver has to come back regardless of whether the
  // customer booked a return trip, so the round-trip time is the real estimate.
  // Distance is already shown in the Distance field, so it's not repeated here.
  Widget _routeInfoChip() {
    if (_routeDurationMinutes == null && _routeDurationText == null) {
      return const SizedBox.shrink();
    }
    final timeText = _routeDurationMinutes != null
        ? _formatDuration(_routeDurationMinutes! * 2)
        : (_routeDurationText ?? '--');
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: _C.accentSoft,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _C.accent.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _C.accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.schedule_rounded,
                size: 14,
                color: _C.accent,
              ),
            ),
            const SizedBox(width: 10),
            // Label ellipsizes if space is tight; the time itself always shows
            // in full so values like "15 hours 20 mins" aren't cut off.
            const Expanded(
              child: Text(
                "Est. time (incl. return)",
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  color: _C.text2,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              timeText,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: _C.text1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Renders a minute count back into a "1 day 3 hours 46 mins" style string.
  String _formatDuration(int minutes) {
    if (minutes <= 0) return '--';
    final d = minutes ~/ 1440;
    final h = (minutes % 1440) ~/ 60;
    final m = minutes % 60;
    final parts = <String>[];
    if (d > 0) parts.add('$d day${d > 1 ? 's' : ''}');
    if (h > 0) parts.add('$h hour${h > 1 ? 's' : ''}');
    if (m > 0) parts.add('$m min${m > 1 ? 's' : ''}');
    return parts.isEmpty ? '--' : parts.join(' ');
  }

  // Round-trip switch. Toggling it doubles / halves the Distance field (a return
  // trip covers the route both ways) and re-seeds Trip Charges + Fuel so the
  // figures stay in sync with the choice.
  Widget _returnTripToggle() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _C.surfaceLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _C.divider),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _C.accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.sync_alt_rounded,
                size: 14,
                color: _C.accent,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Return Trip",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _C.text1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _isReturnTrip
                        ? "Round trip · distance ×2"
                        : "One-way · charged ×1.5 (incl. half return)",
                    style: const TextStyle(fontSize: 11, color: _C.text2),
                  ),
                ],
              ),
            ),
            Switch(
              value: _isReturnTrip,
              activeColor: _C.accent,
              onChanged: (v) {
                // Reflect the round/one-way choice in the Distance field: double
                // it when switching to round trip, halve it when switching back.
                final cur = double.tryParse(distance.text.trim());
                setState(() {
                  _isReturnTrip = v;
                  if (cur != null && cur > 0) {
                    final adjusted = v ? cur * 2 : cur / 2;
                    distance.text = adjusted == adjusted.roundToDouble()
                        ? adjusted.toStringAsFixed(0)
                        : adjusted.toStringAsFixed(1);
                  }
                });
                _recalcFuel();
                _recalcCharges();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _goAddVehicle() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddVehiclePage()),
    );

    if (mounted && startDt != null) {
      _fetch();
    }
  }

  Future<void> _goAddDriver() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddDriverPage()),
    );

    if (mounted && startDt != null) {
      _fetch();
    }
  }

  // ── Save ───────────────────────────────────────────────────────────────────
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (startDt == null) {
      _snack("Select start date/time");
      return;
    }
    if (selVehicle == null) {
      _snack("Select vehicle");
      return;
    }
    // A back-dated (completed) trip needs an end time to be logged.
    if (_isCompletedTrip && endDt == null) {
      _snack("Select end date/time for the completed trip");
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

    final completed = _isCompletedTrip;
    final toll = double.tryParse(tollCharges.text.trim()) ?? 0;
    final repair = double.tryParse(repairCharges.text.trim()) ?? 0;
    final driverChg = double.tryParse(driverCharges.text.trim()) ?? 0;
    final fuelChg = double.tryParse(fuelCharges.text.trim()) ?? 0;
    final received = double.tryParse(amountReceived.text.trim()) ?? 0;

    final bk = TripBooking(
      tripId: widget.booking?.tripId,
      vehicleid: selVehicle!,
      driverid: selDriver,
      customerid: customerId,
      pickuplocation: pickup.text,
      droplocation: drop.text,
      distance: double.tryParse(distance.text.trim()) ?? 0,
      fuelrequired: double.tryParse(fuelReq.text.trim()) ?? 0,
      tripcharges: double.tryParse(charges.text.trim()) ?? 0,
      isreturntrip: _isReturnTrip ? 1 : 0,
      tollcharges: completed ? toll : null,
      repairingcharges: completed ? repair : null,
      drivercharges: completed ? driverChg : null,
      fuelcharges: completed ? fuelChg : null,
      startDateTime: startDt,
      endDateTime: endDt,
      // A back-dated trip is created as Active (1) so it can immediately be
      // ended — which records the charges + payment and moves it to Paid /
      // Unpaid. A normal future trip stays an upcoming booking (3).
      status: widget.booking?.status ?? (completed ? 1 : 3),
      bookingdate: widget.booking?.bookingDate ?? DateTime.now(),
      agencyId: agencyId,
    );

   

    final n = ref.read(tripBookingViewModelProvider.notifier);
    final bool isUpdate = widget.booking != null;
    bool completionRecorded = false;
    int? tripId = widget.booking?.tripId;

    // Save (create or update) the booking. The viewmodel returns null on
    // success or a user-facing reason on failure — surface failures so the
    // operator knows the trip was NOT saved instead of silently navigating away.
    final saveErr = isUpdate
        ? await n.updateTripBooking(tripId ?? 0, bk)
        : await n.addTripBooking(bk);
    if (saveErr != null) {
      if (!mounted) return;
      setState(() => _saving = false);
      _snack(isUpdate ? "Trip not updated: $saveErr" : "Trip not saved: $saveErr");
      return;
    }
    if (!isUpdate) {
      // Recover the new trip id from the create response so we can complete it.
      tripId = _findTripId(ref.read(tripBookingViewModelProvider).data);
      debugPrint("Created trip with id $tripId");
    }

    // For a back-dated trip, stamp the end time + final charges + amount
    // received using the same endTrip flow the trip card uses. This moves
    // the trip to Paid / Unpaid based on what was collected.
    if (completed && tripId != null) {
      final err = await ref
          .read(tripPageViewModelProvider.notifier)
          .updatePaymentStatus(
            BookingInfo(
              tripId: tripId,
              tollCharges: toll,
              repairingCharges: repair,
              driverCharges: driverChg,
              fuelCharges: fuelChg,
              amountReceived: received,
            ),
          );
      if (err != null) {
        if (!mounted) return;
        setState(() => _saving = false);
        _snack("Payment not recorded: $err");
        return;
      }
      completionRecorded = true;
    }

    if (!mounted) return;
    setState(() => _saving = false);
    // Trip was created but we couldn't auto-record payment (no id returned) —
    // let the operator finish it from the trip card.
    if (completed && !completionRecorded) {
      _snack("Trip saved. Record charges & payment from the trip card.");
    } else {
      _snackSuccess(isUpdate
          ? "Trip updated successfully"
          : "Trip booked successfully");
    }
    Navigator.pop(context);
  }

  // Recursively pulls a trip id out of the create-trip API response, mirroring
  // the customer-id extraction. Returns null when none is present.
  int? _findTripId(dynamic node) {
    if (node == null) return null;
    if (node is int) return node;
    if (node is num) return node.toInt();
    if (node is String) {
      final direct = int.tryParse(node.trim());
      if (direct != null) return direct;
      final digits = RegExp(r'\d+').firstMatch(node)?.group(0);
      return digits != null ? int.tryParse(digits) : null;
    }
    if (node is Map) {
      const keys = <String>[
        'trip_id',
        'tripId',
        'TripId',
        'tripID',
        'TripID',
        'id',
        'ID',
        'insertId',
        'InsertId',
        'insertedId',
        'InsertedId',
      ];
      for (final k in keys) {
        if (node.containsKey(k)) {
          final found = _findTripId(node[k]);
          if (found != null) return found;
        }
      }
      for (final v in node.values) {
        final found = _findTripId(v);
        if (found != null) return found;
      }
      return null;
    }
    if (node is Iterable) {
      for (final item in node) {
        final found = _findTripId(item);
        if (found != null) return found;
      }
    }
    return null;
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tripBookingViewModelProvider);
    final tripState = ref.watch(tripPageViewModelProvider);
    final isEdit = widget.booking != null;
    final pb = MediaQuery.of(context).padding.bottom;

    // Build FuelTypeId → name map from the loaded fuel-type list so the vehicle
    // dropdown can show the fuel type even when the API only returns the id.
    final fuelTypes = ref
            .watch(addVehicleViewModelProvider)
            .fetchFuelTypeList
            .asData
            ?.value ??
        const [];
    _fuelTypeNames = {
      for (final f in fuelTypes)
        if (f.FuelTypeId != null && (f.FuelType ?? '').trim().isNotEmpty)
          f.FuelTypeId!: f.FuelType!.trim(),
    };

    // Trips we mine for route + fare memory. We pull from EVERY trip list —
    // active, upcoming, unpaid, cancelled and completed history — so location
    // suggestions cover any route the agency has ever booked, not just paid
    // ones. Fare suggestion (fromHistory) further filters to trips that carry a
    // real `amountApprove`, so including extra lists here is safe.
    final history =
        state.routeHistory.asData?.value ?? const <BookingInfo>[];
    final activeTrips =
        tripState.activeList.asData?.value ?? const <BookingInfo>[];
    final upcomingTrips =
        tripState.upcomingList.asData?.value ?? const <BookingInfo>[];
    final unpaidTrips =
        tripState.unpaidList.asData?.value ?? const <BookingInfo>[];
    final cancelledTrips =
        tripState.cancelledList.asData?.value ?? const <BookingInfo>[];
    final routeTrips = <BookingInfo>[
      ...activeTrips,
      ...upcomingTrips,
      ...unpaidTrips,
      ...cancelledTrips,
      ...history,
    ];

    final fare = RouteFareSuggestion.fromHistory(
      routeTrips,
      pickup: pickup.text,
      drop: drop.text,
      // Only suggest fares from past trips made with the chosen vehicle.
      vehicleId: selVehicle,
    );

    final pickupOptions =
        _distinctLocations(routeTrips.map((t) => t.pickupLocation));
    final dropOptions =
        _distinctLocations(routeTrips.map((t) => t.dropLocation));

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

                      // ── 02  SCHEDULE ─────────────────────────────────────────
                      _FadeSlide(
                        anim: _anims[1],
                        child: _sectionCard(
                          icon: Icons.calendar_month_rounded,
                          label: "Trip Schedule",
                          iconColor: _C.purple,
                          iconBg: _C.purpleSoft,
                          badge: "02",
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
                                label: "End Date & Time (Optional)",
                                ctrl: endDate,
                                icon: Icons.stop_circle_rounded,
                                color: _C.red,
                                bg: _C.redSoft,
                                onTap: () => _pickDt(false),
                                onClear: () {
                                  setState(() {
                                    endDt = null;
                                    endDate.clear();
                                  });
                                },
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

                      // ── 03  ROUTE ────────────────────────────────────────────
                      _FadeSlide(
                        anim: _anims[2],
                        child: _sectionCard(
                          icon: Icons.route_rounded,
                          label: "Route Details",
                          iconColor: _C.accent,
                          iconBg: _C.accentSoft,
                          badge: "03",
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
                              _returnTripToggle(),
                              _divider(),
                              _inputField(
                                label: "Distance (KM)",
                                ctrl: distance,
                                icon: Icons.straighten_rounded,
                                iconColor: _C.accent,
                                iconBg: _C.accentSoft,
                                // Tapping the Distance field auto-calculates the
                                // road distance from the entered pickup/drop.
                                onTap: () => _maybeFetchDistance(),
                                keyboard: const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                fmt: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'[\d.]'),
                                  ),
                                ],
                                suffixIcon: _fetchingDistance
                                    ? const Padding(
                                        padding: EdgeInsets.all(14),
                                        child: SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      )
                                    : null,
                              ),
                              _routeInfoChip(),
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
                              if (startDt == null)
                                _lockedTile(
                                  "Vehicle",
                                  Icons.directions_car_rounded,
                                  "Set start date/time to unlock vehicles",
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
                                      items: _vehiclesByFuelAsc(list)
                                          .map(
                                            (e) => _DropItem(
                                              value: e.vehicleId!,
                                              label:
                                                  "${e.name ?? ''} (${e.number ?? ''})",
                                              subtitle: _fuelLabelFor(e),
                                              icon:
                                                  Icons.directions_car_rounded,
                                              color: _C.accent,
                                            ),
                                          )
                                          .toList(),
                                      onSelect: (val, label) => setState(() {
                                        selVehicle = val;
                                        selVehicleLabel = label;
                                        _recalcFuel();
                                        _recalcCharges();
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

                              // Fuel needed for the SELECTED vehicle (this is the
                              // value saved to the DB). Shown once a vehicle is
                              // chosen; auto-filled from distance ÷ mileage.
                              if (selVehicle != null) ...[
                                const SizedBox(height: 14),
                                _assignLabel("Fuel Required"),
                                const SizedBox(height: 6),
                                _inputField(
                                  label: "Fuel Required (${_selectedFuelUnit()})",
                                  ctrl: fuelReq,
                                  icon: Icons.local_gas_station_rounded,
                                  iconColor: _C.orange,
                                  iconBg: _C.orangeSoft,
                                  keyboard:
                                      const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  fmt: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'[\d.]'),
                                    ),
                                  ],
                                ),
                                // Trip Charges — auto-filled from the selected
                                // vehicle's per-km rate (distance × rate), shown
                                // here like Fuel Required. Still editable, with a
                                // breakdown chip beside it showing the maths.
                                const SizedBox(height: 14),
                                _assignLabel("Trip Charges"),
                                const SizedBox(height: 6),
                                Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: _inputField(
                                        label: "Trip Charges",
                                        ctrl: charges,
                                        icon: Icons.currency_rupee_rounded,
                                        iconColor: _C.purple,
                                        iconBg: _C.purpleSoft,
                                        prefix: "₹  ",
                                        keyboard: const TextInputType
                                            .numberWithOptions(decimal: true),
                                        fmt: [
                                          FilteringTextInputFormatter.allow(
                                            RegExp(r'[\d.]'),
                                          ),
                                        ],
                                      ),
                                    ),
                                    _chargeBreakdown(),
                                  ],
                                ),
                                // Route fare suggestion — tapping it seeds the
                                // Trip Charges field above.
                                _fareChip(fare),
                              ],

                              const SizedBox(height: 14),

                              // ── Driver ───────────────────────────────────────────
                              _assignLabel("Driver (optional)"),
                              const SizedBox(height: 6),
                              if (startDt == null)
                                _lockedTile(
                                  "Driver",
                                  Icons.person_pin_circle_rounded,
                                  "Set start date/time to unlock drivers",
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
                                      hasError: false,
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

                      // ── 05  TRIP COMPLETION (only for back-dated trips) ──────
                      if (_isCompletedTrip) ...[
                        const SizedBox(height: 12),
                        _FadeSlide(
                          anim: _anims[4],
                          child: _completionCard(),
                        ),
                      ],
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
      decoration: BoxDecoration(
        color: _C.surface,
        boxShadow: [
          BoxShadow(
            color: _C.text1.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 16, 14),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _C.surfaceLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _C.divider),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: _C.text1,
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
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: _C.text1,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isEdit
                        ? "Update trip details"
                        : "Fill in all trip details",
                    style: const TextStyle(fontSize: 12.5, color: _C.text2),
                  ),
                ],
              ),
            ),
          ],
        ),
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.divider),
        boxShadow: [
          BoxShadow(
            color: _C.text1.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 15, 14, 14),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 18, color: iconColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: _C.text1,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "STEP $badge",
                    style: TextStyle(
                      color: iconColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 9.5,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: _C.divider),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
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
      optionsBuilder: (TextEditingValue value) async {
        final raw = value.text.trim();
        final q = raw.toLowerCase();
        if (q.isEmpty) {
          // Field focused but empty: show up to 6 recent unique locations.
          return options.take(6);
        }
        // Past trips for this route come first — they're instant and the most
        // relevant to this agency.
        final past = options
            .where((s) {
              final lower = s.toLowerCase();
              return lower.contains(q) && lower != q;
            })
            .take(5)
            .toList();
        // Always also fetch Google Places (debounced) and merge it in AFTER the
        // history matches, so the operator sees both their own past routes and
        // fresh map suggestions. Dedup case-insensitively, keeping history's
        // copy when a place appears in both.
        final places = await _placeSuggestions(raw);
        final seen = past.map((s) => s.toLowerCase()).toSet();
        final merged = <String>[...past];
        for (final p in places) {
          if (seen.add(p.toLowerCase())) merged.add(p);
        }
        return merged;
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
                  // History routes get a clock icon; Google Places suggestions
                  // get a map pin, so the operator can tell at a glance which
                  // came from their own past trips.
                  final isFromHistory = options.any(
                    (o) => o.toLowerCase() == option.toLowerCase(),
                  );
                  return InkWell(
                    onTap: () => onSelected(option),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isFromHistory
                                ? Icons.history_rounded
                                : Icons.location_on_outlined,
                            size: 16,
                            color: isFromHistory ? _C.accent : _C.text2,
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
                          if (isFromHistory)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _C.accentSoft,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                "Past trip",
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: _C.accent,
                                ),
                              ),
                            )
                          else
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
    VoidCallback? onTap,
  }) {
    return TextFormField(
      controller: ctrl,
      focusNode: focusNode,
      onTap: onTap,
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
          padding: const EdgeInsets.all(9),
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 15, color: iconColor),
          ),
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: _C.surfaceLight,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _C.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _C.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _C.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
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
    VoidCallback? onClear,
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
          borderRadius: BorderRadius.circular(14),
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
            if (has && onClear != null)
              GestureDetector(
                onTap: onClear,
                child: Container(
                  width: 28,
                  height: 28,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: _C.text2.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: _C.text2.withOpacity(0.6),
                  ),
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
        borderRadius: BorderRadius.circular(12),
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
        borderRadius: BorderRadius.circular(14),
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
                      color: color,
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
              borderRadius: BorderRadius.circular(14),
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
                    color: hasVal ? color : bg,
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
      borderRadius: BorderRadius.circular(14),
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
      borderRadius: BorderRadius.circular(14),
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
      borderRadius: BorderRadius.circular(14),
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
  // ══════════════════════════════════════════════════════════════════════════
  //  TRIP COMPLETION  ← shown only for back-dated trips (start in the past)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _completionCard() {
    Widget chargeField(
      String label,
      TextEditingController ctrl,
      IconData icon, {
      Color color = _C.orange,
      Color bg = _C.orangeSoft,
    }) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _assignLabel(label),
            const SizedBox(height: 6),
            _inputField(
              label: label,
              ctrl: ctrl,
              icon: icon,
              iconColor: color,
              iconBg: bg,
              prefix: "₹  ",
              keyboard: const TextInputType.numberWithOptions(decimal: true),
              fmt: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
              // Optional — empty means zero, not a validation error.
              validator: (_) => null,
            ),
          ],
        ),
      );
    }

    return _sectionCard(
      icon: Icons.task_alt_rounded,
      label: "Trip Completion",
      iconColor: _C.green,
      iconBg: _C.greenSoft,
      badge: "05",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: _C.greenSoft,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _C.green.withOpacity(0.25)),
            ),
            child: Row(
              children: const [
                Icon(Icons.info_outline_rounded, size: 16, color: _C.green),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "This trip is in the past. Enter the final charges and "
                    "amount received to log it as a completed trip.",
                    style: TextStyle(
                      fontSize: 11.5,
                      color: _C.text1,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          chargeField("Toll Charges", tollCharges, Icons.toll_rounded),
          chargeField("Repair Charges", repairCharges, Icons.build_rounded),
          chargeField(
            "Driver Charges",
            driverCharges,
            Icons.payments_rounded,
          ),
          chargeField(
            "Fuel Charges",
            fuelCharges,
            Icons.local_gas_station_rounded,
          ),
          chargeField(
            "Amount Received",
            amountReceived,
            Icons.account_balance_wallet_rounded,
            color: _C.green,
            bg: _C.greenSoft,
          ),
          _completionSummary(),
        ],
      ),
    );
  }

  // Live balance + payment-status preview for the completion section. Approved
  // fare comes from the Trip Charges field; received from the field above.
  Widget _completionSummary() {
    final approved = double.tryParse(charges.text.trim()) ?? 0;
    final received = double.tryParse(amountReceived.text.trim()) ?? 0;
    final balance = (approved - received) <= 0 ? 0.0 : approved - received;

    late final String label;
    late final Color color;
    late final Color bg;
    late final IconData icon;
    if (approved > 0 && received >= approved) {
      label = "Paid";
      color = _C.green;
      bg = _C.greenSoft;
      icon = Icons.check_circle_rounded;
    } else if (received > 0) {
      label = "Partially Paid";
      color = _C.orange;
      bg = _C.orangeSoft;
      icon = Icons.timelapse_rounded;
    } else {
      label = "Unpaid";
      color = _C.red;
      bg = _C.redSoft;
      icon = Icons.cancel_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: _C.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.divider),
      ),
      child: Column(
        children: [
          _summaryRow("Approved fare", "₹${_money(approved)}", _C.text2),
          const SizedBox(height: 6),
          _summaryRow("Received", "₹${_money(received)}", _C.green),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1, color: _C.divider),
          ),
          Row(
            children: [
              Text(
                "Balance due",
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: _C.text2,
                ),
              ),
              const Spacer(),
              Text(
                "₹${_money(balance)}",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: balance > 0 ? _C.red : _C.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                "Trip will be saved as",
                style: TextStyle(fontSize: 12, color: _C.text2),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 13, color: color),
                    const SizedBox(width: 5),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, Color valueColor) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            color: _C.text2,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
      ],
    );
  }

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
          Expanded(
            child: GestureDetector(
              onTap: _saving ? null : _save,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 54,
                decoration: BoxDecoration(
                  color: _saving ? Colors.grey.shade400 : _C.accent,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: _saving
                      ? []
                      : [
                          BoxShadow(
                            color: _C.accent.withOpacity(0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_saving)
                      const SizedBox(
                        width: 18,
                        height: 18,
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
                        size: 20,
                      ),
                    const SizedBox(width: 10),
                    Text(
                      _saving
                          ? "Saving..."
                          : isEdit
                          ? "Update Trip"
                          : "Save Booking",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        letterSpacing: 0.2,
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

  // Green confirmation snackbar — used when a save/update API call succeeds.
  void _snackSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
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
        backgroundColor: Colors.green,
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
                                color: widget.color,
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
                                  color: isSelected ? widget.color : _C.accent,
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
                                            item.subtitle!.startsWith('Fuel')
                                                ? Icons.local_gas_station_rounded
                                                : (item.subtitle!.startsWith(
                                                            '0',
                                                          ) ||
                                                          item.subtitle!
                                                              .startsWith('+'))
                                                    ? Icons.phone_rounded
                                                    : Icons.badge_rounded,
                                            size: 11,
                                            color:
                                                item.subtitle!.startsWith('Fuel')
                                                    ? _C.orange
                                                    : _C.text2,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            item.subtitle!,
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              color: item.subtitle!.startsWith(
                                                'Fuel',
                                              )
                                                  ? _C.orange
                                                  : _C.text2,
                                              fontWeight:
                                                  item.subtitle!.startsWith(
                                                'Fuel',
                                              )
                                                      ? FontWeight.w800
                                                      : FontWeight.w500,
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
                        color: widget.color,
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

// ════════════════════════════════════════════════════════════════════════════
//  SCROLLABLE + TYPABLE TIME FIELD
//  A single hour/minute unit the operator can: (a) type into directly,
//  (b) drag up/down to change, (c) scroll with a mouse wheel, or (d) nudge with
//  the up/down chevrons. Values wrap within [min, max].
// ════════════════════════════════════════════════════════════════════════════
class _ScrollTypeTimeField extends StatefulWidget {
  final int value;
  final int min;
  final int max;
  final bool pad2;
  final Color accent;
  final ValueChanged<int> onChanged;

  const _ScrollTypeTimeField({
    required this.value,
    required this.min,
    required this.max,
    required this.accent,
    required this.onChanged,
    this.pad2 = false,
  });

  @override
  State<_ScrollTypeTimeField> createState() => _ScrollTypeTimeFieldState();
}

class _ScrollTypeTimeFieldState extends State<_ScrollTypeTimeField> {
  late final TextEditingController _c;
  final _focus = FocusNode();
  double _dragAcc = 0;

  String _fmt(int v) =>
      widget.pad2 ? v.toString().padLeft(2, '0') : v.toString();

  @override
  void initState() {
    super.initState();
    _c = TextEditingController(text: _fmt(widget.value));
    _focus.addListener(() {
      if (_focus.hasFocus) {
        // Select the whole value on focus so a tap lets the user immediately
        // type a new time instead of editing the existing digits.
        _c.selection =
            TextSelection(baseOffset: 0, extentOffset: _c.text.length);
      } else {
        _commit();
      }
    });
  }

  @override
  void didUpdateWidget(covariant _ScrollTypeTimeField old) {
    super.didUpdateWidget(old);
    // Reflect external changes (scroll/chevrons/other unit) unless the user is
    // mid-typing in this field.
    if (!_focus.hasFocus && widget.value != old.value) {
      _c.text = _fmt(widget.value);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _step(int delta) {
    final range = widget.max - widget.min + 1;
    final next =
        ((widget.value + delta - widget.min) % range + range) % range +
            widget.min;
    if (!_focus.hasFocus) _c.text = _fmt(next);
    widget.onChanged(next);
  }

  void _commit() {
    final parsed = int.tryParse(_c.text.trim());
    final clamped = (parsed ?? widget.value).clamp(widget.min, widget.max);
    _c.text = _fmt(clamped);
    if (clamped != widget.value) widget.onChanged(clamped);
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accent;
    return Listener(
      onPointerSignal: (e) {
        if (e is PointerScrollEvent) {
          _step(e.scrollDelta.dy > 0 ? -1 : 1);
        }
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragUpdate: (d) {
          _dragAcc += d.primaryDelta ?? 0;
          if (_dragAcc <= -6) {
            _step(1); // drag up → increase
            _dragAcc = 0;
          } else if (_dragAcc >= 6) {
            _step(-1); // drag down → decrease
            _dragAcc = 0;
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: () => _step(1),
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Icon(Icons.keyboard_arrow_up_rounded,
                    size: 18, color: accent),
              ),
            ),
            SizedBox(
              width: 40,
              child: TextField(
                controller: _c,
                focusNode: _focus,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 2,
                cursorColor: accent,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onTap: () => _c.selection =
                    TextSelection(baseOffset: 0, extentOffset: _c.text.length),
                onChanged: (t) {
                  final p = int.tryParse(t.trim());
                  if (p != null && p >= widget.min && p <= widget.max) {
                    widget.onChanged(p);
                  }
                },
                onSubmitted: (_) => _commit(),
                decoration: const InputDecoration(
                  isDense: true,
                  counterText: '',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 2),
                ),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _C.text1,
                ),
              ),
            ),
            InkWell(
              onTap: () => _step(-1),
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Icon(Icons.keyboard_arrow_down_rounded,
                    size: 18, color: accent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
