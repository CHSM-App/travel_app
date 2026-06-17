import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:travel_agency_app/core/widgets/error_view.dart';
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
  final otpController     = TextEditingController();

  File?   _profileImage;
  String? _imageUrl;
  bool _isSaving = false;
  bool _didPopulateInitialProfile = false;
  int _avatarRefreshToken = 0;
  bool _forceLetterAvatar = false;

  // ── Mobile-number change via OTP ───────────────────
  // The mobile field is editable, but a new number only takes effect once it
  // has been verified with an OTP sent to that number.
  String _originalMobile = '';
  bool _otpSent = false;
  bool _mobileVerified = false;
  bool _sendingOtp = false;
  bool _verifyingOtp = false;

  // ── Design tokens ─────────────────────────────────
  static const _primary = AppColors.brandPrimary;
  static const _primaryLt = AppColors.brandSoft;
  static const _bg = Color(0xFFF0F4FF);
  static const _textDark = Color(0xFF0F1729);
  static const _textMid = Color(0xFF6B7280);
  static const _divider = Color(0xFFE6EAF2);
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
    otpController.dispose();
    super.dispose();
  }


  void _populateProfile(LoginInfo p) {
    if (!_didPopulateInitialProfile) {
      if (nameController.text.isEmpty) nameController.text = p.name ?? '';
      if (mobileController.text.isEmpty) mobileController.text = p.mobile ?? '';
      _originalMobile = mobileController.text.trim();
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

          if (res != null && _isUploadSuccess(res['success'])) {
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
    if (f == null) return;

    final picked = File(f.path);
    setState(() {
      _profileImage = picked;
      _imageUrl = null;
      _forceLetterAvatar = false;
    });

    // Upload immediately so the user gets instant "Image uploaded
    // successfully" feedback instead of waiting for Save Changes.
    await _uploadProfileImage(picked);
  }

  // Uploads [image] to the admin profile and shows a green success snackbar on
  // success, or a red error snackbar on failure. Returns true when uploaded.
  Future<bool> _uploadProfileImage(File image) async {
    final list = ref.read(loginViewModelProvider).adminProfile.value;
    final adminId = list?.firstOrNull?.adminId ?? 0;
    final agId = list?.firstOrNull?.agencyId ?? '';

    if (adminId == 0 || agId.isEmpty) {
      _snack('Admin not found', error: true);
      return false;
    }

    setState(() => _isSaving = true);

    final res = await ref
        .read(loginViewModelProvider.notifier)
        .updateAdminProfile(image, adminId, agId);

    if (res == null || !_isUploadSuccess(res['success'])) {
      _snack(res?['message'] ?? res?['error'] ?? 'Image upload failed',
          error: true);
      setState(() => _isSaving = false);
      return false;
    }

    await ref.read(loginViewModelProvider.notifier).adminProfile(adminId);
    setState(() {
      _imageUrl = _extractUploadedUrl(res);
      _profileImage = null;
      _avatarRefreshToken++;
      _forceLetterAvatar = false;
      _isSaving = false;
    });
    _snack('Image uploaded successfully');
    return true;
  }

  // The upload API returns `success: true` (boolean), while older/other admin
  // endpoints use `1` or `"1"`. Treat all of them as success.
  bool _isUploadSuccess(dynamic v) {
    if (v is bool) return v;
    if (v is num) return v == 1;
    if (v is String) {
      final s = v.toLowerCase().trim();
      return s == 'true' || s == '1';
    }
    return false;
  }

  // The secure-upload handler returns the saved URL in a top-level `urls` list;
  // fall back to the older `data.imageUrl` shape if present.
  String? _extractUploadedUrl(Map res) {
    final urls = res['urls'];
    if (urls is List && urls.isNotEmpty) return urls.first?.toString();
    final data = res['data'];
    if (data is Map) return data['imageUrl']?.toString();
    return null;
  }

  // Re-fetches the admin profile from the server for pull-to-refresh.
  Future<void> _refreshProfile() async {
    await ref
        .read(loginViewModelProvider.notifier)
        .adminProfile(ref.read(loginViewModelProvider).adminId);
  }

  bool get _mobileChanged =>
      mobileController.text.trim() != _originalMobile.trim();

  // Sends an OTP to the newly-entered mobile number (purpose 'change_mobile').
  Future<void> _sendMobileOtp() async {
    final newMobile = mobileController.text.trim();
    if (newMobile.length != 10) {
      _snack('Enter a valid 10-digit mobile number', error: true);
      return;
    }
    HapticFeedback.lightImpact();
    setState(() => _sendingOtp = true);
    final res = await ref
        .read(loginViewModelProvider.notifier)
        .sendOtp(newMobile, 'change_mobile');
    setState(() => _sendingOtp = false);

    if (res.success) {
      setState(() {
        _otpSent = true;
        _mobileVerified = false;
        otpController.clear();
      });
      _snack(res.devOtp != null
          ? 'OTP sent (dev: ${res.devOtp})'
          : 'OTP sent to $newMobile');
    } else {
      _snack(res.message ?? 'Failed to send OTP', error: true);
    }
  }

  // Verifies the OTP for the new mobile number. On success the number is marked
  // verified and will be persisted on the next "Save Changes".
  Future<void> _verifyMobileOtp() async {
    final newMobile = mobileController.text.trim();
    final otp = otpController.text.trim();
    if (otp.isEmpty) {
      _snack('Enter the OTP', error: true);
      return;
    }
    HapticFeedback.lightImpact();
    setState(() => _verifyingOtp = true);
    final res = await ref
        .read(loginViewModelProvider.notifier)
        .verifyOtp(newMobile, otp, 'change_mobile');
    setState(() => _verifyingOtp = false);

    if (res.success) {
      setState(() {
        _mobileVerified = true;
        _otpSent = false;
        otpController.clear();
      });
      _snack('Mobile number verified');
    } else {
      _snack(res.message ?? 'Invalid or expired OTP', error: true);
    }
  }

  // OTP verification UI shown beneath the Mobile field when the number changes.
  Widget _mobileOtpSection() {
    if (!_mobileChanged) return const SizedBox.shrink();

    const padding = EdgeInsets.fromLTRB(44, 0, 12, 10);

    if (_mobileVerified) {
      return const Padding(
        padding: padding,
        child: Row(
          children: [
            Icon(Icons.verified_rounded, color: _green, size: 14),
            SizedBox(width: 6),
            Text(
              'New number verified',
              style: TextStyle(
                fontSize: 11,
                color: _green,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    final canSend = mobileController.text.trim().length == 10;

    return Padding(
      padding: padding,
      child: !_otpSent
          ? Row(
              children: [
                const Expanded(
                  child: Text(
                    'Verify your new mobile number to update it',
                    style: TextStyle(fontSize: 10.5, color: _textMid),
                  ),
                ),
                const SizedBox(width: 8),
                _otpButton(
                  'Send OTP',
                  _sendingOtp,
                  canSend ? _sendMobileOtp : null,
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: otpController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: _textDark,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2,
                        ),
                        cursorColor: _primary,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(6),
                        ],
                        decoration: InputDecoration(
                          counterText: '',
                          isDense: true,
                          hintText: 'Enter OTP',
                          hintStyle: const TextStyle(
                            fontSize: 12,
                            color: _textMid,
                            letterSpacing: 0,
                            fontWeight: FontWeight.w500,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          filled: true,
                          fillColor: _bg,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(9),
                            borderSide: const BorderSide(color: _divider),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(9),
                            borderSide: const BorderSide(color: _divider),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(9),
                            borderSide:
                                const BorderSide(color: _primary, width: 1.4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _otpButton('Verify', _verifyingOtp, _verifyMobileOtp),
                  ],
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: _sendingOtp ? null : _sendMobileOtp,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      _sendingOtp ? 'Sending…' : 'Resend OTP',
                      style: const TextStyle(
                        fontSize: 11,
                        color: _primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _otpButton(String label, bool loading, VoidCallback? onTap) {
    return SizedBox(
      height: 32,
      child: ElevatedButton(
        onPressed: loading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _primary.withOpacity(0.4),
          disabledForegroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9),
          ),
          textStyle:
              const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
        ),
        child: loading
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(label),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    // A changed mobile number must be OTP-verified before it can be saved.
    if (_mobileChanged && !_mobileVerified) {
      _snack('Please verify your new mobile number', error: true);
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _isSaving = true);

    final list = ref.read(loginViewModelProvider).adminProfile.value;
    final adminId = list?.firstOrNull?.adminId ?? 0;

    // A staged image is normally uploaded as soon as it's picked, but if one is
    // still pending (e.g. upload failed earlier) push it now before saving.
    if (_profileImage != null) {
      final ok = await _uploadProfileImage(_profileImage!);
      if (!ok) return; // _uploadProfileImage already cleared _isSaving + snacked
      setState(() => _isSaving = true);
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
      // The new number is now the baseline; clear the verification UI.
      _originalMobile = mobileController.text.trim();
      _otpSent = false;
      _mobileVerified = false;
      otpController.clear();
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
      backgroundColor: _bg,
      body: loginState.adminProfile.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: _primary)),
        error: (e, _) => NetworkErrorView(
          error: e,
          onRetry: () async => ref
              .read(loginViewModelProvider.notifier)
              .adminProfile(ref.read(loginViewModelProvider).adminId),
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
                  child: RefreshIndicator(
                    onRefresh: _refreshProfile,
                    color: _primary,
                    child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            _section(
                              'Personal Info',
                              Icons.person_rounded,
                              [
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
                                  capitalization: TextCapitalization.none,
                                  max: 10,
                                  onChanged: (v) {
                                    setState(() {
                                      // Any edit invalidates a prior verification;
                                      // reverting to the original clears the OTP UI.
                                      _mobileVerified = false;
                                      if (v.trim() == _originalMobile.trim()) {
                                        _otpSent = false;
                                        otpController.clear();
                                      }
                                    });
                                  },
                                  below: _mobileOtpSection(),
                                  validate: (v) {
                                    if (v == null || v.isEmpty) {
                                      return 'Required';
                                    }
                                    if (v.length != 10) {
                                      return '10 digits required';
                                    }
                                    return null;
                                  },
                                ),
                                _FieldItem(
                                  emailController,
                                  'Email',
                                  Icons.email_outlined,
                                  type: TextInputType.emailAddress,
                                  capitalization: TextCapitalization.none,
                                  validate: (v) {
                                    // Email is optional; validate format only when
                                    // a value is entered.
                                    if (v == null || v.trim().isEmpty) {
                                      return null;
                                    }
                                    if (!v.contains('@')) {
                                      return 'Invalid email';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _section(
                              'Agency & Location',
                              Icons.business_rounded,
                              [
                                _FieldItem(
                                  agencyController,
                                  'Agency Name',
                                  Icons.business_outlined,
                                  // Optional field.
                                  validate: (_) => null,
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
                              ],
                            ),
                            const SizedBox(height: 16),
                            _saveButton(),
                          ],
                        ),
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

  // ── Compact header: horizontal avatar + name strip ──────────
  Widget _buildHeader() {
    final initial = nameController.text.isNotEmpty
        ? nameController.text[0].toUpperCase()
        : 'A';
    final displayImageUrl = _displayImageUrl();
    final hasValidNetworkImage = displayImageUrl != null;

    Widget avatarFallback() {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.30),
        ),
        alignment: Alignment.center,
        child: Text(
          initial,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.3,
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.brandHeader,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(22)),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.25),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(22),
        ),
        child: Stack(
          children: [
            // Single soft decorative blob, kept subtle.
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.07),
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 12, 14),
                child: Column(
                  children: [
                    // Title bar
                    Row(
                      children: [
                        Material(
                          color: Colors.white.withOpacity(0.16),
                          borderRadius: BorderRadius.circular(10),
                          child: InkWell(
                            onTap: () => Navigator.pop(context),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              width: 32,
                              height: 32,
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: Colors.white,
                                size: 13,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Edit Profile',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Horizontal avatar + name + camera button row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        children: [
                          Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              GestureDetector(
                                onTap: _showImagePreview,
                                child: Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFFE8EAF6),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.85),
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.18),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
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
                              Positioned(
                                right: -2,
                                bottom: -2,
                                child: GestureDetector(
                                  onTap: _showImageOptions,
                                  child: Container(
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                      border: Border.all(
                                        color: _primary.withOpacity(0.25),
                                        width: 1.2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.15),
                                          blurRadius: 5,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt_rounded,
                                      color: _primary,
                                      size: 11,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  nameController.text.isNotEmpty
                                      ? nameController.text
                                      : 'Your Name',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: -0.3,
                                    height: 1.1,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  emailController.text.isNotEmpty
                                      ? emailController.text
                                      : 'Manage your account',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.white.withOpacity(0.80),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Section card (compact) ───────────────────────────────────
  Widget _section(String title, IconData icon, List<_FieldItem> fields) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 6),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 12,
                decoration: BoxDecoration(
                  color: _primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 7),
              Icon(icon, color: _primary, size: 11),
              const SizedBox(width: 5),
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  color: _textMid,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _divider),
            boxShadow: [
              BoxShadow(
                color: _primary.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: List.generate(fields.length, (i) {
              final isLast = i == fields.length - 1;
              return Column(
                children: [
                  _buildField(fields[i]),
                  if (fields[i].below != null) fields[i].below!,
                  if (!isLast)
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: _divider,
                      indent: 44,
                    ),
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
      textCapitalization: f.capitalization,
      maxLines: 1,
      onChanged: f.onChanged,
      inputFormatters: [
        if (f.max != null) LengthLimitingTextInputFormatter(f.max!),
      ],
      validator:
          f.validate ?? (v) => (v == null || v.isEmpty) ? 'Required' : null,
      style: const TextStyle(
        fontSize: 13.5,
        color: _textDark,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
      ),
      cursorColor: _primary,
      decoration: InputDecoration(
        labelText: f.label,
        isDense: true,
        labelStyle: const TextStyle(
          fontSize: 12,
          color: _textMid,
          fontWeight: FontWeight.w500,
        ),
        floatingLabelStyle: const TextStyle(
          fontSize: 11.5,
          color: _primary,
          fontWeight: FontWeight.w700,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: _primaryLt,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(f.icon, color: _primary, size: 13),
          ),
        ),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 44,
          minHeight: 32,
        ),
        border: InputBorder.none,
        focusedBorder: InputBorder.none,
        enabledBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        focusedErrorBorder: InputBorder.none,
        filled: true,
        fillColor: Colors.transparent,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        errorStyle: const TextStyle(
          fontSize: 9.5,
          color: _red,
          fontWeight: FontWeight.w600,
          height: 0.9,
        ),
      ),
    );
  }

  // ── Save button (compact) ────────────────────────────────────
  Widget _saveButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity,
      height: 46,
      decoration: BoxDecoration(
        color: _isSaving ? _primary.withOpacity(0.55) : _primary,
        borderRadius: BorderRadius.circular(13),
        boxShadow: _isSaving
            ? []
            : [
                BoxShadow(
                  color: _primary.withOpacity(0.32),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(13),
          onTap: _isSaving ? null : _saveProfile,
          child: Center(
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.2,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        color: Colors.white,
                        size: 17,
                      ),
                      SizedBox(width: 7),
                      Text(
                        'Save Changes',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                      ),
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
  final TextCapitalization capitalization;
  final void Function(String)? onChanged;

  /// Optional widget rendered directly beneath the field (inside the card),
  /// used by the mobile field for its OTP-verification UI.
  final Widget? below;

  const _FieldItem(this.ctrl, this.label, this.icon,
      {this.type,
      this.max,
      this.validate,
      this.onChanged,
      this.below,
      this.capitalization = TextCapitalization.words});
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
