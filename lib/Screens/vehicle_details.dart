import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_agency_app/Screens/trip_card.dart';
import 'package:travel_agency_app/Screens/add_vehicle.dart';
import 'package:travel_agency_app/domain/models/services.dart';
import 'package:travel_agency_app/domain/models/vehicles.dart';
import 'package:travel_agency_app/presentation/providers/viewmodel_provider.dart';

// ── Premium Token System ───────────────────────────────────────────────────
abstract class _C {
  static const bg = Color(0xFFF0F2F8);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFF5F6FA);
  static const g1 = Color(0xFF1A1F3A);
  static const g2 = Color(0xFF2D3580);
  static const g3 = Color(0xFF3D4FC8);
  static const accent = Color(0xFF4F6EF7);
  static const indigo = Color(0xFF4F46E5);
  static const violet = Color(0xFF7C3AED);
  static const green = Color(0xFF059669);
  static const red = Color(0xFFDC2626);
  static const redSoft = Color(0xFFFEE2E2);
  static const orange = Color(0xFFEA580C);
  static const text1 = Color(0xFF0F1224);
  static const text2 = Color(0xFF6B7280);
  static const divider = Color(0xFFE5E7F0);
  static const gold = Color(0xFFF59E0B);
}

// ════════════════════════════════════════════════════════════════════════════
class VehicleManagePage extends ConsumerStatefulWidget {
  final Vehicles vehicle;
  const VehicleManagePage({super.key, required this.vehicle});
  @override
  ConsumerState<VehicleManagePage> createState() => _VehicleManagePageState();
}

class _VehicleManagePageState extends ConsumerState<VehicleManagePage>
    with TickerProviderStateMixin {
  late final TabController _tab;
  late int _currentStatus;

  // ── Animation Controllers ──────────────────────────────────────────────
  late final AnimationController _headerAnim;
  late final AnimationController _statsAnim;
  late final AnimationController _avatarAnim;
  late final AnimationController _fabAnim;
  late final AnimationController _pulseAnim;

  // ── Derived Animations ─────────────────────────────────────────────────
  late final Animation<double> _headerFade;
  late final Animation<Offset> _headerSlide;
  late final Animation<double> _statsFade;
  late final Animation<Offset> _statsSlide;
  late final Animation<double> _avatarScale;
  late final Animation<double> _avatarRotate;
  late final Animation<double> _fabScale;
  late final Animation<double> _pulseAnim1;

  int _month = DateTime.now().month - 1;
  int _year = DateTime.now().year;
  int _prevTabIndex = 0;

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  @override
  void initState() {
    super.initState();

    _currentStatus = widget.vehicle.StatusId ?? 1;

    _tab = TabController(length: 3, vsync: this)..addListener(_onTabChanged);

    // Header entrance
    _headerAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _headerFade = CurvedAnimation(
      parent: _headerAnim,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    );
    _headerSlide = Tween<Offset>(begin: const Offset(0, 0.18), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _headerAnim,
            curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
          ),
        );

    // Stats strip entrance (delayed)
    _statsAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) _statsAnim.forward();
    });

    _statsFade = CurvedAnimation(parent: _statsAnim, curve: Curves.easeOut);
    _statsSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _statsAnim, curve: Curves.easeOutCubic));

    // Avatar spring entrance
    _avatarAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) _avatarAnim.forward();
    });

    _avatarScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _avatarAnim,
        curve: const Interval(0.0, 0.75, curve: Curves.elasticOut),
      ),
    );
    _avatarRotate = Tween<double>(begin: -0.15, end: 0.0).animate(
      CurvedAnimation(
        parent: _avatarAnim,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    // FAB entrance
    _fabAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fabScale = CurvedAnimation(parent: _fabAnim, curve: Curves.elasticOut);

    // Pulse for status dot
    _pulseAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnim1 = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulseAnim, curve: Curves.easeInOut));
  }

  void _onTabChanged() {
    setState(() {});
    if (_tab.index == 2) {
      _fabAnim.forward();
    } else {
      _fabAnim.reverse();
    }
    _prevTabIndex = _tab.index;
  }

