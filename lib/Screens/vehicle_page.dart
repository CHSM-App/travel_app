import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_agency_app/Screens/add_vehicle.dart';
import 'package:travel_agency_app/Screens/add_driver.dart';
import 'package:travel_agency_app/Screens/vehicle_history.dart';
import 'package:travel_agency_app/domain/models/vehicles.dart';
import 'package:travel_agency_app/domain/models/drivers.dart';
import 'package:travel_agency_app/presentation/providers/viewmodel_provider.dart';

// ─── Design Tokens ─────────────────────────────────────────────────────────
class _C {
  static const bg           = Color(0xFFF2F4F8);
  static const surface      = Color(0xFFFFFFFF);
  static const surfaceLight = Color(0xFFF0F3FA);
  static const accent       = Color(0xFF3D5AFE);
  static const accentSoft   = Color(0xFFEEF1FF);
  static const accentDark   = Color(0xFF2541D4);
  static const text1        = Color(0xFF1A1D2E);
  static const text2        = Color(0xFF7B82A0);
  static const divider      = Color(0xFFE4E8F0);
  static const green        = Color(0xFF2DB976);
  static const greenSoft    = Color(0xFFE8F8F1);
  static const red          = Color(0xFFE53935);
  static const redSoft      = Color(0xFFFFEBEE);
  static const orange       = Color(0xFFE67E22);
  static const orangeSoft   = Color(0xFFFEF0E6);
  static const diesel       = Color(0xFF1D4ED8);
  static const dieselSoft   = Color(0xFFDBEAFE);
  static const petrol       = Color(0xFF7C3AED);
  static const petrolSoft   = Color(0xFFEDE9FE);
}

class VehiclePage extends ConsumerStatefulWidget {
  const VehiclePage({super.key});

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
    _tabController.addListener(() => setState(() {}));

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

  String _initials(String? name) {
    if (name == null || name.trim().isEmpty) return '?';
    final p = name.trim().split(' ');
    return p.length >= 2
        ? '${p[0][0]}${p[1][0]}'.toUpperCase()
        : name[0].toUpperCase();
  }

  // ── Status Badge ──────────────────────────────────────────────────
  Widget _statusBadge(int? statusId) {
    final isAvailable = statusId == 2;
    final color  = isAvailable ? _C.green  : _C.orange;
    final bg     = isAvailable ? _C.greenSoft : _C.orangeSoft;
    final label  = isAvailable ? 'Available' : statusId == 1 ? 'Engaged' : 'Unknown';

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
            width: 5, height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w700, color: color)),
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
      bg = _C.greenSoft; fg = _C.green; icon = Icons.bolt_rounded;
    } else if (fuel.contains('petrol')) {
      bg = _C.petrolSoft; fg = _C.petrol; icon = Icons.local_gas_station_rounded;
    } else {
      bg = _C.dieselSoft; fg = _C.diesel; icon = Icons.opacity_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 10, color: fg),
        const SizedBox(width: 3),
        Text(fuelType ?? 'N/A',
            style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w700, color: fg)),
      ]),
    );
  }

  // ── Dot info item ─────────────────────────────────────────────────
  Widget _dot(IconData icon, String value) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 12, color: _C.text2),
      const SizedBox(width: 4),
      Text(value,
          style: const TextStyle(
              fontSize: 11, fontWeight: FontWeight.w500, color: _C.text2)),
    ]);
  }

  // ── Three-dot menu ────────────────────────────────────────────────
  Widget _menuBtn({
    required List<PopupMenuEntry<String>> items,
    required void Function(String) onSelected,
  }) {
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      icon: Container(
        width: 32, height: 32,
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
      String val, IconData icon, String label, Color color, Color bg) {
    return PopupMenuItem(
      value: val,
      height: 44,
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration:
              BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 10),
        Text(label,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: color)),
      ]),
    );
  }
