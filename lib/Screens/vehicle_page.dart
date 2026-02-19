import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_agency_app/Screens/add_vehicle.dart';
import 'package:travel_agency_app/Screens/add_driver.dart';
import 'package:travel_agency_app/domain/models/vehicles.dart';
import 'package:travel_agency_app/domain/models/drivers.dart';
import 'package:travel_agency_app/presentation/providers/viewmodel_provider.dart';

// ─── Design Tokens ────────────────────────────────────────────────────────────
class _C {
  static const bg = Color(0xFFF5F4F1);
  static const surface = Color(0xFFFFFFFF);
  static const slate900 = Color(0xFF1C1917);
  static const slate700 = Color(0xFF44403C);
  static const slate500 = Color(0xFF78716C);
  static const slate300 = Color(0xFFD6D3D1);
  static const slate100 = Color(0xFFF5F4F1);

  // Amber — vehicles
  static const amber = Color(0xFFE8A020);
  static const amberLight = Color(0xFFFFF3D6);
  static const amberDark = Color(0xFFC4810A);

  // Teal — drivers
  static const teal = Color(0xFF0F766E);
  static const tealLight = Color(0xFFCCFBF1);
  static const tealDark = Color(0xFF0D5D56);

  // Status colours
  static const green = Color(0xFF059669);
  static const greenLight = Color(0xFFD1FAE5);
  static const red = Color(0xFFDC2626);
  static const redLight = Color(0xFFFEE2E2);

  // Fuel tag colours
  static const diesel = Color(0xFF1D4ED8);
  static const dieselLight = Color(0xFFDBEAFE);
  static const petrol = Color(0xFF7C3AED);
  static const petrolLight = Color(0xFFEDE9FE);
  static const ev = Color(0xFF059669);
  static const evLight = Color(0xFFD1FAE5);
}

