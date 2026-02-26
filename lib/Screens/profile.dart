
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
  bool    _isSaving = false;
  bool    _didPopulateInitialProfile = false;

  // ── Design tokens ─────────────────────────────────
  static const _primary   = Color(0xFF5B6EF5);
  static const _primaryDk = Color(0xFF3D50E0);
  static const _primaryLt = Color(0xFFEEF0FE);
  static const _surface   = Color(0xFFF4F5FF);
  static const _textDark  = Color(0xFF1A1D3B);
  static const _textMid   = Color(0xFF6B7280);
  static const _green     = Color(0xFF10B981);
  static const _red       = Color(0xFFEF4444);

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
     // ref.read(loginViewModelProvider.notifier).adminProfile(ref.read(loginViewModelProvider).adminId);
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

  void _populateProfile(LoginInfo p) {
    if (_didPopulateInitialProfile) return;

    if (nameController.text.isEmpty)    nameController.text    = p.name       ?? '';
    if (mobileController.text.isEmpty)  mobileController.text  = p.mobile     ?? '';
    if (emailController.text.isEmpty)   emailController.text   = p.email      ?? '';
    if (addressController.text.isEmpty) addressController.text = p.address    ?? '';
    if (agencyController.text.isEmpty)  agencyController.text  = p.agencyName ?? '';
    if (cityController.text.isEmpty)    cityController.text    = p.city       ?? '';

    setState(() {
      _imageUrl = p.imageUrl;
      _didPopulateInitialProfile = true;
    });
  }

  // void _showImageOptions() {
  //   HapticFeedback.lightImpact();
  //   showModalBottomSheet(
  //     context: context,
  //     backgroundColor: Colors.transparent,
  //     builder: (_) => _ImagePickerSheet(
  //       hasImage:  _profileImage != null || (_imageUrl?.isNotEmpty == true),
  //       onCamera:  () { Navigator.pop(context); _pickImage(ImageSource.camera); },
  //       onGallery: () { Navigator.pop(context); _pickImage(ImageSource.gallery); },
  //       onRemove:  () {
  //         Navigator.pop(context);
  //         setState(() { _profileImage = null; _imageUrl = null; });
  //       },
  //     ),
  //   );
  // }
