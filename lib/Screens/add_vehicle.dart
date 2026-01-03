import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_agency_app/domain/models/vehicles.dart';
import 'package:travel_agency_app/presentation/providers/viewmodel_provider.dart';


class AddVehiclePage extends ConsumerStatefulWidget {
  const AddVehiclePage({super.key});

  @override
  ConsumerState<AddVehiclePage> createState() => _AddVehiclePageState();
}

class _AddVehiclePageState extends ConsumerState<AddVehiclePage> {
  final _formKey = GlobalKey<FormState>();

  final name = TextEditingController();
  final number = TextEditingController();
  final type = TextEditingController();
  final capacity = TextEditingController();
  final fuelType = TextEditingController();
  final mileage = TextEditingController();
  final status = TextEditingController();
  final rcDocument = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(vehicleViewModelProvider);

    ref.listen(vehicleViewModelProvider, (previous, next) {
      if (next is AsyncData && next.value == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Vehicle added successfully")),
        );
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
              _input(name, "Vehicle Name"),
              _input(number, "Vehicle Number"),
              _input(type, "Vehicle Type"),
              _input(capacity, "Capacity", number: true),
              _input(fuelType, "Fuel Type"),
              _input(mileage, "Mileage", decimal: true),
              _input(status, "Status"),
              _input(rcDocument, "RC Document"),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: state.isLoading
                    ? null
                    : () {
                        if (_formKey.currentState!.validate()) {
                          final vehicle = Vehicle(
                            name: name.text,
                            number: number.text,
                            type: type.text,
                            capacity: int.parse(capacity.text),
                            fuelType: fuelType.text,
                            mileage: double.parse(mileage.text),
                            status: status.text,
                            rcDocument: rcDocument.text,
                          );

                          ref
                              .read(vehicleViewModelProvider.notifier)
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
 