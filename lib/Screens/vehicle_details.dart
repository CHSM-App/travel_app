import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_agency_app/Screens/trip_card.dart';
import 'package:travel_agency_app/Screens/add_vehicle.dart';
import 'package:travel_agency_app/core/network/error_messages.dart';
import 'package:travel_agency_app/core/theme/app_colors.dart';
import 'package:travel_agency_app/core/widgets/error_view.dart';
import 'package:travel_agency_app/core/widgets/skeleton.dart';
import 'package:travel_agency_app/domain/models/booking_info.dart';
import 'package:travel_agency_app/domain/models/services.dart';
import 'package:travel_agency_app/domain/models/vehicles.dart';
import 'package:travel_agency_app/presentation/providers/viewmodel_provider.dart';

// ── Premium Token System ───────────────────────────────────────────────────
abstract class _C {
  static const bg = Color(0xFFF0F2F8);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFF5F6FA);
  static const g1 = Color(0xFF1A1F3A);
  // Brand-indigo gradient companions. g2 = darker stop, g3 = mid, accent = primary.
  static const g2 = AppColors.brandPrimaryDark;
  static const g3 = AppColors.brandPrimary;
  static const accent = AppColors.brandPrimary;
  static const indigo = AppColors.brandPrimary;
  static const green = Color(0xFF059669);
  static const red = Color(0xFFDC2626);
  static const redSoft = Color(0xFFFEE2E2);
  static const orange = Color(0xFFEA580C);
  static const text1 = Color(0xFF0F1224);
  static const text2 = Color(0xFF6B7280);
  static const divider = Color(0xFFE5E7F0);
  static const gold = Color(0xFFF59E0B);
}

/// Date-window filter for the P&L summary above the tabs.
enum _PnlPeriod {
  all('All', Icons.all_inclusive_rounded),
  today('Today', Icons.today_rounded),
  week('Week', Icons.view_week_rounded),
  month('Month', Icons.calendar_month_rounded);

  const _PnlPeriod(this.label, this.icon);
  final String label;
  final IconData icon;

  bool matches(DateTime? d, DateTime now) {
    if (this == _PnlPeriod.all) return true;
    if (d == null) return false;
    final dOnly = DateTime(d.year, d.month, d.day);
    final today = DateTime(now.year, now.month, now.day);
    switch (this) {
      case _PnlPeriod.today:
        return dOnly == today;
      case _PnlPeriod.week:
        final start = today.subtract(const Duration(days: 6));
        return !dOnly.isBefore(start) && !dOnly.isAfter(today);
      case _PnlPeriod.month:
        return d.year == now.year && d.month == now.month;
      case _PnlPeriod.all:
        return true;
    }
  }
}

