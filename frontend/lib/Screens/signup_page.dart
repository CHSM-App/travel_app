import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vego/Screens/login.dart';
import 'package:vego/Screens/otp_verification.dart';
import 'package:vego/Screens/terms_conditions.dart';
import 'package:vego/core/theme/app_colors.dart';
import 'package:vego/domain/models/login_info.dart';
import 'package:vego/presentation/providers/viewmodel_provider.dart';

class SignUpPage extends ConsumerStatefulWidget {
  const SignUpPage({super.key});

  @override
  ConsumerState<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends ConsumerState<SignUpPage>
    with SingleTickerProviderStateMixin {
  //--------------------------------------------------
  // Controllers
  //--------------------------------------------------
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _agencyController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final _formKey = GlobalKey<FormState>();
  final TapGestureRecognizer _termsRecognizer = TapGestureRecognizer();
  bool _agreeTerms = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // Brand colors
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
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _termsRecognizer.dispose();
    _nameController.dispose();
    _addressController.dispose();
    _agencyController.dispose();
    _cityController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  //--------------------------------------------------
  // Sign Up Function
  //--------------------------------------------------
  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_agreeTerms) {
      _showMessage("Please agree to Terms & Conditions");
      return;
    }

    final mobile = _mobileController.text.trim();

    final loginInfo = LoginInfo(
      name: _nameController.text.trim(),
      // address: _addressController.text.trim(),
      // agencyName: _agencyController.text.trim(),
      // city: _cityController.text.trim(),
      mobile: mobile,
      // email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    // Send the registration OTP from here first. The backend rejects this with
    // a "number already exists" error when the mobile is already registered, so
    // we surface that on this screen instead of navigating to the OTP page.
    final otpResponse = await ref
        .read(loginViewModelProvider.notifier)
        .sendOtp(mobile, 'register');

    if (!mounted) return;

    if (!otpResponse.success) {
      _showMessage(otpResponse.message ?? "Failed to send OTP");
      return;
    }

    // Verify the mobile number via WhatsApp OTP before creating the account.
    // The OTP screen verifies the code (already sent above) and only then runs
    // the account-creation action, popping with `true` on full success.
    final verified = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => OtpVerificationPage(
          mobile: mobile,
          purpose: 'register',
          autoSendOtp: false,
          initialDevOtp: otpResponse.devOtp,
          title: "Verify your number",
          subtitle: "Enter the 6-digit code sent to your WhatsApp",
          successMessage: "Account created successfully",
          onVerified: () => ref
              .read(loginViewModelProvider.notifier)
              .addAdmin(loginInfo),
        ),
      ),
    );

    if (!mounted) return;

    if (verified == true) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  void _openTerms() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TermsConditionsPage()),
    );
  }

  void _showMessage(String message, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              success ? Icons.check_circle_outline : Icons.error_outline,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor:
            success ? Colors.green.shade600 : Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  //--------------------------------------------------
  // UI
  //--------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(loginViewModelProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: Stack(
        children: [
          // ── Decorative blobs ─────────────────────────
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

          // ── Content ──────────────────────────────────
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 28, vertical: 20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Logo ──────────────────────
                        Center(
                          child: Image.asset(
                            'assets/branding/vego_logo.png',
                            width: 120,
                            fit: BoxFit.contain,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ── Heading ───────────────────
                        const Center(
                          child: Text(
                            "Create Account",
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
                            "Sign up to get started",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ),

                        const SizedBox(height: 28),

                        // ── Section: Personal Info ────
                        _sectionHeader("Personal Information",
                            Icons.person_outline_rounded),
                        const SizedBox(height: 14),

                        Container(
                          decoration: _cardDecoration(),
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              _buildLabel("Full Name"),
                              const SizedBox(height: 8),
                              _buildField(
                                controller: _nameController,
                                hint: "Enter your full name",
                                icon: Icons.person_rounded,
                                textCapitalization: TextCapitalization.words,
                                validator: (v) => v == null || v.isEmpty
                                    ? "Name is required"
                                    : null,
                              ),
                              const SizedBox(height: 16),
                              _buildLabel("Mobile Number"),
                              const SizedBox(height: 8),
                              _buildField(
                                controller: _mobileController,
                                hint: "Enter 10-digit mobile number",
                                icon: Icons.phone_android_rounded,
                                keyboard: TextInputType.phone,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(10),
                                ],
                                maxLength: 10,
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return "Mobile number is required";
                                  }
                                  if (v.length != 10) {
                                    return "Must be exactly 10 digits";
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              // _buildLabel("Email Address"),
                              // const SizedBox(height: 8),
                              // _buildField(
                              //   controller: _emailController,
                              //   hint: "Enter your email",
                              //   icon: Icons.email_outlined,
                              //   keyboard: TextInputType.emailAddress,
                              //   validator: (v) {
                              //     if (v == null || v.isEmpty) {
                              //       return "Email is required";
                              //     }
                              //     if (!RegExp(
                              //             r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                              //         .hasMatch(v)) {
                              //       return "Enter a valid email";
                              //     }
                              //     return null;
                              //   },
                              // ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ── Section: Agency Info ──────
                        // _sectionHeader(
                        //     "Agency Details", Icons.apartment_rounded),
                        // const SizedBox(height: 14),

                        // Container(
                        //   decoration: _cardDecoration(),
                        //   padding: const EdgeInsets.all(20),
                        //   child: Column(
                        //     children: [
                        //       _buildLabel("Agency Name"),
                        //       const SizedBox(height: 8),
                        //       _buildField(
                        //         controller: _agencyController,
                        //         hint: "Enter agency name",
                        //         icon: Icons.apartment_rounded,
                        //         validator: (v) => v == null || v.isEmpty
                        //             ? "Agency name is required"
                        //             : null,
                        //       ),
                        //       const SizedBox(height: 16),
                        //       _buildLabel("Address"),
                        //       const SizedBox(height: 8),
                        //       _buildField(
                        //         controller: _addressController,
                        //         hint: "Enter full address",
                        //         icon: Icons.home_outlined,
                        //         validator: (v) => v == null || v.isEmpty
                        //             ? "Address is required"
                        //             : null,
                        //       ),
                        //       const SizedBox(height: 16),
                        //       _buildLabel("City"),
                        //       const SizedBox(height: 8),
                        //       _buildField(
                        //         controller: _cityController,
                        //         hint: "Enter city",
                        //         icon: Icons.location_city_rounded,
                        //         validator: (v) => v == null || v.isEmpty
                        //             ? "City is required"
                        //             : null,
                        //       ),
                        //     ],
                        //   ),
                        // ),

                        // const SizedBox(height: 20),

                        // ── Section: Security ─────────
                        _sectionHeader(
                            "Security", Icons.shield_outlined),
                        const SizedBox(height: 14),

                        Container(
                          decoration: _cardDecoration(),
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              _buildLabel("4-Digit PIN"),
                              const SizedBox(height: 8),
                              _buildField(
                                controller: _passwordController,
                                hint: "Create a 4-digit PIN",
                                icon: Icons.lock_outline_rounded,
                                obscure: _obscurePassword,
                                keyboard: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(4),
                                ],
                                maxLength: 4,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: Colors.grey.shade400,
                                    size: 20,
                                  ),
                                  onPressed: () => setState(() =>
                                      _obscurePassword = !_obscurePassword),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return "PIN is required";
                                  }
                                  if (v.length != 4) {
                                    return "PIN must be exactly 4 digits";
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              _buildLabel("Confirm PIN"),
                              const SizedBox(height: 8),
                              _buildField(
                                controller: _confirmPasswordController,
                                hint: "Re-enter PIN",
                                icon: Icons.lock_person_outlined,
                                obscure: _obscureConfirm,
                                keyboard: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(4),
                                ],
                                maxLength: 4,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirm
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: Colors.grey.shade400,
                                    size: 20,
                                  ),
                                  onPressed: () => setState(
                                      () => _obscureConfirm = !_obscureConfirm),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return "Please confirm PIN";
                                  }
                                  if (v != _passwordController.text) {
                                    return "PINs do not match";
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ── Terms & Conditions ────────
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _agreeTerms
                                  ? primaryColor.withOpacity(0.4)
                                  : Colors.grey.shade200,
                              width: 1.2,
                            ),
                          ),
                          child: InkWell(
                            onTap: () =>
                                setState(() => _agreeTerms = !_agreeTerms),
                            borderRadius: BorderRadius.circular(14),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              child: Row(
                                children: [
                                  AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 200),
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      color: _agreeTerms
                                          ? primaryColor
                                          : Colors.transparent,
                                      borderRadius:
                                          BorderRadius.circular(6),
                                      border: Border.all(
                                        color: _agreeTerms
                                            ? primaryColor
                                            : Colors.grey.shade400,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: _agreeTerms
                                        ? const Icon(Icons.check,
                                            color: Colors.white,
                                            size: 14)
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: RichText(
                                      text: TextSpan(
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade700,
                                        ),
                                        children: [
                                          const TextSpan(
                                              text: "I agree to the "),
                                          TextSpan(
                                            text: "Terms & Conditions",
                                            style: const TextStyle(
                                              color: primaryColor,
                                              fontWeight: FontWeight.w600,
                                              decoration:
                                                  TextDecoration.underline,
                                              decorationColor: primaryColor,
                                            ),
                                            recognizer: _termsRecognizer
                                              ..onTap = _openTerms,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ── Sign Up Button ────────────
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: (loginState.isLoading || !_agreeTerms)
                                ? null
                                : _signUp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor:
                                  primaryColor.withOpacity(0.5),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: loginState.isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Text(
                                    "Create Account",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ── Login Row ──────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Already have an account? ",
                              style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const LoginPage()),
                              ),
                              child: const Text(
                                "Sign In",
                                style: TextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),
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
  }

  //--------------------------------------------------
  // Helper Widgets
  //--------------------------------------------------

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: primaryColor, size: 17),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: darkBlue,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.indigo.withOpacity(0.07),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: darkBlue,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    TextInputType keyboard = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.words,
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboard,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      maxLength: maxLength,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        prefixIcon: Icon(icon, color: primaryColor, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFFF5F7FF),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        counterText: "",
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
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
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
      ),
    );
  }
}