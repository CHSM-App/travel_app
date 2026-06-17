import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:travel_agency_app/Screens/deleted_records_page.dart';
import 'package:travel_agency_app/Screens/help_center.dart';
import 'package:travel_agency_app/Screens/login.dart';
import 'package:travel_agency_app/Screens/profile.dart';
import 'package:travel_agency_app/core/network/token_provider.dart';
import 'package:travel_agency_app/core/notifications/push_service.dart';
import 'package:travel_agency_app/core/theme/app_colors.dart';
import 'package:travel_agency_app/core/widgets/error_view.dart';
import 'package:travel_agency_app/domain/models/login_info.dart';
import 'package:travel_agency_app/domain/models/token_response.dart';
import 'package:travel_agency_app/presentation/providers/viewmodel_provider.dart';

class ModernSettingsPage extends ConsumerStatefulWidget {
  const ModernSettingsPage({Key? key}) : super(key: key);

  @override
  ConsumerState<ModernSettingsPage> createState() => _ModernSettingsPageState();
}

class _ModernSettingsPageState extends ConsumerState<ModernSettingsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool notificationsEnabled = true;
  bool locationEnabled = true;

  // App color palette — matches dashboard indigo theme
  static const Color _primary = AppColors.brandPrimary;
  static const Color _primaryLight = AppColors.brandSoft;
  static const Color _surface = Color(0xFFF6F7FF);
  static const Color _cardBg = Colors.white;
  static const Color _textDark = Color(0xFF1A1D3B);
  static const Color _textMid = Color(0xFF6B7280);
  static const Color _danger = Color(0xFFEF4444);
  static const Color _dangerLight = Color(0xFFFEF2F2);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: const Interval(0.0, 0.5, curve: Curves.easeOut)),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: const Interval(0.1, 1.0, curve: Curves.easeOutCubic)),
    );

    Future.microtask(() {
      // ref.read(loginViewModelProvider.notifier).adminProfile(ref.read(loginViewModelProvider).adminId);
    });

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(loginViewModelProvider);
    final adminProfile = loginState.adminProfile;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: _textDark,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back',
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ── Top Bar ──
                // SliverToBoxAdapter(
                //   child: _buildTopBar(),
                // ),

                // ── Profile Hero ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: _buildProfileSection(adminProfile),
                  ),
                ),

                // ── Settings Sections ──
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // _sectionLabel('Preferences'),
                      // const SizedBox(height: 10),
                      // _buildToggleGroup(),
                      // const SizedBox(height: 24),

                      _sectionLabel('Account'),
                      const SizedBox(height: 10),
                      _buildMenuGroup(items: [
                        _MenuItem(Icons.person_outline_rounded, 'Edit Profile', 'Update your personal info', onTap: () async {
                          await Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage()));
                          if (!mounted) return;
                          final adminId = ref.read(loginViewModelProvider).adminId;
                          if (adminId > 0) {
                            await ref.read(loginViewModelProvider.notifier).adminProfile(adminId);
                          }
                        }),
                        _MenuItem(
                          Icons.lock_outline_rounded,
                          'Privacy & Security',
                          'View our privacy policy',
                          onTap: () => _openPrivacyPolicy(context),
                        ),
                        _MenuItem(
                          Icons.delete_sweep_outlined,
                          'Deleted Vehicles & Drivers',
                          'View removed vehicles and drivers',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const DeletedRecordsPage(),
                              ),
                            );
                          },
                        ),
                      ]),
                      const SizedBox(height: 24),

                      _sectionLabel('Support'),
                      const SizedBox(height: 10),
                      _buildMenuGroup(items: [
                        _MenuItem(
                          Icons.help_outline_rounded,
                          'Help Center',
                          'Browse FAQs & guides',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const HelpCenterPage(),
                            ),
                          ),
                        ),
                        _MenuItem(
                          Icons.mail_outline_rounded,
                          'Contact Us',
                          'Get in touch with our team',
                          onTap: () => _showContactSheet(context),
                        ),
                        _MenuItem(Icons.info_outline_rounded, 'About', 'Version 1.0.0', onTap: () => _showAboutDialog(context)),
                      ]),
                      const SizedBox(height: 24),

                      _buildLogoutButton(),
                      const SizedBox(height: 110),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }



  // ─────────────────────────── PROFILE ────────────────────────────

  Widget _buildProfileSection(AsyncValue<List<LoginInfo>> adminProfile) {
    return adminProfile.when(
      loading: () => _profileShimmer(),
      error: (err, _) => NetworkErrorView(
        error: err,
        scrollable: false,
        onRetry: () async => ref
            .read(loginViewModelProvider.notifier)
            .adminProfile(ref.read(loginViewModelProvider).adminId),
      ),
      data: (list) => _profileCard(list.isNotEmpty ? list.first : null),
    );
  }

  Widget _profileShimmer() {
    return Container(
      height: 110,
      decoration: BoxDecoration(
        color: AppColors.brandHeader,
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)),
    );
  }

  Widget _profileCard(LoginInfo? profile) {
    final imageUrl = profile?.imageUrl?.isNotEmpty == true ? profile!.imageUrl : null;
    final initial = (profile?.name?.isNotEmpty == true) ? profile!.name![0].toUpperCase() : 'U';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.brandHeader,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.2),
              border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
            ),
            child: ClipOval(
              child: imageUrl != null
                  ? Image.network(imageUrl, fit: BoxFit.cover)
                  : Center(
                      child: Text(initial,
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
            ),
          ),
          const SizedBox(width: 16),

          // Name + email
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile?.name ?? 'No Name',
                  style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -0.3),
                ),
                const SizedBox(height: 4),
                Text(
                  profile?.mobile ?? '-',
                  style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.82)),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Admin', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────── SECTION LABEL ──────────────────────

  Widget _sectionLabel(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 2),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: _textMid,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  // ─────────────────────────── TOGGLE GROUP ───────────────────────

  Widget _buildToggleGroup() {
    return _card(
      child: Column(
        children: [
          _toggleTile(
            icon: Icons.notifications_outlined,
            label: 'Push Notifications',
            subtitle: 'Receive booking alerts',
            value: notificationsEnabled,
            onChanged: (v) => setState(() => notificationsEnabled = v),
            isFirst: true,
          ),
          _divider(),
          _toggleTile(
            icon: Icons.location_on_outlined,
            label: 'Location Services',
            subtitle: 'Enable GPS tracking',
            value: locationEnabled,
            onChanged: (v) => setState(() => locationEnabled = v),
          ),
        ],
      ),
    );
  }

  Widget _toggleTile({
    required IconData icon,
    required String label,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool isFirst = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(top: isFirst ? 0 : 0),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: _iconBox(icon),
        title: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _textDark)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: _textMid)),
        trailing: Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeColor: _primary,
        ),
      ),
    );
  }

  // ─────────────────────────── MENU GROUP ─────────────────────────

  Widget _buildMenuGroup({required List<_MenuItem> items}) {
    return _card(
      child: Column(
        children: List.generate(items.length, (i) {
          final item = items[i];
          return Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: _iconBox(item.icon),
                title: Text(item.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _textDark)),
                subtitle: Text(item.subtitle, style: TextStyle(fontSize: 12, color: _textMid)),
                trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 20),
                onTap: item.onTap,
              ),
              if (i < items.length - 1) _divider(),
            ],
          );
        }),
      ),
    );
  }

  // ─────────────────────────── LOGOUT ─────────────────────────────

  Widget _buildLogoutButton() {
    return Container(
      decoration: BoxDecoration(
        color: _dangerLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _danger.withOpacity(0.15)),
      ),
      child: ListTile(
        onTap: () => _showLogoutDialog(context, ref),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _danger.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.logout_rounded, color: _danger, size: 20),
        ),
        title: const Text('Logout', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _danger)),
        subtitle: const Text('Sign out of your account', style: TextStyle(fontSize: 12, color: Color(0xFFB91C1C))),
        trailing: Icon(Icons.chevron_right_rounded, color: _danger.withOpacity(0.5)),
      ),
    );
  }

  // ─────────────────────────── HELPERS ────────────────────────────

  Widget _card({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandPrimary.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _iconBox(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _primaryLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: _primary, size: 20),
    );
  }

  Widget _divider() {
    return Divider(height: 1, thickness: 1, color: _surface, indent: 56, endIndent: 16);
  }

  // ─────────────────────────── PRIVACY POLICY ──────────────────────

  Future<void> _openPrivacyPolicy(BuildContext context) async {
    final uri = Uri.parse('https://vego.vengurlatech.com/login/privacy');
    final launched =
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open privacy policy'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ─────────────────────────── CONTACT US ─────────────────────────

  static const String _contactEmail = 'support@vengurlatech.com';
  static const String _contactNo = '+91 9422229951';

  void _showContactSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          20 + MediaQuery.of(context).padding.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Contact Us',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: _textDark,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "We'd love to hear from you. Reach out anytime.",
              style: TextStyle(fontSize: 13, color: _textMid, height: 1.4),
            ),
            const SizedBox(height: 20),
            _contactTile(
              icon: Icons.email_outlined,
              label: 'Email',
              value: _contactEmail,
              onTap: () => _launchContact(
                context,
                Uri(scheme: 'mailto', path: _contactEmail),
                'No email app found',
              ),
            ),
            const SizedBox(height: 12),
            _contactTile(
              icon: Icons.phone_outlined,
              label: 'Mobile',
              value: _contactNo,
              onTap: () => _launchContact(
                context,
                Uri(scheme: 'tel', path: _contactNo.replaceAll(' ', '')),
                'No phone app found',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _contactTile({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Material(
      color: _surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              _iconBox(icon),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _textMid)),
                    const SizedBox(height: 2),
                    Text(value,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _textDark)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: Colors.grey.shade400, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchContact(
    BuildContext context,
    Uri uri,
    String errorMessage, {
    bool external = false,
  }) async {
    Navigator.pop(context);
    final launched = await launchUrl(
      uri,
      mode: external
          ? LaunchMode.externalApplication
          : LaunchMode.platformDefault,
    );
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
    }
  }

  // ─────────────────────────── ABOUT DIALOG ───────────────────────

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: _primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.directions_car_rounded, color: Colors.white, size: 36),
              ),
              const SizedBox(height: 16),
              const Text('Travel Agency App', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _textDark)),
              const SizedBox(height: 6),
              Text('Version 1.0.0', style: TextStyle(fontSize: 13, color: _textMid)),
              const SizedBox(height: 6),
              Text('Build 100', style: TextStyle(fontSize: 12, color: _textMid)),
              const SizedBox(height: 20),
              Divider(color: _surface, thickness: 1.5),
              const SizedBox(height: 12),
              Text(
                '© 2025 Travel Agency. All rights reserved.\nBuilt with ❤️ using Flutter.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: _textMid, height: 1.6),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────── LOGOUT DIALOG ──────────────────────

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _dangerLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.logout_rounded, color: _danger, size: 30),
              ),
              const SizedBox(height: 16),
              const Text('Logout?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _textDark)),
              const SizedBox(height: 8),
              Text('Are you sure you want to sign out of your account?',
                  textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: _textMid, height: 1.5)),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _textMid,
                        side: BorderSide(color: Colors.grey.shade300),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _danger,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        final navigator = Navigator.of(context);
                        final tokenState = ref.read(tokenProvider);
                        // Unregister this device's push token before tokens are cleared.
                        await PushService.removeToken();
                        final response = await ref.read(authViewModelProvider.notifier).logout(
                          TokenResponse(refreshToken: tokenState.refreshToken ?? ''),
                        );
                        if (response) {
                          await ref.read(loginViewModelProvider.notifier).logout();
                          navigator.pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const LoginPage()),
                            (route) => false,
                          );
                        }
                      },
                      child: const Text('Logout', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────── DATA CLASS ─────────────────────────────

class _MenuItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  const _MenuItem(this.icon, this.title, this.subtitle, {this.onTap});
}
