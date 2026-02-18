// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:travel_agency_app/domain/models/drivers.dart';
// import 'package:travel_agency_app/presentation/providers/viewmodel_provider.dart';

// class AddDriverPage extends ConsumerStatefulWidget {
//   const AddDriverPage({super.key});

//   @override
//   ConsumerState<AddDriverPage> createState() => _AddDriverPageState();
// }

// class _AddDriverPageState extends ConsumerState<AddDriverPage> {
//   final _formKey = GlobalKey<FormState>();

//   final TextEditingController nameController = TextEditingController();
//   final TextEditingController phoneController = TextEditingController();
//   final TextEditingController addressController = TextEditingController();
//   final TextEditingController licenceNoController = TextEditingController();
//   final TextEditingController licenceExpiryController =
//       TextEditingController();

//   DateTime? selectedExpiryDate;

//   Future<void> _selectExpiryDate() async {
//     final picked = await showDatePicker(
//       context: context,
//       initialDate: DateTime.now(),
//       firstDate: DateTime.now(),
//       lastDate: DateTime(2100),
//     );

//     if (picked != null) {
//       setState(() {
//         selectedExpiryDate = picked;
//         licenceExpiryController.text =
//             "${picked.day}-${picked.month}-${picked.year}";
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final state = ref.watch(addDriverViewModelProvider);

//     ref.listen(addDriverViewModelProvider, (prev, next) {
//       if (prev == next) return;

//       if (next.error != null) {
//         WidgetsBinding.instance.addPostFrameCallback((_) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text(next.error!)),
//           );
//         });
//       }

//       if (next.data != null && prev?.data != next.data) {
//         WidgetsBinding.instance.addPostFrameCallback((_) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text("Driver Added Successfully")),
//           );
//           Navigator.pop(context);
//         });
//       }
//     });

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Add Driver"),
//         centerTitle: true,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             children: [
//               /// Driver Photo
//               Center(
//                 child: Stack(
//                   children: [
//                     CircleAvatar(
//                       radius: 55,
//                       backgroundColor: Colors.grey.shade300,
//                       child: const Icon(
//                         Icons.person,
//                         size: 60,
//                         color: Colors.white,
//                       ),
//                     ),
//                     Positioned(
//                       bottom: 0,
//                       right: 0,
//                       child: CircleAvatar(
//                         radius: 18,
//                         backgroundColor: Theme.of(context).primaryColor,
//                         child: const Icon(
//                           Icons.camera_alt,
//                           size: 18,
//                           color: Colors.white,
//                         ),
//                       ),
//                     )
//                   ],
//                 ),
//               ),

//               const SizedBox(height: 24),

//               _buildTextField(
//                 controller: nameController,
//                 label: "Driver Name",
//                 icon: Icons.person,
//               ),

//               _buildTextField(
//                 controller: phoneController,
//                 label: "Phone Number",
//                 icon: Icons.phone,
//                 keyboardType: TextInputType.phone,
//               ),

//               _buildTextField(
//                 controller: addressController,
//                 label: "Address",
//                 icon: Icons.location_on,
//                 maxLines: 3,
//               ),

//               _buildTextField(
//                 controller: licenceNoController,
//                 label: "Licence Number",
//                 icon: Icons.credit_card,
//               ),

//               GestureDetector(
//                 onTap: _selectExpiryDate,
//                 child: AbsorbPointer(
//                   child: _buildTextField(
//                     controller: licenceExpiryController,
//                     label: "Licence Expiry Date",
//                     icon: Icons.calendar_today,
//                   ),
//                 ),
//               ),

//               const SizedBox(height: 30),

//               SizedBox(
//                 width: double.infinity,
//                 height: 50,
//                 child: ElevatedButton(
//                   onPressed: state.isLoading
//                       ? null
//                       : () {
//                           if (_formKey.currentState!.validate()) {
//                             final driver = Drivers(
//                               driverId: 0,
//                               name: nameController.text,
//                               phone: phoneController.text,
//                               address: addressController.text,
//                               licenceNo: licenceNoController.text,
//                               licenceExpiry: selectedExpiryDate,
//                             );

