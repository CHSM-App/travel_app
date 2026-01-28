

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:travel_agency_app/Screens/customer_page.dart';
import 'package:travel_agency_app/Screens/dashbord.dart';
import 'package:travel_agency_app/Screens/driver_page.dart';
import 'package:travel_agency_app/Screens/trip_page.dart';
import 'package:travel_agency_app/Screens/vehicle_page.dart';

class MainBottomNav extends StatefulWidget {
  const MainBottomNav({super.key});

  @override
  State<MainBottomNav> createState() => _MainBottomNavState();
}

class _MainBottomNavState extends State<MainBottomNav> {

  int selectedIndex = 0;

  final List<Widget> pages = [
    TravelAdminDashboard(),
    TripPage(),
    CustomerPage(),
    VehiclePage(),
    DriversPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[selectedIndex],

      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() => selectedIndex = index);
        },

        destinations: const [

          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: "Home",
            
          ),

          NavigationDestination(
            icon: Icon(Icons.card_travel_outlined),
            selectedIcon: Icon(Icons.card_travel),
            label: "Trips",
          ),

          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: "Customers",
          ),

          NavigationDestination(
            icon: Icon(Icons.directions_car_outlined),
            selectedIcon: Icon(Icons.directions_car),
            label: "Vehicles",
          ),

          NavigationDestination(
            icon: Icon(Icons.drive_eta_outlined),
            selectedIcon: Icon(Icons.drive_eta),
            label: "Drivers",
          ),

        ],
      ),
    );
  }
}
