import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:travel_agency_app/core/theme/app_colors.dart';
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

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  final nameController    = TextEditingController();
  final mobileController  = TextEditingController();
  final emailController   = TextEditingController();
  final addressController = TextEditingController();
  final agencyController  = TextEditingController();
  final cityController    = TextEditingController();

  File?   _profileImage;
  String? _imageUrl;
  bool _isSaving = false;
  bool _didPopulateInitialProfile = false;
  int _avatarRefreshToken = 0;
  bool _forceLetterAvatar = false;

  // ── Design tokens ─────────────────────────────────
  static const _primary = AppColors.brandPrimary;
  static const _primaryDk = AppColors.brandPrimaryDark;
  static const _primaryLt = AppColors.brandSoft;
  static const _surface = Color(0xFFF4F5FF);
  static const _textDark = Color(0xFF1A1D3B);
  static const _textMid = Color(0xFF6B7280);
  static const _green = Color(0xFF10B981);
  static const _red = Color(0xFFEF4444);

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);

    Future.microtask(() {
      ref.read(loginViewModelProvider.notifier)
          .adminProfile(ref.read(loginViewModelProvider).adminId);
    });
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    nameController.dispose();
    mobileController.dispose();
    emailController.dispose();
    addressController.dispose();
    agencyController.dispose();
    cityController.dispose();
    super.dispose();
  }

  void _populateProfile(LoginInfo p) {
    if (!_didPopulateInitialProfile) {
      if (nameController.text.isEmpty) nameController.text = p.name ?? '';
      if (mobileController.text.isEmpty) mobileController.text = p.mobile ?? '';
      if (emailController.text.isEmpty) emailController.text = p.email ?? '';
      if (addressController.text.isEmpty) {
        addressController.text = p.address ?? '';
      }
      if (agencyController.text.isEmpty) {
        agencyController.text = p.agencyName ?? '';
      }
      if (cityController.text.isEmpty) cityController.text = p.city ?? '';
      _didPopulateInitialProfile = true;
    }

    final raw = p.imageUrl?.trim();
    final nextImageUrl =
        (raw == null || raw.isEmpty || raw.toLowerCase() == 'null') ? null : raw;

    if (!_forceLetterAvatar && _profileImage == null && _imageUrl != nextImageUrl) {
      setState(() {
        _imageUrl = nextImageUrl;
        _avatarRefreshToken++;
      });
    }
  }

  String? _displayImageUrl() {
    if (_forceLetterAvatar) return null;
    final imageUrl = _imageUrl?.trim();
    if (imageUrl == null || imageUrl.isEmpty || imageUrl.toLowerCase() == 'null') {
      return null;
    }
    final sep = imageUrl.contains('?') ? '&' : '?';
    return '$imageUrl${sep}v=$_avatarRefreshToken';
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
        hasImage: _profileImage != null || (_imageUrl?.isNotEmpty == true),
        onCamera: () {
          Navigator.pop(context);
          _pickImage(ImageSource.camera);
        },
        onGallery: () {
          Navigator.pop(context);
          _pickImage(ImageSource.gallery);
        },
        onRemove: () async {
          Navigator.pop(context);
          final list = ref.read(loginViewModelProvider).adminProfile.value;
          final adminId = list?.firstOrNull?.adminId ?? 0;
          final agId = list?.firstOrNull?.agencyId ?? '';
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
            _avatarRefreshToken++;
            _forceLetterAvatar = true;
          });

          final res = await ref
              .read(loginViewModelProvider.notifier)
              .deleteAdminProfile({
                'admin_id': adminId.toString(),
                'agency_id': agId,
              });

          if (res != null && res['success'] == 1) {
            await ref
                .read(loginViewModelProvider.notifier)
                .adminProfile(adminId);
            setState(() => _isSaving = false);
            _snack('Profile image removed successfully');
          } else {
            setState(() {
              _isSaving = false;
              _profileImage = previousLocalImage;
              _imageUrl = previousImageUrl;
              _avatarRefreshToken++;
              _forceLetterAvatar =
                  previousLocalImage == null && (previousImageUrl == null || previousImageUrl.isEmpty);
            });
            _snack(res?['message'] ?? 'Failed to remove image', error: true);
          }
        },
      ),
    );
  }

  Future<void> _pickImage(ImageSource src) async {
    final f = await _picker.pickImage(source: src, imageQuality: 85);
    if (f != null)
      setState(() {
        _profileImage = File(f.path);
        _imageUrl = null;
        _forceLetterAvatar = false;
      });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.mediumImpact();
    setState(() => _isSaving = true);

    final list = ref.read(loginViewModelProvider).adminProfile.value;
    final adminId = list?.firstOrNull?.adminId ?? 0;
    final agId = list?.firstOrNull?.agencyId ?? '';

    if (_profileImage != null) {
      final res = await ref
          .read(loginViewModelProvider.notifier)
          .updateAdminProfile(_profileImage!, adminId, agId);
      if (res == null || res['success'] != 1) {
        _snack(res?['message'] ?? 'Image upload failed', error: true);
        setState(() => _isSaving = false);
        return;
      }
      setState(() {
        _imageUrl = res['data']?['imageUrl']?.toString();
        _profileImage = null;
        _avatarRefreshToken++;
        _forceLetterAvatar = false;
      });
      _snack('Image uploaded successfully');
    }

    final info = LoginInfo(
      adminId: adminId,
      name: nameController.text,
      email: emailController.text,
      mobile: mobileController.text,
      address: addressController.text,
      agencyName: agencyController.text,
      city: cityController.text,
    );

    final res = await ref.read(loginViewModelProvider.notifier).addAdmin(info);
    if (res?.success == 1) {
      await ref.read(loginViewModelProvider.notifier).adminProfile(adminId);
      _snack('Profile updated successfully');
    } else {
      _snack(res?.message ?? 'Update failed', error: true);
    }
    setState(() => _isSaving = false);
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(error ? Icons.error_outline_rounded : Icons.check_circle_rounded,
            color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
      ]),
      backgroundColor: error ? _red : _green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.all(14),
      elevation: 0,
    ));
  }

  void _showImagePreview() {
    final displayImageUrl = _displayImageUrl();
    if (_profileImage == null && displayImageUrl == null) {
      _snack('No profile image to preview', error: true);
      return;
    }

    showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.all(12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: InteractiveViewer(
                    minScale: 1,
                    maxScale: 4,
                    child: _profileImage != null
                        ? Image.file(
                            _profileImage!,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                          )
                        : Image.network(
                            displayImageUrl!,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                          ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Material(
                  color: Colors.black54,
                  shape: const CircleBorder(),
                  child: IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(loginViewModelProvider);

    return Scaffold(
      backgroundColor: _surface,
      body: loginState.adminProfile.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: _primary)),
        error: (e, _) => Center(
          child: Text('Error: $e', style: const TextStyle(color: _red)),
        ),
        data: (list) {
          if (list.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => _populateProfile(list.first),
            );
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
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            _section('Personal Info', [
                              _FieldItem(
                                nameController,
                                'Full Name',
                                Icons.person_outline_rounded,
                              ),
                              _FieldItem(
                                mobileController,
                                'Mobile',
                                Icons.phone_outlined,
                                type: TextInputType.phone,
                                max: 10,
                                validate: (v) {
                                  if (v == null || v.isEmpty) return 'Required';
                                  if (v.length != 10)
                                    return '10 digits required';
                                  return null;
                                },
                              ),
                              _FieldItem(
                                emailController,
                                'Email',
                                Icons.email_outlined,
                                type: TextInputType.emailAddress,
                                validate: (v) {
                                  if (v == null || v.isEmpty) return 'Required';
                                  if (!v.contains('@')) return 'Invalid email';
                                  return null;
                                },
                              ),
                            ]),
                            const SizedBox(height: 14),
                            _section('Agency & Location', [
                              _FieldItem(
                                agencyController,
                                'Agency Name',
                                Icons.business_outlined,
                              ),
                              _FieldItem(
                                cityController,
                                'City',
                                Icons.location_city_outlined,
                              ),
                              _FieldItem(
                                addressController,
                                'Address',
                                Icons.home_outlined,
                              ),
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
        ? nameController.text[0].toUpperCase()
        : 'A';
    final displayImageUrl = _displayImageUrl();
    final hasValidNetworkImage = displayImageUrl != null;

    Widget avatarFallback() {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.3),
              Colors.white.withOpacity(0.15),
            ],
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
          colors: [AppColors.brandPrimary, AppColors.brandPrimaryDark],
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
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 15,
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    'Edit Profile',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.4,
                    ),
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
                      GestureDetector(
                        onTap: _showImagePreview,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: SizedBox.expand(
                              child: _profileImage != null
                                  ? Image.file(
                                      _profileImage!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          avatarFallback(),
                                    )
                                  : hasValidNetworkImage
                                  ? Image.network(
                                      displayImageUrl,
                                      key: ValueKey(displayImageUrl),
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          avatarFallback(),
                                    )
                                  : avatarFallback(),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _showImageOptions,
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border: Border.all(color: _primary, width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              color: _primary,
                              size: 13,
                            ),
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
                            ? nameController.text
                            : 'Your Name',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: _showImageOptions,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.camera_alt_outlined, color: Colors.white, size: 12),
                              SizedBox(width: 4),
                              Text('Change photo',
                                  style: TextStyle(fontSize: 11, color: Colors.white,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Section card ─────────────────────────────────────────────

  Widget _section(String title, List<_FieldItem> fields) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(title.toUpperCase(),
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                  color: _textMid, letterSpacing: 1.3)),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(
                color: _primary.withOpacity(0.07), blurRadius: 16, offset: const Offset(0, 4))],
          ),
          child: Column(
            children: List.generate(fields.length, (i) {
              final isFirst = i == 0;
              final isLast  = i == fields.length - 1;
              return Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.vertical(
                      top:    isFirst ? const Radius.circular(20) : Radius.zero,
                      bottom: isLast  ? const Radius.circular(20) : Radius.zero,
                    ),
                    child: _buildField(fields[i]),
                  ),
                  if (!isLast)
                    Divider(height: 1, thickness: 1,
                        color: _surface, indent: 56, endIndent: 0),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildField(_FieldItem f) {
    return TextFormField(
      controller: f.ctrl,
      keyboardType: f.type,
      maxLines: 1,
      inputFormatters: f.max != null ? [LengthLimitingTextInputFormatter(f.max!)] : null,
      validator: f.validate ?? (v) => (v == null || v.isEmpty) ? 'Required' : null,
      style: const TextStyle(fontSize: 14, color: _textDark, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: f.label,
        labelStyle: const TextStyle(fontSize: 12, color: _textMid),
        prefixIcon: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(color: _primaryLt, borderRadius: BorderRadius.circular(9)),
            child: Icon(f.icon, color: _primary, size: 15),
          ),
        ),
        border:        InputBorder.none,
        focusedBorder: InputBorder.none,
        enabledBorder: InputBorder.none,
        errorBorder:   InputBorder.none,
        filled: true,
        fillColor: Colors.white,
        // Compact vertical padding so fields fit on screen
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        errorStyle: const TextStyle(fontSize: 10, color: _red),
      ),
    );
  }

  // ── Save button ───────────────────────────────────────────────

  Widget _saveButton() {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isSaving
              ? [_primary.withOpacity(0.6), _primaryDk.withOpacity(0.6)]
              : [_primary, _primaryDk],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: _isSaving ? [] : [
          BoxShadow(color: _primary.withOpacity(0.38), blurRadius: 16, offset: const Offset(0, 7)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: _isSaving ? null : _saveProfile,
          child: Center(
            child: _isSaving
                ? const SizedBox(width: 22, height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_rounded, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text('Save Changes',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                              color: Colors.white, letterSpacing: -0.2)),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// ── Field data ────────────────────────────────────────────────────

class _FieldItem {
  final TextEditingController ctrl;
  final String label;
  final IconData icon;
  final TextInputType? type;
  final int? max;
  final String? Function(String?)? validate;

  const _FieldItem(this.ctrl, this.label, this.icon,
      {this.type, this.max, this.validate});
}

// ── Image picker sheet ────────────────────────────────────────────

class _ImagePickerSheet extends StatelessWidget {
  final bool hasImage;
  final VoidCallback onCamera, onGallery, onRemove;

  const _ImagePickerSheet({
    required this.hasImage,
    required this.onCamera,
    required this.onGallery,
    required this.onRemove,
  });

  static const _primary  = AppColors.brandPrimary;
  static const _red      = Color(0xFFEF4444);
  static const _textDark = Color(0xFF1A1D3B);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(width: 38, height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4))),
              const SizedBox(height: 18),
              const Text('Profile Photo',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _textDark)),
              const SizedBox(height: 4),
              Text('Choose an option',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              const SizedBox(height: 18),
              Row(
                children: [
                  _tile(Icons.camera_alt_outlined,    'Camera',  _primary, onCamera),
                  const SizedBox(width: 10),
                  _tile(Icons.photo_library_outlined, 'Gallery', _primary, onGallery),
                  if (hasImage) ...[
                    const SizedBox(width: 10),
                    _tile(Icons.delete_outline_rounded, 'Remove', _red, onRemove),
                  ],
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tile(IconData icon, String label, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.07),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.15)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(height: 6),
              Text(label,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
