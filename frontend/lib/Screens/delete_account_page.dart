import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_agency_app/Screens/login.dart';
import 'package:travel_agency_app/core/notifications/push_service.dart';
import 'package:travel_agency_app/core/storage/token_storage.dart';
import 'package:travel_agency_app/core/theme/app_colors.dart';
import 'package:travel_agency_app/presentation/providers/viewmodel_provider.dart';

/// In-app account deletion (Google Play data-deletion compliance).
///
/// Mirrors the public web flow at vego.vengurlatech.com/delete-account:
///   1. Send a WhatsApp OTP to the signed-in user's registered mobile.
///   2. Enter the OTP (+ an optional reason) and confirm.
///   3. The backend records the request; the account and all associated data
///      are permanently removed within 30 days. On success we sign the user
///      out locally and return them to the login screen.
class DeleteAccountPage extends ConsumerStatefulWidget {
  const DeleteAccountPage({super.key});

  @override
  ConsumerState<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends ConsumerState<DeleteAccountPage> {
  static const Color _danger = Color(0xFFB91C1C);
  static const Color _dangerSoft = Color(0xFFFDECEA);

  final _otpController = TextEditingController();
  final _reasonController = TextEditingController();

  String? _mobile; // registered number, loaded from secure storage
  int _step = 0; // 0 = confirm/send OTP, 1 = enter OTP + confirm
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMobile();
  }

  Future<void> _loadMobile() async {
    final m = await TokenStorage.getValue('mobile');
    if (mounted) setState(() => _mobile = m);
  }

  @override
  void dispose() {
    _otpController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  // ── Step 0 → request a WhatsApp OTP for deletion ────────────────────
  Future<void> _sendOtp() async {
    final mobile = _mobile;
    if (mobile == null || mobile.isEmpty) {
      setState(() => _error = 'Your registered number is unavailable. Please re-login and try again.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final res = await ref
        .read(loginViewModelProvider.notifier)
        .sendOtp(mobile, 'delete_account');
    if (!mounted) return;
    setState(() => _busy = false);
    if (res.success) {
      setState(() {
        _step = 1;
        _error = null;
      });
    } else {
      setState(() => _error = res.message ?? 'Could not send the verification code.');
    }
  }

  // ── Step 1 → verify OTP + record the deletion request ───────────────
  Future<void> _confirmDelete() async {
    final mobile = _mobile;
    final otp = _otpController.text.trim();
    if (mobile == null) return;
    if (otp.length != 6) {
      setState(() => _error = 'Enter the 6-digit code sent to your number.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final res = await ref
        .read(loginViewModelProvider.notifier)
        .deleteAccount(mobile, otp, _reasonController.text.trim());
    if (!mounted) return;
    setState(() => _busy = false);

    final ok = res != null && (res is Map) && res['success'] == true;
    if (!ok) {
      setState(() => _error = (res is Map ? res['message'] as String? : null) ??
          ref.read(loginViewModelProvider).error ??
          'Could not submit your request. Please try again.');
      return;
    }

    // Request recorded — sign out locally and return to login.
    await PushService.removeToken();
    await ref.read(loginViewModelProvider.notifier).logout();
    if (!mounted) return;
    await _showDoneDialog();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  Future<void> _showDoneDialog() {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(color: _dangerSoft, shape: BoxShape.circle),
                child: const Icon(Icons.check_circle_outline_rounded, color: _danger, size: 32),
              ),
              const SizedBox(height: 16),
              const Text('Request received',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              Text(
                'Your account and all associated data will be permanently '
                'deleted within 30 days. Changed your mind? Contact '
                'support@vengurlatech.com before then and we\'ll keep it active.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, height: 1.5, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('OK', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: const Color(0xFF1A1D3B),
        title: const Text('Delete Account',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _warningBanner(),
              const SizedBox(height: 20),
              if (_error != null) ...[
                _errorBox(_error!),
                const SizedBox(height: 16),
              ],
              if (_step == 0) _confirmStep() else _otpStep(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _warningBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _dangerSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _danger.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: _danger, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'This permanently deletes your account and all associated data — '
              'trips, bookings, vehicles, drivers, customers, payments and '
              'reports. It cannot be recovered after the 30-day grace period.',
              style: TextStyle(fontSize: 12.5, height: 1.5, color: const Color(0xFF7A1414)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _confirmStep() {
    final masked = _maskedMobile();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('What will be deleted',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        ..._deletionItems.map(_bullet),
        const SizedBox(height: 20),
        Text(
          masked == null
              ? 'We\'ll send a one-time verification code to your registered WhatsApp number.'
              : 'We\'ll send a one-time verification code to your registered number $masked via WhatsApp.',
          style: TextStyle(fontSize: 13, height: 1.5, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 20),
        _primaryDangerButton(
          label: _busy ? 'Sending code…' : 'Send verification code',
          onPressed: _busy ? null : _sendOtp,
        ),
        const SizedBox(height: 10),
        _cancelButton(),
      ],
    );
  }

  Widget _otpStep() {
    final masked = _maskedMobile();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          masked == null
              ? 'Enter the 6-digit code sent to your number.'
              : 'Enter the 6-digit code sent to $masked.',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          autofocus: true,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(fontSize: 20, letterSpacing: 8, fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            counterText: '',
            hintText: '••••••',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColors.border),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: _busy ? null : _sendOtp,
            child: const Text('Resend code'),
          ),
        ),
        const SizedBox(height: 8),
        const Text('Reason for leaving (optional)',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: _reasonController,
          maxLength: 500,
          maxLines: 3,
          decoration: InputDecoration(
            counterText: '',
            hintText: 'Help us improve Vego…',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColors.border),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _primaryDangerButton(
          label: _busy ? 'Submitting…' : 'Delete my account',
          onPressed: _busy ? null : _confirmDelete,
        ),
        const SizedBox(height: 10),
        _cancelButton(),
      ],
    );
  }

  static const _deletionItems = [
    'All trips and booking history',
    'All vehicles and service records',
    'All drivers and customers',
    'All payments, expenses and reports',
    'Your agency profile and settings',
  ];

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.remove_circle_outline_rounded, size: 16, color: _danger),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: TextStyle(fontSize: 13.5, height: 1.4, color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }

  Widget _primaryDangerButton({required String label, VoidCallback? onPressed}) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: _danger,
        foregroundColor: Colors.white,
        disabledBackgroundColor: _danger.withOpacity(0.5),
        disabledForegroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_busy) ...[
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            const SizedBox(width: 10),
          ],
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        ],
      ),
    );
  }

  Widget _cancelButton() {
    return TextButton(
      onPressed: _busy ? null : () => Navigator.maybePop(context),
      child: Text('Cancel — keep my account',
          style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
    );
  }

  Widget _errorBox(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _dangerSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: _danger, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: const TextStyle(fontSize: 13, color: _danger)),
          ),
        ],
      ),
    );
  }

  String? _maskedMobile() {
    final m = _mobile;
    if (m == null || m.length < 4) return null;
    final last = m.substring(m.length - 4);
    return '••••••$last';
  }
}