Future<void> _toggleVehicleStatus() async {
  try {
    int newStatus;

    if (_currentStatus == 3) {
      newStatus = 1; // Maintenance -> Available
    } else {
      newStatus = 3; // Available -> Maintenance
    }

    // await ref.read(addVehicleViewModelProvider.notifier)
    //     .updateVehicleStatus(
    //   widget.vehicle.vehicleId ?? 0,
    //   newStatus,
    // );

    setState(() {
      _currentStatus = newStatus;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus == 3
                ? "Vehicle moved to Maintenance"
                : "Vehicle is now Available",
          ),
          backgroundColor:
              newStatus == 3 ? Colors.orange : Colors.green,
        ),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to update status: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
  
  @override
  void dispose() {
    _tab.dispose();
    _headerAnim.dispose();
    _statsAnim.dispose();
    _avatarAnim.dispose();
    _fabAnim.dispose();
    _pulseAnim.dispose();
    super.dispose();
  }

  String _fmt(double v) {
    if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '₹${(v / 1000).toStringAsFixed(1)}K';
    return '₹${v.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      backgroundColor: _C.bg,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverToBoxAdapter(child: _buildHeader()),
          SliverPersistentHeader(pinned: true, delegate: _PremiumTabBar(_tab)),
        ],
        body: TabBarView(
          controller: _tab,
          physics: const BouncingScrollPhysics(),
          children: [
            _OverviewTab(vehicle: widget.vehicle, fmt: _fmt, ctx: context),
            _TripsTab(vehicle: widget.vehicle, fmt: _fmt),
            _MaintTab(
              vehicle: widget.vehicle,
              month: _month,
              year: _year,
              months: _months,
              fmt: _fmt,
              onMonth: (m) => setState(() => _month = m),
              onYear: (y) => setState(() => _year = y),
              // FIX: pass null for new service, pass existing service for edit
              onEditService: (service) => _showAddServiceSheet(context, service),
            ),
          ],
        ),
      ),
      floatingActionButton: _fab(),
    );
  }



  // ── PREMIUM HEADER ────────────────────────────────────────────────
