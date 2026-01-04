import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_agency_app/domain/models/vehicles.dart';
import 'package:travel_agency_app/domain/viewModel/addVehicle_viewmodel.dart';
import 'package:travel_agency_app/presentation/providers/viewmodel_provider.dart';


class AddVehiclePage extends ConsumerStatefulWidget {
  const AddVehiclePage({super.key});

  @override
  ConsumerState<AddVehiclePage> createState() => _AddVehiclePageState();
}

class _AddVehiclePageState extends ConsumerState<AddVehiclePage> {
  final _formKey = GlobalKey<FormState>();

 /// TEXT FIELDS
  final name = TextEditingController();
  final number = TextEditingController();
 // final type = TextEditingController();
  final capacity = TextEditingController();
  //final fuelType = TextEditingController();
  final mileage = TextEditingController();
  //final status = TextEditingController();
  final rcDocument = TextEditingController();

  /// DROPDOWN SELECTED IDS
  int? selectedTypeId;
  int? selectedFuelTypeId;
  int? selectedStatusId;

 @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final notifier = ref.read(addVehicleViewModelProvider.notifier);
      //notifier.driverList();
      //notifier.vehicleList();
     // notifier.customerList();
    });
  }



  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addVehicleViewModelProvider);

    ref.listen(addVehicleViewModelProvider, (prev, next) {
    
    if (next.error != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.error!)));
      }
      if (next.data != null && prev?.data != next.data) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Vehicle Added Successfully")));
        Navigator.pop(context);
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text("Add Vehicle")),
      body: Padding(
        padding: const EdgeInsets.all(14),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _VehicleTypeDropdown(state),
                  const SizedBox(height: 12),
              _FuelTypeDropdown(state),
                  const SizedBox(height: 12), 
              _StatusDropdown(state),
              const SizedBox(height: 12),

              _input(name, "Vehicle Name"),
              _input(number, "Vehicle Number"),
              _input(capacity, "Capacity", number: true),
              _input(mileage, "Mileage", decimal: true),
              _input(rcDocument, "RC Document"),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: state.isLoading
                    ? null
                    : () async {
                        if (_formKey.currentState!.validate()) {
                          final vehicle = Vehicles(
                            vehicleId: null,
                            fueltype: selectedFuelTypeId!,
                            name: name.text,
                            number: number.text,
                            type: selectedTypeId! ,
                            capacity: int.parse(capacity.text),
                            // fuelType: fuelType.text,
                            mileage: (mileage.text),
                            status: selectedStatusId!,
                            // rcDocument: rcDocument.text,
                          );

                          ref
                              .read(addVehicleViewModelProvider.notifier)
                              .addVehicle(vehicle);
                        }
                      },
                child: state.isLoading
                    ? const CircularProgressIndicator()
                    : const Text("Add Vehicle"),
              )
            ],
          ),
        ),
      ),
    );
  }

 Widget _VehicleTypeDropdown(AddVehicleState state) => state.fetchDriverList.when(
    loading: () => DropdownButtonFormField<int>(
      items: const [],
      onChanged: null,
      decoration: const InputDecoration(
        labelText: "Loading...",
        border: OutlineInputBorder(),
      ),
    ),

    error: (e, _) => Text("Driver error: $e"),
    data: (List<Drivers> drivers) => DropdownButtonFormField<int>(
      value: selectedDriverId,
      items: drivers
          .map(
            (d) =>
                DropdownMenuItem(value: d.driverId, child: Text(d.name ?? "")),
          )
          .toList(),
      onChanged: (v) => setState(() => selectedDriverId = v),
      validator: (v) => v == null ? "Select driver" : null,
      decoration: const InputDecoration(
        labelText: "Driver",
        border: OutlineInputBorder(),
      ),
    ),
  );

  Widget _input(TextEditingController c, String label,
      {bool number = false, bool decimal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: c,
        keyboardType:
            number ? TextInputType.number : decimal ? TextInputType.number : null,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (v) => v == null || v.isEmpty ? "Required" : null,
      ),
    );
  }
}
 