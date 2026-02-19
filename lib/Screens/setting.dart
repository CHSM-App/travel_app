import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_agency_app/Screens/login.dart';
import 'package:travel_agency_app/Screens/profile.dart';
import 'package:travel_agency_app/domain/models/login_info.dart';
import 'package:travel_agency_app/presentation/providers/viewmodel_provider.dart';
class ModernSettingsPage extends ConsumerStatefulWidget {
 // final int adminId; // pass admin id here
  const ModernSettingsPage({Key? key}) : super(key: key);

  @override
  ConsumerState<ModernSettingsPage> createState() =>
      _ModernSettingsPageState();
}

class _ModernSettingsPageState extends ConsumerState<ModernSettingsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool notificationsEnabled = true;
  bool darkModeEnabled = false;
  bool locationEnabled = true;
  double fontSize = 16.0;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    // fetch admin profile
    Future.microtask(() {
      ref.read(loginViewModelProvider.notifier).adminProfile(ref.read(loginViewModelProvider).adminId);
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
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    final loginState = ref.watch(loginViewModelProvider);
    final adminProfile = loginState.adminProfile;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.indigo.shade50,
              Colors.indigo.shade100.withOpacity(0.3),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 40.0 : 20.0,
                      vertical: 20.0,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildProfileSection(context, adminProfile),
                        const SizedBox(height: 24),
                        _buildSectionTitle('Account'),
                        const SizedBox(height: 12),
                        _buildAccountOption(
                          icon: Icons.person_outline_rounded,
                          title: 'Edit Profile',
                          subtitle: 'Change your personal information',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProfilePage(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildAccountOption(
                          icon: Icons.lock_outline_rounded,
                          title: 'Privacy & Security',
                          subtitle: 'Control your privacy settings',
                        ),
                        const SizedBox(height: 12),
                        _buildAccountOption(
                          icon: Icons.language_rounded,
                          title: 'Language',
                          subtitle: 'English (US)',
                        ),
                        const SizedBox(height: 24),
                        _buildSectionTitle('Support'),
                        const SizedBox(height: 12),
                        _buildAccountOption(
                          icon: Icons.help_outline_rounded,
                          title: 'Help Center',
                          subtitle: 'Get help and support',
                        ),
                        const SizedBox(height: 12),
                        _buildAccountOption(
                          icon: Icons.info_outline_rounded,
                          title: 'About',
                          subtitle: 'Version 1.0.0',
                        ),
                        const SizedBox(height: 12),
                        _buildLogoutButton(),
                        const SizedBox(height: 40),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }Widget _buildProfileSection(
  BuildContext context, 
  AsyncValue<List<LoginInfo>> adminProfile
) {
  return adminProfile.when(
    loading: () => _buildProfilePlaceholder(),
    error: (err, st) => _buildProfileError(err),
    data: (profileList) {
      final profile = profileList.isNotEmpty ? profileList.first : null;
      return _buildProfileCard(profile);
    },
  );
}

Widget _buildProfilePlaceholder() {
  return Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [Colors.indigo.shade700, Colors.indigo.shade500],
      ),
      borderRadius: BorderRadius.circular(24),
    ),
    child: const SizedBox(
      height: 80,
      child: Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    ),
  );
}

Widget _buildProfileError(Object err) {
  return Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [Colors.indigo.shade700, Colors.indigo.shade500],
      ),
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Error loading profile',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Text(
          err.toString(),
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.indigo.shade700,
          ),
          onPressed: () {
            ref.read(loginViewModelProvider.notifier).adminProfile(ref.read(loginViewModelProvider).adminId);
          },
          child: const Text('Retry'),
        ),
      ],
    ),
  );
}

Widget _buildProfileCard(LoginInfo? profile) {
  return TweenAnimationBuilder<double>(
    tween: Tween(begin: 0.0, end: 1.0),
    duration: const Duration(milliseconds: 600),
    curve: Curves.easeOut,
    builder: (context, value, child) {
      return Transform.scale(
        scale: 0.9 + (value * 0.1),
        child: Opacity(opacity: value, child: child),
      );
    },
    child: Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade700, Colors.indigo.shade500],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.shade300.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildProfileAvatar(),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile?.name ?? 'No Name',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  profile?.email ?? 'No Email',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          _buildEditButton(context),
        ],
      ),
    ),
  );
}
Widget _buildProfileAvatar() {
  final loginState = ref.watch(loginViewModelProvider);
  final adminProfile = loginState.adminProfile;

  String firstLetter = 'U'; // Default fallback
  if (adminProfile is AsyncData && adminProfile.value!.isNotEmpty) {
    final name = adminProfile.value?.first.name;
    if (name != null && name.isNotEmpty) {
      firstLetter = name[0].toUpperCase();
    }
  }

  return Container(
    width: 70,
    height: 70,
    decoration: BoxDecoration(
      color: Colors.indigo.shade50,
      borderRadius: BorderRadius.circular(35), // circle
      border: Border.all(
        color: Colors.white.withOpacity(0.3),
        width: 3,
      ),
    ),
    child: Center(
      child: Text(
        firstLetter,
        style: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: Colors.indigo.shade600,
        ),
      ),
    ),
  );
}

