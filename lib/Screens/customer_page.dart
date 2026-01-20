import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_agency_app/domain/models/customers.dart';
import 'package:travel_agency_app/presentation/providers/viewmodel_provider.dart';

class CustomerPage extends ConsumerStatefulWidget {
  const CustomerPage({super.key});

  @override
  ConsumerState<CustomerPage> createState() => _CustomerPageState();
}

class _CustomerPageState extends ConsumerState<CustomerPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref
          .read(customerViewModelProvider.notifier)
          .fetchCustomerslist();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(customerViewModelProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Customers"),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.indigo, Colors.blue],
            ),
          ),
        ),
      ),
      body: state.CustomerList.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),

        error: (e, _) =>
            Center(child: Text("Error: $e")),

        data: (customers) => customers.isEmpty
            ? _emptyView()
            : RefreshIndicator(
                onRefresh: () => ref
                    .read(customerViewModelProvider.notifier)
                    .fetchCustomerslist(),
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: customers.length,
                  itemBuilder: (_, i) =>
                      _customerCard(customers[i]),
                ),
              ),
      ),
    );
  }

  Widget _customerCard(Customer customer) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.only(bottom: 12),
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
      ),
    );
  }

  Widget _emptyView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Icon(Icons.people_outline, size: 80, color: Colors.grey),
        SizedBox(height: 12),
        Text(
          "No customers found",
          style: TextStyle(fontSize: 16),
        ),
      ],
    );
  }
}
