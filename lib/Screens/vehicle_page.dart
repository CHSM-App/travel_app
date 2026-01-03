import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_agency_app/domain/models/vehicles.dart';
import 'package:travel_agency_app/presentation/providers/viewmodel_provider.dart';


class VehiclePage extends ConsumerStatefulWidget {
  const VehiclePage({Key? key}) : super(key: key);

  @override
  ConsumerState<VehiclePage> createState() => _VehiclePageState();
}

class _VehiclePageState extends ConsumerState<VehiclePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _vehicleNoCtrl = TextEditingController();
  final TextEditingController _vehicleNameCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(tripBookingViewModelProvider.notifier).vehicleList();
    });
  }

  void _openAddVehicleDialog() {
    _vehicleNoCtrl.clear();
    _vehicleNameCtrl.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add New Vehicle"),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _vehicleNoCtrl,
                decoration: const InputDecoration(
                  labelText: "Vehicle Number",
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? "Enter vehicle number" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _vehicleNameCtrl,
                decoration: const InputDecoration(
                  labelText: "Vehicle Name / Model",
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? "Enter vehicle name" : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          // FilledButton(
          //   child: const Text("Save"),
          //   onPressed: () {
          //     if (_formKey.currentState!.validate()) {
          //       ref.read(tripBookingViewModelProvider.notifier).addVehicle(
          //             Vehicles(
          //               name: _vehicleNameCtrl.text,
          //               number: _vehicleNoCtrl.text,


          //             ),
          //           );
          //       Navigator.pop(context);
          //     }
          //   },
          // ),
          //               vehicleNo: _vehicleNoCtrl.text,
          //               vehicleName: _vehicleNameCtrl.text,
          //             ),
          //           );
          //       Navigator.pop(context);
          //     }
          //   },
          // ),
        ],
      ),
    );
  }

  Widget _vehicleCard(Vehicles vehicle) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: const Icon(Icons.directions_car_outlined),
        title: Text(vehicle.name??""),
        subtitle: Text(vehicle.number??""),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tripBookingViewModelProvider).fetchVehicleList;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Vehicles"),
        centerTitle: true,
      ),

      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Error: $e")),
        data: (vehicles) => vehicles.isEmpty
            ? const Center(child: Text("No vehicles found"))
            : ListView.builder(
                itemCount: vehicles.length,
                itemBuilder: (context, i) => _vehicleCard(vehicles[i]),
              ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddVehicleDialog,
        label: const Text("Add Vehicle"),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
