import 'package:flutter/material.dart';
import 'package:vego/Screens/add_driver.dart';
import 'package:vego/Screens/add_vehicle.dart';
import 'package:vego/Screens/login.dart';
import 'package:vego/core/theme/app_colors.dart';

/// Shown right after a successful sign-up. Lets the new admin add their
/// first vehicle and driver before landing on the login screen. Every step
/// is optional — the admin can skip straight to login and add these later
/// from the dashboard.
class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  static const primaryColor = AppColors.brandPrimary;
  static const darkBlue = Color(0xFF1A237E);

  bool _vehicleAdded = false;
  bool _driverAdded = false;

  Future<void> _addVehicle() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddVehiclePage()),
    );
    if (result == true && mounted) {
      setState(() => _vehicleAdded = true);
    }
  }

  Future<void> _addDriver() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddDriverPage()),
    );
    if (result == true && mounted) {
      setState(() => _driverAdded = true);
    }
  }

  void _goToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      "Set up your profile",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: darkBlue,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _goToLogin,
                    child: Text(
                      "Skip",
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                "Add your fleet details to get started. You can always do this later from the dashboard.",
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 28),
              Expanded(
                child: ListView(
                  children: [
                    _StepCard(
                      icon: Icons.directions_car_rounded,
                      title: "Add a Vehicle",
                      subtitle: "Register your first vehicle for trips",
                      done: _vehicleAdded,
                      onTap: _addVehicle,
                      color: primaryColor,
                    ),
                    const SizedBox(height: 16),
                    _StepCard(
                      icon: Icons.badge_rounded,
                      title: "Add a Driver",
                      subtitle: "Add a driver to assign to bookings",
                      done: _driverAdded,
                      onTap: _addDriver,
                      color: primaryColor,
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _goToLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    "Continue to Login",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool done;
  final VoidCallback onTap;
  final Color color;

  const _StepCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.done,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: done ? color.withOpacity(0.4) : Colors.grey.shade200,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A237E),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      done ? "Added — tap to add another" : subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: done ? color : Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                done ? Icons.check_circle_rounded : Icons.chevron_right_rounded,
                color: done ? color : Colors.grey.shade400,
                size: done ? 24 : 26,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