Widget _buildEditButton(BuildContext context) {
  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProfilePage(),
        ),
      );
    },
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(
        Icons.edit_rounded,
        color: Colors.white,
        size: 20,
      ),
    ),
  );
}


  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.indigo.shade900,
          letterSpacing: -0.3,
        ),
      ),
    );
  }

  Widget _buildNotificationCard() {
    return _buildAnimatedCard(
      child: SwitchListTile(
        value: notificationsEnabled,
        onChanged: (value) {
          setState(() {
            notificationsEnabled = value;
          });
        },
        title: const Text(
          'Push Notifications',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
        subtitle: Text(
          'Receive push notifications',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
        ),
        secondary: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.indigo.shade50,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            Icons.notifications_outlined,
            color: Colors.indigo.shade600,
            size: 24,
          ),
        ),
        activeColor: Colors.indigo,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  Widget _buildDarkModeCard() {
    return _buildAnimatedCard(
      delay: 100,
      child: SwitchListTile(
        value: darkModeEnabled,
        onChanged: (value) {
          setState(() {
            darkModeEnabled = value;
          });
        },
        title: const Text(
          'Dark Mode',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
        subtitle: Text(
          'Enable dark theme',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
        ),
        secondary: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.indigo.shade50,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            Icons.dark_mode_outlined,
            color: Colors.indigo.shade600,
            size: 24,
          ),
        ),
        activeColor: Colors.indigo,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  Widget _buildLocationCard() {
    return _buildAnimatedCard(
      delay: 200,
      child: SwitchListTile(
        value: locationEnabled,
        onChanged: (value) {
          setState(() {
            locationEnabled = value;
          });
        },
        title: const Text(
          'Location Services',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
        subtitle: Text(
          'Allow location access',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
        ),
        secondary: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.indigo.shade50,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            Icons.location_on_outlined,
            color: Colors.indigo.shade600,
            size: 24,
          ),
        ),
        activeColor: Colors.indigo,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  Widget _buildFontSizeCard() {
    return _buildAnimatedCard(
      delay: 300,
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.text_fields_rounded,
                    color: Colors.indigo.shade600,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Font Size',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                    ),
                    Text(
                      '${fontSize.toInt()}px',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: Colors.indigo.shade400,
                inactiveTrackColor: Colors.indigo.shade100,
                thumbColor: Colors.indigo.shade600,
                overlayColor: Colors.indigo.shade100,
                trackHeight: 4,
              ),
              child: Slider(
                value: fontSize,
                min: 12.0,
                max: 24.0,
                divisions: 12,
                onChanged: (value) {
                  setState(() {
                    fontSize = value;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
Widget _buildAccountOption({
  required IconData icon,
  required String title,
  required String subtitle,
  VoidCallback? onTap,
}) {
  return _buildAnimatedCard(
    child: ListTile(
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.indigo.shade50,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          icon,
          color: Colors.indigo.shade600,
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey.shade600,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: Colors.grey.shade400,
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      onTap: onTap,
    ),
  );
}


  Widget _buildAnimatedCard({required Widget child, int delay = 0}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 500 + delay),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.indigo.shade100.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
Widget _buildLogoutButton() {
  return _buildAnimatedCard(
    child: InkWell(
      onTap: () {
        _showLogoutDialog(context); // 👈 Call dialog here
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.logout_rounded,
              color:  const Color.fromARGB(255, 209, 43, 40),
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'Logout',
              style: TextStyle(
                fontSize: 16,
                
                fontWeight: FontWeight.bold,
                color: const Color.fromARGB(255, 209, 43, 40),
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
void _showLogoutDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          "Confirm Logout",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "Are you sure you want to logout?",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Cancel
            },
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(context);

              // 🔹 If using SharedPreferences (optional)
              // final prefs = await SharedPreferences.getInstance();
              // await prefs.clear();

              // 🔹 Redirect to Login Page
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => const LoginPage(),
                ),
                (route) => false,
              );
            },
            child: const Text("Logout"),
          ),
        ],
      );
    },
  );
}

}