Widget _buildHeader() {
  final top = MediaQuery.of(context).padding.top;
  final isEngaged = (_currentStatus) == 2;

  return Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [_C.g1, _C.g2, _C.g3],
        stops: [0.0, 0.5, 1.0],
      ),
    ),
    child: Stack(
      children: [
        _AnimatedDecoCircle(
          size: 180,
          color: Colors.white,
          opacity: 0.04,
          right: -30,
          top: -20,
          delay: const Duration(milliseconds: 0),
        ),
        _AnimatedDecoCircle(
          size: 80,
          color: _C.accent,
          opacity: 0.15,
          right: 60,
          top: 60,
          delay: const Duration(milliseconds: 100),
        ),
        _AnimatedDecoCircle(
          size: 140,
          color: _C.indigo,
          opacity: 0.12,
          left: -40,
          bottom: 10,
          delay: const Duration(milliseconds: 200),
        ),

        SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(18, top > 0 ? 2 : 10, 18, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                /// NAV ROW
                FadeTransition(
                  opacity: _headerFade,
                  child: Row(
                    children: [
                      _AnimatedGlassBtn(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onTap: () => Navigator.pop(context),
                        delay: const Duration(milliseconds: 100),
                      ),
                      const Spacer(),
                      _AnimatedGlassBtn(
                        icon: Icons.edit_rounded,
                        onTap: () async {
                          final r = await Navigator.push(
                            context,
                            _slidePageRoute(
                              AddVehiclePage(
                                vehicle: widget.vehicle,
                                isEdit: true,
                              ),
                            ),
                          );
                          if (r == true && mounted) setState(() {});
                        },
                        delay: const Duration(milliseconds: 200),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                /// IDENTITY ROW
                FadeTransition(
                  opacity: _headerFade,
                  child: SlideTransition(
                    position: _headerSlide,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedBuilder(
                          animation: _avatarAnim,
                          builder: (_, child) => Transform.rotate(
                            angle: _avatarRotate.value,
                            child: Transform.scale(
                              scale: _avatarScale.value,
                              child: child,
                            ),
                          ),
                          child: Container(
                            width: 62,
                            height: 62,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF6B83FF),
                                  Color(0xFF3D5AFE),
                                ],
                              ),
                            ),
                            child: const Icon(
                              Icons.directions_car_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),

                        const SizedBox(width: 14),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 2),
                              _StaggeredText(
                                text: widget.vehicle.name ?? 'Unknown Vehicle',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                                delay: const Duration(milliseconds: 300),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  if (widget.vehicle.number != null)
                                    _glassBadge(
                                      Icons.pin_outlined,
                                      widget.vehicle.number ?? '',
                                      isGold: true,
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 8),

                        AnimatedBuilder(
                          animation: _pulseAnim1,
                          builder: (_, __) => _StatusBadge(
                            isEngaged: isEngaged,
                            pulseValue: _pulseAnim1.value,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                /// STATS STRIP (UNCHANGED)
                FadeTransition(
                  opacity: _statsFade,
                  child: SlideTransition(
                    position: _statsSlide,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: IntrinsicHeight(
                        child: Row(
                          children: [
                            _hStat(
                              '${widget.vehicle.capacity ?? "--"}',
                              'Seats',
                              Icons.people_rounded,
                            ),
                            _hStatDivider(),
                            _hStat(
                              widget.vehicle.mileage != null
                                  ? '${widget.vehicle.mileage}'
                                  : '--',
                              'km / l',
                              Icons.speed_rounded,
                            ),
                            _hStatDivider(),
                            _hStat(
                              widget.vehicle.FuelType ?? '--',
                              'Fuel',
                              Icons.local_gas_station_rounded,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
  Widget _glassBadge(IconData icon, String label, {bool isGold = false}) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isGold
              ? _C.gold.withOpacity(0.20)
              : Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isGold
                ? _C.gold.withOpacity(0.45)
                : Colors.white.withOpacity(0.20),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 10,
              color: isGold ? _C.gold : Colors.white.withOpacity(0.8),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isGold ? _C.gold : Colors.white.withOpacity(0.95),
                letterSpacing: isGold ? 1.2 : 0.3,
              ),
            ),
          ],
        ),
      );

  Widget _hStat(String value, String label, IconData icon) => Expanded(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Colors.white.withOpacity(0.5)),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.3,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 1),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: Colors.white.withOpacity(0.5),
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
          ),
        ),
      ],
    ),
  );

  Widget _hStatDivider() =>
      Container(width: 1, height: 36, color: Colors.white.withOpacity(0.12));

  // ── FAB ───────────────────────────────────────────────────────────
  Widget? _fab() {
    return ScaleTransition(
      scale: _fabScale,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFF5B76FF), Color(0xFF3D5AFE)],
          ),
          boxShadow: [
            BoxShadow(
              color: _C.accent.withOpacity(0.40),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          // FIX: pass null to indicate a NEW service
          onPressed: () => _showAddServiceSheet(context, null),
          backgroundColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          icon: const Icon(Icons.add_rounded, color: Colors.white, size: 17),
          label: const Text(
            "Add Service",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Route _slidePageRoute(Widget page) => PageRouteBuilder(
    pageBuilder: (_, animation, __) => page,
    transitionsBuilder: (_, animation, __, child) {
      final offset = Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
      return SlideTransition(position: offset, child: child);
    },
    transitionDuration: const Duration(milliseconds: 400),
  );

  // ─────────────────────────────────────────────────────────────────────────
  // FIX: Accept nullable Services — null means ADD, non-null means EDIT
  // ─────────────────────────────────────────────────────────────────────────
  void _showAddServiceSheet(BuildContext context, Services? service) {
    // Determine mode BEFORE building the sheet
    final bool isEdit = service != null;

    final formKey = GlobalKey<FormState>();

    final serviceController =
        TextEditingController(text: isEdit ? (service.serviceName ?? '') : '');
    final costController = TextEditingController(
        text: isEdit ? (service.serviceCost?.toString() ?? '') : '');
    final noteController =
        TextEditingController(text: isEdit ? (service.description ?? '') : '');

    DateTime selectedDate =
        (isEdit && service.serviceDate != null) ? service.serviceDate! : DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                color: Colors.transparent,
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFF8F9FF), Colors.white],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Column(
                    children: [
                      /// ─── DRAG HANDLE ─────────────────────────────
                      const SizedBox(height: 10),
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),

                      const SizedBox(height: 16),

                      /// ─── HEADER ─────────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.build_rounded,
                              color: Color(0xFF3D5AFE),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              // FIX: correctly shows Edit or Add title
                              isEdit ? "Edit Service" : "Add Service",
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 10),

                      /// ─── FORM AREA ─────────────────────────────
                      Expanded(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.fromLTRB(
                            20,
                            10,
                            20,
                            MediaQuery.of(context).viewInsets.bottom + 20,
                          ),
                          child: Form(
                            key: formKey,
                            child: Column(
                              children: [
                                /// SERVICE NAME
                                _modernField(
                                  controller: serviceController,
                                  label: "Service Name",
                                  icon: Icons.miscellaneous_services_rounded,
                                  validator: (v) => v == null || v.isEmpty
                                      ? "Enter service name"
                                      : null,
                                ),

                                const SizedBox(height: 16),

                                /// COST
                                _modernField(
                                  controller: costController,
                                  label: "Service Cost",
                                  icon: Icons.currency_rupee_rounded,
                                  keyboard: TextInputType.number,
                                  prefix: "₹ ",
                                  validator: (v) => v == null || v.isEmpty
                                      ? "Enter cost"
                                      : null,
                                ),

                                const SizedBox(height: 16),

                                /// DATE PICKER
                                InkWell(
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: selectedDate,
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime.now(),
                                    );
                                    if (picked != null) {
                                      setSheetState(() => selectedDate = picked);
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 18,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Colors.grey.shade200,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.03),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.calendar_today_rounded,
                                          size: 18,
                                          color: Color(0xFF3D5AFE),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          "${selectedDate.day}-${selectedDate.month}-${selectedDate.year}",
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const Spacer(),
                                        const Icon(
                                          Icons.arrow_forward_ios,
                                          size: 14,
                                          color: Colors.grey,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 16),

                                /// NOTES
                                _modernField(
                                  controller: noteController,
                                  label: "Notes (Optional)",
                                  icon: Icons.notes_rounded,
                                  maxLines: 3,
                                ),

                                const SizedBox(height: 30),
                              ],
                            ),
                          ),
                        ),
                      ),

                      /// ─── STICKY SAVE BUTTON ─────────────────────
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        child: SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3D5AFE),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 6,
                            ),
                            onPressed: () async {
                              if (formKey.currentState!.validate()) {
                                // FIX: Build a proper Services object instead of a raw Map
                                final Services serviceData = Services(
                                  vehicleId: widget.vehicle.vehicleId,
                                  serviceName: serviceController.text.trim(),
                                  serviceCost: double.parse(costController.text.trim()),
                                  serviceDate: selectedDate,
                                  description: noteController.text.trim(),
                                  agencyId: ref.read(loginViewModelProvider).agencyId,
                                  // carry over the existing id when editing
                                  serviceId: isEdit ? service.serviceId : null,
                                );

                                try {
                                  if (isEdit) {
                                    // 🔹 UPDATE SERVICE — use the existing service's id
                                    await ref
                                        .read(addVehicleViewModelProvider.notifier)
                                        .updateService(
                                          service.serviceId ?? 0,
                                          serviceData,
                                        );
                                  } else {
                                    // 🔹 ADD SERVICE
                                    await ref
                                        .read(addVehicleViewModelProvider.notifier)
                                        .addService(serviceData);
                                  }

                                  // Refresh the service list after save/update
                                  await ref
                                      .read(addVehicleViewModelProvider.notifier)
                                      .getServiceRecords(
                                        ref.read(loginViewModelProvider).agencyId ?? '',
                                        widget.vehicle.vehicleId ?? 0,
                                      );

                                  if (mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          isEdit
                                              ? "Service updated successfully"
                                              : "Service added successfully",
                                        ),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          isEdit
                                              ? "Failed to update service: $e"
                                              : "Failed to add service: $e",
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              }
                            },
                            child: Text(
                              isEdit ? "Update Service" : "Save Service",
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// ─── MODERN TEXT FIELD ─────────────────────────────
  Widget _modernField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboard = TextInputType.text,
    String? prefix,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      validator: validator,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixText: prefix,
        prefixIcon: Icon(icon, size: 18, color: const Color(0xFF3D5AFE)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide(color: Color(0xFF3D5AFE), width: 1.4),
        ),
      ),
    );
  }
}

