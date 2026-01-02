import 'package:flutter/material.dart';

class TripsPage extends StatefulWidget {
  const TripsPage({Key? key}) : super(key: key);

  @override
  State<TripsPage> createState() => _TripsPageState();
}

class _TripsPageState extends State<TripsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 105, 108, 128),
        title: const Text("Trips"),
        centerTitle: true,
        elevation: 0,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(Icons.calendar_month),
          )
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFFFFFFF),
          tabs: const [
            Tab(text: "Upcoming Journeys"),
            Tab(text: "History"),
            Tab(text: "Unpaid Trips"),
          ],
        ),
      ),

      body: TabBarView(
        controller: _tabController,
        children: [
          buildUpcomingTrips(),
          buildHistoryTrips(),
          Center(child: Text("Unpaid Trips List")),
        ],
      ),
      
    );
  }

  // Upcoming Section
  Widget buildUpcomingTrips() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Upcoming Trips",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

          const SizedBox(height: 10),

          TripCard(
            title: "Manali Adventure",
            date: "May 10, 2024",
            travelers: "15 Travelers",
            guide: "Ramesh",
            image:
                "https://images.unsplash.com/photo-1520962922320-2038eebab146",
            status: "Upcoming",
            showDue: false,
          ),

          TripCard(
            title: "Goa Beach Tour",
            date: "May 18, 2024",
            travelers: "20 Travelers",
            guide: "—",
            image:
                "https://images.unsplash.com/photo-1507525428034-b723cf961d3e",
            status: "Upcoming",
            showDue: true,
          ),

          TripCard(
            title: "Dubai City Tour",
            date: "May 25, 2024",
            travelers: "12 Travelers",
            guide: "—",
            image:
                "https://images.unsplash.com/photo-1504274066651-8d31a536b11a",
            status: "Upcoming",
            showDue: true,
          ),
        ],
      ),
    );
  }

  // History Section
  Widget buildHistoryTrips() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: const [
        HistoryTripTile(
          title: "Shimla Group Tour",
          date: "Apr 1, 2024",
          travelers: "18 Travelers",
          guide: "Sunil",
          image:
              "https://images.unsplash.com/photo-1603262110263-fb0112e7cc33",
        ),
        HistoryTripTile(
          title: "Jaipur Heritage Tour",
          date: "Mar 20, 2024",
          travelers: "22 Travelers",
          guide: "Vikram",
          image:
              "https://images.unsplash.com/photo-1585987894396-6fa6e3b95f36",
        ),
        HistoryTripTile(
          title: "Kerala Backwaters",
          date: "Mar 10, 2024",
          travelers: "16 Travelers",
          guide: "Anil",
          image:
              "https://images.unsplash.com/photo-1544986581-efac024faf62",
        ),
      ],
    );
  }
}

class TripCard extends StatelessWidget {
  final String title;
  final String date;
  final String travelers;
  final String guide;
  final String image;
  final String status;
  final bool showDue;

  const TripCard({
    super.key,
    required this.title,
    required this.date,
    required this.travelers,
    required this.guide,
    required this.image,
    required this.status,
    required this.showDue,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(14)),
            child: Image.network(image, height: 120, width: double.infinity, fit: BoxFit.cover),
          ),

          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                        child: Text(title,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold))),
                    Chip(
                      label: Text(status),
                      backgroundColor: Colors.teal.shade600,
                      labelStyle: const TextStyle(color: Colors.white),
                    )
                  ],
                ),

                Row(
                  children: [
                    const Icon(Icons.calendar_month, size: 16),
                    const SizedBox(width: 6),
                    Text(date),
                  ],
                ),

                const SizedBox(height: 4),

                Row(
                  children: [
                    const Icon(Icons.group, size: 16),
                    const SizedBox(width: 6),
                    Text(travelers),
                  ],
                ),

                const SizedBox(height: 4),

                Row(
                  children: [
                    const Icon(Icons.person, size: 16),
                    const SizedBox(width: 6),
                    Text("Guide: $guide"),
                  ],
                ),

                if (showDue)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 64, 3, 105),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text("Due Trips"),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class HistoryTripTile extends StatelessWidget {
  final String title, date, travelers, guide, image;

  const HistoryTripTile({
    super.key,
    required this.title,
    required this.date,
    required this.travelers,
    required this.guide,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.only(bottom: 14),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(image, width: 55, height: 55, fit: BoxFit.cover),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("$date\n$travelers  •  Guide: $guide"),
        trailing: Chip(
          label: const Text("Completed"),
          backgroundColor: Colors.indigo.shade600,
          labelStyle: const TextStyle(color: Colors.white
  ),
        ),
        isThreeLine: true,
      ),
    );
  }       
} 