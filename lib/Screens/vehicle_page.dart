import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_agency_app/Screens/add_vehicle.dart';
import 'package:travel_agency_app/Screens/add_driver.dart';
import 'package:travel_agency_app/domain/models/vehicles.dart';
import 'package:travel_agency_app/domain/models/drivers.dart';
import 'package:travel_agency_app/presentation/providers/viewmodel_provider.dart';

class VehiclePage extends ConsumerStatefulWidget {
  const VehiclePage({super.key});

  @override
  ConsumerState<VehiclePage> createState() => _VehicleDriverPageState();
}

class _VehicleDriverPageState extends ConsumerState<VehiclePage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchCtrl = TextEditingController();
  late TabController _tabController;
  bool _isSearchExpanded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    Future.microtask(() {
      ref.read(tripBookingViewModelProvider.notifier).vehicleList();
      ref.read(tripBookingViewModelProvider.notifier).driverList();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // MODERN VEHICLE CARD
  Widget _vehicleCard(Vehicles vehicle, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            // Handle vehicle tap
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Top Row with Icon and Menu
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon Container
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.indigo.shade400,
                            Colors.indigo.shade600,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.indigo.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.directions_car_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 18),

                    // Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            vehicle.name ?? "Unknown",
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A1A),
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.indigo.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              vehicle.number ?? "",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.indigo.shade700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Three Dots Menu at Top
                    PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        Icons.more_vert_rounded,
                        color: Colors.grey.shade600,
                        size: 22,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onSelected: (value) {
                        if (value == 'edit') {
                          // Handle edit
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AddVehiclePage(),
                            ),
                          );
                        } else if (value == 'delete') {
                          // Handle delete - show confirmation dialog
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              title: const Text('Delete Vehicle'),
                              content: Text(
                                'Are you sure you want to delete ${vehicle.name}?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    // Call delete API
                                    Navigator.pop(context);
                                  },
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.red,
                                  ),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(
                                Icons.edit_outlined,
                                size: 20,
                                color: Colors.indigo.shade600,
                              ),
                              const SizedBox(width: 12),
                              const Text('Edit'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline_rounded,
                                size: 20,
                                color: Colors.red.shade400,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Delete',
                                style: TextStyle(color: Colors.red.shade400),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===========================
  // MODERN DRIVER CARD
  // ===========================
  Widget _driverCard(Drivers driver, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            // Handle driver tap
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Top Row with Icon and Menu
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar Container
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.indigo.shade400,
                            Colors.indigo.shade600,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.indigo.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 18),

                    // Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            driver.name ?? "Unknown",
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A1A),
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.phone_rounded,
                                size: 14,
                                color: Colors.grey.shade500,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                driver.phone ?? "",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Three Dots Menu at Top
                    PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        Icons.more_vert_rounded,
                        color: Colors.grey.shade600,
                        size: 22,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onSelected: (value) {
                        if (value == 'edit') {
                          // Handle edit
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AddDriverPage(),
                            ),
                          );
                        } else if (value == 'delete') {
                          // Handle delete - show confirmation dialog
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              title: const Text('Delete Driver'),
                              content: Text(
                                'Are you sure you want to delete ${driver.name}?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    // Call delete API
                                    Navigator.pop(context);
                                  },
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.red,
                                  ),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(
                                Icons.edit_outlined,
                                size: 20,
                                color: Colors.indigo.shade600,
                              ),
                              const SizedBox(width: 12),
                              const Text('Edit'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline_rounded,
                                size: 20,
                                color: Colors.red.shade400,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Delete',
                                style: TextStyle(color: Colors.red.shade400),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===========================
  // BUILD
  // ===========================
  @override
  Widget build(BuildContext context) {
    final vehicleState = ref
        .watch(tripBookingViewModelProvider)
        .fetchVehicleList;
    final driverState = ref.watch(tripBookingViewModelProvider).fetchDriverList;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),

      body: SafeArea(
        child: Column(
          children: [
            // ===========================
            // MODERN HEADER WITH TABS
            // ===========================
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header Title & Search
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    child: Row(
                      children: [
                        // Title
                        const Expanded(
                          child: Text(
                            'Fleet Management',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A1A),
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),

                        // Search Icon Button
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.indigo.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              transitionBuilder: (child, animation) {
                                return RotationTransition(
                                  turns: animation,
                                  child: FadeTransition(
                                    opacity: animation,
                                    child: child,
                                  ),
                                );
                              },
                              child: Icon(
                                _isSearchExpanded ? Icons.close : Icons.search,
                                key: ValueKey<bool>(_isSearchExpanded),
                                color: Colors.indigo.shade700,
                              ),
                            ),
                            onPressed: () {
                              setState(() {
                                _isSearchExpanded = !_isSearchExpanded;
                                if (!_isSearchExpanded) {
                                  _searchCtrl.clear();
                                }
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Search Bar (Expandable)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeInOutCubic,
                    height: _isSearchExpanded ? 70 : 0,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 250),
                      opacity: _isSearchExpanded ? 1.0 : 0.0,
                      child: _isSearchExpanded
                          ? Padding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                              child: TextField(
                                controller: _searchCtrl,
                                autofocus: true,
                                onChanged: (_) => setState(() {}),
                                decoration: InputDecoration(
                                  hintText: _tabController.index == 0
                                      ? "Search vehicles..."
                                      : "Search drivers...",
                                  prefixIcon: Icon(
                                    Icons.search,
                                    color: Colors.indigo.shade400,
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 16,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade200,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color: Colors.indigo.shade300,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),

                  // Tab Bar
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.indigo.shade400,
                            Colors.indigo.shade600,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.indigo.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.grey.shade600,
                      labelStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      onTap: (index) {
                        setState(() {
                          _searchCtrl.clear();
                        });
                      },
                      tabs: const [
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.directions_car_rounded, size: 18),
                              SizedBox(width: 8),
                              Text("Vehicles"),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.person_rounded, size: 18),
                              SizedBox(width: 8),
                              Text("Drivers"),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),

            // ===========================
            // TAB CONTENT
            // ===========================
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // VEHICLES TAB
                  vehicleState.when(
                    loading: () => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 50,
                            height: 50,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.indigo.shade400,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Loading vehicles...',
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
                            size: 60,
                            color: Colors.red.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Oops! Something went wrong',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            e.toString(),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    data: (vehicles) {
                      final filtered = vehicles.where((v) {
                        final query = _searchCtrl.text.toLowerCase();
                        final name = v.name?.toLowerCase() ?? '';
                        final number = v.number?.toLowerCase() ?? '';
                        return name.contains(query) || number.contains(query);
                      }).toList();

                      if (filtered.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.directions_car_rounded,
                                  size: 60,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                _searchCtrl.text.isNotEmpty
                                    ? 'No vehicles found'
                                    : 'No vehicles yet',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _searchCtrl.text.isNotEmpty
                                    ? 'Try a different search term'
                                    : 'Add your first vehicle to get started',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.only(top: 16, bottom: 100),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) => _vehicleCard(filtered[i], i),
                      );
                    },
                  ),
                  // DRIVERS TAB
                  driverState.when(
                    loading: () => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 50,
                            height: 50,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.indigo.shade400,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Loading drivers...',
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
                            size: 60,
                            color: Colors.red.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Oops! Something went wrong',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            e.toString(),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    data: (drivers) {
                      final filtered = drivers.where((d) {
                        final query = _searchCtrl.text.toLowerCase();
                        final name = d.name?.toLowerCase() ?? '';
                        final phone = d.phone?.toLowerCase() ?? '';
                        return name.contains(query) || phone.contains(query);
                      }).toList();

                      if (filtered.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.person_rounded,
                                  size: 60,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                _searchCtrl.text.isNotEmpty
                                    ? 'No drivers found'
                                    : 'No drivers yet',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _searchCtrl.text.isNotEmpty
                                    ? 'Try a different search term'
                                    : 'Add your first driver to get started',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.only(top: 16, bottom: 100),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) => _driverCard(filtered[i], i),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      floatingActionButton: AnimatedBuilder(
        animation: _tabController,
        builder: (context, child) {
          return AnimatedScale(
            duration: const Duration(milliseconds: 300),
            scale: 1.0,
            curve: Curves.easeOutBack,
            child: FloatingActionButton.extended(
              onPressed: () {
                if (_tabController.index == 0) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddVehiclePage()),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddDriverPage()),
                  );
                }
              },
              backgroundColor: Colors.indigo.shade600,
              elevation: 4,
              highlightElevation: 8,
              icon: const Icon(
                Icons.add_rounded,
                size: 24,
                color: Colors.white,
              ),
              label: Text(
                _tabController.index == 0 ? "Add Vehicle" : "Add Driver",
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 0.3,
                  color: Colors.white,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