// ─────────────────────────────────────────────────────────────────────────────

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

  // ── Lifecycle ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));

    Future.microtask(() {
      ref.read(tripBookingViewModelProvider.notifier).vehicleList(ref.read(loginViewModelProvider).agencyId??"");
      ref.read(tripBookingViewModelProvider.notifier).driverList(ref.read(loginViewModelProvider).agencyId??"");
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  bool get _isVehicleTab => _tabController.index == 0;

  String _initials(String? name) {
    if (name == null || name.trim().isEmpty) return '?';
    final parts = name.trim().split(' ');
    return parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : name[0].toUpperCase();
  }

  // ── Fuel chip helper ──────────────────────────────────────────────────────
  Widget _fuelChip(String? fuelType) {
    Color bg, fg;
    IconData icon;
    final fuel = (fuelType ?? '').toLowerCase();

    if (fuel.contains('ev') || fuel.contains('electric')) {
      bg = _C.evLight;
      fg = _C.ev;
      icon = Icons.bolt_rounded;
    } else if (fuel.contains('petrol')) {
      bg = _C.petrolLight;
      fg = _C.petrol;
      icon = Icons.local_gas_station_rounded;
    } else {
      // Diesel (default)
      bg = _C.dieselLight;
      fg = _C.diesel;
      icon = Icons.opacity_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: fg.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            fuelType ?? 'N/A',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: fg,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  // ── Status chip ───────────────────────────────────────────────────────────
  // Widget _statusChip(String? status) {
  //   final isActive = (status ?? '').toLowerCase() == 'active';
  //   return Container(
  //     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  //     decoration: BoxDecoration(
  //       color: isActive ? _C.greenLight : _C.redLight,
  //       borderRadius: BorderRadius.circular(8),
  //       border: Border.all(
  //         color: (isActive ? _C.green : _C.red).withOpacity(0.25),
  //       ),
  //     ),
  //     child: Row(
  //       mainAxisSize: MainAxisSize.min,
  //       children: [
  //         Container(
  //           width: 6,
  //           height: 6,
  //           decoration: BoxDecoration(
  //             color: isActive ? _C.green : _C.red,
  //             shape: BoxShape.circle,
  //           ),
  //         ),
  //         const SizedBox(width: 5),
  //         Text(
  //           status ?? 'Unknown',
  //           style: TextStyle(
  //             fontSize: 11,
  //             fontWeight: FontWeight.w700,
  //             color: isActive ? _C.green : _C.red,
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }
Widget _statusChip(int? statusId) {
  late Color bg;
  late Color fg;
  late String label;

  switch (statusId) {
    case 1:
      // Engaged
      bg = _C.redLight;
      fg = _C.red;
      label = "Engaged";
      break;

    case 2:
      // Available
      bg = _C.greenLight;
      fg = _C.green;
      label = "Available";
      break;

    default:
      bg = _C.slate100;
      fg = _C.slate500;
      label = "Unknown";
  }

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: fg.withOpacity(0.25)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: fg,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: fg,
          ),
        ),
      ],
    ),
  );
}




  // ── Stat box ──────────────────────────────────────────────────────────────
  Widget _statBox(IconData icon, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: color,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: _C.slate500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Vehicle Card ──────────────────────────────────────────────────────────
  Widget _vehicleCard(Vehicles vehicle, int index) {
    const double iconSize = 42;
    const double spacing = 12;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 250 + index * 40),
      curve: Curves.easeOutCubic,
      builder: (ctx, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(0, 15 * (1 - v)),
          child: child,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _C.slate300.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: _C.slate900.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ───── ROW 1 ─────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: iconSize,
                  height: iconSize,
                  decoration: BoxDecoration(
                    color: _C.amberLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.directions_car_rounded,
                    size: 22,
                    color: _C.amberDark,
                  ),
                ),
                const SizedBox(width: spacing),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              vehicle.name ?? 'Unknown',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: _C.slate900,
                              ),
                            ),
                          ),
                          // _statusChip(vehicle.StatusName),
                          _statusChip(vehicle.StatusId),


                          const SizedBox(width: 6),
                          _vehicleMenu(vehicle),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        vehicle.number ?? '—',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _C.slate500,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // ───── ROW 2 (ALIGNED UNDER NAME) ─────
            Padding(
              padding: const EdgeInsets.only(left: iconSize + spacing),
              child: Row(
                children: [
                  _miniStat(
                    Icons.people_rounded,
                    "${vehicle.capacity ?? '—'} Seats",
                  ),
                  const SizedBox(width: 14),
                  _miniStat(
                    Icons.speed_rounded,
                    vehicle.mileage != null ? "${vehicle.mileage} km/l" : "—",
                  ),
                  const SizedBox(width: 14),
                  _miniStat(
                    Icons.local_gas_station_rounded,
                    vehicle.FuelType ?? "N/A",
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: _C.slate500),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _C.slate700,
          ),
        ),
      ],
    );
  }

  // ── Vehicle Menu ──────────────────────────────────────────────────────────
  Widget _vehicleMenu(Vehicles vehicle) {
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      icon: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: _C.slate100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(
          Icons.more_vert_rounded,
          color: _C.slate500,
          size: 18,
        ),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 8,
      color: _C.surface,
      onSelected: (val) async {
        if (val == 'edit') {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddVehiclePage(vehicle: vehicle, isEdit: true),
            ),
          );
          if (result == true) {
            ref.read(tripBookingViewModelProvider.notifier).vehicleList(ref.read(loginViewModelProvider).agencyId??"");
          }
        } else if (val == 'delete') {
          _showDeleteDialog(
            title: 'Delete Vehicle',
            name: vehicle.name ?? 'this vehicle',
            icon: Icons.directions_car_rounded,
            onConfirm: () {
              Navigator.pop(context);
              // TODO: call delete API
              ref.read(tripBookingViewModelProvider.notifier).vehicleList(ref.read(loginViewModelProvider).agencyId??"");
            },
          );
        }
      },
      itemBuilder: (ctx) => [
        _menuItem('edit', Icons.edit_rounded, 'Edit', _C.amberLight, _C.amber),
        const PopupMenuDivider(height: 0),
        _menuItem(
          'delete',
          Icons.delete_rounded,
          'Delete',
          _C.redLight,
          _C.red,
          textColor: _C.red,
        ),
      ],
    );
  }

  // ── Driver Card ───────────────────────────────────────────────────────────
  Widget _driverCard(Drivers driver, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + index * 55),
      curve: Curves.easeOutCubic,
      builder: (ctx, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(0, 20 * (1 - v)),
          child: child,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _C.slate300.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: _C.slate900.withOpacity(0.05),
              blurRadius: 16,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            splashColor: _C.amberLight,
            highlightColor: _C.amberLight.withOpacity(0.4),
            onTap: () {},
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
              child: Row(
                children: [
                  // Initials avatar
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: _C.amberLight,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _C.amber.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _initials(driver.name),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: _C.amber,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          driver.name ?? 'Unknown',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _C.slate900,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 5),
                        if (driver.phone != null && driver.phone!.isNotEmpty)
                          Row(
                            children: [
                              const Icon(
                                Icons.phone_rounded,
                                size: 13,
                                color: _C.amber,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                driver.phone!,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _C.amber,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),

                  // Three-dot menu
                  _driverMenu(driver),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Driver Menu ───────────────────────────────────────────────────────────
  Widget _driverMenu(Drivers driver) {
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      icon: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: _C.slate100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(
          Icons.more_vert_rounded,
          color: _C.slate500,
          size: 18,
        ),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 8,
      color: _C.surface,
      onSelected: (val) async {
        if (val == 'edit') {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddDriverPage(driver: driver, isEdit: true),
            ),
          );
          if (result == true) {
            ref.read(tripBookingViewModelProvider.notifier).driverList(ref.read(loginViewModelProvider).agencyId??"");
          }
        } else if (val == 'delete') {
          _showDeleteDialog(
            title: 'Delete Driver',
            name: driver.name ?? 'this driver',
            icon: Icons.person_rounded,
            onConfirm: () {
              Navigator.pop(context);
              // TODO: call delete API
ref.read(tripBookingViewModelProvider.notifier).driverList(ref.read(loginViewModelProvider).agencyId??"");
            },
          );
        }
      },
      itemBuilder: (ctx) => [
        _menuItem('edit', Icons.edit_rounded, 'Edit', _C.amberDark, _C.amber),
        const PopupMenuDivider(height: 0),
        _menuItem(
          'delete',
          Icons.delete_rounded,
          'Delete',
          _C.redLight,
          _C.red,
          textColor: _C.red,
        ),
      ],
    );
  }

  // ── Shared menu item ──────────────────────────────────────────────────────
  PopupMenuItem<String> _menuItem(
    String value,
    IconData icon,
    String label,
    Color iconBg,
    Color iconColor, {
    Color textColor = _C.slate700,
  }) {
    return PopupMenuItem(
      value: value,
      height: 46,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 15, color: iconColor),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  // ── Delete dialog ─────────────────────────────────────────────────────────
  void _showDeleteDialog({
    required String title,
    required String name,
    required IconData icon,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: _C.redLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: _C.red, size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _C.slate900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Are you sure you want to delete "$name"?\nThis cannot be undone.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: _C.slate500,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: const BorderSide(color: _C.slate300),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _C.slate700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: onConfirm,
                      style: FilledButton.styleFrom(
                        backgroundColor: _C.red,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Delete',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────────
  Widget _emptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color accentColor,
    required Color accentLight,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: accentLight,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 44, color: accentColor),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _C.slate900,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: _C.slate500,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Loading state ─────────────────────────────────────────────────────────
  Widget _loadingState(String label, Color color) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 44,
          height: 44,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            strokeCap: StrokeCap.round,
            color: color,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          label,
          style: const TextStyle(
            color: _C.slate500,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );

  // ── Error state ───────────────────────────────────────────────────────────
  Widget _errorState(Object e) => Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: _C.redLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.wifi_off_rounded, size: 40, color: _C.red),
          ),
          const SizedBox(height: 20),
          const Text(
            'Something went wrong',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _C.slate900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            e.toString(),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: _C.slate500),
          ),
        ],
      ),
    ),
  );

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    final tabColor = _isVehicleTab ? _C.amber : _C.amber;

    return Container(
      color: _C.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tabs + Search icon in same row
          // Tabs + Search icon in same row
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Row(
              children: [
                // Tabs Expanded
                Expanded(
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: _C.slate100,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _C.slate300),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: _isVehicleTab ? _C.amber : _C.amber,
                        borderRadius: BorderRadius.circular(11),
                        boxShadow: [
                          BoxShadow(
                            color: (_isVehicleTab ? _C.amber : _C.amber)
                                .withOpacity(0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      indicatorPadding: const EdgeInsets.all(3),
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelColor: Colors.white,
                      unselectedLabelColor: _C.slate500,
                      labelStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      dividerColor: Colors.transparent,
                      onTap: (_) => setState(() => _searchCtrl.clear()),
                      tabs: const [
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.directions_car_rounded, size: 16),
                              SizedBox(width: 7),
                              Text('Vehicles'),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.person_rounded, size: 16),
                              SizedBox(width: 7),
                              Text('Drivers'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Search Icon
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isSearchExpanded = !_isSearchExpanded;
                      if (!_isSearchExpanded) _searchCtrl.clear();
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    height: 46,
                    width: 46,
                    decoration: BoxDecoration(
                      color: _isSearchExpanded
                          ? (_isVehicleTab ? _C.amberLight : _C.amberLight)
                          : _C.slate100,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _isSearchExpanded
                            ? (_isVehicleTab ? _C.amber : _C.amber).withOpacity(
                                0.4,
                              )
                            : _C.slate300,
                      ),
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        _isSearchExpanded
                            ? Icons.close_rounded
                            : Icons.search_rounded,
                        key: ValueKey(_isSearchExpanded),
                        color: _isSearchExpanded
                            ? (_isVehicleTab ? _C.amberDark : _C.amberDark)
                            : _C.slate500,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Expandable search bar
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            firstCurve: Curves.easeInOutCubic,
            secondCurve: Curves.easeInOutCubic,
            crossFadeState: _isSearchExpanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
              child: TextField(
                controller: _searchCtrl,
                autofocus: true,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: _C.slate900,
                ),
                decoration: InputDecoration(
                  hintText: _isVehicleTab
                      ? 'Search by name or plate...'
                      : 'Search by name or phone...',
                  hintStyle: const TextStyle(
                    color: _C.slate500,
                    fontWeight: FontWeight.w400,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: _C.slate500,
                    size: 20,
                  ),
                  filled: true,
                  fillColor: _C.slate100,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: _C.slate300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: _C.amber, width: 2),
                  ),
                ),
              ),
            ),
            secondChild: const SizedBox(width: double.infinity),
          ),

          const SizedBox(height: 16),
          Container(height: 1, color: _C.slate300.withOpacity(0.4)),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final vehicleState = ref
        .watch(tripBookingViewModelProvider)
        .fetchVehicleList;
    final driverState = ref.watch(tripBookingViewModelProvider).fetchDriverList;

    return Scaffold(
      backgroundColor: _C.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // ── VEHICLES TAB ─────────────────────────────────────────
                  vehicleState.when(
                    loading: () =>
                        _loadingState('Loading vehicles...', _C.amber),
                    error: (e, _) => _errorState(e),
                    data: (vehicles) {
                      final q = _searchCtrl.text.toLowerCase();
                      final filtered = vehicles.where((v) {
                        return (v.name?.toLowerCase().contains(q) ?? false) ||
                            (v.number?.toLowerCase().contains(q) ?? false);
                      }).toList();

                      if (filtered.isEmpty) {
                        return _emptyState(
                          icon: Icons.directions_car_rounded,
                          title: q.isNotEmpty
                              ? 'No results found'
                              : 'No vehicles yet',
                          subtitle: q.isNotEmpty
                              ? 'Try a different search term'
                              : 'Tap the button below to add your first vehicle',
                          accentColor: _C.amberDark,
                          accentLight: _C.amberLight,
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.only(top: 12, bottom: 110),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) => _vehicleCard(filtered[i], i),
                      );
                    },
                  ),

                  // ── DRIVERS TAB ──────────────────────────────────────────
                  driverState.when(
                    loading: () => _loadingState('Loading drivers...', _C.amber),
                    error: (e, _) => _errorState(e),
                    data: (drivers) {
                      final q = _searchCtrl.text.toLowerCase();
                      final filtered = drivers.where((d) {
                        return (d.name?.toLowerCase().contains(q) ?? false) ||
                            (d.phone?.toLowerCase().contains(q) ?? false);
                      }).toList();

                      if (filtered.isEmpty) {
                        return _emptyState(
                          icon: Icons.person_rounded,
                          title: q.isNotEmpty
                              ? 'No results found'
                              : 'No drivers yet',
                          subtitle: q.isNotEmpty
                              ? 'Try a different search term'
                              : 'Tap the button below to add your first driver',
                          accentColor: _C.amber,
                          accentLight: _C.amber,
                        );

                      }

                      return ListView.builder(
                        padding: const EdgeInsets.only(top: 12, bottom: 110),
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

      // ── FAB ─────────────────────────────────────────────────────────────
      floatingActionButton: AnimatedBuilder(
        animation: _tabController,
        builder: (context, _) {
          final isVehicle = _tabController.index == 0;
          return FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => isVehicle
                      ? const AddVehiclePage()
                      : const AddDriverPage(),
                ),
              );
            },
            backgroundColor: isVehicle ? _C.amber : _C.amber,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            icon: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
            label: Text(
              isVehicle ? 'Add Vehicle' : 'Add Driver',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
                letterSpacing: 0.2,
              ),
            ),
          );
        },
      ),
    );
  }
}
