import 'package:flutter/material.dart';

class CustomersPage extends StatefulWidget {
  const CustomersPage({Key? key}) : super(key: key);

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      appBar: AppBar(
        title: const Text("Customers"),
        centerTitle: true,
        backgroundColor: Colors.blue,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.add),
          )
        ],
      ),

      body: Column(
        children: [
          const SizedBox(height: 10),

          // Search bar with filter icon + badge
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Search Customers",
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.filter_list),
                    ),

                    Positioned(
                      right: 0,
                      top: 2,
                      child: CircleAvatar(
                        radius: 10,
                        backgroundColor: Colors.blue,
                        child: const Text(
                          "12",
                          style: TextStyle(fontSize: 11, color: Colors.white),
                        ),
                      ),
                    )
                  ],
                )
              ],
            ),
          ),

          const SizedBox(height: 10),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: const [
                CustomerCard(
                  name: "Rohan Gupta",
                  phone: "+1 123-456-7890",
                  email: "rohan.gupta@email.com",
                  trips: "12 Trips",
                  location: "Delhi, India",
                  imageUrl:
                      "https://randomuser.me/api/portraits/men/31.jpg",
                  status: "Frequent",
                ),

                CustomerCard(
                  name: "Anjali Sharma",
                  phone: "+91 98765 43210",
                  email: "anjali.sharma@email.com",
                  trips: "2 Trips",
                  location: "Mumbai, India",
                  imageUrl:
                      "https://randomuser.me/api/portraits/women/65.jpg",
                  status: "New",
                ),

                CustomerCard(
                  name: "Arun Patel",
                  phone: "+44 7891 234567",
                  email: "arun.patel@email.com",
                  trips: "8 Trips",
                  location: "London, UK",
                  imageUrl:
                      "https://randomuser.me/api/portraits/men/76.jpg",
                  status: "Regular",
                ),

                CustomerCard(
                  name: "Priya Verma",
                  phone: "+61 410 123 987",
                  email: "priya.verma@email.com",
                  trips: "15 Trips",
                  location: "Sydney, Australia",
                  imageUrl:
                      "https://randomuser.me/api/portraits/women/21.jpg",
                  status: "Frequent",
                ),

                CustomerCard(
                  name: "Vikram Joshi",
                  phone: "+91 99876 54321",
                  email: "vikram.joshi@email.com",
                  trips: "5 Trips",
                  location: "Jaipur, India",
                  imageUrl:
                      "https://randomuser.me/api/portraits/men/5.jpg",
                  status: "Regular",
                ),

                CustomerCard(
                  name: "Simran Kaur",
                  phone: "+1 987-654-3210",
                  email: "simran.kaur@email.com",
                  trips: "1 Trip",
                  location: "Toronto, Canada",
                  imageUrl:
                      "https://randomuser.me/api/portraits/women/44.jpg",
                  status: "Inactive",
                ),
              ],
            ),
          ),
        ],
      ),
    
    );
  }
}

class CustomerCard extends StatelessWidget {
  final String name;
  final String phone;
  final String email;
  final String trips;
  final String location;
  final String imageUrl;
  final String status;

  const CustomerCard({
    super.key,
    required this.name,
    required this.phone,
    required this.email,
    required this.trips,
    required this.location,
    required this.imageUrl,
    required this.status,
  });

  Color getStatusColor() {
    switch (status) {
      case "Frequent":
        return Colors.teal.shade600;
      case "Regular":
        return Colors.blue.shade600;
      case "New":
        return Colors.orange.shade600;
      default:
        return Colors.grey.shade500;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundImage: NetworkImage(imageUrl),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                      Chip(
                        label: Text(status),
                        backgroundColor: getStatusColor(),
                        labelStyle: const TextStyle(color: Colors.white),
                      )
                    ],
                  ),

                  Row(
                    children: [
                      const Icon(Icons.phone, size: 16),
                      const SizedBox(width: 6),
                      Text(phone),
                    ],
                  ),

                  Row(
                    children: [
                      const Icon(Icons.email, size: 16),
                      const SizedBox(width: 6),
                      Text(email),
                    ],
                  ),

                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16),
                      const SizedBox(width: 6),
                      Text("$trips · $location"),
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
