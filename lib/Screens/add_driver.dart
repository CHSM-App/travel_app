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
  void initState() {
    super.initState();
    Future.microtask(() {
      final notifier = ref.read(addDriverViewModelProvider.notifier);
     
    });
  }

  @override
  Widget build(BuildContext context) {
    final state= ref.watch(addDriverViewModelProvider);
    String error="";
     String message="" ;
    ref.listen(addDriverViewModelProvider, (prev, next) {
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
        ).showSnackBar(const SnackBar(content: Text("Driver Added Successfully")));
        Navigator.pop(context);
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
                  onPressed: state.isLoading?null: () async {
                    if (_formKey.currentState!.validate()) {
                      
                      final driver=Drivers(
                        driverId: 0,
                        name: nameController.text,
                        phone: phoneController.text,
                        address: addressController.text,
                        licenceNo: licenceNoController.text,
                       
                        licenceExpiry: DateTime.now(),
                         
                      );
                       ref
                              .read(addDriverViewModelProvider.notifier)
                              .addDriver(Drivers as Drivers);
                        }
                  },
                  child: state.isLoading
                  ? const CircularProgressIndicator() 
                  :const Text(
                    "Save Driver",
                    style: TextStyle(fontSize: 16),
                  ),
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
