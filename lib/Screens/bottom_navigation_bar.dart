
import 'package:flutter/material.dart';
import 'package:travel_agency_app/Screens/customer_page.dart';
import 'package:travel_agency_app/Screens/dashbord.dart';
import 'package:travel_agency_app/Screens/driver_page.dart';
import 'package:travel_agency_app/Screens/setting.dart';
import 'package:travel_agency_app/Screens/trip_page.dart';
import 'package:travel_agency_app/Screens/vehicle_page.dart';

class MainBottomNav extends StatefulWidget {
  const MainBottomNav({super.key});

  @override
  State<MainBottomNav> createState() => _MainBottomNavState();
}

class _MainBottomNavState extends State<MainBottomNav> with TickerProviderStateMixin {
  int selectedIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<Widget> pages = [
    TravelAdminDashboard(),
    TripPage(),
    CustomerPage(),
    VehiclePage(),
    ModernSettingsPage(),
  ];

  final List<String> pageTitles = [
    "Dashboard",
    "Trips",
    "Customers",
    "Vehicles",
    "Drivers",
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
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
    return Scaffold(
      backgroundColor: Colors.grey[50],
      
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).primaryColor.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: AppBar(
            backgroundColor: Colors.indigo,
            elevation: 0,
            toolbarHeight: 70,
            title: Row(
              children: [
                // Profile Avatar with animation
                Hero(
                  tag: 'profile_avatar',
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.white,
                      child: Text(
                        'JD', // Replace with user initials
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      // Or use an image:
                      // backgroundImage: NetworkImage('https://your-image-url.com'),
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Name and Title
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Welcome', // Replace with user name
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      
                       Text(
                        'John Doe', // Replace with user name
                        style: TextStyle(
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
              // Notification Icon with badge
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    color: Colors.white,
                    iconSize: 28,
                    onPressed: () {
                      // Handle notification tap
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Notifications'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                  // Notification badge
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: const Text(
                        '3', // Replace with actual notification count
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),

      // Animated page content
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
              icon: _buildNavIcon(Icons.directions_car_outlined, 3),
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

  // Build regular navigation icon
  Widget _buildNavIcon(IconData icon, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1.0, end: selectedIndex == index ? 1.0 : 1.0),
      duration: const Duration(milliseconds: 200),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Icon(
            icon,
            size: 26,
            color: Colors.grey[600],
          ),
        );
      },
    );
  }

  // Build selected navigation icon with animation
  Widget _buildSelectedNavIcon(IconData icon, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.8, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.elasticOut,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Icon(
            icon,
            size: 26,
            color: Theme.of(context).primaryColor,
          ),
        );
      },
    );
  }
}