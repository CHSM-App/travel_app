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
        children: const [
          Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
          SizedBox(width: 8),
          Text("Vehicle Added Successfully"),
        ],
      ),
      backgroundColor: Colors.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      duration: const Duration(seconds: 1), // show short
    ),
  );

  Future.delayed(const Duration(milliseconds: 500), () {
    Navigator.pop(context);
  });
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

  /// ============================================================================
  /// FIXED DROPDOWN WIDGETS - CLEAR SELECTED VALUE DISPLAY
  /// ============================================================================
  
  Widget _VehicleTypeDropdown(AddVehicleState state) =>
      state.fetchVehicleTypeList.when(
        loading: () => _enhancedDropdownLoading("Vehicle Type", Icons.category_outlined),
        error: (e, _) => _enhancedErrorWidget("Vehicle Type", e, Icons.category_outlined),
        data: (List<VehicleType> vehicleTypes) {
          if (vehicleTypes.isEmpty) {
            return _emptyStateDropdown("Vehicle Type", Icons.category_outlined);
          }

          return DropdownButtonFormField<int>(
            value: selectedTypeId,
            // DROPDOWN MENU ITEMS - Show with icon
            items: vehicleTypes.map((vehicleType) {
              return DropdownMenuItem<int>(
                value: vehicleType.TypeId,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: selectedTypeId == vehicleType.TypeId
                            ? Colors.indigo.shade100
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.directions_car_outlined,
                        size: 16,
                        color: selectedTypeId == vehicleType.TypeId
                            ? Colors.indigo.shade700
                            : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        vehicleType.Type ?? "Unknown",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: selectedTypeId == vehicleType.TypeId
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: selectedTypeId == vehicleType.TypeId
                              ? Colors.indigo.shade900
                              : Colors.grey.shade800,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (selectedTypeId == vehicleType.TypeId)
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Colors.indigo.shade600,
                      ),
                  ],
                ),
              );
            }).toList(),
            // SELECTED ITEM BUILDER - Show text only (no icon) for clarity
            selectedItemBuilder: (BuildContext context) {
              return vehicleTypes.map((vehicleType) {
                return Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    vehicleType.Type ?? "Unknown",
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList();
            },
            onChanged: (v) => setState(() => selectedTypeId = v),
            validator: (v) => v == null ? "Please select vehicle type" : null,
            decoration: _enhancedDropdownDecoration("Vehicle Type", Icons.category_outlined),
            isDense: true,
            isExpanded: true,
            menuMaxHeight: 320,
            borderRadius: BorderRadius.circular(12),
            icon: const Icon(Icons.keyboard_arrow_down, size: 22),
            iconEnabledColor: Colors.indigo.shade600,
            dropdownColor: Colors.white,
            elevation: 8,
          );
        },
      );

  Widget _FuelTypeDropdown(AddVehicleState state) =>
      state.fetchFuelTypeList.when(
        loading: () => _enhancedDropdownLoading("Fuel Type", Icons.local_gas_station_outlined),
        error: (e, _) => _enhancedErrorWidget("Fuel Type", e, Icons.local_gas_station_outlined),
        data: (List<Fueltype> fuelTypes) {
          if (fuelTypes.isEmpty) {
            return _emptyStateDropdown("Fuel Type", Icons.local_gas_station_outlined);
          }

          return DropdownButtonFormField<int>(
            value: selectedFuelTypeId,
            // DROPDOWN MENU ITEMS - Show with icon
            items: fuelTypes.map((fuelType) {
              return DropdownMenuItem<int>(
                value: fuelType.FuelTypeId,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: selectedFuelTypeId == fuelType.FuelTypeId
                            ? Colors.indigo.shade100
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.local_gas_station,
                        size: 16,
                        color: selectedFuelTypeId == fuelType.FuelTypeId
                            ? Colors.indigo.shade700
                            : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        fuelType.FuelType ?? "Unknown",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: selectedFuelTypeId == fuelType.FuelTypeId
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: selectedFuelTypeId == fuelType.FuelTypeId
                              ? Colors.indigo.shade900
                              : Colors.grey.shade800,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (selectedFuelTypeId == fuelType.FuelTypeId)
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Colors.indigo.shade600,
                      ),
                  ],
                ),
              );
            }).toList(),
            // SELECTED ITEM BUILDER - Show text only (no icon) for clarity
            selectedItemBuilder: (BuildContext context) {
              return fuelTypes.map((fuelType) {
                return Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    fuelType.FuelType ?? "Unknown",
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList();
            },
            onChanged: (v) => setState(() => selectedFuelTypeId = v),
            validator: (v) => v == null ? "Please select fuel type" : null,
            decoration: _enhancedDropdownDecoration("Fuel Type", Icons.local_gas_station_outlined),
            isDense: true,
            isExpanded: true,
            menuMaxHeight: 320,
            borderRadius: BorderRadius.circular(12),
            icon: const Icon(Icons.keyboard_arrow_down, size: 22),
            iconEnabledColor: Colors.indigo.shade600,
            dropdownColor: Colors.white,
            elevation: 8,
          );
        },
      );

  Widget _StatusDropdown(AddVehicleState state) => 
      state.fetchstatusList.when(
        loading: () => _enhancedDropdownLoading("Status", Icons.check_circle_outline),
        error: (e, _) => _enhancedErrorWidget("Status", e, Icons.check_circle_outline),
        data: (List<Status> statuses) {
          if (statuses.isEmpty) {
            return _emptyStateDropdown("Status", Icons.check_circle_outline);
          }

          return DropdownButtonFormField<int>(
            value: selectedStatusId,
            // DROPDOWN MENU ITEMS - Show with icon and color
            items: statuses.map((status) {
              final statusColor = _getStatusColor(status.StatusName ?? "");
              final statusIcon = _getStatusIcon(status.StatusName ?? "");
              
              return DropdownMenuItem<int>(
                value: status.StatusId,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: selectedStatusId == status.StatusId
                            ? statusColor.withOpacity(0.15)
                            : statusColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        statusIcon,
                        size: 16,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        status.StatusName ?? "Unknown",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: selectedStatusId == status.StatusId
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: selectedStatusId == status.StatusId
                              ? Colors.black87
                              : Colors.grey.shade800,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (selectedStatusId == status.StatusId)
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: statusColor,
                      ),
                  ],
                ),
              );
            }).toList(),
            // SELECTED ITEM BUILDER - Show text only (no icon) for clarity
            selectedItemBuilder: (BuildContext context) {
              return statuses.map((status) {
                return Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    status.StatusName ?? "Unknown",
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList();
            },
            onChanged: (v) => setState(() => selectedStatusId = v),
            validator: (v) => v == null ? "Please select status" : null,
            decoration: _enhancedDropdownDecoration("Status", Icons.check_circle_outline),
            isDense: true,
            isExpanded: true,
            menuMaxHeight: 320,
            borderRadius: BorderRadius.circular(12),
            icon: const Icon(Icons.keyboard_arrow_down, size: 22),
            iconEnabledColor: Colors.indigo.shade600,
            dropdownColor: Colors.white,
            elevation: 8,
          );
        },
      );

  /// ============================================================================
  /// HELPER METHODS FOR STATUS ICONS AND COLORS
  /// ============================================================================
  
  IconData _getStatusIcon(String statusName) {
    switch (statusName.toLowerCase()) {
      case 'active':
      case 'available':
        return Icons.check_circle;
      case 'inactive':
      case 'unavailable':
        return Icons.cancel;
      case 'maintenance':
      case 'under maintenance':
        return Icons.build_circle;
      case 'pending':
        return Icons.pending;
      default:
        return Icons.info;
    }
  }

  Color _getStatusColor(String statusName) {
    switch (statusName.toLowerCase()) {
      case 'active':
      case 'available':
        return Colors.green.shade600;
      case 'inactive':
      case 'unavailable':
        return Colors.red.shade600;
      case 'maintenance':
      case 'under maintenance':
        return Colors.orange.shade600;
      case 'pending':
        return Colors.amber.shade700;
      default:
        return Colors.grey.shade600;
    }
  }

  /// ============================================================================
  /// ENHANCED LOADING STATE
  /// ============================================================================
  
  Widget _enhancedDropdownLoading(String label, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 1.5),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(icon, color: Colors.grey.shade400, size: 20),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo.shade600),
          ),
        ),
      ),
    );
  }

  /// ============================================================================
  /// ENHANCED ERROR STATE
  /// ============================================================================
  
  Widget _enhancedErrorWidget(String label, Object error, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.error_outline,
                  color: Colors.red.shade700,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Failed to load $label",
                  style: TextStyle(
                    color: Colors.red.shade900,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 34),
            child: Text(
              error.toString(),
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(left: 34),
            child: TextButton.icon(
              onPressed: () {
                final notifier = ref.read(addVehicleViewModelProvider.notifier);
                if (label == "Vehicle Type") {
                  notifier.fetchVehicleTypeList();
                } else if (label == "Fuel Type") {
                  notifier.fetchVehicleFuelTypeList();
                } else if (label == "Status") {
                  notifier.fetchstatusList();
                }
              },
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text(
                "Retry",
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red.shade700,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ============================================================================
  /// EMPTY STATE WIDGET
  /// ============================================================================
  
  Widget _emptyStateDropdown(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade200, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.amber.shade100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              Icons.inbox_outlined,
              color: Colors.amber.shade900,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "No $label Available",
                  style: TextStyle(
                    color: Colors.amber.shade900,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Please add some data first",
                  style: TextStyle(
                    color: Colors.amber.shade700,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ============================================================================
  /// ENHANCED DROPDOWN DECORATION
  /// ============================================================================
  
  InputDecoration _enhancedDropdownDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        fontSize: 14,
        color: Colors.grey.shade700,
        fontWeight: FontWeight.w500,
      ),
      prefixIcon: Icon(icon, color: Colors.indigo.shade600, size: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.indigo.shade600, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade600, width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      isDense: true,
    );
  }

  /// ============================================================================
  /// TEXT FIELD WIDGETS
  /// ============================================================================

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

  @override
  void dispose() {
    name.dispose();
    number.dispose();
    capacity.dispose();
    mileage.dispose();
    rcDocument.dispose();
    super.dispose();
  }
}