// ── Animated Deco Circle ───────────────────────────────────────────────────
class _AnimatedDecoCircle extends StatefulWidget {
  final double size;
  final Color color;
  final double opacity;
  final double? right, left, top, bottom;
  final Duration delay;

  const _AnimatedDecoCircle({
    required this.size,
    required this.color,
    required this.opacity,
    this.right,
    this.left,
    this.top,
    this.bottom,
    required this.delay,
  });

  @override
  State<_AnimatedDecoCircle> createState() => _AnimatedDecoCircleState();
}

class _AnimatedDecoCircleState extends State<_AnimatedDecoCircle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _scale = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);

    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: widget.right,
      left: widget.left,
      top: widget.top,
      bottom: widget.bottom,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => Transform.scale(
          scale: _scale.value,
          child: Opacity(
            opacity: _opacity.value,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withOpacity(widget.opacity),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Animated Glass Button ──────────────────────────────────────────────────
class _AnimatedGlassBtn extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Duration delay;

  const _AnimatedGlassBtn({
    required this.icon,
    required this.onTap,
    required this.delay,
  });

  @override
  State<_AnimatedGlassBtn> createState() => _AnimatedGlassBtnState();
}

class _AnimatedGlassBtnState extends State<_AnimatedGlassBtn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scale = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: _isPressed ? 0.88 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _isPressed
                  ? Colors.white.withOpacity(0.20)
                  : Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.20)),
            ),
            child: Icon(widget.icon, size: 15, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

// ── Staggered Text ─────────────────────────────────────────────────────────
class _StaggeredText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final Duration delay;

  const _StaggeredText({
    required this.text,
    required this.style,
    required this.delay,
  });

  @override
  State<_StaggeredText> createState() => _StaggeredTextState();
}

