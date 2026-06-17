import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_agency_app/core/theme/app_colors.dart';
import 'package:travel_agency_app/domain/models/login_response.dart';
import 'package:travel_agency_app/presentation/providers/viewmodel_provider.dart';

/// Reusable WhatsApp OTP verification screen.
///
/// Sends an OTP on entry, lets the user enter the 6-digit code, verifies it
/// against the backend (`login/verifyOtp`) and — only on success — runs
/// [onVerified] to perform the final action (e.g. create the account or reset
/// the password). Pops with `true` once the whole flow succeeds, so the caller
/// can resume via `await Navigator.push(...)`.
class OtpVerificationPage extends ConsumerStatefulWidget {
  /// 10-digit mobile number the OTP is sent to.
  final String mobile;

  /// 'register' | 'forgot_pin'
  final String purpose;

  final String title;
  final String subtitle;

  /// The action to run after the OTP is verified. Treated as successful when it
  /// returns a [LoginResponse] with `success == 1`. Returning null / non-success
  /// keeps the user on this screen with the failure message.
  final Future<LoginResponse?> Function() onVerified;

  /// Message shown (and surfaced to the caller via pop) on full success.
  final String successMessage;

  /// When false, the caller has already sent the OTP (e.g. the sign-up screen
  /// sends it first so it can surface "number already exists" before navigating
  /// here). This screen then just starts the resend countdown instead of sending
  /// a second OTP on mount.
  final bool autoSendOtp;

  /// Dev OTP captured by the caller's send (only when WhatsApp is disabled in
  /// non-production). Shown in the "OTP sent" message when [autoSendOtp] is false.
  final String? initialDevOtp;

  const OtpVerificationPage({
    super.key,
    required this.mobile,
    required this.purpose,
    required this.title,
    required this.subtitle,
    required this.onVerified,
    this.successMessage = "Verified successfully",
    this.autoSendOtp = true,
    this.initialDevOtp,
  });

  @override
  ConsumerState<OtpVerificationPage> createState() =>
      _OtpVerificationPageState();
}

