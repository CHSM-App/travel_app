import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:travel_agency_app/domain/models/customers.dart';
import 'package:travel_agency_app/domain/models/drivers.dart';
import 'package:travel_agency_app/domain/models/tripbooking_info.dart';
import 'package:travel_agency_app/domain/models/vehicles.dart';
import 'package:travel_agency_app/domain/viewModel/tripbooking_viewmodel.dart';
import 'package:travel_agency_app/presentation/providers/viewmodel_provider.dart';

class TripBookingForm extends ConsumerStatefulWidget {
  const TripBookingForm({super.key});

  @override
  ConsumerState<TripBookingForm> createState() => _TripBookingFormState();
}

class _TripBookingFormState extends ConsumerState<TripBookingForm> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final pickup = TextEditingController();
  final drop = TextEditingController();
  final distance = TextEditingController();
  final fuelRequired = TextEditingController();
  final tollCharges = TextEditingController();
  final repairingCharges = TextEditingController();
  final driverCharges = TextEditingController();
  final tripCharges = TextEditingController();
  final bookingDate = TextEditingController(
    text: DateFormat("yyyy-MM-dd").format(DateTime.now()),
  );

  final startDate = TextEditingController();
  final endDate = TextEditingController();
  DateTime? startDateValue;
  DateTime? endDateValue;
  int? selectedDriverId;
  int? selectedVehicleId;
  int? selectedCustomerId;

  // Indigo color palette
  static const Color primaryIndigo = Color(0xFF3F51B5);
  static const Color lightIndigo = Color(0xFF5C6BC0);
  static const Color darkIndigo = Color(0xFF283593);
  static const Color accentIndigo = Color(0xFF536DFE);

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final notifier = ref.read(tripBookingViewModelProvider.notifier);
      notifier.driverList();
      notifier.vehicleList();
      notifier.customerList();
    });
  }

  @override
  void dispose() {
    pickup.dispose();
    drop.dispose();
    distance.dispose();
    fuelRequired.dispose();
    tollCharges.dispose();
    repairingCharges.dispose();
    driverCharges.dispose();
    tripCharges.dispose();
    bookingDate.dispose();
    startDate.dispose();
    endDate.dispose();
    super.dispose();
  }

  // ---------------- BUILD ----------------

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tripBookingViewModelProvider);

    ref.listen(tripBookingViewModelProvider, (prev, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
      if (next.data != null && prev?.data != next.data) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Trip booking added successfully"),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        Navigator.pop(context);
      }
    });

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryIndigo,
        foregroundColor: Colors.white,
        title: const Text(
          "New Trip Booking",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 700) {
            return _mobileLayout(state);
          } else if (constraints.maxWidth < 1100) {
            return _tabletLayout(state);
          } else {
            return _desktopLayout(state);
          }
        },
      ),
      bottomNavigationBar: _buildBottomBar(state),
    );
  }

  Widget _buildBottomBar(TripBookingState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: state.isLoading ? null : _onSavePressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryIndigo,
            foregroundColor: Colors.white,

            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: state.isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  "Save Booking",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
        ),
      ),
    );
  }

  // ---------------- RESPONSIVE LAYOUTS ----------------

  Widget _mobileLayout(TripBookingState state) {
    return _base(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ..._sections(state).map(
              (section) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: section,
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _tabletLayout(TripBookingState state) {
    return _base(
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 900),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              children: _sections(state)
                  .map(
                    (section) =>
                        SizedBox(width: (900 - 40 - 16) / 2, child: section),
                  )
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _desktopLayout(TripBookingState state) {
    return _base(
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1300),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Wrap(
              spacing: 20,
              runSpacing: 20,
              children: _sections(state)
                  .map(
                    (section) =>
                        SizedBox(width: (1300 - 48 - 40) / 3, child: section),
                  )
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _base({required Widget child}) {
    return Stack(
      children: [
        Form(key: _formKey, child: child),
        if (ref.watch(tripBookingViewModelProvider).isLoading)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: Center(
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: primaryIndigo),
                      SizedBox(height: 16),
                      Text(
                        "Processing...",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ---------------- SECTIONS ----------------

  Widget _disabledNumber(TextEditingController c, String label, IconData icon) =>
    TextFormField(
      controller: c,
      readOnly: true,
      enabled: false,
      decoration: _decoration(label, icon).copyWith(
        fillColor: Colors.grey[200],
      ),
    );




  List<Widget> _sections(TripBookingState state) => [
    _sectionCard("Schedule", Icons.calendar_today_rounded, [
      _readonly(bookingDate, "Booking Date", Icons.today),
      _gap(),
      _dateField(startDate, "Start Date & Time", true),
      _gap(),
      _dateField(endDate, "End Date & Time", false),
    ]),
    _sectionCard("Trip Details", Icons.info_outline_rounded, [
      _vehicleDropdown(state),
      _gap(),
      _driverDropdown(state),
      _gap(),
      _customerDropdown(state),
    ]),
    _sectionCard("Locations", Icons.place_outlined, [
      _text(pickup, "Pickup Location", Icons.my_location),
      _gap(),
      _text(drop, "Drop Location", Icons.location_on),
    ]),
    _sectionCard("Distance & Fuel", Icons.route_outlined, [
      _number(distance, "Distance (KM)", Icons.straighten),
      _gap(),
      _number(fuelRequired, "Fuel Required (L)", Icons.local_gas_station),
    ]),
    // _sectionCard("Additional Charges", Icons.receipt_long_outlined, [
    //   _number(tollCharges, "Toll Charges", Icons.toll),
    //   _gap(),
    //   _number(repairingCharges, "Repair Charges", Icons.build),
    //   _gap(),
    //   _number(driverCharges, "Driver Charges", Icons.person),
    // ]),
    _sectionCard("Additional Charges", Icons.receipt_long_outlined, [
  _disabledNumber(tollCharges, "Toll Charges", Icons.toll),
  _gap(),
  _disabledNumber(repairingCharges, "Repair Charges", Icons.build),
  _gap(),
  _disabledNumber(driverCharges, "Driver Charges", Icons.person),
]),

    _sectionCard("Total Amount", Icons.payments_outlined, [
      _number(tripCharges, "Total Trip Charges", Icons.currency_rupee),
    ]),
  ];

  // ---------------- SAVE ----------------

  Future<void> _onSavePressed() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Please fill all required fields"),
          backgroundColor: Colors.orange.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    if (startDateValue == null || endDateValue == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Please select start and end date"),
          backgroundColor: Colors.orange.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    final booking = TripBooking(
      vehicleid: selectedVehicleId!,
      driverid: selectedDriverId!,
      customerid: selectedCustomerId!,
      pickuplocation: pickup.text,
      droplocation: drop.text,
      distance: double.parse(distance.text),
      fuelrequired: double.parse(fuelRequired.text),
      // tollcharges: double.parse(tollCharges.text),
      // repairingcharges: double.parse(repairingCharges.text),
      // drivercharges: double.parse(driverCharges.text),
      tollcharges: 0,
      repairingcharges: 0,
      drivercharges: 0,

      tripcharges: double.parse(tripCharges.text),
      startDateTime: startDateValue!,
      endDateTime: endDateValue!,
      status: 3,
      bookingdate: DateTime.now(),
    );

    await ref
        .read(tripBookingViewModelProvider.notifier)
        .addTripBooking(booking);
  }

  // ---------------- UI HELPERS ----------------

  Widget _sectionCard(String title, IconData icon, List<Widget> children) {
    return Card(
      elevation: 2,
      shadowColor: primaryIndigo.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primaryIndigo.withOpacity(0.08),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: primaryIndigo, size: 22),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: darkIndigo,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _gap() => const SizedBox(height: 14);

  Widget _text(TextEditingController c, String label, IconData icon) =>
      TextFormField(
        controller: c,
        decoration: _decoration(label, icon),
        validator: (v) => v == null || v.isEmpty ? "Required" : null,
      );

  Widget _number(TextEditingController c, String label, IconData icon) =>
      TextFormField(
        controller: c,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: _decoration(label, icon),
        validator: (v) => v == null || v.isEmpty || double.tryParse(v) == null
            ? "Enter valid number"
            : null,
      );

  Widget _dateField(TextEditingController c, String label, bool isStart) =>
      TextFormField(
        controller: c,
        readOnly: true,
        decoration: _decoration(label, Icons.event).copyWith(
          suffixIcon: Icon(Icons.arrow_drop_down, color: primaryIndigo),
        ),
        onTap: () => _pickDate(c, isStart),
        validator: (v) => v == null || v.isEmpty ? "Select date" : null,
      );

  Widget _readonly(TextEditingController c, String label, IconData icon) =>
      TextFormField(
        controller: c,
        readOnly: true,
        decoration: _decoration(label, icon),
      );

  InputDecoration _decoration(String label, IconData icon) => InputDecoration(
    labelText: label,
    labelStyle: TextStyle(color: Colors.grey[700]),
    prefixIcon: Icon(icon, color: lightIndigo, size: 22),
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey[300]!),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey[300]!),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: primaryIndigo, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.red),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.red, width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  );

  // ---------------- DATE PICKER ----------------

  Future<void> _pickDate(TextEditingController controller, bool isStart) async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2050),
      initialDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryIndigo,
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (date == null) return;

    if (!mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryIndigo,
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (time == null) return;

    final selected = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    controller.text = DateFormat("MMM dd, yyyy • hh:mm a").format(selected);

    setState(() {
      if (isStart) {
        startDateValue = selected;
      } else {
        endDateValue = selected;
      }
    });
  }

  // ---------------- DROPDOWNS ----------------

  Widget _driverDropdown(TripBookingState state) => state.fetchDriverList.when(
    loading: () => _loadingDropdown("Driver", Icons.person),
    error: (e, _) => _errorText("Driver error: $e"),
    data: (List<Drivers> drivers) => DropdownButtonFormField<int>(
      value: selectedDriverId,
      items: drivers
          .map(
            (d) => DropdownMenuItem(
              value: d.driverId,
              child: Text(d.name ?? "Unknown"),
            ),
          )
          .toList(),
      onChanged: (v) => setState(() => selectedDriverId = v),
      validator: (v) => v == null ? "Select driver" : null,
      decoration: _decoration("Select Driver", Icons.person),
      isExpanded: true,
      icon: const Icon(Icons.arrow_drop_down, color: primaryIndigo),
    ),
  );

  Widget _vehicleDropdown(TripBookingState state) =>
      state.fetchVehicleList.when(
        loading: () => _loadingDropdown("Vehicle", Icons.directions_car),
        error: (e, _) => _errorText("Vehicle error: $e"),
        data: (List<Vehicles> vehicles) => DropdownButtonFormField<int>(
          value: selectedVehicleId,
          items: vehicles
              .map(
                (v) => DropdownMenuItem(
                  value: v.vehicleId,
                  child: Text(v.name ?? "Unknown"),
                ),
              )
              .toList(),
          onChanged: (v) => setState(() => selectedVehicleId = v),
          validator: (v) => v == null ? "Select vehicle" : null,
          decoration: _decoration("Select Vehicle", Icons.directions_car),
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, color: primaryIndigo),
        ),
      );

  // Widget _customerDropdown(TripBookingState state) =>
  //     state.fetchCustomerList.when(
  //       loading: () => _loadingDropdown("Customer", Icons.people),
  //       error: (e, _) => _errorText("Customer error: $e"),
  //       data: (List<Customer> customers) => DropdownButtonFormField<int>(
  //         value: selectedCustomerId,
  //         items: customers
  //             .map(
  //               (c) => DropdownMenuItem(
  //                 value: c.customerId,
  //                 child: Text(c.name ?? "Unknown"),
  //               ),
  //             )
  //             .toList(),
  //         onChanged: (v) => setState(() => selectedCustomerId = v),
  //         validator: (v) => v == null ? "Select customer" : null,
  //         decoration: _decoration("Select Customer", Icons.people),
  //         isExpanded: true,
  //         icon: const Icon(Icons.arrow_drop_down, color: primaryIndigo),
  //       ),
  //     );

  Widget _customerDropdown(TripBookingState state) =>
    
    state.fetchCustomerList.when(
      loading: () => _loadingDropdown("Customer", Icons.people),
      error: (e, _) => _errorText("Customer error: $e"),
      data: (List<Customer> customers) {

        // Remove duplicates (very important)
        final uniqueCustomers = {
          for (var c in customers) c.customerId: c
        }.values.toList();

        // If selected ID is not in list, reset it
        if (selectedCustomerId != null &&
            !uniqueCustomers.any((c) => c.customerId == selectedCustomerId)) {
          selectedCustomerId = null;
        }

        return DropdownButtonFormField<int>(
          value: selectedCustomerId,
          items: uniqueCustomers
              .map(
                (c) => DropdownMenuItem<int>(
                  value: c.customerId,
                  child: Text(c.name ?? "Unknown"),
                ),
              )
              .toList(),
          onChanged: (v) => setState(() => selectedCustomerId = v),
          validator: (v) => v == null ? "Select customer" : null,
          decoration: _decoration("Select Customer", Icons.people),
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, color: primaryIndigo),
        );
      },
    );


  Widget _loadingDropdown(String label, IconData icon) =>
      DropdownButtonFormField<int>(
        items: const [],
        onChanged: null,
        decoration: _decoration("Loading $label...", icon).copyWith(
          suffixIcon: const Padding(
            padding: EdgeInsets.only(right: 12),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: primaryIndigo,
              ),
            ),
          ),
        ),
      );

  Widget _errorText(String error) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.red.shade50,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.red.shade200),
    ),
    child: Row(
      children: [
        Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            error,
            style: TextStyle(color: Colors.red.shade700, fontSize: 13),
          ),
        ),
      ],
    ),
  );
}