class _StaggeredTextState extends State<_StaggeredText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0.1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Text(widget.text, style: widget.style),
      ),
    );
  }
}

// ── Status Badge ───────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final bool isEngaged;
  final double pulseValue;

  const _StatusBadge({required this.isEngaged, required this.pulseValue});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isEngaged
            ? _C.orange.withOpacity(0.20)
            : _C.green.withOpacity(0.20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isEngaged
              ? _C.orange.withOpacity(0.50)
              : _C.green.withOpacity(0.50),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isEngaged
                  ? const Color(0xFFFB923C)
                  : const Color(0xFF34D399),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (isEngaged ? _C.orange : _C.green).withOpacity(
                    0.6 * pulseValue,
                  ),
                  blurRadius: 6 * pulseValue,
                  spreadRadius: 2 * pulseValue,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isEngaged ? 'Engaged' : 'Available',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isEngaged
                  ? const Color(0xFFFB923C)
                  : const Color(0xFF34D399),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Animated Form Field ────────────────────────────────────────────────────
class _AnimatedFormField extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const _AnimatedFormField({required this.child, required this.delay});

  @override
  State<_AnimatedFormField> createState() => _AnimatedFormFieldState();
}

class _AnimatedFormFieldState extends State<_AnimatedFormField>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

// ── Pressable Button ───────────────────────────────────────────────────────
class _PressableButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget child;

  const _PressableButton({required this.onPressed, required this.child});

  @override
  State<_PressableButton> createState() => _PressableButtonState();
}

class _PressableButtonState extends State<_PressableButton>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _pressed
                  ? [const Color(0xFF3D5AFE), const Color(0xFF3D5AFE)]
                  : [const Color(0xFF5B76FF), const Color(0xFF3D5AFE)],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: _pressed
                ? []
                : [
                    BoxShadow(
                      color: _C.accent.withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          alignment: Alignment.center,
          child: widget.child,
        ),
      ),
    );
  }
}

// ── Premium Tab Bar ────────────────────────────────────────────────────────
class _PremiumTabBar extends SliverPersistentHeaderDelegate {
  final TabController ctrl;
  const _PremiumTabBar(this.ctrl);

  static const _labels = ['Overview', 'Trips', 'Maintenance'];
  static const _icons = [
    Icons.dashboard_rounded,
    Icons.route_rounded,
    Icons.build_rounded,
  ];

  @override
  double get minExtent => 52;
  @override
  double get maxExtent => 52;

