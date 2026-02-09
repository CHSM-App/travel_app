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

  // ---------------- BUILD ----------------

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tripBookingViewModelProvider);

    ref.listen(tripBookingViewModelProvider, (prev, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(next.error!)));
      }
      if (next.data != null && prev?.data != next.data) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Trip booking added successfully")),
        );
        Navigator.pop(context);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text("New Trip Booking"),
        centerTitle: true,
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: FilledButton.icon(
          icon: const Icon(Icons.save),
          label: const Text("Save Booking"),
          onPressed: state.isLoading ? null : _onSavePressed,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            textStyle: const TextStyle(fontSize: 16),
          ),
        ),
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
    );
  }

  // ---------------- RESPONSIVE LAYOUTS ----------------

  Widget _mobileLayout(TripBookingState state) {
    return _base(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: _sections(state),
      ),
    );
  }

  Widget _tabletLayout(TripBookingState state) {
    return _base(
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 900),
          child: GridView.count(
            padding: const EdgeInsets.all(16),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: _sections(state),
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
          child: GridView.count(
            padding: const EdgeInsets.all(20),
            crossAxisCount: 3,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            children: _sections(state),
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
          const Center(child: CircularProgressIndicator()),
      ],
    );
  }

  // ---------------- SECTIONS ----------------

  List<Widget> _sections(TripBookingState state) => [
         _sectionCard("Schedule", [
          _readonly(bookingDate, "Booking Date"),
          _gap(),
          _dateField(startDate, "Start Date & Time", true),
          _gap(),
          _dateField(endDate, "End Date & Time", false),
                   
        ]),

        _sectionCard("Trip Details", [
          _vehicleDropdown(state),
          _gap(),
          _driverDropdown(state),
          _gap(),
          _customerDropdown(state),
        ]),

        _sectionCard("Locations", [
          _text(pickup, "Pickup Location", Icons.location_on),
          _gap(),
          _text(drop, "Drop Location", Icons.flag),
        ]),
        
        _sectionCard("Charges & Distance", [
          _number(distance, "Distance (KM)", Icons.route),
          _gap(),
          _number(fuelRequired, "Fuel Required", Icons.local_gas_station),
          _gap(),
          _number(tollCharges, "Toll Charges", Icons.toll),
          _gap(),
          _number(repairingCharges, "Repair Charges", Icons.build),
          _gap(),
          _number(driverCharges, "Driver Charges", Icons.person),
          _gap(),
          _number(tripCharges, "Total Charges", Icons.currency_rupee),
        ]),
       
      ];

  // ---------------- SAVE ----------------

  Future<void> _onSavePressed() async {
    if (!_formKey.currentState!.validate()) return;

    if (startDateValue == null || endDateValue == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select start & end date")),
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
      tollcharges: double.parse(tollCharges.text),
      repairingcharges: double.parse(repairingCharges.text),
      drivercharges: double.parse(driverCharges.text),
      tripcharges: double.parse(tripCharges.text),
      startDateTime: startDateValue!,
      endDateTime: endDateValue!,
      status: 1,
      bookingdate: DateTime.now(),
    );

    await ref
        .read(tripBookingViewModelProvider.notifier)
        .addTripBooking(booking);
  }

  // ---------------- UI HELPERS ----------------

  Widget _sectionCard(String title, List<Widget> children) => Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...children,
            ],
          ),
        ),
      );

  Widget _gap() => const SizedBox(height: 12);

  Widget _text(TextEditingController c, String label, IconData icon) =>
      TextFormField(
        controller: c,
        decoration: _decoration(label, icon),
        validator: (v) => v == null || v.isEmpty ? "Required" : null,
      );

  Widget _number(TextEditingController c, String label, IconData icon) =>
      TextFormField(
        controller: c,
        keyboardType: TextInputType.number,
        decoration: _decoration(label, icon),
        validator: (v) =>
            v == null || double.tryParse(v) == null ? "Invalid number" : null,
      );

  Widget _dateField(
          TextEditingController c, String label, bool isStart) =>
      TextFormField(
        controller: c,
        readOnly: true,
        decoration: _decoration(label, Icons.calendar_month),
        onTap: () => _pickDate(c, isStart),
        validator: (v) => v == null || v.isEmpty ? "Select date" : null,
      );

  Widget _readonly(TextEditingController c, String label) => TextFormField(
        controller: c,
        readOnly: true,
        decoration: _decoration(label, Icons.event),
      );

  InputDecoration _decoration(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      );

  // ---------------- DATE PICKER ----------------

  Future<void> _pickDate(TextEditingController controller, bool isStart) async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2050),
      initialDate: DateTime.now(),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;

    final selected =
        DateTime(date.year, date.month, date.day, time.hour, time.minute);

    controller.text = DateFormat("yyyy-MM-dd HH:mm").format(selected);

    if (isStart) {
      startDateValue = selected;
    } else {
      endDateValue = selected;
    }
  }

  // ---------------- DROPDOWNS ----------------

  Widget _driverDropdown(TripBookingState state) =>
      state.fetchDriverList.when(
        loading: () => _loadingDropdown("Driver"),
        error: (e, _) => Text("Driver error: $e"),
        data: (List<Drivers> drivers) => DropdownButtonFormField<int>(
          value: selectedDriverId,
          items: drivers
              .map((d) => DropdownMenuItem(
                    value: d.driverId,
                    child: Text(d.name ?? ""),
                  ))
              .toList(),
          onChanged: (v) => setState(() => selectedDriverId = v),
          validator: (v) => v == null ? "Select driver" : null,
          decoration: _decoration("Driver", Icons.person),
        ),
      );

  Widget _vehicleDropdown(TripBookingState state) =>
      state.fetchVehicleList.when(
        loading: () => _loadingDropdown("Vehicle"),
        error: (e, _) => Text("Vehicle error: $e"),
        data: (List<Vehicles> vehicles) => DropdownButtonFormField<int>(
          value: selectedVehicleId,
          items: vehicles
              .map((v) => DropdownMenuItem(
                    value: v.vehicleId,
                    child: Text(v.name ?? ""),
                  ))
              .toList(),
          onChanged: (v) => setState(() => selectedVehicleId = v),
          validator: (v) => v == null ? "Select vehicle" : null,
          decoration: _decoration("Vehicle", Icons.directions_car),
        ),
      );

  Widget _customerDropdown(TripBookingState state) =>
      state.fetchCustomerList.when(
        loading: () => _loadingDropdown("Customer"),
        error: (e, _) => Text("Customer error: $e"),
        data: (List<Customer> customers) => DropdownButtonFormField<int>(
          value: selectedCustomerId,
          items: customers
              .map((c) => DropdownMenuItem(
                    value: c.CustomerId,
                    child: Text(c.name ?? ""),
                  ))
              .toList(),
          onChanged: (v) => setState(() => selectedCustomerId = v),
          validator: (v) => v == null ? "Select customer" : null,
          decoration: _decoration("Customer", Icons.people),
        ),
      );

  Widget _loadingDropdown(String label) => DropdownButtonFormField<int>(
        items: const [],
        onChanged: null,
        decoration: _decoration("Loading $label...", Icons.hourglass_empty),
      );
}
