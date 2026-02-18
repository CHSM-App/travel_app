import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_agency_app/Screens/trip_card.dart';
import 'package:travel_agency_app/domain/models/booking_info.dart';
import 'package:travel_agency_app/domain/models/customers.dart';
import 'package:travel_agency_app/presentation/providers/viewmodel_provider.dart';

class CustomerHist extends ConsumerStatefulWidget {
   final Customer customer;
   const CustomerHist({super.key, required this.customer});

  @override
  ConsumerState<CustomerHist> createState() => _CustomerHistState();
}

class _CustomerHistState extends ConsumerState<CustomerHist>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this); // ✅ match children count

    Future.microtask(() {
      final notifier = ref.read(customerViewModelProvider.notifier);
      notifier.fetchCustomershist(widget.customer.customerId??0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(customerViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trips'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "History"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTripList(state.Customerhist), // ⚠️ make sure property name matches
        ],
      ),
    );
  }

  Widget _buildTripList(AsyncValue<List<BookingInfo>> state) {
    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (trips) {
        if (trips.isEmpty) {
          return const Center(child: Text('No trips found'));
        }

        return ListView.builder(
          itemCount: trips.length,
          itemBuilder: (_, i) => TripCard(
            key: ValueKey(trips[i].customerId), // ✅ better than index
            bookinginfo: trips[i],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose(); // ✅ important
    super.dispose();
  }
}