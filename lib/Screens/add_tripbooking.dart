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

  /// TEXT FIELDS
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

  /// DROPDOWN SELECTED IDS
  int? selectedDriverId;
  int? selectedVehicleId;
  int? selectedCustomerId;

  /// DATE
  final startDate = TextEditingController();
  final endDate = TextEditingController();
  DateTime? startDateValue;
  DateTime? endDateValue;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final notifier =
          ref.read(tripBookingViewModelProvider.notifier);
      notifier.driverList();
      notifier.vehicleList();
      notifier.customerList();
    });
  }

  Future<void> pickDate(
      TextEditingController controller, bool isStart) async {
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

    final selected = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    controller.text =
        DateFormat("yyyy-MM-dd HH:mm").format(selected);

    if (isStart) {
      startDateValue = selected;
    } else {
      endDateValue = selected;
    }
  }

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
          const SnackBar(content: Text("Trip booking added")),
        );
        Navigator.pop(context);
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text("Add Trip Booking")),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  _vehicleDropdown(state),
                   const SizedBox(height: 12),
                  _driverDropdown(state),
                   const SizedBox(height: 12),
                  _customerDropdown(state),
                   const SizedBox(height: 12),

                  _text(pickup, "Pickup Location"),
                  _text(drop, "Drop Location"),

                  Row(
                    children: [
                      Expanded(child: _number(distance, "Distance (KM)")),
                      const SizedBox(width: 10),
                      Expanded(child: _number(fuelRequired, "Fuel Required")),
                    ],
                  ),

                  Row(
                    children: [
                      Expanded(child: _number(tollCharges, "Toll Charges")),
                      const SizedBox(width: 10),
                      Expanded(
                          child:
                              _number(repairingCharges, "Repair Charges")),
                    ],
                  ),

                  _number(driverCharges, "Driver Charges"),
                  _number(tripCharges, "Trip Charges"),

                  _dateField(startDate, "Start Date & Time", true),
                  _dateField(endDate, "End Date & Time", false),

                  _readonly(bookingDate, "Booking Date"),

                  const SizedBox(height: 20),

                  FilledButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text("Save Booking"),
                    onPressed: state.isLoading
                        ? null
                        : () async {
                            if (!_formKey.currentState!.validate()) return;
                            if (startDateValue == null ||
                                endDateValue == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text("Select start & end date")),
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
                              fuelrequired:
                                  double.parse(fuelRequired.text),
                              tollcharges:
                                  double.parse(tollCharges.text),
                              repairingcharges:
                                  double.parse(repairingCharges.text),
                              drivercharges:
                                  double.parse(driverCharges.text),
                              tripcharges:
                                  double.parse(tripCharges.text),
                              startDateTime: startDateValue!,
                              endDateTime: endDateValue!,
                              status: 1,
                              bookingdate: DateTime.now(),
                            );

                            await ref
                                .read(tripBookingViewModelProvider
                                    .notifier)
                                .addTripBooking(booking);
                          },
                  )
                ],
              ),
            ),
          ),
          if (state.isLoading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  /// ---------------- DROPDOWNS ----------------

 Widget _driverDropdown(TripBookingState state) =>
      state.fetchDriverList.when(
       loading: () => DropdownButtonFormField<int>(
  items: const [],
  onChanged: null,
  decoration: const InputDecoration(
    labelText: "Loading...",
    border: OutlineInputBorder(),
  ),
),

        error: (e, _) => Text("Driver error: $e"),
        data: (List<Drivers> drivers) =>
            DropdownButtonFormField<int>(
          value: selectedDriverId,
          items: drivers
              .map((d) => DropdownMenuItem(
                    value: d.driverId,
                    child: Text(d.name??""),
                  ))
              .toList(),
          onChanged: (v) => setState(() => selectedDriverId = v),
          validator: (v) => v == null ? "Select driver" : null,
          decoration: const InputDecoration(
            labelText: "Driver",
            border: OutlineInputBorder(),
          ),
        ),
      );

  Widget _vehicleDropdown(TripBookingState state) =>
      state.fetchVehicleList.when(
       loading: () => DropdownButtonFormField<int>(
  items: const [],
  onChanged: null,
  decoration: const InputDecoration(
    labelText: "Loading...",
    border: OutlineInputBorder(),
  ),
),

        error: (e, _) => Text("Vehicle error: $e"),
        data: (List<Vehicles> vehicles) =>
            DropdownButtonFormField<int>(
          value: selectedVehicleId,
          items: vehicles
              .map((v) => DropdownMenuItem(
                    value: v.vehicleId,
                    child: Text(v.name??""),
                  ))
              .toList(),
          onChanged: (v) => setState(() => selectedVehicleId = v),
          validator: (v) => v == null ? "Select vehicle" : null,
          decoration: const InputDecoration(
            labelText: "Vehicle",
            border: OutlineInputBorder(),
          ),
        ),
      );

  Widget _customerDropdown(TripBookingState state) =>
      state.fetchCustomerList.when(
     loading: () => DropdownButtonFormField<int>(
  items: const [],
  onChanged: null,
  decoration: const InputDecoration(
    labelText: "Loading...",
    border: OutlineInputBorder(),
  ),
),

        error: (e, _) => Text("Customer error: $e"),
        data: (List<Customer> customers) =>
            DropdownButtonFormField<int>(
          value: selectedCustomerId,
          items: customers
              .map((c) => DropdownMenuItem(
                    value: c.customerId??0,
                    child: Text(c.name??""),
                  ))
              .toList(),
          onChanged: (v) => setState(() => selectedCustomerId = v),
          validator: (v) => v == null ? "Select customer" : null,
          decoration: const InputDecoration(
            labelText: "Customer",
            border: OutlineInputBorder(),
          ),
        ),
      );

  /// ---------------- COMMON FIELDS ----------------

  Widget _text(TextEditingController c, String label) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: TextFormField(
          controller: c,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
          validator: (v) =>
              v == null || v.isEmpty ? "Required" : null,
        ),
      );

  Widget _number(TextEditingController c, String label) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: TextFormField(
          controller: c,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
          validator: (v) =>
              v == null || double.tryParse(v) == null
                  ? "Invalid number"
                  : null,
        ),
      );

  Widget _dateField(
          TextEditingController c, String label, bool isStart) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: TextFormField(
          controller: c,
          readOnly: true,
          decoration: InputDecoration(
            labelText: label,
            suffixIcon: const Icon(Icons.calendar_month),
            border: const OutlineInputBorder(),
          ),
          onTap: () => pickDate(c, isStart),
          validator: (v) =>
              v == null || v.isEmpty ? "Select date" : null,
        ),
      );

  Widget _readonly(TextEditingController c, String label) =>
      TextFormField(
        controller: c,
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      );
}