// ── Vehicle Card ──────────────────────────────────────────────────
Widget _vehicleCard(Vehicles v, int i) {
  return TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: Duration(milliseconds: 200 + i * 40),
    curve: Curves.easeOutCubic,
    builder: (_, val, child) => Opacity(
      opacity: val,
      child: Transform.translate(offset: Offset(0, 10 * (1 - val)), child: child),
    ),
    child: InkWell(
  borderRadius: BorderRadius.circular(14),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VehicleTripHistory(vehicle: v, vehicleId: v.vehicleId ?? 0, vehicleName: v.name ?? 'Unknown Vehicle'),
      ),
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
            blurRadius: 8, offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: _C.accentSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.directions_car_rounded,
                color: _C.accent, size: 18),
          ),
          const SizedBox(width: 10),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Row 1: Name + plate + menu
                // Row 1: Name + plate inline + status + menu
Row(
  children: [
    Expanded(
      child: Row(
        children: [
          Flexible(
            child: Text(v.name ?? 'Unknown',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: _C.text1),
                overflow: TextOverflow.ellipsis),
          ),
          if (v.number != null) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _C.surfaceLight,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: _C.divider),
              ),
              child: Text(v.number!,
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _C.text1,
                      letterSpacing: 0.8)),
            ),
          ],
        ],
      ),
    ),
    const SizedBox(width: 4),
    _menuBtn(
      items: [
        _menuItem('edit', Icons.edit_rounded, 'Edit',
            _C.accent, _C.accentSoft),
        const PopupMenuDivider(height: 0),
        _menuItem('delete', Icons.delete_rounded, 'Delete',
            _C.red, _C.redSoft),
      ],
      onSelected: (val) async {
        if (val == 'edit') {
          final result = await Navigator.push(context,
              MaterialPageRoute(
                  builder: (_) => AddVehiclePage(
                      vehicle: v, isEdit: true)));
          if (result == true) {
            ref.read(tripBookingViewModelProvider.notifier)
                .vehicleList(ref.read(loginViewModelProvider).agencyId ?? '');
          }
        } else if (val == 'delete') {
          _deleteDialog('Delete Vehicle', v.name ?? 'vehicle',
              Icons.directions_car_rounded, () {
            Navigator.pop(context);
            ref.read(tripBookingViewModelProvider.notifier)
                .vehicleList(ref.read(loginViewModelProvider).agencyId ?? '');
          });
        }
      },
    ),
  ],
),

const SizedBox(height: 5),