// Reusable All/Today/Week/Month segmented control, used inside the Revenue and
// Expense tabs to drive the shared period filter.
class _PeriodChips extends StatelessWidget {
  final _PnlPeriod selected;
  final ValueChanged<_PnlPeriod> onChanged;
  const _PeriodChips({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _C.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.divider),
      ),
      child: Row(
        children: [
          for (final p in _PnlPeriod.values) Expanded(child: _chip(p)),
        ],
      ),
    );
  }

  Widget _chip(_PnlPeriod p) {
    final active = p == selected;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(p),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          gradient: active
              ? const LinearGradient(
                  colors: [AppColors.brandPrimaryLight, AppColors.brandPrimary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          borderRadius: BorderRadius.circular(10),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: _C.accent.withOpacity(0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(p.icon, size: 13, color: active ? Colors.white : _C.text2),
              const SizedBox(width: 5),
              Text(
                p.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: active ? Colors.white : _C.text2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
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
  late final AnimationController _avatarAnim;
  late final AnimationController _fabAnim;
  late final AnimationController _pulseAnim;

  // ── Derived Animations ─────────────────────────────────────────────────
  late final Animation<double> _headerFade;
  late final Animation<Offset> _headerSlide;
  late final Animation<double> _avatarScale;
  late final Animation<double> _avatarRotate;
  late final Animation<double> _fabScale;
  late final Animation<double> _pulseAnim1;

  // Shared period filter — driven from the Revenue / Expense tab chips and
  // reflected in the P&L summary above the tabs.
  _PnlPeriod _pnlPeriod = _PnlPeriod.month;

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

    // Prefetch trips + services so the P&L summary above the tabs is populated
    // regardless of which tab is active. Both calls are idempotent and shared
    // with the tabs.
    Future.microtask(() {
      final agencyId = ref.read(loginViewModelProvider).agencyId ?? '';
      final vid = widget.vehicle.vehicleId ?? 0;
      ref.read(addVehicleViewModelProvider.notifier).getTripsByVehicle(vid);
      ref
          .read(addVehicleViewModelProvider.notifier)
          .getServiceRecords(agencyId, vid);
    });
  }

  void _onTabChanged() {
    setState(() {});
    if (_tab.index == 2) {
      _fabAnim.forward();
    } else {
      _fabAnim.reverse();
    }
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
          content: Text(friendlyErrorMessage(e)),
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

  // ── P&L SUMMARY (period chips + net profit/loss hero) ─────────────────────
  Widget _buildPnlSummary() {
    final tripsAsync = ref.watch(
      addVehicleViewModelProvider.select((s) => s.fetchTripsByVehicleId),
    );
    final servicesAsync = ref.watch(
      addVehicleViewModelProvider.select((s) => s.fetchServiceRecords),
    );
    final trips = tripsAsync.asData?.value ?? const <BookingInfo>[];
    final services = servicesAsync.asData?.value ?? const <Services>[];
    final now = DateTime.now();

    // Revenue = money received; trip expense = toll + repair + driver; both
    // attributed by payment/start/booking date. Maintenance from service costs.
    final periodTrips = trips.where((t) {
      final d = t.paymentDate ?? t.startDateTime ?? t.bookingDate;
      return _pnlPeriod.matches(d, now);
    }).toList();
    final revenue =
        periodTrips.fold<double>(0, (s, t) => s + (t.amountReceived ?? 0));
    // Trips that still have an outstanding balance (received < approved).
    final unpaidCount = periodTrips
        .where((t) => (t.amountApprove ?? 0) > (t.amountReceived ?? 0))
        .length;
    final tripExpense = periodTrips.fold<double>(
      0,
      (s, t) =>
          s +
          (t.tollCharges ?? 0) +
          (t.repairingCharges ?? 0) +
          (t.driverCharges ?? 0),
    );
    final maintenance = services
        .where((s) => _pnlPeriod.matches(s.serviceDate, now))
        .fold<double>(0, (sum, e) => sum + (e.serviceCost ?? 0));
    final expense = tripExpense + maintenance;
    final net = revenue - expense;
    final isProfit = net >= 0;
    final margin = revenue > 0 ? (net / revenue * 100) : 0.0;

    return Container(
      color: _C.bg,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Column(
        children: [
          // Hero net profit/loss card (period is controlled from the
          // Revenue / Expense tabs).
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.brandPrimary, AppColors.brandPrimaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: _C.accent.withOpacity(0.30),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${isProfit ? '' : '−'}${_fmt(net.abs())}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(
                        isProfit ? 'net profit' : 'net loss',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.82),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.20),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isProfit
                                ? Icons.trending_up_rounded
                                : Icons.trending_down_rounded,
                            color: Colors.white,
                            size: 11,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${isProfit ? '+' : ''}${margin.toStringAsFixed(1)}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _pnlStat('Revenue', _fmt(revenue),
                          Icons.south_west_rounded),
                    ),
                    _pnlDivider(),
                    Expanded(
                      child: _pnlStat('Expense', _fmt(expense),
                          Icons.north_east_rounded),
                    ),
                    _pnlDivider(),
                    Expanded(
                      child: _pnlStat('Trips', '${periodTrips.length}',
                          Icons.receipt_long_rounded),
                    ),
                    _pnlDivider(),
                    Expanded(
                      child: _pnlStat('Unpaid', '$unpaidCount',
                          Icons.pending_actions_rounded),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pnlDivider() => Container(
        width: 1,
        height: 30,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        color: Colors.white.withOpacity(0.18),
      );

  Widget _pnlStat(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(icon, size: 11, color: Colors.white.withOpacity(0.85)),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.82),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15.5,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    // Built here (not lazily in the sliver callback) so the ref.watch inside
    // registers as a dependency of this build.
    final pnlSummary = _buildPnlSummary();

    return Scaffold(
      backgroundColor: _C.bg,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverToBoxAdapter(child: _buildHeader()),
          SliverToBoxAdapter(child: pnlSummary),
          SliverPersistentHeader(pinned: true, delegate: _PremiumTabBar(_tab)),
        ],
        body: TabBarView(
          controller: _tab,
          physics: const BouncingScrollPhysics(),
          children: [
            _OverviewTab(vehicle: widget.vehicle),
            _TripsTab(
              vehicle: widget.vehicle,
              fmt: _fmt,
              period: _pnlPeriod,
              onPeriodChanged: (p) => setState(() => _pnlPeriod = p),
            ),
            _MaintTab(
              vehicle: widget.vehicle,
              fmt: _fmt,
              period: _pnlPeriod,
              onPeriodChanged: (p) => setState(() => _pnlPeriod = p),
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
            padding: EdgeInsets.fromLTRB(18, top > 0 ? 2 : 8, 18, 16),
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

                const SizedBox(height: 14),

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
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.brandPrimaryLight,
                                  AppColors.brandPrimary,
                                ],
                              ),
                            ),
                            child: const Icon(
                              Icons.directions_car_rounded,
                              color: Colors.white,
                              size: 24,
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
                                  fontSize: 19,
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

  // ── FAB ───────────────────────────────────────────────────────────
  Widget? _fab() {
    return ScaleTransition(
      scale: _fabScale,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [AppColors.brandPrimaryLight, AppColors.brandPrimary],
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
                              color: AppColors.brandPrimary,
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
                                          color: AppColors.brandPrimary,
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
                              backgroundColor: AppColors.brandPrimary,
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
                                          friendlyErrorMessage(e),
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
        prefixIcon: Icon(icon, size: 18, color: AppColors.brandPrimary),
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
          borderSide: BorderSide(color: AppColors.brandPrimary, width: 1.4),
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
                  ? [AppColors.brandPrimary, AppColors.brandPrimary]
                  : [AppColors.brandPrimaryLight, AppColors.brandPrimary],
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

  static const _labels = ['Overview', 'Revenue', 'Expense'];
  static const _icons = [
    Icons.directions_car_rounded,
    Icons.south_west_rounded,
    Icons.north_east_rounded,
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
          colors: [AppColors.brandPrimaryLight, AppColors.brandPrimary],
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

/// Client-side status filter for the per-vehicle trip list. All trips for the
/// vehicle are fetched once, so filtering happens in memory — mirroring the
/// status filter in [TripPage] but keyed on [BookingInfo.status]:
/// 1 = Active, 2 = Unpaid, 3 = Upcoming, 4 = Complete, 5 = Cancelled.
enum _VehicleTripFilter {
  all('All', Icons.list_alt_rounded),
  active('Active', Icons.directions_car_rounded),
  upcoming('Upcoming', Icons.schedule_rounded),
  completed('Completed', Icons.task_alt_rounded),
  cancelled('Cancelled', Icons.cancel_rounded);

  const _VehicleTripFilter(this.label, this.icon);

  final String label;
  final IconData icon;

  bool matches(BookingInfo t) {
    switch (this) {
      case _VehicleTripFilter.all:
        return true;
      case _VehicleTripFilter.active:
        return t.status == 1;
      case _VehicleTripFilter.upcoming:
        return t.status == 3;
      case _VehicleTripFilter.completed:
        // Completed covers both the unpaid (2) and fully paid/complete (4) buckets.
        return t.status == 2 || t.status == 4;
      case _VehicleTripFilter.cancelled:
        return t.status == 5;
    }
  }
}

class _TripsTab extends ConsumerStatefulWidget {
  final Vehicles vehicle;
  final String Function(double) fmt;
  final _PnlPeriod period;
  final ValueChanged<_PnlPeriod> onPeriodChanged;
  const _TripsTab({
    required this.vehicle,
    required this.fmt,
    required this.period,
    required this.onPeriodChanged,
  });

  @override
  ConsumerState<_TripsTab> createState() => _TripsTabState();
}

class _TripsTabState extends ConsumerState<_TripsTab> {
  _VehicleTripFilter _filter = _VehicleTripFilter.all;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref
          .read(addVehicleViewModelProvider.notifier)
          .getTripsByVehicle(widget.vehicle.vehicleId ?? 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addVehicleViewModelProvider).fetchTripsByVehicleId;

    return state.when(
      loading: () => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
        children: const [
          SkeletonListItem(),
          SkeletonListItem(),
          SkeletonListItem(),
          SkeletonListItem(),
        ],
      ),
      error: (e, _) => _errState(friendlyErrorMessage(e)),
      data: (allTrips) {
        // Date-window filter (All / Today / Week / Month), matched on
        // payment/start/booking date.
        final now = DateTime.now();
        final trips = allTrips.where((t) {
          final d = t.paymentDate ?? t.startDateTime ?? t.bookingDate;
          return widget.period.matches(d, now);
        }).toList();

        if (allTrips.isEmpty) {
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

        // Apply the in-memory status filter to the already-fetched list.
        final filtered =
            trips.where((t) => _filter.matches(t)).toList();

        return Column(
          children: [
            // ── Date-window filter ───────────────────────────────────────
            Container(
              color: _C.surface,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: _PeriodChips(
                selected: widget.period,
                onChanged: widget.onPeriodChanged,
              ),
            ),

            // ── Status filter chips ──────────────────────────────────────
            _buildFilterChips(trips),

            Expanded(
              child: filtered.isEmpty
                  ? _filteredEmptyState()
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(0, 2, 0, 100),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) => _AnimatedListItem(
                        delay: Duration(milliseconds: 50 + 40 * i),
                        child: TripCard(
                          key: ValueKey(filtered[i].tripId),
                          bookinginfo: filtered[i],
                          status: filtered[i].status ?? 0,
                        ),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  // ── Status filter chips ────────────────────────────────────────────────
  Widget _buildFilterChips(List<BookingInfo> trips) {
    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        itemCount: _VehicleTripFilter.values.length,
        itemBuilder: (context, index) {
          final filter = _VehicleTripFilter.values[index];
          final isSelected = filter == _filter;
          final count = filter == _VehicleTripFilter.all
              ? trips.length
              : trips.where(filter.matches).length;

          return GestureDetector(
            onTap: () {
              if (filter != _filter) setState(() => _filter = filter);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isSelected ? _C.accent : _C.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? _C.accent : _C.divider,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: _C.accent.withOpacity(0.30),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : [],
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    filter.icon,
                    size: 14,
                    color: isSelected ? Colors.white : _C.text2,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${filter.label} ($count)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : _C.text1,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Shown when the vehicle has trips but none match the active filter.
  Widget _filteredEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_filter.icon, size: 56, color: _C.accent.withOpacity(0.5)),
            const SizedBox(height: 14),
            Text(
              'No ${_filter.label.toLowerCase()} trips',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Try a different filter.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// TAB 3 — MAINTENANCE
// ════════════════════════════════════════════════════════════════════════════
class _MaintTab extends ConsumerStatefulWidget {
  final Vehicles vehicle;
  final String Function(double) fmt;
  final _PnlPeriod period;
  final ValueChanged<_PnlPeriod> onPeriodChanged;
  // FIX: callback now receives a Services object for edit, called with null for add
  final void Function(Services? service) onEditService;

  const _MaintTab({
    required this.vehicle,
    required this.fmt,
    required this.period,
    required this.onPeriodChanged,
    required this.onEditService,
  });

  @override
  ConsumerState<_MaintTab> createState() => _MaintTabState();
}

class _MaintTabState extends ConsumerState<_MaintTab> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref
          .read(addVehicleViewModelProvider.notifier)
          .getServiceRecords(
            ref.read(loginViewModelProvider).agencyId ?? '',
            widget.vehicle.vehicleId ?? 0,
          );
      // Trips power the toll / repair / driver rows of the expense breakdown.
      ref
          .read(addVehicleViewModelProvider.notifier)
          .getTripsByVehicle(widget.vehicle.vehicleId ?? 0);
    });
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
                    content: Text(friendlyErrorMessage(e)),
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
    final tripsAsync = ref.watch(
      addVehicleViewModelProvider.select((s) => s.fetchTripsByVehicleId),
    );
    final trips = tripsAsync.asData?.value ?? const <BookingInfo>[];
    final now = DateTime.now();

    return Column(
      children: [
        // ── Date-window filter ───────────────────────────────────────────
        Container(
          color: _C.surface,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: _PeriodChips(
            selected: widget.period,
            onChanged: widget.onPeriodChanged,
          ),
        ),

        Container(height: 1, color: _C.divider),

        Expanded(
          child: serviceAsync.when(
            loading: () => ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
              children: const [
                SkeletonListItem(hasTrailingLine: false),
                SkeletonListItem(hasTrailingLine: false),
                SkeletonListItem(hasTrailingLine: false),
              ],
            ),
            error: (e, _) => NetworkErrorView(error: e),
            data: (services) {
              final filteredServices = services
                  .where((s) => widget.period.matches(s.serviceDate, now))
                  .toList();

              // Maintenance cost for the selected period (from service records).
              final maintenance = filteredServices.fold<double>(
                0.0,
                (sum, s) => sum + (s.serviceCost ?? 0.0),
              );

              // Trip-level expenses (toll / repair / driver) for trips that
              // fall in the selected period, matched on payment/start/booking
              // date so unpaid trips still count once they have a date.
              bool inPeriod(BookingInfo t) {
                final d = t.paymentDate ?? t.startDateTime ?? t.bookingDate;
                return widget.period.matches(d, now);
              }

              final periodTrips = trips.where(inPeriod).toList();
              final toll = periodTrips.fold<double>(
                  0.0, (sum, t) => sum + (t.tollCharges ?? 0.0));
              final repair = periodTrips.fold<double>(
                  0.0, (sum, t) => sum + (t.repairingCharges ?? 0.0));
              final driver = periodTrips.fold<double>(
                  0.0, (sum, t) => sum + (t.driverCharges ?? 0.0));
              final totalExpense = toll + repair + driver + maintenance;

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
                children: [
                  // Expense breakdown
                  _breakdownCard(
                      toll, repair, driver, maintenance, totalExpense),
                  const SizedBox(height: 16),

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
                            "No maintenance for ${widget.period.label}.",
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

  // ── Expense breakdown (toll / repair / driver / maintenance) ──────────
  Widget _breakdownCard(double toll, double repair, double driver,
      double maintenance, double expense) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Expense Breakdown',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: _C.text1,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 12),
          _breakdownRow('Toll charges', toll, Icons.toll_rounded),
          _breakdownRow('Repair charges', repair, Icons.build_rounded),
          _breakdownRow('Driver charges', driver, Icons.payments_rounded),
          _breakdownRow('Maintenance', maintenance, Icons.handyman_rounded),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: _C.divider),
          ),
          Row(
            children: [
              const Text(
                'Total expense',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: _C.text1,
                ),
              ),
              const Spacer(),
              Text(
                widget.fmt(expense),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: _C.orange,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _breakdownRow(String label, double value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: _C.orange.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: _C.orange),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: _C.text2,
              ),
            ),
          ),
          Text(
            widget.fmt(value),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: _C.text1,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

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

// ════════════════════════════════════════════════════════════════════════════
// TAB 3 — OVERVIEW
// Vehicle specs that used to live in the header stats strip — capacity,
// mileage, fuel — plus the rest of the vehicle's identity, in a clean card.
// ════════════════════════════════════════════════════════════════════════════
class _OverviewTab extends StatelessWidget {
  final Vehicles vehicle;
  const _OverviewTab({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    final v = vehicle;
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        _specCard(
          title: 'Specifications',
          rows: [
            _SpecRow(
              Icons.people_rounded,
              'Seating Capacity',
              v.capacity != null ? '${v.capacity} seats' : '--',
            ),
            _SpecRow(
              Icons.speed_rounded,
              'Mileage',
              v.mileage != null ? '${v.mileage} km / l' : '--',
            ),
            _SpecRow(
              Icons.local_gas_station_rounded,
              'Fuel Type',
              v.FuelType ?? '--',
            ),
          ],
        ),
        const SizedBox(height: 14),
        _specCard(
          title: 'Vehicle Details',
          rows: [
            _SpecRow(Icons.directions_car_rounded, 'Name', v.name ?? '--'),
            _SpecRow(Icons.pin_rounded, 'Registration', v.number ?? '--'),
            _SpecRow(Icons.category_rounded, 'Type', v.Type ?? '--'),
            if (v.perKmCharge != null)
              _SpecRow(
                Icons.route_rounded,
                'Per-km Charge',
                '₹ ${v.perKmCharge!.toStringAsFixed(0)}',
              ),
            _SpecRow(
              Icons.verified_rounded,
              'Status',
              v.StatusName ?? '--',
            ),
          ],
        ),
      ],
    );
  }

  Widget _specCard({required String title, required List<_SpecRow> rows}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: _C.text1,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 6),
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: _C.divider),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AppColors.brandPrimaryLight,
                          AppColors.brandPrimary,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(rows[i].icon, size: 16, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      rows[i].label,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: _C.text2,
                      ),
                    ),
                  ),
                  Text(
                    rows[i].value,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: _C.text1,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SpecRow {
  final IconData icon;
  final String label;
  final String value;
  const _SpecRow(this.icon, this.label, this.value);
}