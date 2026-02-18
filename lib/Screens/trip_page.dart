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

class _TripPageState extends ConsumerState<TripPage> {
  String _selectedFilter = 'active';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      final notifier = ref.read(TripPageViewModelProvider.notifier);
      notifier.activeList();
      notifier.upcomingList();
      notifier.historyList();
      notifier.unpaidList();
      notifier.cancelledList();
    });
  }

  void _loadListForFilter(String filter) {
    final notifier = ref.read(TripPageViewModelProvider.notifier);
    switch (filter) {
      case 'active':
        notifier.activeList();
        break;
      case 'upcoming':
        notifier.upcomingList();
        break;
      case 'history':
        notifier.historyList();
        break;
      case 'unpaid':
        notifier.unpaidList();
        break;
      case 'cancelled':
        notifier.cancelledList();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(TripPageViewModelProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar and Dropdown Container
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Search Bar
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value.toLowerCase();
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Search trips...',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 14,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: Colors.grey.shade600,
                            size: 22,
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: Icon(
                                    Icons.clear_rounded,
                                    color: Colors.grey.shade600,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _searchQuery = '';
                                    });
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Dropdown Filter
                  Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade700,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.indigo.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedFilter,
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                        dropdownColor: Colors.indigo.shade700,
                        borderRadius: BorderRadius.circular(12),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        items: [
                          _buildDropdownItem(
                            'active',
                            'Active',
                            Icons.directions_car_rounded,
                          ),
                          _buildDropdownItem(
                            'upcoming',
                            'Upcoming',
                            Icons.schedule_rounded,
                          ),
                          _buildDropdownItem(
                            'history',
                            'History',
                            Icons.history_rounded,
                          ),
                          _buildDropdownItem(
                            'unpaid',
                            'Unpaid',
                            Icons.payment_rounded,
                          ),
                          _buildDropdownItem(
                            'cancelled',
                            'Cancelled',
                            Icons.cancel_rounded,
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedFilter = value;
                            });
                            _loadListForFilter(value);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _getCurrentList(state),
            ),
          ],
        ),
      ),
    );
  }

  DropdownMenuItem<String> _buildDropdownItem(
    String value,
    String label,
    IconData icon,
  ) {
    return DropdownMenuItem(
      value: value,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Colors.white),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  Widget _getCurrentList(dynamic state) {
    AsyncValue<List<BookingInfo>> currentList;

    switch (_selectedFilter) {
      case 'active':
        currentList = state.activeList;
        break;
      case 'upcoming':
        currentList = state.upcomingList;
        break;
      case 'history':
        currentList = state.historyList;
        break;
      case 'unpaid':
        currentList = state.unpaidList;
        break;
      case 'cancelled':
        currentList = state.cancelledList;
        break;
      default:
        currentList = state.activeList;
    }

    return _buildTripList(currentList, _selectedFilter);
  }

  Widget _buildTripList(AsyncValue<List<BookingInfo>> state, String type) {
    return state.when(
      loading: () => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Colors.indigo.shade700,
            ),
            const SizedBox(height: 16),
            Text(
              'Loading trips...',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ],
        ),
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
              'Error loading trips',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                e.toString(),
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                _loadListForFilter(type);
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
      data: (trips) {
        // Filter trips based on search query
        final filteredTrips = trips.where((trip) {
          if (_searchQuery.isEmpty) return true;
          
          final customerName = trip.customer_name?.toLowerCase() ?? '';
          final vehicleNumber = trip.vehicle_info?.toLowerCase() ?? '';
          final driverName = trip.driver_name?.toLowerCase() ?? '';
          final startLocation = trip.pickupLocation?.toLowerCase() ?? '';
          final endLocation = trip.dropLocation?.toLowerCase() ?? '';
          
          return customerName.contains(_searchQuery) ||
               vehicleNumber.contains(_searchQuery) ||
              driverName.contains(_searchQuery) ||
              startLocation.contains(_searchQuery) ||
              endLocation.contains(_searchQuery);
        }).toList();

        if (filteredTrips.isEmpty) {
          return _buildEmptyState(type);
        }

        return RefreshIndicator(
          onRefresh: () async {
            _loadListForFilter(type);
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredTrips.length,
            itemBuilder: (_, i) => TripCard(
              key: ValueKey(filteredTrips[i].tripId ?? i),
              bookinginfo: filteredTrips[i],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String type) {
    IconData icon;
    String title;
    String subtitle;

    switch (type) {
      case 'active':
        icon = Icons.car_rental_rounded;
        title = 'No Active Trips';
        subtitle = 'You don\'t have any active trips right now';
        break;
      case 'upcoming':
        icon = Icons.event_rounded;
        title = 'No Upcoming Trips';
        subtitle = 'No trips scheduled for the future';
        break;
      case 'history':
        icon = Icons.history_rounded;
        title = 'No Trip History';
        subtitle = 'Your completed trips will appear here';
        break;
      case 'unpaid':
        icon = Icons.payment_rounded;
        title = 'No Unpaid Trips';
        subtitle = 'All trips are paid. Great job!';
        break;
      case 'cancelled':
        icon = Icons.cancel_rounded;
        title = 'No Cancelled Trips';
        subtitle = 'You haven\'t cancelled any trips';
        break;
      default:
        icon = Icons.info_outline_rounded;
        title = 'No Trips Found';
        subtitle = 'No trips available';
    }

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
              icon,
              size: 64,
              color: Colors.indigo.shade300,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}