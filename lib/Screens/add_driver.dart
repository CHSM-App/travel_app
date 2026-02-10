
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_agency_app/domain/models/drivers.dart';
import 'package:travel_agency_app/presentation/providers/viewmodel_provider.dart';

class AddDriverPage extends ConsumerStatefulWidget {
  const AddDriverPage({super.key});

  @override
  ConsumerState<AddDriverPage> createState() => _AddDriverPageState();
}

class _AddDriverPageState extends ConsumerState<AddDriverPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController licenceNoController = TextEditingController();
  final TextEditingController licenceExpiryController =
      TextEditingController();

  DateTime? selectedExpiryDate;

  Future<void> _selectExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        selectedExpiryDate = picked;
        licenceExpiryController.text =
            "${picked.day}-${picked.month}-${picked.year}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addDriverViewModelProvider);


    ref.listen(addDriverViewModelProvider, (prev, next) {
      if (prev == next) return;

      if (next.error != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(next.error!)),
          );
        });
      }

      if (next.data != null && prev?.data != next.data) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Driver Added Successfully")),
          );
          Navigator.pop(context);
        });
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Driver"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              /// Driver Photo
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 55,
                      backgroundColor: Colors.grey.shade300,
                      child: const Icon(
                        Icons.person,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: Theme.of(context).primaryColor,
                        child: const Icon(
                          Icons.camera_alt,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    )
                  ],
                ),
              ),

              const SizedBox(height: 24),

              _buildTextField(
                controller: nameController,
                label: "Driver Name",
                icon: Icons.person,
              ),

              _buildTextField(
                controller: phoneController,
                label: "Phone Number",
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
              ),

              _buildTextField(
                controller: addressController,
                label: "Address",
                icon: Icons.location_on,
                maxLines: 3,
              ),

              _buildTextField(
                controller: licenceNoController,
                label: "Licence Number",
                icon: Icons.credit_card,
              ),

              GestureDetector(
                onTap: _selectExpiryDate,
                child: AbsorbPointer(
                  child: _buildTextField(
                    controller: licenceExpiryController,
                    label: "Licence Expiry Date",
                    icon: Icons.calendar_today,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: state.isLoading
                      ? null
                      : () {
                          if (_formKey.currentState!.validate()) {
                            final driver = Drivers(
                              driverId: 0,
                              name: nameController.text,
                              phone: phoneController.text,
                              address: addressController.text,
                              licenceNo: licenceNoController.text,
                              licenceExpiry: selectedExpiryDate,
                            );

                            ref
                                .read(addDriverViewModelProvider.notifier)
                                .addDriver(driver);
                          }
                        },
                  child: state.isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text("Save Driver"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: (value) =>
            value == null || value.isEmpty ? "Required field" : null,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}