//                             ref
//                                 .read(addDriverViewModelProvider.notifier)
//                                 .addDriver(driver);
//                           }
//                         },
//                   child: state.isLoading
//                       ? const SizedBox(
//                           height: 24,
//                           width: 24,
//                           child: CircularProgressIndicator(
//                             strokeWidth: 2,
//                             color: Colors.white,
//                           ),
//                         )
//                       : const Text("Save Driver"),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildTextField({
//     required TextEditingController controller,
//     required String label,
//     required IconData icon,
//     TextInputType keyboardType = TextInputType.text,
//     int maxLines = 1,
//   }) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 16),
//       child: TextFormField(
//         controller: controller,
//         keyboardType: keyboardType,
//         maxLines: maxLines,
//         validator: (value) =>
//             value == null || value.isEmpty ? "Required field" : null,
//         decoration: InputDecoration(
//           labelText: label,
//           prefixIcon: Icon(icon),
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(10),
//           ),
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_agency_app/domain/models/drivers.dart';
import 'package:travel_agency_app/presentation/providers/viewmodel_provider.dart';
import 'package:flutter/services.dart';

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
  final TextEditingController licenceExpiryController = TextEditingController();

  DateTime? selectedExpiryDate;

  Future<void> _selectExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF6C63FF),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        selectedExpiryDate = picked;
        licenceExpiryController.text =
            "${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}";
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
            SnackBar(
              content: Text(next.error!),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        });
      }

      if (next.data != null && prev?.data != next.data) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Driver Added Successfully"),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context);
        });
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F5),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Add Driver",
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // Profile Photo Section
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              Icons.person_outline,
                              size: 60,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF7C72FF), Color(0xFF6C63FF)],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF6C63FF,
                                  ).withOpacity(0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),

                    // Full Name
                    _buildInputField(
                      label: "Full Name",
                      controller: nameController,
                      icon: Icons.person_outline,
                      iconColor: const Color(0xFF6C63FF),
                    ),

                    const SizedBox(height: 20),

                    // Phone Number
                    // _buildInputField(
                    //   label: "Phone Number",
                    //   controller: phoneController,
                    //   icon: Icons.phone_outlined,
                    //   iconColor: const Color(0xFF6C63FF),
                    //   keyboardType: TextInputType.phone,
                    // ),
                    _buildInputField(
                      label: "Phone Number",
                      controller: phoneController,
                      icon: Icons.phone_outlined,
                      iconColor: const Color(0xFF6C63FF),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Phone number is required";
                        }
                        if (value.length != 10) {
                          return "Phone number must be 10 digits";
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // License Number
                    _buildInputField(
                      label: "License Number",
                      controller: licenceNoController,
                      icon: Icons.credit_card_outlined,
                      iconColor: const Color(0xFF6C63FF),
                    ),

                    const SizedBox(height: 20),

                    // License Expiry Date
                    GestureDetector(
                      onTap: _selectExpiryDate,
                      child: AbsorbPointer(
                        child: _buildInputField(
                          label: "License Expiry Date",
                          controller: licenceExpiryController,
                          icon: Icons.calendar_today_outlined,
                          iconColor: const Color(0xFF6C63FF),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Address
                    _buildInputField(
                      label: "Address",
                      controller: addressController,
                      icon: Icons.location_on_outlined,
                      iconColor: const Color(0xFF6C63FF),
                      maxLines: 3,
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),

            // Save Button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C72FF), Color(0xFF6C63FF)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6C63FF).withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: state.isLoading
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
                    borderRadius: BorderRadius.circular(16),
                    child: Center(
                      child: state.isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              "Save Changes",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required Color iconColor,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            inputFormatters: inputFormatters,
             validator: validator ??
      (value) =>
          value == null || value.isEmpty ? "This field is required" : null,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: iconColor, size: 22),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF6C63FF),
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 1),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    licenceNoController.dispose();
    licenceExpiryController.dispose();
    super.dispose();
  }
}
