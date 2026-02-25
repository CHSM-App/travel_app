import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_agency_app/Screens/add_customer.dart';
import 'package:travel_agency_app/Screens/add_driver.dart';
import 'package:travel_agency_app/Screens/add_vehicle.dart';
import 'package:travel_agency_app/Screens/customer_page.dart';
import 'package:travel_agency_app/Screens/dashbord.dart';
import 'package:travel_agency_app/Screens/setting.dart';
import 'package:travel_agency_app/Screens/trip_page.dart';
import 'package:travel_agency_app/Screens/vehicle_page.dart';
import 'package:travel_agency_app/presentation/providers/viewmodel_provider.dart';

class MainBottomNav extends ConsumerStatefulWidget {
  const MainBottomNav({super.key});

  @override
  ConsumerState<MainBottomNav> createState() => _MainBottomNavState();
}

class _MainBottomNavState extends ConsumerState<MainBottomNav>
    with TickerProviderStateMixin {
  int selectedIndex = 0;
  int vehicleTabIndex = 0;

  static const primaryColor = Color(0xFF3D5AFE);

  late AnimationController _pageAnimController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late List<AnimationController> _tabControllers;

  late final List<Widget> pages = [
    const TravelAdminDashboard(),
    const TripPage(),
    const CustomerListPage(),
    VehiclePage(
      onTabChanged: (index) {
        setState(() {
          vehicleTabIndex = index;
        });
      },
    ),
    const ModernSettingsPage(),
  ];

  final List<_NavItem> _navItems = const [
    _NavItem(label: "Home",      icon: Icons.home_outlined,           activeIcon: Icons.home_rounded),
    _NavItem(label: "Trips",     icon: Icons.card_travel_outlined,    activeIcon: Icons.card_travel_rounded),
    _NavItem(label: "Customers", icon: Icons.people_outline,          activeIcon: Icons.people_rounded),
    _NavItem(label: "Vehicles",  icon: Icons.directions_car_outlined, activeIcon: Icons.directions_car_rounded),
    _NavItem(label: "Settings",  icon: Icons.settings_outlined,       activeIcon: Icons.settings_rounded),
  ];

  @override
  void initState() {
    super.initState();

    // Transparent status bar — iPhone style
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    Future.microtask(() async {
      await ref.read(loginViewModelProvider.notifier).loadFromStorage();
      final adminId = ref.read(loginViewModelProvider).adminId;
      if (adminId > 0) {
        ref.read(loginViewModelProvider.notifier).adminProfile(adminId);
      }
    });

    _pageAnimController = AnimationController(
      duration: const Duration(milliseconds: 280),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
        parent: _pageAnimController, curve: Curves.easeInOut);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.05, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _pageAnimController, curve: Curves.easeOutCubic));
    _pageAnimController.forward();

    _tabControllers = List.generate(
      _navItems.length,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 180),
        lowerBound: 0.82,
        upperBound: 1.0,
        value: 1.0,
      ),
    );
  }

  @override
  void dispose() {
    _pageAnimController.dispose();
    for (final c in _tabControllers) c.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (selectedIndex == index) return;
    _tabControllers[index]
        .reverse()
        .then((_) => _tabControllers[index].forward());
    setState(() => selectedIndex = index);
    _pageAnimController.reset();
    _pageAnimController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(loginViewModelProvider);
    String userName = "Admin";
    String initials = "A";

    loginState.adminProfile.whenData((profileList) {
      if (profileList.isNotEmpty) {
        userName = profileList.first.name ?? "Admin";
        if (userName.isNotEmpty) initials = userName[0].toUpperCase();
      }
    });

    return Scaffold(
      // ✅ KEY: content goes under the floating nav bar
      extendBody: true,
      
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFFF0F4FF),

      // ── AppBar ─────────────────────────────────────────
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(68),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primaryColor.withOpacity(0.92),
                    const Color(0xFF536DFE).withOpacity(0.90),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Hero(
                        tag: 'profile_avatar',
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.45),
                                width: 1.5),
                          ),
                          child: Center(
                            child: Text(
                              initials,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Welcome Back 👋",
                              style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  letterSpacing: 0.3),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              userName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ],
                        ),
                      ),

                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),

      // ── Body ───────────────────────────────────────────
      // body: FadeTransition(
      //   opacity: _fadeAnimation,
      //   child: SlideTransition(
      //     position: _slideAnimation,
      //     child: pages[selectedIndex],
      //   ),
      // ),
      
body: Stack(
  children: [

    /// PAGE CONTENT
    FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: pages[selectedIndex],
      ),
    ),

  if (selectedIndex == 2 || selectedIndex == 3)
 // In the body Stack, replace the existing FAB Positioned block:

if (selectedIndex == 2 || selectedIndex == 3)
  Positioned(
    right: 20,
    bottom: 90, // sits above the floating nav bar
    child: FloatingActionButton.extended(
      onPressed: () {
        if (selectedIndex == 2) {
          // Customers tab
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddCustomerPage()),
          );
        } else if (selectedIndex == 3) {
          // Vehicles tab
          if (vehicleTabIndex == 0) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddVehiclePage()),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddDriverPage()),
            );
          }
        }
      },
      backgroundColor: const Color(0xFF3D5AFE),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      icon: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
      label: Text(
        selectedIndex == 2
            ? "Add Customer"
            : vehicleTabIndex == 0
                ? "Add Vehicle"
                : "Add Driver",
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
    ),
  ),

  ],
),
      // ── iPhone-style Floating Glass Nav Bar ────────────
      bottomNavigationBar: _buildGlassNavBar(),
      
    );
  }

  Widget _buildGlassNavBar() {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Padding(
      // Floats above screen bottom with margin on all sides
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: bottomPadding > 0 ? bottomPadding + 6 : 16,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          // ✨ THE FROSTED GLASS EFFECT — same as iPhone dock
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              // White with transparency — lets background show through
              color: Colors.white.withOpacity(0.70),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                // Thin white border — adds glass edge highlight
                color: Colors.white.withOpacity(0.65),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.13),
                  blurRadius: 32,
                  spreadRadius: 0,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.07),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(
                _navItems.length,
                (index) => _buildNavItem(index),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index) {
    final item = _navItems[index];
    final isSelected = selectedIndex == index;

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _tabControllers[index],
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: isSelected ? 14 : 10,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            // Active: solid indigo pill with glow shadow
            color: isSelected ? primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.38),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    )
                  ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? item.activeIcon : item.icon,
                color: isSelected ? Colors.white : Colors.grey.shade500,
                size: 22,
              ),
              // Label slides in for active tab
              AnimatedSize(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                child: isSelected
                    ? Row(
                        children: [
                          const SizedBox(width: 6),
                          Text(
                            item.label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Data Model ────────────────────────────────────────────
class _NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  const _NavItem(
      {required this.label, required this.icon, required this.activeIcon});
}