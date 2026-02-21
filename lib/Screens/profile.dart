
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:travel_agency_app/domain/models/login_info.dart';
import 'package:travel_agency_app/presentation/providers/viewmodel_provider.dart';

class ProfilePage extends ConsumerStatefulWidget {
  
  const ProfilePage({Key? key}) : super(key: key);

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Controllers
  TextEditingController nameController = TextEditingController();
  TextEditingController mobileController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  TextEditingController agencyController = TextEditingController();
  TextEditingController cityController = TextEditingController();
  TextEditingController pincodeController = TextEditingController();

  File? _profileImage;
  String? _imageUrl;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation =
        CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);
    _animationController.forward();

    // Fetch profile from API
    Future.microtask(() {
      ref.read(loginViewModelProvider.notifier).adminProfile(ref.read(loginViewModelProvider).adminId);
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    nameController.dispose();
    mobileController.dispose();
    emailController.dispose();
    addressController.dispose();
    agencyController.dispose();
    cityController.dispose();
    pincodeController.dispose();
    super.dispose();
  }

  void _populateProfile(LoginInfo profile) {
    nameController.text = profile.name ?? '';
    mobileController.text = profile.mobile ?? '';
    emailController.text = profile.email ?? '';
    addressController.text = profile.address ?? '';
    agencyController.text = profile.agencyName ?? '';
    cityController.text = profile.city ?? '';
  //  pincodeController.text = profile.pincode ?? '';
  _imageUrl = profile.imageUrl;
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 15),
              Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Profile Photo',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.indigo.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.photo_camera, color: Colors.indigo),
                ),
                title: const Text(
                  'Camera',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.indigo.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.photo_library, color: Colors.indigo),
                ),
                title: const Text(
                  'Gallery',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (_profileImage != null || _imageUrl != null)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.delete, color: Colors.red),
                  ),
                  title: const Text(
                    'Remove',
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _profileImage = null;
                      _imageUrl = null;
                    });
                  },
                ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
        _imageUrl = null;
      });
    }
  }

//   void _saveProfile() async {
//     print("Save profile clicked");
//   if (!_formKey.currentState!.validate()) return;

//   final profileList = ref.read(loginViewModelProvider).adminProfile.value;
//   int adminId = 0;
//   String agencyId = '';

//   if (profileList != null && profileList.isNotEmpty) {
//     adminId = profileList.first.adminId ?? 0;
//     agencyId = profileList.first.agencyId ?? '';
//   }
//   print('adminId: $adminId, agencyId: $agencyId');
// if (_profileImage != null) {
//   print('Uploading image for adminId: $adminId, agencyId: $agencyId');

//   final imageResponse = await ref
//       .read(loginViewModelProvider.notifier)
//       .updateAdminProfile(_profileImage!, adminId, agencyId);
// if (_profileImage != null) {
//   final imageResponse =
//       await ref.read(loginViewModelProvider.notifier)
//           .updateAdminProfile(_profileImage!, adminId, agencyId);

//   if (imageResponse['success'] != 1) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text('Image upload failed: ${imageResponse['message']}'),
//         backgroundColor: Colors.red,
//       ),
//     );
//   } else {
//     setState(() {
//       _imageUrl = imageResponse['data']?['imageUrl'] ?? _imageUrl;
//     });
//     print('Image uploaded successfully: $_imageUrl');
//   }
// }
// }

//   // ✅ Save profile info regardless of image upload
//   final loginInfo = LoginInfo(
//     adminId: adminId,
//     name: nameController.text,
//     email: emailController.text,
//     mobile: mobileController.text,
//     address: addressController.text,
//     agencyName: agencyController.text,
//     city: cityController.text,
//   );

//   final response = await ref
//       .read(loginViewModelProvider.notifier)
//       .addAdmin(loginInfo);

//   if (response?.success == 1) {
//     // Reload profile
//     await ref
//         .read(loginViewModelProvider.notifier)
//         .adminProfile(adminId);

//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         content: Text("Profile Updated successfully"),
//         backgroundColor: Colors.green,
//       ),
//     );
//   } else {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(response?.message ?? "Update failed"),
//         backgroundColor: Colors.red,
//       ),
//     );
//   }
// }

