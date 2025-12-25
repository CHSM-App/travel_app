import 'package:flutter/material.dart';

class VehiclePage extends StatefulWidget {
  const VehiclePage({Key? key}) : super(key: key);

  @override
  State<VehiclePage> createState() => _VehiclePageState();
}

class _VehiclePageState extends State<VehiclePage> {
  final List<Map<String, String>> vehicles = [
    {"vehicleNo": "MH12 AB 1234", "vehicleName": "Toyota Innova"},
    {"vehicleNo": "MH14 XY 9876", "vehicleName": "Swift Dzire"},
  ];

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _vehicleNoCtrl = TextEditingController();
  final TextEditingController _vehicleNameCtrl = TextEditingController();

  void _openAddVehicleDialog() {
    _vehicleNoCtrl.clear();
    _vehicleNameCtrl.clear();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
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
                  validator: (value) =>
                      value == null || value.isEmpty ? "Enter vehicle number" : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _vehicleNameCtrl,
                  decoration: const InputDecoration(
                    labelText: "Vehicle Name / Model",
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty ? "Enter vehicle name" : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.pop(context),
            ),
            FilledButton(
              child: const Text("Save"),
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  setState(() {
                    vehicles.add({
                      "vehicleNo": _vehicleNoCtrl.text,
                      "vehicleName": _vehicleNameCtrl.text,
                    });
                  });
                  Navigator.pop(context);
                }
              },
            ),
          ],
        );
      },
    );
  }

  Widget _vehicleCard(vehicle) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: const Icon(Icons.directions_car_outlined),
        title: Text(vehicle["vehicleNo"]!),
        subtitle: Text(vehicle["vehicleName"]!),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Vehicles"),
        centerTitle: true,
      ),

      body: vehicles.isEmpty
          ? const Center(child: Text("No vehicles found"))
          : ListView.builder(
              itemCount: vehicles.length,
              itemBuilder: (context, index) =>
                  _vehicleCard(vehicles[index]),
            ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddVehicleDialog,
        label: const Text("Add Vehicle"),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
