import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_agency_app/Screens/add_customer.dart';
import 'package:travel_agency_app/Screens/customer_hist.dart';
import 'package:travel_agency_app/domain/models/customers.dart';
import 'package:travel_agency_app/presentation/providers/viewmodel_provider.dart';

class CustomerPage extends ConsumerStatefulWidget {
  const CustomerPage({super.key});

  @override
  ConsumerState<CustomerPage> createState() => _CustomerPageState();
}

class _CustomerPageState extends ConsumerState<CustomerPage> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(customerViewModelProvider.notifier).fetchCustomerslist();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(customerViewModelProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      
      // appBar: AppBar(
      //   elevation: 0,
      //   backgroundColor: Colors.indigo.shade700,
      //   foregroundColor: Colors.white,
      //   title: const Text(
      //     "Customers",
      //     style: TextStyle(
      //       fontWeight: FontWeight.w600,
      //       fontSize: 20,
      //     ),
      //   ),
      //   centerTitle: true,
      //   actions: [
      //     IconButton(
      //       icon: const Icon(Icons.refresh_rounded),
      //       onPressed: () {
      //         ref.read(customerViewModelProvider.notifier).fetchCustomerslist();
      //       },
      //     ),
      //   ],
      // ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.indigo.shade700,
        foregroundColor: Colors.white,
        elevation: 4,
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddCustomerPage(),
            ),
          );

          if (result != null && mounted) {
            ref.read(customerViewModelProvider.notifier).fetchCustomerslist();
          }
        },
        child: const Icon(Icons.person_add_rounded, size: 26),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            color:  Colors.grey.shade50,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
                decoration: InputDecoration(
                  hintText: "Search customers...",
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: Colors.indigo.shade700,
                    size: 22,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),

          // Customer List
          Expanded(
            child: state.CustomerList.when(
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 64,
                      color: Colors.red.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Error: $e",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              data: (customers) {
                // Filter customers based on search
                final filteredCustomers = customers.where((customer) {
                  final name = customer.name?.toLowerCase() ?? '';
                  final phone = customer.phone?.toLowerCase() ?? '';
                  final address = customer.address?.toLowerCase() ?? '';
                  return name.contains(_searchQuery) ||
                      phone.contains(_searchQuery) ||
                      address.contains(_searchQuery);
                }).toList();

                if (filteredCustomers.isEmpty) {
                  return _emptyView();
                }

                return RefreshIndicator(
                  onRefresh: () => ref
                      .read(customerViewModelProvider.notifier)
                      .fetchCustomerslist(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredCustomers.length,
                    itemBuilder: (_, i) => _customerCard(
                      filteredCustomers[i],
                      i,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _customerCard(Customer customer, int index) {
    // Generate color based on index for variety
    final colors = [
      Colors.indigo,
    ];
    final color = colors[index % colors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
     // margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          radius: 26,
          backgroundColor: Colors.indigo.shade100,
          child: Text(
            customer.name![0],
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.indigo,
            ),
          ),
        ),
        title: Text(
          customer.name!,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(customer.phone ?? ''),
            Text(customer.licenceNo ?? ''),
            Text(customer.licenceExpiry?.toString() ?? ''),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
         onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
       builder: (context) => CustomerHist(customer: customer),
      ),
    );
  },

      ),
    );
  }

  Widget _emptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.indigo.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.people_outline_rounded,
              size: 64,
              color: Colors.indigo.shade300,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _searchQuery.isEmpty
                ? "No customers found"
                : "No matching customers",
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty
                ? "Add your first customer to get started"
                : "Try a different search term",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  void _editCustomer(Customer customer) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddCustomerPage(
          isEdit: true,
          customer: customer,
        ),
      ),
    );

    if (result != null && mounted) {
      ref.read(customerViewModelProvider.notifier).fetchCustomerslist();
    }
  }

  void _deleteCustomer(Customer customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.warning_rounded,
              color: Colors.orange.shade700,
              size: 28,
            ),
            const SizedBox(width: 12),
            const Text(
              'Delete Customer',
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${customer.name}"? This action cannot be undone.',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              // TODO: Implement delete functionality in your ViewModel
              // await ref
              //     .read(customerViewModelProvider.notifier)
              //     .deleteCustomer(customer.customerId!);
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Customer deleted successfully'),
                  backgroundColor: Colors.green.shade600,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );

              ref.read(customerViewModelProvider.notifier).fetchCustomerslist();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}