void _saveProfile() async {
  if (!_formKey.currentState!.validate()) return;

  final profileList = ref.read(loginViewModelProvider).adminProfile.value;

  int adminId = 0;
  String agencyId = '';

  if (profileList != null && profileList.isNotEmpty) {
    adminId = profileList.first.adminId ?? 0;
    agencyId = profileList.first.agencyId ?? '';
  }

  print('adminId: $adminId, agencyId: $agencyId');
if (_profileImage != null) {
  print('Uploading image for adminId: $adminId, agencyId: $agencyId');

  final imageResponse = await ref
      .read(loginViewModelProvider.notifier)
      .updateAdminProfile(_profileImage!, adminId, agencyId);

  print("Image Response: $imageResponse");

  if (imageResponse == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Image upload failed: No response from server"),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  if (imageResponse['success'] != 1) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(imageResponse['message'] ?? "Upload failed"),
        backgroundColor: Colors.red,
      ),
    );
  } else {
    setState(() {
      _imageUrl = imageResponse['data']?['imageUrl'];
    });

    print("Image uploaded successfully: $_imageUrl");
  }
}
  // ✅ Save profile data
  final loginInfo = LoginInfo(
    adminId: adminId,
    name: nameController.text,
    email: emailController.text,
    mobile: mobileController.text,
    address: addressController.text,
    agencyName: agencyController.text,
    city: cityController.text,
  );

  final response =
      await ref.read(loginViewModelProvider.notifier).addAdmin(loginInfo);

  if (response?.success == 1) {
    await ref
        .read(loginViewModelProvider.notifier)
        .adminProfile(adminId);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Profile Updated successfully"),
        backgroundColor: Colors.green,
      ),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(response?.message ?? "Update failed"),
        backgroundColor: Colors.red,
      ),
    );
  }
}
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int? maxLength,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLength: maxLength,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.indigo,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          counterText: '',
        ),
        validator: validator,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(loginViewModelProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: loginState.adminProfile.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, st) => Center(child: Text('Error: $err')),
          data: (profileList) {
            if (profileList.isNotEmpty) {
              final profile = profileList.first;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _populateProfile(profile);
              });
            }

            // Scrollable form (design unchanged)
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // AppBar
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.indigo),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'My Profile',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Profile Image
                      Stack(
                        children: [
                       CircleAvatar(
  radius: 60,
  backgroundColor: Colors.indigo.shade100,
  backgroundImage: _profileImage != null
      ? FileImage(_profileImage!)
      : (_imageUrl != null && _imageUrl!.isNotEmpty)
          ? NetworkImage(_imageUrl!) as ImageProvider
          : null,
  child: (_profileImage == null && (_imageUrl == null || _imageUrl!.isEmpty))
      ? Text(
          nameController.text.isNotEmpty
              ? nameController.text[0].toUpperCase() // first letter of name
              : 'U', // fallback if name is empty
          style: const TextStyle(
            fontSize: 40,
            color: Colors.indigo,
            fontWeight: FontWeight.bold,
          ),
        )
      : null,
),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _showImageOptions,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.indigo,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.camera_alt, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      const Text(
                        'Upload Profile Photo',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                      const SizedBox(height: 30),

                      // Form Fields
                      _buildTextField(
                        controller: nameController,
                        label: 'Full Name',
                        icon: Icons.person_outline,
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Enter name' : null,
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(
                        controller: mobileController,
                        label: 'Mobile Number',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Enter mobile';
                          if (value.length != 10) return '10 digits required';
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(
                        controller: emailController,
                        label: 'Email Address',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Enter email';
                          if (!value.contains('@')) return 'Enter valid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(
                        controller: addressController,
                        label: 'Address',
                        icon: Icons.home_outlined,
                        maxLines: 2,
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Enter address' : null,
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(
                        controller: agencyController,
                        label: 'Agency Name',
                        icon: Icons.business_outlined,
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Enter agency' : null,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: _buildTextField(
                              controller: cityController,
                              label: 'City',
                              icon: Icons.location_city_outlined,
                              validator: (value) =>
                                  value == null || value.isEmpty ? 'Enter city' : null,
                            ),
                          ),
                          const SizedBox(width: 15),
                          // Expanded(
                          //   flex: 1,
                          //   child: _buildTextField(
                          //     controller: pincodeController,
                          //     label: 'Pincode',
                          //     icon: Icons.pin_drop_outlined,
                          //     keyboardType: TextInputType.number,
                          //     maxLength: 6,
                          //     validator: (value) {
                          //       if (value == null || value.isEmpty) return 'Required';
                          //       if (value.length != 6) return '6 digits';
                          //       return null;
                          //     },
                          //   ),
                          // ),
                        ],
                      ),
                      const SizedBox(height: 35),

                      // Save Button
                   SizedBox(
  width: double.infinity,
  height: 56,
  child: ElevatedButton.icon(
    icon: const Icon(Icons.save_outlined),
    label: const Text(
      'Save Profile',
      style: TextStyle(
        fontSize: 18,
        color: Colors.white, // 👈 text white
      ),
    ),
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.indigo,
      foregroundColor: Colors.white, // 👈 icon + text white
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
    ),
    onPressed: _saveProfile,
  ),
),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