class _OtpVerificationPageState extends ConsumerState<OtpVerificationPage>
    with SingleTickerProviderStateMixin {
  static const primaryColor = AppColors.brandPrimary;
  static const darkBlue = Color(0xFF1A237E);
  static const int _otpLength = 6;
  static const int _resendSeconds = 30;

  final List<TextEditingController> _otpControllers =
      List.generate(_otpLength, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes =
      List.generate(_otpLength, (_) => FocusNode());

  String get _otp => _otpControllers.map((c) => c.text).join();

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  Timer? _resendTimer;
  int _secondsLeft = 0;
  bool _verifying = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();

    // Send the first OTP as soon as the screen mounts — unless the caller
    // already sent it, in which case just start the resend countdown.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.autoSendOtp) {
        _sendOtp(initial: true);
      } else {
        _startResendCountdown();
        final devNote =
            widget.initialDevOtp != null ? " (dev OTP: ${widget.initialDevOtp})" : "";
        _showMessage("OTP sent to your WhatsApp$devNote", success: true);
      }
      _otpFocusNodes.first.requestFocus();
    });
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _animController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  //--------------------------------------------------
  // Networking
  //--------------------------------------------------
  Future<void> _sendOtp({bool initial = false}) async {
    final response = await ref
        .read(loginViewModelProvider.notifier)
        .sendOtp(widget.mobile, widget.purpose);

    if (!mounted) return;

    if (response.success) {
      _startResendCountdown();
      final devNote = response.devOtp != null ? " (dev OTP: ${response.devOtp})" : "";
      _showMessage(
        initial
            ? "OTP sent to your WhatsApp$devNote"
            : "OTP resent to your WhatsApp$devNote",
        success: true,
      );
    } else {
      _showMessage(response.message ?? "Failed to send OTP");
    }
  }

  Future<void> _verify() async {
    final otp = _otp.trim();
    if (otp.length != _otpLength) {
      _showMessage("Please enter the $_otpLength-digit OTP");
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _verifying = true);

    final notifier = ref.read(loginViewModelProvider.notifier);
    final verifyResult =
        await notifier.verifyOtp(widget.mobile, otp, widget.purpose);

    if (!mounted) return;

    if (!verifyResult.success) {
      setState(() => _verifying = false);
      _showMessage(verifyResult.message ?? "Invalid or expired OTP");
      return;
    }

    // OTP confirmed — run the caller's final action (create account / reset pin).
    final actionResult = await widget.onVerified();

    if (!mounted) return;
    setState(() => _verifying = false);

    if (actionResult != null && actionResult.success == 1) {
      _showMessage(widget.successMessage, success: true);
      Navigator.pop(context, true);
    } else {
      _showMessage(actionResult?.message ?? "Something went wrong");
    }
  }

  //--------------------------------------------------
  // Resend countdown
  //--------------------------------------------------
  void _startResendCountdown() {
    _resendTimer?.cancel();
    setState(() => _secondsLeft = _resendSeconds);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsLeft <= 1) {
        timer.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft--);
      }
    });
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
        backgroundColor: success ? Colors.green.shade600 : Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
    final isBusy = _verifying || loginState.isLoading;

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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context, false),
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
                        "Verify OTP",
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
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: primaryColor.withOpacity(0.4),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.chat_rounded,
                                  size: 38,
                                  color: Colors.white,
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // ── Title ─────────────────
                            Center(
                              child: Text(
                                widget.title,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: darkBlue,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Center(
                              child: Text(
                                widget.subtitle,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade500,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Center(
                              child: Text(
                                "+91 ${widget.mobile}",
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: primaryColor,
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
                                    color: Colors.indigo.withOpacity(0.08),
                                    blurRadius: 30,
                                    offset: const Offset(0, 12),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                children: [
                                  _buildOtpBoxes(),
                                  const SizedBox(height: 28),

                                  // ── Verify Button ──────
                                  SizedBox(
                                    width: double.infinity,
                                    height: 54,
                                    child: ElevatedButton(
                                      onPressed: isBusy ? null : _verify,
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
                                      child: isBusy
                                          ? const SizedBox(
                                              width: 22,
                                              height: 22,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2.5,
                                              ),
                                            )
                                          : const Text(
                                              "Verify & Continue",
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                    ),
                                  ),

                                  const SizedBox(height: 18),

                                  // ── Resend ─────────────
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "Didn't get the code? ",
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      _secondsLeft > 0
                                          ? Text(
                                              "Resend in ${_secondsLeft}s",
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.grey.shade500,
                                              ),
                                            )
                                          : GestureDetector(
                                              onTap: isBusy
                                                  ? null
                                                  : () => _sendOtp(),
                                              child: const Text(
                                                "Resend OTP",
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700,
                                                  color: primaryColor,
                                                ),
                                              ),
                                            ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),
                          ],
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

  /// 6 independently editable boxes — tap any box to correct its digit. Typing
  /// advances focus, backspace on an empty box steps back, and pasting a full
  /// code distributes it across all boxes.
  Widget _buildOtpBoxes() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(_otpLength, _buildOtpBox),
    );
  }

  Widget _buildOtpBox(int index) {
    final hasDigit = _otpControllers[index].text.isNotEmpty;

    return SizedBox(
      width: 46,
      height: 56,
      child: KeyboardListener(
        focusNode: FocusNode(skipTraversal: true),
        onKeyEvent: (event) {
          // Step back to the previous box when backspace is pressed on an
          // already-empty box.
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.backspace &&
              _otpControllers[index].text.isEmpty &&
              index > 0) {
            _otpControllers[index - 1].clear();
            _otpFocusNodes[index - 1].requestFocus();
            setState(() {});
          }
        },
        child: TextField(
          controller: _otpControllers[index],
          focusNode: _otpFocusNodes[index],
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 1,
          showCursor: true,
          cursorColor: primaryColor,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: darkBlue,
          ),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            counterText: "",
            filled: true,
            fillColor: const Color(0xFFF5F7FF),
            contentPadding: EdgeInsets.zero,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasDigit
                    ? primaryColor.withOpacity(0.4)
                    : Colors.grey.shade200,
                width: 1.2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: primaryColor, width: 1.8),
            ),
          ),
          onChanged: (value) => _onDigitChanged(index, value),
          onTap: () {
            // Place the cursor after the digit so typing overwrites cleanly.
            _otpControllers[index].selection = TextSelection.collapsed(
              offset: _otpControllers[index].text.length,
            );
          },
        ),
      ),
    );
  }

  void _onDigitChanged(int index, String value) {
    // Handle a pasted / autofilled multi-digit string by spreading it out.
    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'\D'), '');
      for (var i = 0; i < _otpLength; i++) {
        _otpControllers[i].text = i < digits.length ? digits[i] : '';
      }
      final next =
          digits.length >= _otpLength ? _otpLength - 1 : digits.length;
      _otpFocusNodes[next].requestFocus();
    } else if (value.isNotEmpty && index < _otpLength - 1) {
      _otpFocusNodes[index + 1].requestFocus();
    }

    setState(() {});

    if (_otp.length == _otpLength && !_verifying) {
      FocusScope.of(context).unfocus();
      _verify();
    }
  }
}
