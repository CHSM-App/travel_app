import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_agency_app/Screens/customer_page.dart';
import 'package:travel_agency_app/Screens/dashbord.dart';
import 'package:travel_agency_app/Screens/driver_page.dart';
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

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<Widget> pages = [
    TravelAdminDashboard(),
    TripPage(),
    // CustomerPage(),
    CustomerListPage(),
    VehiclePage(),   
    ModernSettingsPage(),
  ];

  @override
  void initState() {
    super.initState();

    /// Load profile once
    Future.microtask(() {
      final adminId = ref.read(loginViewModelProvider).adminId;
      if (adminId != null) {
        ref.read(loginViewModelProvider.notifier).adminProfile(adminId);
      }
    });

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.1, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (selectedIndex != index) {
      setState(() {
        selectedIndex = index;
      });

      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(loginViewModelProvider);

    /// default values
    String userName = "User";
    String initials = "U";

    /// get profile data
    loginState.adminProfile.whenData((profileList) {
      if (profileList.isNotEmpty) {
        userName = profileList.first.name ?? "User";

        if (userName.isNotEmpty) {
          initials = userName[0].toUpperCase();
        }
      }
    });

    return Scaffold(
      backgroundColor: Colors.grey[50],

      /// APP BAR
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withOpacity(0.8),
              ],
            ),
          ),
          child: AppBar(
            backgroundColor: const Color.fromARGB(255, 63, 81, 181),
            elevation: 0,
            toolbarHeight: 70,

            title: Row(
              children: [
                /// Profile Avatar
                Hero(
                  tag: 'profile_avatar',
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.white,
                      child: Text(
                        initials,
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                /// Name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Welcome',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            actions: [
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    color: Colors.white,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Notifications")),
                      );
                    },
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Text(
                        "3",
                        style: TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ),
                  )
                ],
              )
            ],
          ),
        ),
      ),

      /// BODY
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: pages[selectedIndex],
        ),
      ),

      // Modern Bottom Navigation Bar
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.indigo.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: _onItemTapped,
          height: 70,
          elevation: 0,
          backgroundColor: Colors.white,
          indicatorColor: Theme.of(context).primaryColor.withOpacity(0.15),
          animationDuration: const Duration(milliseconds: 400),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          
          destinations: [
            NavigationDestination(
              icon: _buildNavIcon(Icons.home_outlined, 0),
              selectedIcon: _buildSelectedNavIcon(Icons.home, 0),
              label: "Home",
            ),
            NavigationDestination(
              icon: _buildNavIcon(Icons.card_travel_outlined, 1),
              selectedIcon: _buildSelectedNavIcon(Icons.card_travel, 1),
              label: "Trips",
            ),
            NavigationDestination(
              icon: _buildNavIcon(Icons.people_outline, 2),
              selectedIcon: _buildSelectedNavIcon(Icons.people, 2),
              label: "Customers",
            ),
            NavigationDestination(
              icon: _buildNavIcon(Icons.directions_car_filled_rounded, 3),
              selectedIcon: _buildSelectedNavIcon(Icons.directions_car, 3),
              label: "Vehicles",
            ),
            NavigationDestination(
              icon: _buildNavIcon(Icons.settings_outlined, 4),
              selectedIcon: _buildSelectedNavIcon(Icons.settings, 4),
              label: "Setting",
            ),
          ],
        ),
      ),
    );
  }
}
