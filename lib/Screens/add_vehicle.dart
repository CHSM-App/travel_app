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
  final capacity = TextEditingController();
  final mileage = TextEditingController();
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
    String message = "";

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

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(error.toString())),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
      if (next.data != null && prev?.data != next.data) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                const Text("Vehicle Added Successfully"),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
        Navigator.pop(context);
      }
    });

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.indigo.shade600,
        foregroundColor: Colors.white,
        title: const Text(
          "Add Vehicle",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Compact Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.indigo.shade600, Colors.indigo.shade400],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.directions_car, color: Colors.white, size: 24),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          "Vehicle Registration Form",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // All form fields in one card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section: Vehicle Information
                      _compactSectionHeader("Vehicle Information"),
                      const SizedBox(height: 10),
                      
                      _VehicleTypeDropdown(state),
                      const SizedBox(height: 12),
                      _FuelTypeDropdown(state),
                      const SizedBox(height: 12),
                      _StatusDropdown(state),
                      
                      const SizedBox(height: 18),
                      const Divider(height: 1),
                      const SizedBox(height: 18),

                      // Section: Vehicle Details
                      _compactSectionHeader("Vehicle Details"),
                      const SizedBox(height: 10),

                      _compactInput(name, "Vehicle Name", Icons.badge_outlined),
                      const SizedBox(height: 12),
                      _compactInput(number, "Vehicle Number", Icons.pin, hint: "e.g., MH12AB1234"),
                      const SizedBox(height: 12),
                      
                      // Row for Capacity and Mileage
                      Row(
                        children: [
                          Expanded(
                            child: _compactInput(
                              capacity,
                              "Capacity",
                              Icons.people_outline,
                              number: true,
                              suffix: "Seats",
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _compactInput(
                              mileage,
                              "Mileage",
                              Icons.speed,
                              decimal: true,
                              suffix: "km/l",
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      _compactInput(rcDocument, "RC Document", Icons.description_outlined),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Compact Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: state.isLoading
                        ? null
                        : () async {
                            if (_formKey.currentState!.validate()) {
                              final vehicle = Vehicles(
                                vehicleId: null,
                                fueltype: selectedFuelTypeId!,
                                name: name.text,
                                number: number.text,
                                type: selectedTypeId!,
                                capacity: int.parse(capacity.text),
                                mileage: (mileage.text),
                                status: selectedStatusId!,
                              );

                              ref
                                  .read(addVehicleViewModelProvider.notifier)
                                  .addVehicle(vehicle);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo.shade600,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      disabledBackgroundColor: Colors.grey.shade300,
                    ),
                    child: state.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_circle_outline, size: 20),
                              SizedBox(width: 8),
                              Text(
                                "Add Vehicle",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _compactSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.indigo.shade700,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _VehicleTypeDropdown(AddVehicleState state) =>
      state.fetchVehicleTypeList.when(
        loading: () => _compactDropdownLoading("Vehicle Type", Icons.category_outlined),
        error: (e, _) => _compactErrorWidget("Vehicle Type", e),
        data: (List<VehicleType> vehicleTypes) =>
            DropdownButtonFormField<int>(
          value: selectedTypeId,
          items: vehicleTypes
              .map((d) => DropdownMenuItem(
                    value: d.TypeId,
                    child: Text(d.Type ?? "", style: const TextStyle(fontSize: 14)),
                  ))
              .toList(),
          onChanged: (v) => setState(() => selectedTypeId = v),
          validator: (v) => v == null ? "Required" : null,
          decoration: _compactInputDecoration("Vehicle Type", Icons.category_outlined),
          isDense: true,
        ),
      );

  Widget _FuelTypeDropdown(AddVehicleState state) =>
      state.fetchFuelTypeList.when(
        loading: () => _compactDropdownLoading("Fuel Type", Icons.local_gas_station_outlined),
        error: (e, _) => _compactErrorWidget("Fuel Type", e),
        data: (List<Fueltype> fuelTypes) => DropdownButtonFormField<int>(
          value: selectedFuelTypeId,
          items: fuelTypes
              .map((d) => DropdownMenuItem(
                    value: d.FuelTypeId,
                    child: Text(d.FuelType ?? "", style: const TextStyle(fontSize: 14)),
                  ))
              .toList(),
          onChanged: (v) => setState(() => selectedFuelTypeId = v),
          validator: (v) => v == null ? "Required" : null,
          decoration: _compactInputDecoration("Fuel Type", Icons.local_gas_station_outlined),
          isDense: true,
        ),
      );

  Widget _StatusDropdown(AddVehicleState state) => state.fetchstatusList.when(
        loading: () => _compactDropdownLoading("Status", Icons.check_circle_outline),
        error: (e, _) => _compactErrorWidget("Status", e),
        data: (List<Status> statuses) => DropdownButtonFormField<int>(
          value: selectedStatusId,
          items: statuses
              .map((d) => DropdownMenuItem(
                    value: d.StatusId,
                    child: Text(d.StatusName ?? "", style: const TextStyle(fontSize: 14)),
                  ))
              .toList(),
          onChanged: (v) => setState(() => selectedStatusId = v),
          validator: (v) => v == null ? "Required" : null,
          decoration: _compactInputDecoration("Status", Icons.check_circle_outline),
          isDense: true,
        ),
      );

  InputDecoration _compactInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 14),
      prefixIcon: Icon(icon, color: Colors.indigo.shade600, size: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.indigo.shade600, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.red.shade400),
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      isDense: true,
    );
  }

  Widget _compactDropdownLoading(String label, IconData icon) {
    return DropdownButtonFormField<int>(
      items: const [],
      onChanged: null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 14),
        prefixIcon: SizedBox(
          width: 20,
          height: 20,
          child: Center(
            child: SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.indigo.shade600,
              ),
            ),
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        isDense: true,
      ),
    );
  }

  Widget _compactErrorWidget(String label, Object error) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "$label: $error",
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _compactInput(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool number = false,
    bool decimal = false,
    String? hint,
    String? suffix,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: number || decimal ? TextInputType.number : null,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 14),
        hintText: hint,
        hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
        prefixIcon: Icon(icon, color: Colors.indigo.shade600, size: 20),
        suffixText: suffix,
        suffixStyle: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.indigo.shade600, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.red.shade400),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        isDense: true,
      ),
      validator: (v) => v == null || v.isEmpty ? "Required" : null,
    );
  }
}