  @override
  Widget build(_, __, ___) => Container(
    decoration: BoxDecoration(
      color: _C.surface,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: TabBar(
      controller: ctrl,
      isScrollable: false,
      tabAlignment: TabAlignment.fill,
      dividerColor: Colors.transparent,
      indicator: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5B76FF), Color(0xFF3D5AFE)],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      indicatorSize: TabBarIndicatorSize.tab,
      indicatorPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
      labelColor: Colors.white,
      unselectedLabelColor: _C.text2,
      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
      labelStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.1,
      ),
      unselectedLabelStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      tabs: List.generate(
        _labels.length,
        (i) => Tab(
          height: 50,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_icons[i], size: 13),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(_labels[i], overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  @override
  bool shouldRebuild(_) => false;
}

// ════════════════════════════════════════════════════════════════════════════
// TAB 1 — OVERVIEW
// ════════════════════════════════════════════════════════════════════════════
class _OverviewTab extends StatelessWidget {
  final Vehicles vehicle;
  final String Function(double) fmt;
  final BuildContext ctx;
  const _OverviewTab({
    required this.vehicle,
    required this.fmt,
    required this.ctx,
  });

  @override
  Widget build(BuildContext context) {
    final rows = [
      _RowData(
        Icons.directions_car_rounded,
        'Vehicle Name',
        vehicle.name ?? '—',
        _C.accent,
      ),
      _RowData(
        Icons.pin_outlined,
        'Vehicle Number',
        vehicle.number ?? '—',
        _C.indigo,
      ),
      _RowData(
        Icons.local_gas_station_rounded,
        'Fuel Type',
        vehicle.FuelType ?? '—',
        _C.orange,
      ),
      _RowData(
        Icons.people_rounded,
        'Seating',
        '${vehicle.capacity ?? "--"} seats',
        _C.green,
      ),
      _RowData(
        Icons.speed_rounded,
        'Mileage',
        vehicle.mileage != null ? '${vehicle.mileage} km/l' : '—',
        _C.violet,
      ),
    ];

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        Container(
          decoration: BoxDecoration(
            color: _C.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _C.divider),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: rows.asMap().entries.map((e) {
              final i = e.key;
              final r = e.value;
              return _AnimatedListItem(
                delay: Duration(milliseconds: 60 * i),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _dRow(r.icon, r.label, r.value, r.color),
                    if (i < rows.length - 1)
                      Divider(height: 1, indent: 62, color: _C.divider),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _dRow(IconData icon, String label, String value, Color color) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 15, color: color),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: _C.text2,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _C.text1,
              ),
            ),
            const SizedBox(width: 2),
            Icon(Icons.chevron_right_rounded, size: 14, color: _C.divider),
          ],
        ),
      );

  Widget _label(String t) => Text(
    t,
    style: const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: _C.text2,
      letterSpacing: 0.8,
    ),
  );
}

class _RowData {
  final IconData icon;
  final String label, value;
  final Color color;
  const _RowData(this.icon, this.label, this.value, this.color);
}

// ── Animated list item ─────────────────────────────────────────────────────
class _AnimatedListItem extends StatefulWidget {
  final Widget child;
  final Duration delay;
  const _AnimatedListItem({required this.child, required this.delay});

  @override
  State<_AnimatedListItem> createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<_AnimatedListItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// TAB 2 — TRIPS
// ════════════════════════════════════════════════════════════════════════════
class _TripsTab extends ConsumerStatefulWidget {
  final Vehicles vehicle;
  final String Function(double) fmt;
  const _TripsTab({required this.vehicle, required this.fmt});

