import 'package:flutter/material.dart';

class VehiclesPage extends StatefulWidget {
  const VehiclesPage({Key? key}) : super(key: key);

  @override
  State<VehiclesPage> createState() => _VehiclesPageState();
}

class _VehiclesPageState extends State<VehiclesPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      appBar: AppBar(
        title: const Text("Vehicles"),
        centerTitle: true,
        backgroundColor: Colors.blue,
        elevation: 0,
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: Colors.blue,
        icon: const Icon(Icons.add),
        label: const Text("Add Vehicle"),
      ),

      body: Column(
        children: [
          const SizedBox(height: 10),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search Vehicle",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.all(6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: const [
                VehicleCard(
                  name: "Toyota Innova Crysta",
                  type: "SUV",
                  capacity: "7 Seater",
                  reg: "MH 12 AB 3456",
                  driver: "Ramesh",
                  image:
                    "https://images.unsplash.com/photo-1552519507-da3b142c6e3d",
                  status: "Active",
                ),

                VehicleCard(
                  name: "Tempo Traveller",
                  type: "Mini Bus",
                  capacity: "12 Seater",
                  reg: "MH 14 CD 7890",
                  driver: "Suresh",
                  image:
                    "https://images.unsplash.com/photo-1617788138017-80ad7e5c0400",
                  status: "Active",
                ),

                VehicleCard(
                  name: "Swift Dzire",
                  type: "Sedan",
                  capacity: "4 Seater",
                  reg: "MH 15 EF 9999",
                  driver: "Anil",
                  image:
                    "https://images.unsplash.com/photo-1590362891991-f776e747a588",
                  status: "In Maintenance",
                ),

                VehicleCard(
                  name: "Traveller Deluxe",
                  type: "Mini Bus",
                  capacity: "17 Seater",
                  reg: "MH 11 GH 2222",
                  driver: "—",
                  image:
                    "https://images.unsplash.com/photo-1502877338535-766e1452684a",
                  status: "Unavailable",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class VehicleCard extends StatelessWidget {
  final String name;
  final String type;
  final String capacity;
  final String reg;
  final String driver;
  final String image;
  final String status;

  const VehicleCard({
    super.key,
    required this.name,
    required this.type,
    required this.capacity,
    required this.reg,
    required this.driver,
    required this.image,
    required this.status,
  });

  Color getStatusColor() {
    switch (status) {
      case "Active":
        return Colors.green.shade600;
      case "In Maintenance":
        return Colors.orange.shade700;
      default:
        return Colors.red.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
            child: Image.network(
              image,
              width: 110,
              height: 95,
              fit: BoxFit.cover,
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                      Chip(
                        label: Text(status),
                        backgroundColor: getStatusColor(),
                        labelStyle: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),

                  Text("$type • $capacity"),

                  const SizedBox(height: 4),

                  Row(
                    children: [
                      const Icon(Icons.numbers, size: 16),
                      const SizedBox(width: 6),
                      Text(reg),
                    ],
                  ),

                  const SizedBox(height: 4),

                  Row(
                    children: [
                      const Icon(Icons.person, size: 16),
                      const SizedBox(width: 6),
                      Text("Driver: $driver"),
                    ],
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
