import 'package:flutter/material.dart';
import 'package:travel_agency_app/Screens/add_customer.dart';
import 'package:travel_agency_app/Screens/add_driver.dart';
import 'package:travel_agency_app/Screens/add_tripbooking.dart';
import 'package:travel_agency_app/Screens/add_vehicle.dart';

class TravelAdminDashboard extends StatelessWidget {
  const TravelAdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _welcomeCard(),
            const SizedBox(height: 20),
            _statsSection(),
            const SizedBox(height: 20),
            const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _quickActions(context),
            const SizedBox(height: 20),
            const Text('Recent Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _recentActivity(),
          ],
        ),
      ),
         );
  }

  Widget _welcomeCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.indigo,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Welcome Back,', style: TextStyle(color: Colors.white70)),
            SizedBox(height: 4),
            Text('Admin', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          ]),
          Icon(Icons.business_center, color: Colors.white, size: 40),
        ],
      ),
    );
  }

  Widget _statsSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _statCard('Total Bookings', '25,000', Icons.attach_money, Colors.green),
        _statCard('Revenue', 'RS12000', Icons.shopping_cart, Colors.orange),
        _statCard('Expenditure', '45000', Icons.people, Colors.blue),
      ],
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(title, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _quickActions(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _actionButton('New Booking', Icons.add_chart, context),
        _actionButton('New Vehicle', Icons.drive_eta_rounded, context),
        _actionButton('New Drivers', Icons.person, context),
        _actionButton('New Customers', Icons.people_alt, context),
       // _actionButton('Reports', Icons.bar_chart, context),
      //  _actionButton('Trips', Icons.card_travel, context),
      ],
    );
  }

  // Widget _actionButton(String label, IconData icon, BuildContext context) {
  //   return Card(
  //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  //     child: InkWell(
  //       onTap: () {},
  //       child: Column(
  //         mainAxisAlignment: MainAxisAlignment.center,
  //         children: [
  //           Icon(icon, color: Colors.indigo),
  //           const SizedBox(height: 8),
  //           Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
  //         ],
  //       ),
  //     ),
  //   );
  // }
Widget _actionButton(String title, IconData icon, BuildContext context) {
  return InkWell(
    onTap: () {
      switch (title) {
        case 'New Booking':
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => TripBookingForm()),
          );
          break;

        case 'Vehicle':
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddVehiclePage()),
          );
          break;

        case 'Drivers':
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddDriverPage()),
          );
          break;

        case 'Customers':
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddCustomerPage()),
          );
          break;

       // case 'Reports':
         // Navigator.push(
           // context,
      //      MaterialPageRoute(builder: (_) => TripBookingForm()),
      //    );
      //    break;

      //  case 'Trips':
      //    Navigator.push(
      //      context,
      //      MaterialPageRoute(builder: (_) => TripBookingForm()),
      //    );
       //   break; 
      }
    },
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 22,
          child: Icon(icon),
        ),
        const SizedBox(height: 8),
        Text(title, textAlign: TextAlign.center),
      ],
    ),
  );
}

  Widget _recentActivity() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: const [
          ListTile(
            leading: Icon(Icons.check_circle, color: Colors.green),
            title: Text('Invoice #1021 Paid'),
            subtitle: Text('2 hours ago'),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.shopping_bag, color: Colors.blue),
            title: Text('New Order Received'),
            subtitle: Text('Today'),
          ),
        ],
      ),
    );
  }
}
