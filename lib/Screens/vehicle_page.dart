import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_agency_app/Screens/add_vehicle.dart';
import 'package:travel_agency_app/Screens/add_driver.dart';
import 'package:travel_agency_app/Screens/driver_history.dart';
import 'package:travel_agency_app/Screens/vehicle_details.dart';
import 'package:travel_agency_app/Screens/vehicle_report.dart';
import 'package:travel_agency_app/core/network/error_messages.dart';
import 'package:travel_agency_app/core/theme/app_colors.dart';
import 'package:travel_agency_app/core/widgets/skeleton.dart';
import 'package:travel_agency_app/domain/models/vehicles.dart';
import 'package:travel_agency_app/domain/models/drivers.dart';
import 'package:travel_agency_app/presentation/providers/viewmodel_provider.dart';

// ─── Design Tokens ─────────────────────────────────────────────────────────
class _C {
  static const bg = Color(0xFFF2F4F8);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceLight = Color(0xFFF0F3FA);
  static const accent = AppColors.brandPrimary;
  static const accentSoft = AppColors.brandSoft;
  static const accentDark = AppColors.brandPrimaryDark;
  static const text1 = Color(0xFF1A1D2E);
  static const text2 = Color(0xFF7B82A0);
  static const divider = Color(0xFFE4E8F0);
  static const green = Color(0xFF2DB976);
  static const greenSoft = Color(0xFFE8F8F1);
  static const red = Color(0xFFE53935);
  static const redSoft = Color(0xFFFFEBEE);
  static const orange = Color(0xFFE67E22);
  static const orangeSoft = Color(0xFFFEF0E6);
  static const diesel = Color(0xFF1D4ED8);
  static const dieselSoft = Color(0xFFDBEAFE);
  static const petrol = Color(0xFF7C3AED);
  static const petrolSoft = Color(0xFFEDE9FE);
}

class VehiclePage extends ConsumerStatefulWidget {
  final Function(int)? onTabChanged;

  const VehiclePage({this.onTabChanged, Key? key}) : super(key: key);

  @override
  ConsumerState<VehiclePage> createState() => _VehiclePageState();
}

