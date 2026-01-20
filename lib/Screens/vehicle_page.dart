import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_agency_app/Screens/add_vehicle.dart';
import 'package:travel_agency_app/domain/models/vehicles.dart';
import 'package:travel_agency_app/presentation/providers/viewmodel_provider.dart';

class VehiclePage extends ConsumerStatefulWidget {
  const VehiclePage({super.key});

  @override
  ConsumerState<VehiclePage> createState() => _VehiclePageState();
}

class _VehiclePageState extends ConsumerState<VehiclePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _vehicleNoCtrl = TextEditingController();
  final TextEditingController _vehicleNameCtrl = TextEditingController();
  final TextEditingController _vehicleCapacityCtrl = TextEditingController();

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
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.directions_car, size: 48, color: Colors.blue),
                const SizedBox(height: 8),
                const Text(
                  "Add New Vehicle",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _vehicleNoCtrl,
                  decoration: const InputDecoration(
                    labelText: "Vehicle Number",
                    prefixIcon: Icon(Icons.confirmation_number),
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
                    prefixIcon: Icon(Icons.car_rental),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? "Enter vehicle name" : null,
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Cancel"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            ref
                                .read(tripBookingViewModelProvider.notifier)
                                .addVehicle(
                                  Vehicles(
                                    vehicleId: 0,
                                    name: _vehicleNameCtrl.text,
                                    number: _vehicleNoCtrl.text,
                                    capacity: int.tryParse(_vehicleCapacityCtrl.text) ?? 0,
                                    fueltype: 0,                                                                                                                                                                                        
                                  ),
                                );
                            Navigator.pop(context);
                          }
                        },
                        child: const Text("Save"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _vehicleCard(Vehicles vehicle) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          radius: 26,
          backgroundColor: Colors.blue.shade50,
          child: const Icon(Icons.directions_car, color: Colors.blue),
        ),
        title: Text(
          vehicle.name ?? "",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Row(
          children: [
            const Icon(Icons.confirmation_number, size: 14),
            const SizedBox(width: 4),
            Text(vehicle.number ?? ""),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                "Active",
                style: TextStyle(color: Colors.green, fontSize: 12),
              ),
            ),
            const SizedBox(height: 6),
            const Icon(Icons.more_vert, size: 18),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tripBookingViewModelProvider).fetchVehicleList;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Vehicles"),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.indigo],
            ),
          ),
        ),
      ),

      body: Column(
        children: [
          // 🔍 Search Bar (UI only)
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search vehicle...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          Expanded(
            child: state.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) =>
                  Center(child: Text("Error: $e")),
              data: (vehicles) => vehicles.isEmpty
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.car_crash, size: 80, color: Colors.grey),
                        SizedBox(height: 12),
                        Text(
                          "No vehicles added yet",
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    )
                  : ListView.builder(
                      itemCount: vehicles.length,
                      itemBuilder: (context, i) =>
                          _vehicleCard(vehicles[i]),
                    ),
            ),
          ),
        ],
      ),

     floatingActionButton: FloatingActionButton.extended(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddVehiclePage(),
      ),
    );
  },
  icon: const Icon(Icons.add),
  label: const Text("Add Vehicle")
     ),
    );
  
  }

  
}
