import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_agency_app/Screens/add_driver.dart';

class DriversPage extends ConsumerStatefulWidget {
  const DriversPage({super.key});

  @override
  ConsumerState<DriversPage> createState() => _DriversPageState();
}

class _DriversPageState extends ConsumerState<DriversPage> {

  String selectedFilter = "All";

  final List<String> filters = ["All", "Available", "On Trip"];

  final List<Map<String, dynamic>> drivers = [
    {
      "name": "Ramesh Kumar",
      "phone": "+91 98765 12345",
      "license": "MH12 AB 4567",
      "status": "Available"
    },
    {
      "name": "Amit Sharma",
      "phone": "+91 98234 66821",
      "license": "DL09 XY 8934",
      "status": "On Trip"
    },
    {
      "name": "Suresh Patil",
      "phone": "+91 99876 23456",
      "license": "MH14 CD 9988",
      "status": "Available"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Drivers"),
        centerTitle: true,
      ),

    floatingActionButton: FloatingActionButton.extended(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AddDriverPage(),
      ),
    );
  },
  icon: const Icon(Icons.person_add_alt),
  label: const Text("Add Driver"),
),


      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            /// Search Field
            TextField(
              decoration: InputDecoration(
                hintText: "Search drivers",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 12),

            /// Capsule Filters
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: filters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final filter = filters[index];
                  final isSelected = selectedFilter == filter;

                  return GestureDetector(
                    onTap: () {
                      setState(() => selectedFilter = filter);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.red.shade400
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Text(
                        filter,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            /// Driver List
            Expanded(
              child: ListView.builder(
                itemCount: drivers.length,
                itemBuilder: (context, index) {
                  final driver = drivers[index];
                  final status = driver["status"];

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          /// Avatar
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: Colors.red.shade200,
                            child: const Icon(Icons.person,
                                color: Colors.white, size: 28),
                          ),

                          const SizedBox(width: 14),

                          /// Driver Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  driver["name"],
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                ),
                                const SizedBox(height: 4),
                                Text(driver["phone"]),
                                const SizedBox(height: 4),
                                Text(
                                  "License: ${driver["license"]}",
                                  style: const TextStyle(
                                      color: Colors.black54),
                                ),
                              ],
                            ),
                          ),

                          /// Status + Call Button
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: status == "Available"
                                      ? Colors.green.shade100
                                      : Colors.orange.shade100,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  status,
                                  style: TextStyle(
                                    color: status == "Available"
                                        ? Colors.green.shade800
                                        : Colors.orange.shade800,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 8),

                              IconButton(
                                onPressed: () {},
                                icon: const Icon(Icons.call),
                                color: Colors.green,
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
 