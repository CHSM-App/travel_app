import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_agency_app/domain/models/fueltype.dart';
import 'package:travel_agency_app/domain/models/status.dart';
import 'package:travel_agency_app/domain/models/vehicles.dart';
import 'package:travel_agency_app/domain/models/vehicletype.dart';
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
      notifier.fetchVehicleFuelTypeList();
      notifier.fetchVehicleTypeList();
      notifier.fetchstatusList();
    });
  }



  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addVehicleViewModelProvider);
    String error = "";
    String message="" ;
    ref.listen(addVehicleViewModelProvider, (prev, next) {
    
    if (next.error != null) {
         error = next.error!.toLowerCase().toString();

  if (error.contains("unique") || error.contains("duplicate")) {
    error = "Vehicle number already exists.";
  }

  if (error.contains("foreign key")) {
    message = "Selected record is linked and cannot be deleted.";
  }

  if (error.contains("not null")) {
    message = "Required field is missing.";
  }

  if (error.contains("check constraint")) {
    message = "Entered value is not valid.";
  }


        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
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
               const SizedBox(height: 10),
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

 Widget _VehicleTypeDropdown(AddVehicleState state) => state.fetchVehicleTypeList.when(
    loading: () => DropdownButtonFormField<int>(
      items: const [],
      onChanged: null,
      decoration: const InputDecoration(
        labelText: "Loading...",
        border: OutlineInputBorder(),
      ),
    ),

    error: (e, _) => Text("Vehicle Type error: $e"),
    data: (List<VehicleType> vehicleTypes) => DropdownButtonFormField<int>(
      value: selectedTypeId,
      items: vehicleTypes
          .map(
            (d) =>
                DropdownMenuItem(value: d.TypeId, child: Text(d.Type ?? "")),
          )
          .toList(),
      onChanged: (v) => setState(() => selectedTypeId = v),
      validator: (v) => v == null ? "Select vehicle type" : null,
      decoration: const InputDecoration(
        labelText: "Vehicle Type",
        border: OutlineInputBorder(),
      ),
    ),
  );


 Widget _FuelTypeDropdown(AddVehicleState state) => state.fetchFuelTypeList.when(
    loading: () => DropdownButtonFormField<int>(
      items: const [],
      onChanged: null,
      decoration: const InputDecoration(
        labelText: "Loading...",
        border: OutlineInputBorder(),
      ),
    ),

    error: (e, _) => Text("Fuel Type error: $e"),
    data: (List<Fueltype> fuelTypes) => DropdownButtonFormField<int>(
      value: selectedFuelTypeId,
      items: fuelTypes
          .map(
            (d) =>
                DropdownMenuItem(value: d.FuelTypeId, child: Text(d.FuelType ?? "")),
          )
          .toList(),
      onChanged: (v) => setState(() => selectedFuelTypeId = v),
      validator: (v) => v == null ? "Select fuel type" : null,
      decoration: const InputDecoration(
        labelText: "Fuel Type",
        border: OutlineInputBorder(),
      ),
    ),
  );


 Widget _StatusDropdown(AddVehicleState state) => state.fetchstatusList.when(
    loading: () => DropdownButtonFormField<int>(
      items: const [],
      onChanged: null,
      decoration: const InputDecoration(
        labelText: "Loading...",
        border: OutlineInputBorder(),
      ),
    ),

    error: (e, _) => Text("Status Type error: $e"),
    data: (List<Status> statuses) => DropdownButtonFormField<int>(
      value: selectedStatusId,
      items: statuses
          .map(
            (d) =>
                DropdownMenuItem(value: d.StatusId, child: Text(d.StatusName ?? "")),
          )
          .toList(),
      onChanged: (v) => setState(() => selectedStatusId = v),
      validator: (v) => v == null ? "Select Status" : null,
      decoration: const InputDecoration(
        labelText: "Status",
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
 