void _showImageOptions() {
  HapticFeedback.lightImpact();
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => _ImagePickerSheet(
      hasImage:  _profileImage != null || (_imageUrl?.isNotEmpty == true),
      onCamera:  () { Navigator.pop(context); _pickImage(ImageSource.camera); },
      onGallery: () { Navigator.pop(context); _pickImage(ImageSource.gallery); },
      onRemove:  () async {
        Navigator.pop(context);
        final list    = ref.read(loginViewModelProvider).adminProfile.value;
        final adminId = list?.firstOrNull?.adminId  ?? 0;
        final agId    = list?.firstOrNull?.agencyId ?? '';
        final previousLocalImage = _profileImage;
        final previousImageUrl = _imageUrl;

        if (adminId == 0 || agId.isEmpty) {
          _snack('Admin not found', error: true);
          return;
        }

        setState(() {
          _isSaving = true;
          _profileImage = null;
          _imageUrl = null;
        });

        final res = await ref.read(loginViewModelProvider.notifier)
            .deleteAdminProfile({
          'admin_id': adminId.toString(),
          'agency_id': agId,
        });

        if (res != null && res['success'] == 1) {
          await ref.read(loginViewModelProvider.notifier).adminProfile(adminId);
          setState(() => _isSaving = false);
          _snack('Profile image removed successfully');
        } else {
          setState(() {
            _isSaving = false;
            _profileImage = previousLocalImage;
            _imageUrl = previousImageUrl;
          });
          _snack(res?['message'] ?? 'Failed to remove image', error: true);
        }
      },
    ),
  );
}
  Future<void> _pickImage(ImageSource src) async {
    final f = await _picker.pickImage(source: src, imageQuality: 85);
    if (f != null) setState(() { _profileImage = File(f.path); _imageUrl = null; });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.mediumImpact();
    setState(() => _isSaving = true);

    final list    = ref.read(loginViewModelProvider).adminProfile.value;
    final adminId = list?.firstOrNull?.adminId  ?? 0;
    final agId    = list?.firstOrNull?.agencyId ?? '';

    if (_profileImage != null) {
      final res = await ref.read(loginViewModelProvider.notifier)
          .updateAdminProfile(_profileImage!, adminId, agId);
      if (res == null || res['success'] != 1) {
        _snack(res?['message'] ?? 'Image upload failed', error: true);
        setState(() => _isSaving = false);
        return;
      }
      setState(() => _imageUrl = res['data']?['imageUrl']);
    }

    final info = LoginInfo(
      adminId: adminId, name: nameController.text,
      email: emailController.text, mobile: mobileController.text,
      address: addressController.text, agencyName: agencyController.text,
      city: cityController.text,
    );

  final response =
      await ref.read(loginViewModelProvider.notifier).addAdmin(loginInfo);

  if (response?.success == 1) {
    // await ref
    //     .read(loginViewModelProvider.notifier)
    //     .adminProfile(adminId);

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
      backgroundColor: _surface,
      body: loginState.adminProfile.when(
        loading: () => const Center(child: CircularProgressIndicator(color: _primary)),
        error:   (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: _red))),
        data: (list) {
          if (list.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _populateProfile(list.first));
          }
          return FadeTransition(
            opacity: _fadeAnim,
            child: Column(
              children: [
                // ── TOP HEADER with avatar INSIDE ──
                _buildHeader(),

                // ── FORM BODY (fills remaining space) ──
                Expanded(
                  child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            _section('Personal Info', [
                              _FieldItem(nameController,   'Full Name',     Icons.person_outline_rounded),
                              _FieldItem(mobileController, 'Mobile',        Icons.phone_outlined,
                                  type: TextInputType.phone, max: 10,
                                  validate: (v) {
                                    if (v == null || v.isEmpty) return 'Required';
                                    if (v.length != 10) return '10 digits required';
                                    return null;
                                  }),
                              _FieldItem(emailController,  'Email',         Icons.email_outlined,
                                  type: TextInputType.emailAddress,
                                  validate: (v) {
                                    if (v == null || v.isEmpty) return 'Required';
                                    if (!v.contains('@')) return 'Invalid email';
                                    return null;
                                  }),
                            ]),
                            const SizedBox(height: 14),
                            _section('Agency & Location', [
                              _FieldItem(agencyController,  'Agency Name', Icons.business_outlined),
                              _FieldItem(cityController,    'City',        Icons.location_city_outlined),
                              _FieldItem(addressController, 'Address',     Icons.home_outlined),
                            ]),
                            const SizedBox(height: 20),
                            _saveButton(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Header: gradient + avatar fully inside ────────────────────

  Widget _buildHeader() {
    final initial = nameController.text.isNotEmpty
        ? nameController.text[0].toUpperCase() : 'A';
    final imageUrl = _imageUrl?.trim();
    final hasValidNetworkImage = imageUrl != null &&
        imageUrl.isNotEmpty &&
        imageUrl.toLowerCase() != 'null';

    Widget avatarFallback() {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white.withOpacity(0.3), Colors.white.withOpacity(0.15)],
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          initial,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF5B6EF5), Color(0xFF3340C8)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 16, 20),
          child: Column(
            children: [
              // Back + Title row
              Row(
                children: [
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 15),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    'Edit Profile',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
                        color: Colors.white, letterSpacing: -0.4),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Avatar row — fully inside header
              Row(
                children: [
                  const SizedBox(width: 16),
                  // Avatar
                  Stack(
                    children: [
                      Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 16, offset: const Offset(0, 6))],
                        ),
                        child: ClipOval(
                          child: SizedBox.expand(
                            child: _profileImage != null
                                ? Image.file(
                                    _profileImage!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => avatarFallback(),
                                  )
                                : hasValidNetworkImage
                                    ? Image.network(
                                        imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => avatarFallback(),
                                      )
                                    : avatarFallback(),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0, right: 0,
                        child: GestureDetector(
                          onTap: _showImageOptions,
                          child: Container(
                            width: 26, height: 26,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border: Border.all(color: _primary, width: 1.5),
                              boxShadow: [BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 6)],
                            ),
                            child: const Icon(Icons.camera_alt_rounded,
                                color: _primary, size: 13),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),

                  // Name + tap hint
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nameController.text.isNotEmpty
                            ? nameController.text : 'Your Name',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
                            color: Colors.white, letterSpacing: -0.3),
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
