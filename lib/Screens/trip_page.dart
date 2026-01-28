// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:travel_agency_app/Screens/trip_card.dart';
// import 'package:travel_agency_app/domain/models/booking_info.dart';
// import 'package:travel_agency_app/presentation/providers/viewmodel_provider.dart';

// class TripPage extends ConsumerStatefulWidget {
//   const TripPage({super.key});

//   @override
//   ConsumerState<TripPage> createState() => _TripPageState();
// }

// class _TripPageState extends ConsumerState<TripPage>
//     with SingleTickerProviderStateMixin {
//   late TabController _tabController;

//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 3, vsync: this);

//     Future.microtask(() {
//       final notifier = ref.read(TripPageViewModelProvider.notifier);
//       notifier.upcomingList();
//       notifier.historyList();
//       notifier.unpaidList();
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     final state = ref.watch(TripPageViewModelProvider);

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Trips'),
//         bottom: TabBar(
//           controller: _tabController,
//           tabs: const [
//             Tab(text: 'Upcoming'),
//             Tab(text: 'History'),
//             Tab(text: 'Unpaid'),
//           ],
//         ),
//       ),
//       body: TabBarView(
//         controller: _tabController,
//         children: [
//           _buildTripList(state.upcomingList),
//           _buildTripList(state.historyList),
//           _buildTripList(state.unpaidList),
//         ],
//       ),
//     );
//   }

//   Widget _buildTripList(AsyncValue<List<BookingInfo>> state) {
//     return state.when(
//       loading: () => const Center(child: CircularProgressIndicator()),
//       error: (e, _) => Center(child: Text('Error: $e')),
//       data: (trips) => trips.isEmpty
//           ? const Center(child: Text('No trips found'))
//           : ListView.builder(
//               itemCount: trips.length,
//               itemBuilder: (_, i) =>
//                   TripCard(bookinginfo: trips[i]),
//             ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_agency_app/Screens/trip_card.dart';
import 'package:travel_agency_app/domain/models/booking_info.dart';
import 'package:travel_agency_app/presentation/providers/viewmodel_provider.dart';

class TripPage extends ConsumerStatefulWidget {
  const TripPage({super.key});

  @override
  ConsumerState<TripPage> createState() => _TripPageState();
}

class _TripPageState extends ConsumerState<TripPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    Future.microtask(() {
      final notifier = ref.read(TripPageViewModelProvider.notifier);
      notifier.upcomingList();
      notifier.historyList();
      notifier.unpaidList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(TripPageViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trips'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'History'),
            Tab(text: 'Unpaid'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTripList(state.upcomingList),
          _buildTripList(state.historyList),
          _buildTripList(state.unpaidList),
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
            key: ValueKey(i), // 🔥 forces rebuild
            bookinginfo: trips[i],
          ),
        );
      },
    );
  }
}
