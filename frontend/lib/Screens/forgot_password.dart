import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_agency_app/Screens/otp_verification.dart';
import 'package:travel_agency_app/core/theme/app_colors.dart';
import 'package:travel_agency_app/domain/models/login_info.dart';
import 'package:travel_agency_app/presentation/providers/viewmodel_provider.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() =>
      _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage>
    with SingleTickerProviderStateMixin {
  //--------------------------------------------------
  // Controllers & State
  //--------------------------------------------------
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // Brand colors (same as login page)
  static const primaryColor = AppColors.brandPrimary;
  static const darkBlue = Color(0xFF1A237E);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  //--------------------------------------------------
  // Forgot Password Function
  //--------------------------------------------------
  Future<void> _forgotPassword() async {
    if (!_formKey.currentState!.validate()) return;

    final mobile = _mobileController.text.trim();
    final password = _passwordController.text.trim();

    final loginInfo = LoginInfo(mobile: mobile, password: password);

    // Verify the mobile via WhatsApp OTP before resetting the password. The OTP
    // screen sends the code, verifies it, and only then runs the reset action,
    // popping with `true` on full success.
    final verified = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => OtpVerificationPage(
          mobile: mobile,
          purpose: 'forgot_pin',
          title: "Verify your number",
          subtitle: "Enter the 6-digit code sent to your WhatsApp",
          successMessage: "Password reset successfully",
          onVerified: () => ref
              .read(loginViewModelProvider.notifier)
              .forgotPassword(loginInfo),
        ),
      ),
    );

    if (!mounted) return;

    if (verified == true) {
      Navigator.pop(context);
    }
  }

  //--------------------------------------------------
  // UI
  //--------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(loginViewModelProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: Stack(
        children: [
          // ── Decorative blobs ─────────────────────────────
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryColor.withOpacity(0.12),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            left: -40,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.brandPrimaryLight.withOpacity(0.08),
              ),
            ),
          ),

          // ── Main Content ─────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // ── Custom AppBar ──────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.indigo.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 16,
                            color: primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        "Reset Password",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: darkBlue,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Scrollable Body ────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 10),
                    child: FadeTransition(
                      opacity: _fadeAnim,
                      child: SlideTransition(
                        position: _slideAnim,
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 16),

                              // ── Icon ──────────────────
                              Center(
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: AppColors.brandPrimary,
                                    borderRadius:
                                        BorderRadius.circular(24),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            primaryColor.withOpacity(0.4),
                                        blurRadius: 20,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.lock_reset_rounded,
                                    size: 40,
                                    color: Colors.white,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 24),

                              // ── Title ─────────────────
                              const Center(
                                child: Text(
                                  "Forgot Password?",
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    color: darkBlue,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Center(
                                child: Text(
                                  "Enter your mobile & set a new password",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade500,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 32),

                              // ── Card ──────────────────
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.indigo.withOpacity(0.08),
                                      blurRadius: 30,
                                      offset: const Offset(0, 12),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    // ── Mobile ──────────
                                    _buildLabel("Mobile Number"),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: _mobileController,
                                      keyboardType: TextInputType.phone,
                                      maxLength: 10,
                                      inputFormatters: [
                                        FilteringTextInputFormatter
                                            .digitsOnly,
                                        LengthLimitingTextInputFormatter(
                                            10),
                                      ],
                                      validator: (value) {
                                        if (value == null ||
                                            value.isEmpty) {
                                          return "Please enter mobile number";
                                        }
                                        if (value.length != 10) {
                                          return "Mobile number must be exactly 10 digits";
                                        }
                                        return null;
                                      },
                                      decoration: _inputDecoration(
                                        hint:
                                            "Enter 10-digit mobile number",
                                        icon:
                                            Icons.phone_android_rounded,
                                      ),
                                    ),

                                    const SizedBox(height: 16),

                                    // ── New Password ────
                                    _buildLabel("New Password"),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: _passwordController,
                                      obscureText: _obscurePassword,
                                      validator: (value) {
                                        if (value == null ||
                                            value.isEmpty) {
                                          return "Please enter new password";
                                        }
                                        if (value.length < 6) {
                                          return "Password must be at least 6 characters";
                                        }
                                        return null;
                                      },
                                      decoration:
                                          _inputDecoration(
                                        hint: "Enter new password",
                                        icon: Icons.lock_outline_rounded,
                                      ).copyWith(
                                        counterText: "",
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscurePassword
                                                ? Icons
                                                    .visibility_off_outlined
                                                : Icons
                                                    .visibility_outlined,
                                            color: Colors.grey.shade400,
                                            size: 20,
                                          ),
                                          onPressed: () => setState(() =>
                                              _obscurePassword =
                                                  !_obscurePassword),
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 16),

                                    // ── Confirm Password ─
                                    _buildLabel("Confirm Password"),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller:
                                          _confirmPasswordController,
                                      obscureText: _obscureConfirm,
                                      validator: (value) {
                                        if (value == null ||
                                            value.isEmpty) {
                                          return "Please confirm password";
                                        }
                                        if (value !=
                                            _passwordController.text) {
                                          return "Passwords do not match";
                                        }
                                        return null;
                                      },
                                      decoration:
                                          _inputDecoration(
                                        hint: "Re-enter new password",
                                        icon: Icons
                                            .lock_person_outlined,
                                      ).copyWith(
                                        counterText: "",
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscureConfirm
                                                ? Icons
                                                    .visibility_off_outlined
                                                : Icons
                                                    .visibility_outlined,
                                            color: Colors.grey.shade400,
                                            size: 20,
                                          ),
                                          onPressed: () => setState(() =>
                                              _obscureConfirm =
                                                  !_obscureConfirm),
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 28),

                                    // ── Reset Button ────
                                    SizedBox(
                                      width: double.infinity,
                                      height: 54,
                                      child: ElevatedButton(
                                        onPressed: state.isLoading
                                            ? null
                                            : _forgotPassword,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: primaryColor,
                                          foregroundColor: Colors.white,
                                          disabledBackgroundColor:
                                              primaryColor.withOpacity(0.5),
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(14),
                                          ),
                                        ),
                                        child: state.isLoading
                                            ? const SizedBox(
                                                width: 22,
                                                height: 22,
                                                child:
                                                    CircularProgressIndicator(
                                                  color: Colors.white,
                                                  strokeWidth: 2.5,
                                                ),
                                              )
                                            : const Text(
                                                "Reset Password",
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight:
                                                      FontWeight.w700,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 24),

                              // ── Back to Login ──────────
                              Center(
                                child: GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.arrow_back_rounded,
                                        size: 16,
                                        color: primaryColor,
                                      ),
                                      const SizedBox(width: 6),
                                      const Text(
                                        "Back to Login",
                                        style: TextStyle(
                                          color: primaryColor,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: darkBlue,
        letterSpacing: 0.3,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      prefixIcon: Icon(icon, color: primaryColor, size: 20),
      filled: true,
      fillColor: const Color(0xFFF5F7FF),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            const BorderSide(color: primaryColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            const BorderSide(color: Colors.redAccent, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
      counterText: "",
    );
  }
}