class _VehiclePageState extends ConsumerState<VehiclePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchCtrl = TextEditingController();
  bool _searchVisible = false;
  final FocusNode _searchFocus = FocusNode();

  bool get _isVehicleTab => _tabController.index == 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      if (widget.onTabChanged != null) {
        widget.onTabChanged!(_tabController.index);
      }
      if (mounted) setState(() {});
    });

    Future.microtask(() {
      final agencyId = ref.read(loginViewModelProvider).agencyId ?? '';
      ref.read(tripBookingViewModelProvider.notifier).vehicleList(agencyId);
      ref.read(tripBookingViewModelProvider.notifier).driverList(agencyId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    final agencyId = ref.read(loginViewModelProvider).agencyId ?? '';

    await Future.wait([
      ref.read(tripBookingViewModelProvider.notifier).vehicleList(agencyId),
      ref.read(tripBookingViewModelProvider.notifier).driverList(agencyId),
    ]);
  }

  // Opens the right "add" form for the active tab (Vehicle vs Driver), then
  // refreshes the lists so the new item shows without a manual pull-to-refresh.
  Future<void> _openAdd() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            _isVehicleTab ? const AddVehiclePage() : const AddDriverPage(),
      ),
    );
    if (mounted) _refreshData();
  }

  String _initials(String? name) {
    if (name == null || name.trim().isEmpty) return '?';
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    return parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : parts[0][0].toUpperCase();
  }

  // ── Status Badge ──────────────────────────────────────────────────
  Widget _statusBadge(int? statusId) {
    final isAvailable = statusId == 1;
    final color = isAvailable ? _C.green : _C.orange;
    final bg = isAvailable ? _C.greenSoft : _C.orangeSoft;
    final label = isAvailable
        ? 'Available'
        : statusId == 2
        ? 'Engaged'
        : 'Unknown';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ── Fuel Badge ────────────────────────────────────────────────────
  Widget _fuelBadge(String? fuelType) {
    final fuel = (fuelType ?? '').toLowerCase();
    Color bg, fg;
    IconData icon;

    if (fuel.contains('ev') || fuel.contains('electric')) {
      bg = _C.greenSoft;
      fg = _C.green;
      icon = Icons.bolt_rounded;
    } else if (fuel.contains('petrol')) {
      bg = _C.petrolSoft;
      fg = _C.petrol;
      icon = Icons.local_gas_station_rounded;
    } else if (fuel.contains('cng')) {
      bg = _C.greenSoft;
      fg = _C.green;
      icon = Icons.local_gas_station_rounded;
    } else {
      bg = _C.dieselSoft;
      fg = _C.diesel;
      icon = Icons.opacity_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: fg),
          const SizedBox(width: 3),
          Text(
            fuelType ?? 'N/A',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  // ── Dot info item ─────────────────────────────────────────────────
  Widget _dot(IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: _C.text2),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: _C.text2,
          ),
        ),
      ],
    );
  }

  // ── Three-dot menu ────────────────────────────────────────────────
  Widget _menuBtn({
    required List<PopupMenuEntry<String>> items,
    required void Function(String) onSelected,
  }) {
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      icon: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: _C.surfaceLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _C.divider),
        ),
        child: const Icon(Icons.more_vert_rounded, color: _C.text2, size: 16),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 8,
      color: _C.surface,
      onSelected: onSelected,
      itemBuilder: (_) => items,
    );
  }

  PopupMenuItem<String> _menuItem(
    String val,
    IconData icon,
    String label,
    Color color,
    Color bg,
  ) {
    return PopupMenuItem(
      value: val,
      height: 44,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ── Vehicle Card (REDESIGNED + OVERFLOW FIXED) ───────────────────
  Widget _vehicleCard(Vehicles v, int i) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 200 + i * 40),
      curve: Curves.easeOutCubic,
      builder: (_, val, child) => Opacity(
        opacity: val,
        child: Transform.translate(
          offset: Offset(0, 14 * (1 - val)),
          child: child,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => VehicleManagePage(vehicle: v)),
          );
        },
        child: Container(
          // ✅ NO horizontal margin here — padding handled by ListView
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: _C.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _C.divider, width: 1),
            boxShadow: [
              BoxShadow(
                color: _C.accent.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Card body ───────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Row 1: Icon + Name + Plate + Menu
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Vehicle icon
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.brandPrimaryLight, _C.accent],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: _C.accent.withOpacity(0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.directions_car_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Name + plate
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                v.name ?? 'Unknown',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: _C.text1,
                                  letterSpacing: -0.2,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              if (v.number != null) ...[
                                const SizedBox(height: 3),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.credit_card_rounded,
                                      size: 11,
                                      color: _C.text2,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      v.number!,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: _C.text2,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),

                        // Status + menu
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _menuBtn(
                              items: [
                                _menuItem(
                                  'edit',
                                  Icons.edit_rounded,
                                  'Edit',
                                  _C.accent,
                                  _C.accentSoft,
                                ),
                                const PopupMenuDivider(height: 0),
                                _menuItem(
                                  'delete',
                                  Icons.delete_rounded,
                                  'Delete',
                                  _C.red,
                                  _C.redSoft,
                                ),
                              ],
                              onSelected: (val) async {
                                if (val == 'edit') {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AddVehiclePage(
                                        vehicle: v,
                                        isEdit: true,
                                      ),
                                    ),
                                  );
                                  if (!mounted) return;
                                  if (result == true) {
                                    ref
                                        .read(
                                          tripBookingViewModelProvider.notifier,
                                        )
                                        .vehicleList(
                                          ref
                                                  .read(loginViewModelProvider)
                                                  .agencyId ??
                                              '',
                                        );
                                  }
                                } else if (val == 'delete') {
                                  _deleteDialog(
                                    'Delete Vehicle',
                                    v.name ?? 'vehicle',
                                    Icons.directions_car_rounded,
                                    () async {
                                      Navigator.pop(context);
                                      final agencyId =
                                          ref
                                              .read(loginViewModelProvider)
                                              .agencyId ??
                                          '';
                                      final vehicleId = v.vehicleId;
                                      if (vehicleId == null || vehicleId <= 0) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text('Cannot delete yet'),
                                            backgroundColor: _C.red,
                                          ),
                                        );
                                        return;
                                      }
                                      final result = await ref
                                          .read(
                                            addVehicleViewModelProvider
                                                .notifier,
                                          )
                                          .deleteVehicle(vehicleId);
                                      if (!mounted) return;
                                      if (result['success'] == true) {
                                        ref
                                            .read(
                                              tripBookingViewModelProvider
                                                  .notifier,
                                            )
                                            .vehicleList(agencyId);
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              result['message']?.toString() ??
                                                  '${v.name} deleted successfully',
                                            ),
                                            backgroundColor: _C.green,
                                          ),
                                        );
                                      } else {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              result['message']?.toString() ??
                                                  ref
                                                      .read(
                                                        addVehicleViewModelProvider,
                                                      )
                                                      .error ??
                                                  'Cannot delete yet',
                                            ),
                                            backgroundColor: _C.red,
                                          ),
                                        );
                                      }
                                    },
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // ── Divider ─────────────────────────────────
                    Container(height: 1, color: _C.divider),

                    const SizedBox(height: 10),

                    // ── Row 2: Stats (Wrap so chips never overflow) ──
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Chips wrap if needed
                        Expanded(
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              _statChip(
                                Icons.event_seat_rounded,
                                '${v.capacity ?? "--"}',
                                'Seats',
                              ),
                              _statChip(
                                Icons.speed_rounded,
                                v.mileage != null ? '${v.mileage}' : '--',
                                'km/l',
                              ),
                              _fuelBadge(v.FuelType),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Status stays right-aligned
                        _statusBadge(v.StatusId),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Stat chip for vehicle card ─────────────────────────────────────
  Widget _statChip(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: _C.surfaceLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _C.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: _C.accent),
          const SizedBox(width: 4),
          Text(
            '$value $label',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: _C.text1,
            ),
          ),
        ],
      ),
    );
  }

  // ── Driver Card ───────────────────────────────────────────────────
  Widget _driverCard(Drivers d, int i) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 200 + i * 40),
      curve: Curves.easeOutCubic,
      builder: (_, val, child) => Opacity(
        opacity: val,
        child: Transform.translate(
          offset: Offset(0, 10 * (1 - val)),
          child: child,
        ),
      ),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => DriverHistoryPage(driver: d)),
          );
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: _C.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _C.divider, width: 1),
            boxShadow: [
              BoxShadow(
                color: _C.accent.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.brandPrimaryLight, _C.accent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: _C.accent.withOpacity(0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    _initials(d.name),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Name + phone
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      d.name ?? 'Unknown',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: _C.text1,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if ((d.phone != null && d.phone!.isNotEmpty) ||
                        (d.address != null && d.address!.isNotEmpty)) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          if (d.phone != null && d.phone!.isNotEmpty) ...[
                            const Icon(
                              Icons.phone_rounded,
                              size: 11,
                              color: _C.accent,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              d.phone!,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _C.text2,
                              ),
                            ),
                          ],
                          if (d.phone != null &&
                              d.phone!.isNotEmpty &&
                              d.address != null &&
                              d.address!.isNotEmpty)
                            const SizedBox(width: 10),
                          if (d.address != null && d.address!.isNotEmpty) ...[
                            const Icon(
                              Icons.location_on_rounded,
                              size: 11,
                              color: _C.text2,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                d.address!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: _C.text2,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Menu
              _menuBtn(
                items: [
                  _menuItem(
                    'edit',
                    Icons.edit_rounded,
                    'Edit',
                    _C.accent,
                    _C.accentSoft,
                  ),
                  const PopupMenuDivider(height: 0),
                  _menuItem(
                    'delete',
                    Icons.delete_rounded,
                    'Delete',
                    _C.red,
                    _C.redSoft,
                  ),
                ],
                onSelected: (val) async {
                  if (val == 'edit') {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddDriverPage(driver: d, isEdit: true),
                      ),
                    );
                    if (!mounted) return;
                    if (result == true) {
                      ref
                          .read(tripBookingViewModelProvider.notifier)
                          .driverList(
                            ref.read(loginViewModelProvider).agencyId ?? '',
                          );
                    }
                  } else if (val == 'delete') {
                    _deleteDialog(
                      'Delete Driver',
                      d.name ?? 'driver',
                      Icons.person_rounded,
                      () async {
                        Navigator.pop(context);
                        final agencyId =
                            ref.read(loginViewModelProvider).agencyId ?? '';
                        final result = await ref
                            .read(addDriverViewModelProvider.notifier)
                            .deleteDriver(d.driverId ?? 0);
                        if (!mounted) return;
                        if (result['success'] == true) {
                          ref
                              .read(tripBookingViewModelProvider.notifier)
                              .driverList(agencyId);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                result['message']?.toString() ??
                                    '${d.name} deleted successfully',
                              ),
                              backgroundColor: _C.green,
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                result['message']?.toString() ??
                                    ref
                                        .read(addDriverViewModelProvider)
                                        .error ??
                                    'Cannot delete yet',
                              ),
                              backgroundColor: _C.red,
                            ),
                          );
                        }
                      },
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Stats strip ───────────────────────────────────────────────────
  Widget _statsStrip(List items, bool isVehicle) {
    if (isVehicle) {
      final vehicles = items.cast<Vehicles>();
      final available = vehicles.where((v) => v.StatusId == 1).length;
      final engaged = vehicles.where((v) => v.StatusId == 2).length;
      return _strip([
        _stripItem(
          '${items.length}',
          'Total',
          Icons.inventory_2_rounded,
          _C.accent,
          _C.accentSoft,
        ),
        _stripDivider(),
        _stripItem(
          '$available',
          'Available',
          Icons.check_circle_outline_rounded,
          _C.green,
          _C.greenSoft,
        ),
        _stripDivider(),
        _stripItem(
          '$engaged',
          'Engaged',
          Icons.directions_car_rounded,
          _C.orange,
          _C.orangeSoft,
        ),
      ]);
    } else {
      return _strip([
        _stripItem(
          '${items.length}',
          'Total',
          Icons.people_rounded,
          _C.accent,
          _C.accentSoft,
        ),
      ]);
    }
  }

  Widget _strip(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.divider),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: children,
      ),
    );
  }

  Widget _stripItem(
    String value,
    String label,
    IconData icon,
    Color color,
    Color bg,
  ) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 12, color: color),
          ),
          const SizedBox(width: 7),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: _C.text1,
                  height: 1,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  color: _C.text2,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stripDivider() => Container(width: 1, height: 28, color: _C.divider);

  // ── Delete Dialog ─────────────────────────────────────────────────
  void _deleteDialog(
    String title,
    String name,
    IconData icon,
    VoidCallback onConfirm,
  ) {
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
                  color: _C.redSoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: _C.red, size: 30),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: _C.text1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Delete "$name"?\nThis cannot be undone.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: _C.text2,
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
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: const BorderSide(color: _C.divider),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _C.text2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: onConfirm,
                      style: FilledButton.styleFrom(
                        backgroundColor: _C.red,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Delete',
                        style: TextStyle(fontWeight: FontWeight.w700),
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

  // ── Empty ─────────────────────────────────────────────────────────
  Widget _empty(IconData icon, String title, String sub) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: _C.accentSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: _C.accent),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _C.text1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              sub,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: _C.text2,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Loading ───────────────────────────────────────────────────────
  Widget _loading(String msg) => RefreshIndicator(
    onRefresh: _refreshData,
    color: _C.accent,
    child: ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 110),
      children: const [
        SkeletonListItem(),
        SkeletonListItem(),
        SkeletonListItem(),
        SkeletonListItem(),
        SkeletonListItem(),
      ],
    ),
  );

  // ── Error ─────────────────────────────────────────────────────────
  Widget _error(Object e) => Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(
              color: _C.redSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.cloud_off_rounded, color: _C.red, size: 28),
          ),
          const SizedBox(height: 14),
          const Text(
            'Failed to load',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _C.text1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            friendlyErrorMessage(e),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: _C.text2),
          ),
        ],
      ),
    ),
  );

  // ── Header ────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      color: _C.surface,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: _C.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _C.divider),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.brandPrimaryLight, _C.accent],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: _C.accent.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      indicatorPadding: const EdgeInsets.all(3),
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelColor: Colors.white,
                      unselectedLabelColor: _C.text2,
                      labelStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      dividerColor: Colors.transparent,
                      onTap: (_) {
                        _searchCtrl.clear();
                        setState(() => _searchVisible = false);
                      },
                      tabs: const [
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.directions_car_rounded, size: 15),
                              SizedBox(width: 6),
                              Text('Vehicles'),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.person_rounded, size: 15),
                              SizedBox(width: 6),
                              Text('Drivers'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                // Report button — only on the Vehicles tab, since the report
                // is a per-vehicle revenue/expense breakdown. Promoted to a
                // gradient pill so it visibly stands out in the header strip.
                if (_isVehicleTab) ...[
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const VehicleReportPage(),
                      ),
                    ),
                    child: Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF8A33), Color(0xFFE67E22)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE67E22).withOpacity(0.45),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.insights_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Report',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],

                GestureDetector(
                  onTap: () {
                    setState(() {
                      _searchVisible = !_searchVisible;
                      if (!_searchVisible) _searchCtrl.clear();
                      if (_searchVisible) {
                        Future.delayed(
                          const Duration(milliseconds: 100),
                          () => _searchFocus.requestFocus(),
                        );
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _searchVisible ? _C.accentSoft : _C.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _searchVisible
                            ? _C.accent.withOpacity(0.4)
                            : _C.divider,
                      ),
                    ),
                    child: Icon(
                      _searchVisible
                          ? Icons.close_rounded
                          : Icons.search_rounded,
                      color: _searchVisible ? _C.accent : _C.text2,
                      size: 19,
                    ),
                  ),
                ),
              ],
            ),
          ),

          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            crossFadeState: _searchVisible
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: TextField(
                controller: _searchCtrl,
                focusNode: _searchFocus,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _C.text1,
                ),
                decoration: InputDecoration(
                  hintText: _isVehicleTab
                      ? 'Search vehicles...'
                      : 'Search drivers...',
                  hintStyle: const TextStyle(color: _C.text2, fontSize: 13),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: _C.text2,
                    size: 18,
                  ),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? GestureDetector(
                          onTap: () => setState(() => _searchCtrl.clear()),
                          child: const Icon(
                            Icons.cancel_rounded,
                            color: _C.text2,
                            size: 16,
                          ),
                        )
                      : null,
                  filled: true,
                  fillColor: _C.surfaceLight,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _C.divider),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _C.accent, width: 1.5),
                  ),
                ),
              ),
            ),
            secondChild: const SizedBox(width: double.infinity, height: 0),
          ),

          const SizedBox(height: 12),
          Divider(height: 1, color: _C.divider),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    final vehicleState = ref
        .watch(tripBookingViewModelProvider)
        .fetchVehicleList;
    final driverState = ref.watch(tripBookingViewModelProvider).fetchDriverList;

    return Scaffold(
      backgroundColor: _C.bg,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
          children: [
            _buildHeader(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // ── VEHICLES ─────────────────────────────────────
                  vehicleState.when(
                    loading: () => _loading('Loading vehicles...'),
                    error: (e, _) => _error(e),
                    data: (vehicles) {
                      final q = _searchCtrl.text.toLowerCase();
                      final filtered = vehicles
                          .where(
                            (v) =>
                                (v.name?.toLowerCase().contains(q) ?? false) ||
                                (v.number?.toLowerCase().contains(q) ?? false),
                          )
                          .toList();

                      if (filtered.isEmpty) {
                        return _empty(
                          Icons.directions_car_rounded,
                          q.isNotEmpty ? 'No results' : 'No vehicles yet',
                          q.isNotEmpty
                              ? 'Try a different search term'
                              : 'Add your first vehicle below',
                        );
                      }

                      return Column(
                        children: [
                          // Stats strip uses filtered for accurate counts
                          _statsStrip(filtered, true),
                          Expanded(
                            child: RefreshIndicator(
                              onRefresh: _refreshData,
                              child: ListView.builder(
                                physics:
                                    const AlwaysScrollableScrollPhysics(), // 🔥 important
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  10,
                                  16,
                                  100,
                                ),
                                itemCount: filtered.length,
                                itemBuilder: (_, i) =>
                                    _vehicleCard(filtered[i], i),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  // ── DRIVERS ──────────────────────────────────────
                  driverState.when(
                    loading: () => _loading('Loading drivers...'),
                    error: (e, _) => _error(e),
                    data: (drivers) {
                      final q = _searchCtrl.text.toLowerCase();
                      final filtered = drivers
                          .where(
                            (d) =>
                                (d.name?.toLowerCase().contains(q) ?? false) ||
                                (d.phone?.toLowerCase().contains(q) ?? false),
                          )
                          .toList();

                      if (filtered.isEmpty) {
                        return _empty(
                          Icons.person_rounded,
                          q.isNotEmpty ? 'No results' : 'No drivers yet',
                          q.isNotEmpty
                              ? 'Try a different search term'
                              : 'Add your first driver below',
                        );
                      }
                      return Column(
                        children: [
                          _statsStrip(filtered, false),
                          Expanded(
                            child: RefreshIndicator(
                              onRefresh: _refreshData,
                              child: ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.only(
                                  top: 6,
                                  bottom: 100,
                                ),
                                itemCount: filtered.length,
                                itemBuilder: (_, i) =>
                                    _driverCard(filtered[i], i),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
            // Plain circular "+" FAB — adds a Vehicle or Driver depending on
            // the active tab. Lifted to clear the floating pill nav.
            Positioned(
              right: 20,
              bottom: 90,
              child: FloatingActionButton(
                heroTag: 'fleetAddFab',
                onPressed: _openAdd,
                backgroundColor: AppColors.brandPrimary,
                shape: const CircleBorder(),
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