  @override
  ConsumerState<_TripsTab> createState() => _TripsTabState();
}

class _TripsTabState extends ConsumerState<_TripsTab> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref
          .read(addVehicleViewModelProvider.notifier)
          .getTripsByVehicle(widget.vehicle.vehicleId ?? 0),
    );
  }

  String _fmt(double v) {
    if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '₹${(v / 1000).toStringAsFixed(1)}K';
    return '₹${v.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addVehicleViewModelProvider).fetchTripsByVehicleId;

    return state.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: _C.accent, strokeWidth: 2),
      ),
      error: (e, _) => _errState(e.toString()),
      data: (trips) {
        if (trips.isEmpty) {
          return LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.route_outlined,
                            size: 70,
                            color: _C.accent.withOpacity(0.6),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "No trips yet",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Trip history will appear here.",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        }

        final total = trips.length;
        final paid = trips
            .where(
              (t) =>
                  (t.amountReceived ?? 0) >= (t.amountApprove ?? 0) &&
                  (t.amountApprove ?? 0) > 0,
            )
            .length;
        final revenue = trips.fold<double>(
          0,
          (s, t) => s + (t.amountApprove ?? 0),
        );

        return Column(
          children: [
            _AnimatedListItem(
              delay: const Duration(milliseconds: 0),
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _C.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _C.divider),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      _stat('$total', 'Total Trips', _C.indigo),
                      _vd(),
                      _stat('$paid', 'Paid', _C.green),
                      _vd(),
                      _stat(_fmt(revenue), 'Revenue', _C.accent),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(0, 2, 0, 100),
                itemCount: trips.length,
                itemBuilder: (_, i) => _AnimatedListItem(
                  delay: Duration(milliseconds: 50 + 40 * i),
                  child: TripCard(
                    key: ValueKey(trips[i].tripId),
                    bookinginfo: trips[i],
                    ref: ref,
                    status: trips[i].status?? 0,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _stat(String v, String l, Color c) => Expanded(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
          builder: (_, val, child) => Opacity(opacity: val, child: child),
          child: Text(
            v,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: c,
              letterSpacing: -0.4,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          l,
          style: const TextStyle(
            fontSize: 9,
            color: _C.text2,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ],
    ),
  );

  Widget _vd() => Container(
    width: 1,
    height: 32,
    margin: const EdgeInsets.symmetric(horizontal: 2),
    color: _C.divider,
  );
}

// ════════════════════════════════════════════════════════════════════════════
// TAB 3 — MAINTENANCE
// ════════════════════════════════════════════════════════════════════════════
class _MaintTab extends ConsumerStatefulWidget {
  final Vehicles vehicle;
  final int month, year;
  final List<String> months;
  final String Function(double) fmt;
  final ValueChanged<int> onMonth, onYear;
  // FIX: callback now receives a Services object for edit, called with null for add
  final void Function(Services? service) onEditService;

  const _MaintTab({
    required this.vehicle,
    required this.month,
    required this.year,
    required this.months,
    required this.fmt,
    required this.onMonth,
    required this.onYear,
    required this.onEditService,
  });

  @override
  ConsumerState<_MaintTab> createState() => _MaintTabState();
}

class _MaintTabState extends ConsumerState<_MaintTab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _listAnim;

  @override
  void initState() {
    super.initState();
    _listAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    Future.microtask(() {
      ref
          .read(addVehicleViewModelProvider.notifier)
          .getServiceRecords(
            ref.read(loginViewModelProvider).agencyId ?? '',
            widget.vehicle.vehicleId ?? 0,
          );
    });
  }

  @override
  void dispose() {
    _listAnim.dispose();
    super.dispose();
  }

  void _triggerListAnim() {
    _listAnim.forward(from: 0);
  }

  void _confirmDelete(BuildContext context, Services service) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        "Delete Service",
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      content: Text(
        'Are you sure you want to delete ${service.serviceName} service permanently?',
        style: const TextStyle(color: Colors.grey),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: () async {
            Navigator.pop(ctx);
            try {
              await ref
                  .read(addVehicleViewModelProvider.notifier)
                  .deleteService(service.serviceId ?? 0);

              // Refresh list after delete
              await ref
                  .read(addVehicleViewModelProvider.notifier)
                  .getServiceRecords(
                    ref.read(loginViewModelProvider).agencyId ?? '',
                    widget.vehicle.vehicleId ?? 0,
                  );

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Service deleted successfully"),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Failed to delete service: $e"),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          child: const Text(
            "Delete",
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    ),
  );
}



  @override
  Widget build(BuildContext context) {
    final serviceAsync = ref.watch(
      addVehicleViewModelProvider.select((s) => s.fetchServiceRecords),
    );

    return Column(
      children: [
        // Year + month selector
        Container(
          color: _C.surface,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          child: Column(
            children: [
              Row(
                children: [
                  _yBtn(Icons.chevron_left_rounded, () {
                    widget.onYear(widget.year - 1);
                    _triggerListAnim();
                  }),
                  Expanded(
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        transitionBuilder: (child, anim) => FadeTransition(
                          opacity: anim,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, -0.3),
                              end: Offset.zero,
                            ).animate(anim),
                            child: child,
                          ),
                        ),
                        child: Text(
                          '${widget.year}',
                          key: ValueKey(widget.year),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: _C.text1,
                          ),
                        ),
                      ),
                    ),
                  ),
                  _yBtn(Icons.chevron_right_rounded, () {
                    widget.onYear(widget.year + 1);
                    _triggerListAnim();
                  }),
                ],
              ),

              const SizedBox(height: 12),

              SizedBox(
                height: 36,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.months.length,
                  itemBuilder: (context, index) {
                    final isSelected = index == widget.month;
                    return GestureDetector(
                      onTap: () {
                        widget.onMonth(index);
                        _triggerListAnim();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: isSelected ? _C.orange : _C.surfaceAlt,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? _C.orange : _C.divider,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: _C.orange.withOpacity(0.30),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : [],
                        ),
                        alignment: Alignment.center,
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : _C.text1,
                          ),
                          child: Text(widget.months[index]),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        Container(height: 1, color: _C.divider),

        Expanded(
          child: serviceAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text("Error: $e")),
            data: (services) {
              final filteredServices = services.where((s) {
                if (s.serviceDate == null) return false;
                return s.serviceDate!.month == widget.month + 1 &&
                    s.serviceDate!.year == widget.year;
              }).toList();

              final monthlyTotal = filteredServices.fold<double>(
                0.0,
                (sum, s) => sum + (s.serviceCost ?? 0.0),
              );

              final yearlyTotal = services
                  .where((s) =>
                      s.serviceDate != null &&
                      s.serviceDate!.year == widget.year)
                  .fold<double>(0.0, (sum, s) => sum + (s.serviceCost ?? 0.0));

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
                children: [
                  // Summary cards
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Monthly Total",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "₹ ${monthlyTotal.toStringAsFixed(0)}",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.purple.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Yearly Total",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "₹ ${yearlyTotal.toStringAsFixed(0)}",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Empty state
                  if (filteredServices.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: Column(
                        children: [
                          Icon(
                            Icons.build_outlined,
                            size: 70,
                            color: Colors.orange.withOpacity(0.6),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "No records",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "No maintenance in ${widget.months[widget.month]} ${widget.year}.",
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),

                  // Service list
                  ...filteredServices.map((s) {
                    final formattedDate =
                        "${s.serviceDate!.day.toString().padLeft(2, '0')}/"
                        "${s.serviceDate!.month.toString().padLeft(2, '0')}/"
                        "${s.serviceDate!.year}";
                    return _mCard(
                      _MR(
                        s.serviceName ?? '',
                        s.description ?? '',
                        formattedDate,
                        (s.serviceCost ?? 0).toDouble(),
                        true,
                        Icons.build_rounded,
                      ),
                      s,
                    );
                  }).toList(),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _yBtn(IconData icon, VoidCallback fn) => _TapScaleButton(
    onTap: fn,
    child: Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: _C.surfaceAlt,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: _C.divider),
      ),
      child: Icon(icon, size: 16, color: _C.text1),
    ),
  );

  Widget _mCard(_MR r, Services service) {
    final bool isDone = r.done;
    final Color accentColor =
        isDone ? const Color(0xFF2A7A4B) : const Color(0xFFC8622A);
    final Color accentLight =
        isDone ? const Color(0xFFDFF0E8) : const Color(0xFFF5E8DF);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: accentColor, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    r.type,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1612),
                      height: 1.3,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),

                // FIX: Pass the actual service object to edit
                InkWell(
                  onTap: () => widget.onEditService(service),
                  borderRadius: BorderRadius.circular(20),
                  child: const Padding(
                    padding: EdgeInsets.all(6.0),
                    child: Icon(
                      Icons.edit_outlined,
                      size: 15,
                      color: Color.fromARGB(255, 114, 107, 107),
                    ),
                  ),
                ),

                InkWell(
                  onTap: () => _confirmDelete(context, service),
                  borderRadius: BorderRadius.circular(20),
                  child: const Padding(
                    padding: EdgeInsets.all(6.0),
                    child: Icon(
                      Icons.delete_outline,
                      size: 15,
                      color: Color.fromARGB(255, 114, 107, 107),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: accentLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '₹ ${r.cost.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: accentColor,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 255, 239, 183),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    r.date,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color.fromARGB(255, 155, 104, 27),
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            const Divider(height: 1, color: Color(0xFFE8E2DA)),

            const SizedBox(height: 14),

            Text(
              r.notes,
              style: const TextStyle(
                fontSize: 13.5,
                color: Color(0xFF5A534A),
                height: 1.65,
                fontWeight: FontWeight.w300,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _MR {
  final String type, notes, date;
  final double cost;
  final bool done;
  final IconData icon;
  const _MR(this.type, this.notes, this.date, this.cost, this.done, this.icon);
}

// ── Tap scale helper ───────────────────────────────────────────────────────
class _TapScaleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _TapScaleButton({required this.child, required this.onTap});

  @override
  State<_TapScaleButton> createState() => _TapScaleButtonState();
}

class _TapScaleButtonState extends State<_TapScaleButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.88 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: widget.child,
      ),
    );
  }
}

// ── Error State ────────────────────────────────────────────────────────────
Widget _errState(String msg) => Center(
  child: Padding(
    padding: const EdgeInsets.all(48),
    child: TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      builder: (_, v, child) => Opacity(opacity: v, child: child),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _C.redSoft,
              shape: BoxShape.circle,
              border: Border.all(color: _C.red.withOpacity(0.20)),
            ),
            child: const Icon(
                Icons.cloud_off_rounded, color: _C.red, size: 26),
          ),
          const SizedBox(height: 14),
          const Text(
            'Failed to load',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: _C.text1,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            msg,
            textAlign: TextAlign.center,
            style:
                const TextStyle(fontSize: 11, color: _C.text2, height: 1.5),
          ),
        ],
      ),
    ),
  ),
);