// Row 2: Stats
Row(
  children: [
    _dot(Icons.people_rounded, '${v.capacity ?? "--"} Seats'),
    const SizedBox(width: 10),
    _dot(Icons.speed_rounded,
        v.mileage != null ? '${v.mileage} km/l' : '--'),
    const SizedBox(width: 8),
    _fuelBadge(v.FuelType),
    const Spacer(),
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

// ── Driver Card ───────────────────────────────────────────────────
Widget _driverCard(Drivers d, int i) {
  return TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: Duration(milliseconds: 200 + i * 40),
    curve: Curves.easeOutCubic,
    builder: (_, val, child) => Opacity(
      opacity: val,
      child: Transform.translate(offset: Offset(0, 10 * (1 - val)), child: child),
    ),
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
            blurRadius: 8, offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6378FF), _C.accent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: _C.accent.withOpacity(0.2),
                  blurRadius: 6, offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(_initials(d.name),
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.white)),
            ),
          ),
          const SizedBox(width: 10),

          // Name + phone in one row
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(d.name ?? 'Unknown',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: _C.text1),
                    overflow: TextOverflow.ellipsis),
                if (d.phone != null && d.phone!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Row(children: [
                    const Icon(Icons.phone_rounded, size: 11, color: _C.accent),
                    const SizedBox(width: 4),
                    Text(d.phone!,
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _C.text2)),
                  ]),
                ],
              ],
            ),
          ),

          // Menu
          _menuBtn(
            items: [
              _menuItem('edit', Icons.edit_rounded, 'Edit',
                  _C.accent, _C.accentSoft),
              const PopupMenuDivider(height: 0),
              _menuItem('delete', Icons.delete_rounded, 'Delete',
                  _C.red, _C.redSoft),
            ],
            onSelected: (val) async {
              if (val == 'edit') {
                final result = await Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) =>
                            AddDriverPage(driver: d, isEdit: true)));
                if (result == true) {
                  ref.read(tripBookingViewModelProvider.notifier).driverList(
                      ref.read(loginViewModelProvider).agencyId ?? '');
                }
              } else if (val == 'delete') {
                _deleteDialog('Delete Driver', d.name ?? 'driver',
                    Icons.person_rounded, () {
                  Navigator.pop(context);
                  ref.read(tripBookingViewModelProvider.notifier).driverList(
                      ref.read(loginViewModelProvider).agencyId ?? '');
                });
              }
            },
          ),
        ],
      ),
    ),
  );
}
 

  // ── Stats strip ───────────────────────────────────────────────────
  Widget _statsStrip(List items, bool isVehicle) {
    if (isVehicle) {
      final vehicles = items.cast<Vehicles>();
      final available =
          vehicles.where((v) => v.StatusId == 2).length;
      final engaged =
          vehicles.where((v) => v.StatusId == 1).length;
      return _strip([
        _stripItem('${items.length}', 'Total', Icons.inventory_2_rounded, _C.accent, _C.accentSoft),
        _stripDivider(),
        _stripItem('$available', 'Available', Icons.check_circle_outline_rounded, _C.green, _C.greenSoft),
        _stripDivider(),
        _stripItem('$engaged', 'Engaged', Icons.directions_car_rounded, _C.orange, _C.orangeSoft),
      ]);
    } else {
      return _strip([
        _stripItem('${items.length}', 'Total', Icons.people_rounded, _C.accent, _C.accentSoft),
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

  Widget _stripItem(String value, String label, IconData icon,
      Color color, Color bg) {
    return Expanded(
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration:
              BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 12, color: color),
        ),
        const SizedBox(width: 7),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: _C.text1,
                  height: 1)),
          Text(label,
              style: const TextStyle(
                  fontSize: 10, color: _C.text2, fontWeight: FontWeight.w500)),
        ]),
      ]),
    );
  }

  Widget _stripDivider() =>
      Container(width: 1, height: 28, color: _C.divider);

  // ── Delete Dialog ─────────────────────────────────────────────────
  void _deleteDialog(String title, String name, IconData icon,
      VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration:
                  const BoxDecoration(color: _C.redSoft, shape: BoxShape.circle),
              child: Icon(icon, color: _C.red, size: 30),
            ),
            const SizedBox(height: 16),
            Text(title,
                style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: _C.text1)),
            const SizedBox(height: 8),
            Text('Delete "$name"?\nThis cannot be undone.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 13, color: _C.text2, height: 1.5)),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    side: const BorderSide(color: _C.divider),
                  ),
                  child: const Text('Cancel',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, color: _C.text2)),
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
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Delete',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  // ── Empty ─────────────────────────────────────────────────────────
  Widget _empty(IconData icon, String title, String sub) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
                color: _C.accentSoft, shape: BoxShape.circle),
            child: Icon(icon, size: 36, color: _C.accent),
          ),
          const SizedBox(height: 20),
          Text(title,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _C.text1)),
          const SizedBox(height: 6),
          Text(sub,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13, color: _C.text2, height: 1.5)),
        ]),
      ),
    );
  }

  // ── Loading ───────────────────────────────────────────────────────
  Widget _loading(String msg) => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          SizedBox(
            width: 32, height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: _C.accent,
              backgroundColor: _C.accent.withOpacity(0.1),
            ),
          ),
          const SizedBox(height: 12),
          Text(msg,
              style: const TextStyle(
                  color: _C.text2, fontSize: 13, fontWeight: FontWeight.w500)),
        ]),
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
                      color: _C.redSoft, shape: BoxShape.circle),
                  child:
                      const Icon(Icons.cloud_off_rounded, color: _C.red, size: 28),
                ),
                const SizedBox(height: 14),
                const Text('Failed to load',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _C.text1)),
                const SizedBox(height: 6),
                Text(e.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: _C.text2)),
              ]),
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
            child: Row(children: [
              // Tab switcher
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
                        colors: [Color(0xFF6378FF), _C.accent],
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
                        fontSize: 13, fontWeight: FontWeight.w700),
                    unselectedLabelStyle: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500),
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

              // Search toggle
              GestureDetector(
                onTap: () {
                  setState(() {
                    _searchVisible = !_searchVisible;
                    if (!_searchVisible) _searchCtrl.clear();
                    if (_searchVisible) {
                      Future.delayed(const Duration(milliseconds: 100),
                          () => _searchFocus.requestFocus());
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 44, height: 44,
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
            ]),
          ),

          // Search bar
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
                    color: _C.text1),
                decoration: InputDecoration(
                  hintText: _isVehicleTab
                      ? 'Search vehicles...'
                      : 'Search drivers...',
                  hintStyle:
                      const TextStyle(color: _C.text2, fontSize: 13),
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: _C.text2, size: 18),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? GestureDetector(
                          onTap: () =>
                              setState(() => _searchCtrl.clear()),
                          child: const Icon(Icons.cancel_rounded,
                              color: _C.text2, size: 16),
                        )
                      : null,
                  filled: true,
                  fillColor: _C.surfaceLight,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _C.divider)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: _C.accent, width: 1.5)),
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
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    final vehicleState =
        ref.watch(tripBookingViewModelProvider).fetchVehicleList;
    final driverState =
        ref.watch(tripBookingViewModelProvider).fetchDriverList;

    return Scaffold(
      backgroundColor: _C.bg,
      body: SafeArea(
        child: Column(children: [
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
                    final filtered = vehicles.where((v) =>
                        (v.name?.toLowerCase().contains(q) ?? false) ||
                        (v.number?.toLowerCase().contains(q) ?? false)).toList();

                    if (filtered.isEmpty) {
                      return _empty(Icons.directions_car_rounded,
                          q.isNotEmpty ? 'No results' : 'No vehicles yet',
                          q.isNotEmpty
                              ? 'Try a different search term'
                              : 'Add your first vehicle below');
                    }
                    return Column(children: [
                      _statsStrip(filtered, true),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.only(top: 6, bottom: 100),
                          itemCount: filtered.length,
                          itemBuilder: (_, i) =>
                              _vehicleCard(filtered[i], i),
                        ),
                      ),
                    ]);
                  },
                ),

                // ── DRIVERS ──────────────────────────────────────
                driverState.when(
                  loading: () => _loading('Loading drivers...'),
                  error: (e, _) => _error(e),
                  data: (drivers) {
                    final q = _searchCtrl.text.toLowerCase();
                    final filtered = drivers.where((d) =>
                        (d.name?.toLowerCase().contains(q) ?? false) ||
                        (d.phone?.toLowerCase().contains(q) ?? false)).toList();

                    if (filtered.isEmpty) {
                      return _empty(Icons.person_rounded,
                          q.isNotEmpty ? 'No results' : 'No drivers yet',
                          q.isNotEmpty
                              ? 'Try a different search term'
                              : 'Add your first driver below');
                    }
                    return Column(children: [
                      _statsStrip(filtered, false),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.only(top: 6, bottom: 100),
                          itemCount: filtered.length,
                          itemBuilder: (_, i) =>
                              _driverCard(filtered[i], i),
                        ),
                      ),
                    ]);
                  },
                ),
              ],
            ),
          ),
        ]),
      ),

      // ── FAB ───────────────────────────────────────────────────────
      floatingActionButton: AnimatedBuilder(
        animation: _tabController,
        builder: (_, __) {
          final isVehicle = _tabController.index == 0;
          return FloatingActionButton.extended(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => isVehicle
                      ? const AddVehiclePage()
                      : const AddDriverPage(),
                ),
              );
              if (result == true && mounted) {
                final agencyId = ref.read(loginViewModelProvider).agencyId ?? '';
                if (isVehicle) {
                  ref.read(tripBookingViewModelProvider.notifier).vehicleList(agencyId);
                } else {
                  ref.read(tripBookingViewModelProvider.notifier).driverList(agencyId);
                }
              }
            },
            backgroundColor: _C.accent,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            icon: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
            label: Text(
              isVehicle ? 'Add Vehicle' : 'Add Driver',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14),
            ),
          );
        },
      ),
    );
  }
}
