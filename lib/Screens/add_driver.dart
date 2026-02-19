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
  final Drivers? driver;
  final bool isEdit;

  const AddDriverPage({
    super.key,
    this.driver,
    this.isEdit = false,
  });

  @override
  ConsumerState<AddDriverPage> createState() => _AddDriverPageState();
}

class _AddDriverPageState extends ConsumerState<AddDriverPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController licenceNoController = TextEditingController();
  final TextEditingController licenceExpiryController =
      TextEditingController();

  DateTime? selectedExpiryDate;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  // Brand colors (matches VehiclePage)
  static const Color _primary = Color(0xFF3D5AFE);
  static const Color _primaryDark = Color(0xFF0031CA);
  static const Color _surface = Color(0xFFF4F6FB);
  static const Color _cardBg = Colors.white;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _animController.forward();

    if (widget.isEdit && widget.driver != null) {
      final d = widget.driver!;
      nameController.text = d.name ?? '';
      phoneController.text = d.phone ?? '';
      addressController.text = d.address ?? '';
      licenceNoController.text = d.licenceNo ?? '';
      if (d.licenceExpiry != null) {
        selectedExpiryDate = d.licenceExpiry;
        licenceExpiryController.text = _formatDate(d.licenceExpiry!);
      }
    }
  }

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}-'
      '${dt.month.toString().padLeft(2, '0')}-'
      '${dt.year}';

  Future<void> _selectExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedExpiryDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _primary,
            onPrimary: Colors.white,
            surface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        selectedExpiryDate = picked;
        licenceExpiryController.text = _formatDate(picked);
      });
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    nameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    licenceNoController.dispose();
    licenceExpiryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addDriverViewModelProvider);

    ref.listen(addDriverViewModelProvider, (prev, next) {
      if (prev == next) return;
      if (next.error != null) {
        _showSnack(next.error!, isError: true);
      }
      if (next.data != null && prev?.data != next.data) {
        _showSnack(
          widget.isEdit
              ? 'Driver updated successfully'
              : 'Driver added successfully',
        );
        Navigator.pop(context, true);
      }
    });

    // Derive initials for avatar
    final name = nameController.text.trim();
    final initials = name.isEmpty
        ? '?'
        : name
            .split(' ')
            .take(2)
            .map((e) => e.isNotEmpty ? e[0].toUpperCase() : '')
            .join();

    return Scaffold(
      backgroundColor: _surface,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // ── HEADER ────────────────────────────────────────────────
                _buildHeader(),

                // ── SCROLLABLE CONTENT ────────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),

                        // Form card
                        _buildFormCard(),

                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      // ── BOTTOM SAVE BUTTON ─────────────────────────────────────────────
      bottomNavigationBar: _buildBottomBar(state),
    );
  }

  // ─── HEADER ──────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      color: _cardBg,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        children: [
          // Back button
          Container(
            margin: const EdgeInsets.only(left: 8),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 18, color: Color(0xFF0D0D2B)),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // Title (centered)
          Expanded(
            child: Text(
              widget.isEdit ? 'Edit Driver' : 'Add Driver',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0D0D2B),
                letterSpacing: -0.4,
              ),
            ),
          ),

          // Spacer to balance the back button
          const SizedBox(width: 56),
        ],
      ),
    );
  }

  // ─── FORM CARD ────────────────────────────────────────────────────────────────
  Widget _buildFormCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('Personal Info'),
            const SizedBox(height: 14),

            _buildField(
              label: 'Full Name',
              controller: nameController,
              icon: Icons.person_rounded,
              hint: 'e.g. Rahul Sharma',
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),

            _buildField(
              label: 'Phone Number',
              controller: phoneController,
              icon: Icons.phone_rounded,
              hint: '10-digit mobile number',
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              validator: (v) {
                if (v == null || v.isEmpty) return 'Phone number is required';
                if (v.length != 10) return 'Must be exactly 10 digits';
                return null;
              },
            ),
            const SizedBox(height: 16),

            _buildField(
              label: 'Address',
              controller: addressController,
              icon: Icons.location_on_rounded,
              hint: 'Full residential address',
              maxLines: 3,
            ),

            const SizedBox(height: 24),
            _sectionLabel('Licence Details'),
            const SizedBox(height: 14),

            _buildField(
              label: 'Licence Number',
              controller: licenceNoController,
              icon: Icons.credit_card_rounded,
              hint: 'e.g. MH1220230012345',
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 16),

            GestureDetector(
              onTap: _selectExpiryDate,
              child: AbsorbPointer(
                child: _buildField(
                  label: 'Expiry Date',
                  controller: licenceExpiryController,
                  icon: Icons.calendar_month_rounded,
                  hint: 'Tap to select date',
                  suffixIcon: Icons.chevron_right_rounded,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── BOTTOM SAVE BAR ──────────────────────────────────────────────────────────
  Widget _buildBottomBar(dynamic state) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: _cardBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: state.isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: _primary,
            disabledBackgroundColor: _primary.withOpacity(0.5),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: state.isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      widget.isEdit
                          ? Icons.check_circle_rounded
                          : Icons.person_add_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      widget.isEdit ? 'Update Driver' : 'Save Driver',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final driver = Drivers(
        driverId: widget.isEdit ? widget.driver!.driverId : 0,
        name: nameController.text.trim(),
        phone: phoneController.text.trim(),
        address: addressController.text.trim(),
        licenceNo: licenceNoController.text.trim(),
        licenceExpiry: selectedExpiryDate,
        agencyId: ref.read(loginViewModelProvider).agencyId.toString(),
      );

      if (widget.isEdit) {
        ref.read(addDriverViewModelProvider.notifier).updateDriver(driver);
      } else {
        ref.read(addDriverViewModelProvider.notifier).addDriver(driver);
      }
    }
  }

  // ─── SECTION LABEL ────────────────────────────────────────────────────────────
  Widget _sectionLabel(String text) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_primary, Color(0xFF00BFA5)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0D0D2B),
            letterSpacing: 0.1,
          ),
        ),
      ],
    );
  }

  // ─── FIELD ────────────────────────────────────────────────────────────────────
  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    ValueChanged<String>? onChanged,
    IconData? suffixIcon,
    TextCapitalization textCapitalization = TextCapitalization.words,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
              letterSpacing: 0.1,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          inputFormatters: inputFormatters,
          textCapitalization: textCapitalization,
          onChanged: onChanged,
          validator: validator ??
              (v) => v == null || v.isEmpty ? 'This field is required' : null,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Color(0xFF0D0D2B),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                TextStyle(color: Colors.grey.shade400, fontSize: 14),
            prefixIcon: Container(
              margin: const EdgeInsets.all(10),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: _primary),
            ),
            suffixIcon: suffixIcon != null
                ? Icon(suffixIcon,
                    color: Colors.grey.shade400, size: 20)
                : null,
            filled: true,
            fillColor: _surface,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: maxLines > 1 ? 16 : 0,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  BorderSide(color: Colors.grey.shade200, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _primary, width: 1.8),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: Colors.red, width: 1.4),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: Colors.red, width: 1.8),
            ),
          ),
        ),
      ],
    );
  }

  // ─── SNACKBAR ─────────────────────────────────────────────────────────────────
  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_rounded
                  : Icons.check_circle_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade600 : const Color(0xFF00BFA5),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}