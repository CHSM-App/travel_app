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
  static const accentSoft = Color(0xFFEBEEFF);
  static const indigo = Color(0xFF4F46E5);
  static const indigoSoft = Color(0xFFEEF2FF);
  static const violet = Color(0xFF7C3AED);
  static const green = Color(0xFF059669);
  static const greenSoft = Color(0xFFD1FAE5);
  static const red = Color(0xFFDC2626);
  static const redSoft = Color(0xFFFEE2E2);
  static const orange = Color(0xFFEA580C);
  static const orangeSoft = Color(0xFFFFEDD5);
  static const amber = Color(0xFFD97706);
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
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  void initState() {
    super.initState();

    _tab = TabController(length: 4, vsync: this)
      ..addListener(_onTabChanged);

    // Header entrance
    _headerAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _headerFade = CurvedAnimation(
      parent: _headerAnim,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    );
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _headerAnim,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
    ));

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
    _fabScale = CurvedAnimation(
      parent: _fabAnim,
      curve: Curves.elasticOut,
    );

    // Pulse for status dot
    _pulseAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnim1 = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseAnim, curve: Curves.easeInOut),
    );
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
          SliverPersistentHeader(
            pinned: true,
            delegate: _PremiumTabBar(_tab),
          ),
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
            ),
            // _DocsTab(vehicle: widget.vehicle),
          ],
        ),
      ),
      floatingActionButton: _fab(),
    );
  }

  // ── PREMIUM HEADER ────────────────────────────────────────────────
  Widget _buildHeader() {
    final top = MediaQuery.of(context).padding.top;
    final isEngaged = (widget.vehicle.StatusId ?? 0) == 1;

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
          // Animated decorative circles
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
                  // Nav row
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

                  // Identity row
                  FadeTransition(
                    opacity: _headerFade,
                    child: SlideTransition(
                      position: _headerSlide,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Avatar with spring + rotate animation
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
                                boxShadow: [
                                  BoxShadow(
                                    color: _C.accent.withOpacity(0.5),
                                    blurRadius: 20,
                                    spreadRadius: -4,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.25),
                                  width: 1.5,
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
                                // Vehicle name shimmer-in
                                _StaggeredText(
                                  text: widget.vehicle.name ?? 'Unknown Vehicle',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: -0.6,
                                    height: 1.1,
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

                          // Animated status badge
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

                  const SizedBox(height: 20),

                  // Stats strip with slide-up
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
                          border: Border.all(
                            color: Colors.white.withOpacity(0.12),
                          ),
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
          onPressed: () => _showAddServiceSheet(context),
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
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      ));
      return SlideTransition(position: offset, child: child);
    },
    transitionDuration: const Duration(milliseconds: 400),
  );

  void _showAddServiceSheet(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final serviceController = TextEditingController();
    final costController = TextEditingController();
    final noteController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      transitionAnimationController: AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 450),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeOutCubic,
              builder: (_, value, child) => Transform.translate(
                offset: Offset(0, 40 * (1 - value)),
                child: Opacity(opacity: value, child: child),
              ),
              child: Container(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Handle bar
                        Center(
                          child: Container(
                            width: 36,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: _C.divider,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Add Service",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        _AnimatedFormField(
                          delay: const Duration(milliseconds: 50),
                          child: TextFormField(
                            controller: serviceController,
                            decoration: _inputDeco("Service Name", null),
                            validator: (v) => v == null || v.isEmpty
                                ? "Enter service name"
                                : null,
                          ),
                        ),

                        const SizedBox(height: 12),

                        _AnimatedFormField(
                          delay: const Duration(milliseconds: 100),
                          child: TextFormField(
                            controller: costController,
                            keyboardType: TextInputType.number,
                            decoration: _inputDeco("Service Cost", "₹ "),
                            validator: (v) =>
                                v == null || v.isEmpty ? "Enter cost" : null,
                          ),
                        ),

                        const SizedBox(height: 12),

                        _AnimatedFormField(
                          delay: const Duration(milliseconds: 150),
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) {
                                setState(() => selectedDate = picked);
                              }
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade400),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "${selectedDate.day}-${selectedDate.month}-${selectedDate.year}",
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  const Icon(Icons.calendar_today, size: 18),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        _AnimatedFormField(
                          delay: const Duration(milliseconds: 200),
                          child: TextFormField(
                            controller: noteController,
                            maxLines: 3,
                            decoration: _inputDeco("Notes (Optional)", null),
                          ),
                        ),

                        const SizedBox(height: 20),

                        _AnimatedFormField(
                          delay: const Duration(milliseconds: 250),
                          child: SizedBox(
                            width: double.infinity,
                            child: _PressableButton(
                              onPressed: () async {
                                if (formKey.currentState!.validate()) {
                                  final body = {
                                    "vehicle_id": widget.vehicle.vehicleId,
                                    "service_name": serviceController.text,
                                    "service_cost":
                                        double.parse(costController.text),
                                    "service_date":
                                        selectedDate.toIso8601String(),
                                    "description": noteController.text,
                                    "agency_id": ref
                                        .read(loginViewModelProvider)
                                        .agencyId,
                                  };

                                  try {
                                    await ref
                                        .read(
                                            addVehicleViewModelProvider.notifier)
                                        .addService(Services.fromJson(body));

                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              "Service added successfully ✅"),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    }

                                    await ref
                                        .read(
                                            addVehicleViewModelProvider.notifier)
                                        .getServiceRecords(
                                          ref
                                                  .read(loginViewModelProvider)
                                                  .agencyId ??
                                              '',
                                          widget.vehicle.vehicleId ?? 0,
                                        );

                                    Navigator.pop(context);
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text("Failed to add service ❌"),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                              child: const Text(
                                "Save Service",
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  InputDecoration _inputDeco(String label, String? prefix) => InputDecoration(
    labelText: label,
    prefixText: prefix,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: _C.accent, width: 2),
    ),
  );
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

    _scale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
    );
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
    _scale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut),
    );
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
                  color: (isEngaged ? _C.orange : _C.green)
                      .withOpacity(0.6 * pulseValue),
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
    Icons.folder_rounded,
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
      indicatorPadding:
          const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
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
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_icons[i], size: 13),
                const SizedBox(width: 5),
                Text(_labels[i]),
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
// TAB 1 — OVERVIEW  (animated list items)
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
      _RowData(Icons.directions_car_rounded, 'Vehicle Name',
          vehicle.name ?? '—', _C.accent),
      _RowData(Icons.pin_outlined, 'Plate Number', vehicle.number ?? '—',
          _C.indigo),
      _RowData(Icons.local_gas_station_rounded, 'Fuel Type',
          vehicle.FuelType ?? '—', _C.orange),
      _RowData(Icons.people_rounded, 'Seating',
          '${vehicle.capacity ?? "--"} seats', _C.green),
      _RowData(Icons.speed_rounded, 'Mileage',
          vehicle.mileage != null ? '${vehicle.mileage} km/l' : '—',
          _C.violet),
    ];

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        // Detail card — items animate in staggered
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

        const SizedBox(height: 16),

        _label('Compliance & Expiry'),
        const SizedBox(height: 10),

        // Compliance grid — staggered cards
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.65,
          children: [
            _AnimatedListItem(
              delay: const Duration(milliseconds: 200),
              child: _compTile('Insurance', null, Icons.verified_rounded, _C.green),
            ),
            _AnimatedListItem(
              delay: const Duration(milliseconds: 260),
              child: _compTile('RC Book', null, Icons.article_rounded, _C.indigo),
            ),
            _AnimatedListItem(
              delay: const Duration(milliseconds: 320),
              child: _compTile('Pollution', null, Icons.air_rounded, _C.orange),
            ),
            _AnimatedListItem(
              delay: const Duration(milliseconds: 380),
              child: _compTile('Permit', null, Icons.badge_rounded, _C.violet),
            ),
          ],
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

  Widget _compTile(String label, DateTime? expiry, IconData icon, Color color) {
    final days = expiry?.difference(DateTime.now()).inDays;
    final warn = days != null && days < 30 && days >= 0;
    final expired = days != null && days < 0;
    final c = expired ? _C.red : warn ? _C.orange : color;

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: (warn || expired) ? c.withOpacity(0.30) : _C.divider,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [c.withOpacity(0.16), c.withOpacity(0.06)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 14, color: c),
              ),
              const Spacer(),
              if (warn || expired)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: c.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    expired ? 'Expired' : '${days}d left',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      color: c,
                    ),
                  ),
                ),
            ],
          ),
          const Spacer(),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: _C.text2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            expiry != null
                ? '${expiry.day}/${expiry.month}/${expiry.year}'
                : 'Not set',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: c,
            ),
          ),
        ],
      ),
    );
  }
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
          return _emptyState(
            Icons.route_outlined,
            'No trips yet',
            'Trip history will appear here.',
            _C.accent,
          );
        }

        final total = trips.length;
        final paid = trips
            .where((t) =>
                (t.amountReceived ?? 0) >= (t.amountApprove ?? 0) &&
                (t.amountApprove ?? 0) > 0)
            .length;
        final revenue =
            trips.fold<double>(0, (s, t) => s + (t.amountApprove ?? 0));

        return Column(
          children: [
            // Stat strip with slide-down
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
                    tripType: '',
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

  const _MaintTab({
    required this.vehicle,
    required this.month,
    required this.year,
    required this.months,
    required this.fmt,
    required this.onMonth,
    required this.onYear,
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
      ref.read(addVehicleViewModelProvider.notifier).getServiceRecords(
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

  // Re-trigger animation on month/year change
  void _triggerListAnim() {
    _listAnim.forward(from: 0);
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
                  _yBtn(Icons.chevron_left_rounded,
                      () { widget.onYear(widget.year - 1); _triggerListAnim(); }),
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
                  _yBtn(Icons.chevron_right_rounded,
                      () { widget.onYear(widget.year + 1); _triggerListAnim(); }),
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
                            color: isSelected
                                ? _C.orange
                                : _C.divider,
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
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text("Error: $e")),
            data: (services) {
              final filtered = services.where((s) {
                if (s.serviceDate == null) return false;
                return s.serviceDate?.month == widget.month + 1 &&
                    s.serviceDate?.year == widget.year;
              }).toList();

              if (filtered.isEmpty) {
                return _emptyState(
                  Icons.build_outlined,
                  'No records',
                  'No maintenance in ${widget.months[widget.month]} ${widget.year}.',
                  _C.orange,
                );
              }

              return ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
                itemCount: filtered.length,
                itemBuilder: (_, i) {
                  final s = filtered[i];
                  return _AnimatedListItem(
                    delay: Duration(milliseconds: 60 * i),
                    child: _mCard(
                      _MR(
                        s.serviceName ?? '',
                        s.description ?? '',
                        s.serviceCost ?? 0,
                        true,
                        Icons.build_rounded,
                      ),
                    ),
                  );
                },
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

  Widget _mCard(_MR r) {
    final c = r.done ? _C.green : _C.orange;
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _C.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [c.withOpacity(0.15), c.withOpacity(0.05)],
              ),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(r.icon, color: c, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.type,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: _C.text1,
                  ),
                ),
                if (r.notes.isNotEmpty)
                  Text(
                    r.notes,
                    style: const TextStyle(fontSize: 12, color: _C.text2),
                  ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: c.withOpacity(0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '₹${r.cost.toStringAsFixed(0)}',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: c,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MR {
  final String type, notes;
  final double cost;
  final bool done;
  final IconData icon;
  const _MR(this.type, this.notes, this.cost, this.done, this.icon);
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

// ════════════════════════════════════════════════════════════════════════════
// TAB 4 — DOCUMENTS
// ════════════════════════════════════════════════════════════════════════════
class _DocsTab extends StatelessWidget {
  final Vehicles vehicle;
  const _DocsTab({required this.vehicle});

  static const _docs = [
    _D('RC Book', Icons.article_rounded, _C.indigo, 'Registration'),
    _D('Insurance', Icons.verified_rounded, _C.green, 'Active'),
    _D('PUC', Icons.air_rounded, _C.orange, 'Pollution'),
    _D('Permit', Icons.badge_rounded, _C.violet, 'Commercial'),
    _D('Fitness', Icons.health_and_safety_rounded, _C.green, 'Annual'),
    _D('Road Tax', Icons.receipt_rounded, _C.text2, 'Annual'),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        _AnimatedListItem(
          delay: const Duration(milliseconds: 0),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_C.indigoSoft, _C.accentSoft],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _C.indigo.withOpacity(0.15)),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _C.indigo.withOpacity(0.20),
                        _C.accent.withOpacity(0.10),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: _C.indigo,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Document Vault',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: _C.text1,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Upload and manage all vehicle documents',
                        style: TextStyle(fontSize: 11, color: _C.text2),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 14),

        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.35,
          children: _docs.asMap().entries.map((e) {
            final i = e.key;
            final d = e.value;
            const uploaded = false;

            return _AnimatedListItem(
              delay: Duration(milliseconds: 80 * i),
              child: _DocTile(d: d, uploaded: uploaded),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _DocTile extends StatefulWidget {
  final _D d;
  final bool uploaded;
  const _DocTile({required this.d, required this.uploaded});

  @override
  State<_DocTile> createState() => _DocTileState();
}

class _DocTileState extends State<_DocTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final d = widget.d;
    final uploaded = widget.uploaded;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () {},
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _pressed ? _C.surfaceAlt : _C.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: uploaded ? d.color.withOpacity(0.28) : _C.divider,
            ),
            boxShadow: _pressed
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          d.color.withOpacity(0.18),
                          d.color.withOpacity(0.07),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: d.color.withOpacity(0.18)),
                    ),
                    child: Icon(d.icon, size: 16, color: d.color),
                  ),
                  const Spacer(),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: uploaded ? _C.greenSoft : _C.surfaceAlt,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: uploaded ? _C.green : _C.divider,
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      uploaded ? Icons.check_rounded : Icons.upload_rounded,
                      size: 12,
                      color: uploaded ? _C.green : _C.text2,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                d.label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: _C.text1,
                  letterSpacing: -0.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                d.subtitle,
                style: TextStyle(
                  fontSize: 10,
                  color: d.color,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                uploaded ? 'Tap to view' : 'Tap to upload',
                style: const TextStyle(fontSize: 9, color: _C.text2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _D {
  final String label, subtitle;
  final IconData icon;
  final Color color;
  const _D(this.label, this.icon, this.color, this.subtitle);
}

// ── Shared helpers ─────────────────────────────────────────────────────────
Widget _emptyState(IconData icon, String title, String sub, Color c) => Center(
  child: Padding(
    padding: const EdgeInsets.all(48),
    child: TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutBack,
      builder: (_, v, child) => Transform.scale(scale: v, child: child),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [c.withOpacity(0.15), c.withOpacity(0.03)],
              ),
              shape: BoxShape.circle,
              border: Border.all(color: c.withOpacity(0.15)),
            ),
            child: Icon(icon, size: 30, color: c),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: _C.text1,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            sub,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: _C.text2,
              height: 1.6,
            ),
          ),
        ],
      ),
    ),
  ),
);

Widget _errState(String msg) => Center(
  child: Padding(
    padding: const EdgeInsets.all(48),
    child: TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      builder: (_, v, child) =>
          Opacity(opacity: v, child: child),
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
            child: const Icon(Icons.cloud_off_rounded, color: _C.red, size: 26),
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
            style: const TextStyle(fontSize: 11, color: _C.text2, height: 1.5),
          ),
        ],
      ),
    ),
  ),
);