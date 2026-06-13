import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:travel_agency_app/Screens/trip_card.dart';
import 'package:travel_agency_app/Screens/add_vehicle.dart';
import 'package:travel_agency_app/core/network/error_messages.dart';
import 'package:travel_agency_app/core/storage/constant.dart';
import 'package:travel_agency_app/core/theme/app_colors.dart';
import 'package:travel_agency_app/core/utils/vehicle_report_export.dart';
import 'package:travel_agency_app/core/widgets/error_view.dart';
import 'package:travel_agency_app/core/widgets/skeleton.dart';
import 'package:travel_agency_app/core/widgets/trip_filter.dart';
import 'package:travel_agency_app/domain/models/booking_info.dart';
import 'package:travel_agency_app/domain/models/ledger_entry.dart';
import 'package:travel_agency_app/domain/models/services.dart';
import 'package:travel_agency_app/domain/models/vehicles.dart';
import 'package:travel_agency_app/presentation/providers/viewmodel_provider.dart';

// ── Premium Token System ───────────────────────────────────────────────────
abstract class _C {
  static const bg = Color(0xFFF0F4FF);
  static const surface = Color(0xFFFFFFFF);
  static const accent = AppColors.brandPrimary;
  static const green = Color(0xFF059669);
  static const greenSoft = Color(0xFFD1FAE5);
  static const orange = Color(0xFFEA580C);
  static const orangeSoft = Color(0xFFFEF3C7);
  static const red = Color(0xFFEF4444);
  static const text1 = Color(0xFF0F1224);
  static const text2 = Color(0xFF6B7280);
  static const text3 = Color(0xFFA3ABBD);
  static const divider = Color(0xFFE5E7F0);
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

  // ── Derived Animations ─────────────────────────────────────────────────
  late final Animation<double> _headerFade;
  late final Animation<Offset> _headerSlide;
  late final Animation<double> _avatarScale;
  late final Animation<double> _avatarRotate;
  late final Animation<double> _fabScale;

  // Shared date filter — driven from the Revenue / Expense tab date button and
  // reflected in the P&L summary above the tabs.
  TripDateRange _range = TripDateRange.all;
  DateTimeRange? _customRange;

  // True while a PDF/Excel report is being generated for this vehicle.
  bool _exporting = false;

  @override
  void initState() {
    super.initState();

    _currentStatus = widget.vehicle.StatusId ?? 1;

    _tab = TabController(length: 5, vsync: this)..addListener(_onTabChanged);

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
    // The "Add Service" FAB belongs to the Maintenance tab (index 4).
    if (_tab.index == 4) {
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
    super.dispose();
  }

  String _fmt(double v) {
    if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '₹${(v / 1000).toStringAsFixed(1)}K';
    return '₹${v.toStringAsFixed(0)}';
  }

  // ── Report export (this vehicle only) ─────────────────────────────────────
  /// Concrete from–to label for the active [_range], mirroring
  /// [TripDateRange.matches] so the document header matches what's on screen.
  String _rangeLabel(DateTime now) {
    final fmt = DateFormat('dd MMM yyyy');
    final today = DateTime(now.year, now.month, now.day);
    switch (_range) {
      case TripDateRange.all:
        return 'All time';
      case TripDateRange.today:
        return fmt.format(today);
      case TripDateRange.week:
        return '${fmt.format(today.subtract(const Duration(days: 6)))} - '
            '${fmt.format(today)}';
      case TripDateRange.month:
        return '${fmt.format(today.subtract(const Duration(days: 29)))} - '
            '${fmt.format(today)}';
      case TripDateRange.custom:
        final c = _customRange;
        if (c == null) return 'All time';
        return '${fmt.format(c.start)} - ${fmt.format(c.end)}';
    }
  }

  /// Builds a single-vehicle [ReportSnapshot] from the loaded trips/services,
  /// filtered to the active period, then runs the shared export flow.
  Future<void> _exportReport() async {
    if (_exporting) return;
    final state = ref.read(addVehicleViewModelProvider);
    final trips = state.fetchTripsByVehicleId.asData?.value ?? const <BookingInfo>[];
    final services =
        state.fetchServiceRecords.asData?.value ?? const <Services>[];
    final now = DateTime.now();

    final periodTrips = trips
        .where((t) =>
            _range.matches(tripSortKey(t), now, customRange: _customRange))
        .toList()
      ..sort((a, b) => (tripSortKey(b) ?? DateTime(0))
          .compareTo(tripSortKey(a) ?? DateTime(0)));
    final periodServices = services
        .where((s) =>
            _range.matches(s.serviceDate, now, customRange: _customRange))
        .toList()
      ..sort((a, b) => (b.serviceDate ?? DateTime(0))
          .compareTo(a.serviceDate ?? DateTime(0)));

    // Headline figures from the agency ledger (same source as the on-screen
    // P&L summary): revenue on payment date, expense on trip/service date.
    final agencyId = ref.read(loginViewModelProvider).agencyId ?? '';
    final ledger =
        ref.read(vehicleReportLedgerProvider(agencyId)).asData?.value ??
            const <LedgerEntry>[];
    final vid = widget.vehicle.vehicleId;
    final rows = ledger.where((e) =>
        e.vehicleId == vid &&
        _range.matches(e.entryDate, now, customRange: _customRange));
    final revenue = rows
        .where((e) => e.isPayment)
        .fold<double>(0, (s, e) => s + (e.revenue ?? 0));
    final tripExpense = rows
        .where((e) => e.isTripExpense)
        .fold<double>(0, (s, e) => s + (e.tripExpense ?? 0));
    final maintenance = rows
        .where((e) => e.isMaintenance)
        .fold<double>(0, (s, e) => s + (e.maintenance ?? 0));

    final stat = VehicleStat(
      vehicle: widget.vehicle,
      revenue: revenue,
      tripExpense: tripExpense,
      maintenanceExpense: maintenance,
      tripCount: periodTrips.length,
      trips: periodTrips,
      services: periodServices,
    );
    final snap = ReportSnapshot(
      title: '${widget.vehicle.name ?? 'Vehicle'} Report',
      periodLabel: _range.label,
      dateRangeLabel: _rangeLabel(now),
      stats: [stat],
      totalRevenue: revenue,
      totalExpense: stat.expense,
      activeVehicles: stat.hasActivity ? 1 : 0,
      totalVehicles: 1,
      tripCount: periodTrips.length,
    );

    setState(() => _exporting = true);
    await runVehicleReportExport(context, snap);
    if (mounted) setState(() => _exporting = false);
  }

  // ── P&L SUMMARY (period chips + net profit/loss hero) ─────────────────────
  Widget _buildPnlSummary() {
    final tripsAsync = ref.watch(
      addVehicleViewModelProvider.select((s) => s.fetchTripsByVehicleId),
    );
    final trips = tripsAsync.asData?.value ?? const <BookingInfo>[];
    final now = DateTime.now();

    // Per-vehicle money comes from the agency ledger (fetched once, shared with
    // the Vehicle Report) so the numbers match the report exactly: revenue is
    // recognised on the payment date, trip expense / maintenance on their own
    // dates. Filtered here to this vehicle + the active period.
    final agencyId = ref.watch(loginViewModelProvider).agencyId ?? '';
    final ledger =
        ref.watch(vehicleReportLedgerProvider(agencyId)).asData?.value ??
            const <LedgerEntry>[];
    final vid = widget.vehicle.vehicleId;
    final rows = ledger.where((e) =>
        e.vehicleId == vid &&
        _range.matches(e.entryDate, now, customRange: _customRange));
    final revenue = rows
        .where((e) => e.isPayment)
        .fold<double>(0, (s, e) => s + (e.revenue ?? 0));
    final tripExpense = rows
        .where((e) => e.isTripExpense)
        .fold<double>(0, (s, e) => s + (e.tripExpense ?? 0));
    final maintenance = rows
        .where((e) => e.isMaintenance)
        .fold<double>(0, (s, e) => s + (e.maintenance ?? 0));
    final expense = tripExpense + maintenance;
    final net = revenue - expense;
    final isProfit = net >= 0;
    final margin = revenue > 0 ? (net / revenue * 100) : 0.0;

    // Trip count + unpaid count still come from the trip list — the ledger
    // doesn't carry each trip's approved-vs-received balance. Bucketed by the
    // trip's own date (start → booking → end), matching the trip list.
    final periodTrips = trips.where((t) {
      final d = tripSortKey(t);
      return _range.matches(d, now, customRange: _customRange);
    }).toList();
    final unpaidCount = periodTrips
        .where((t) => (t.amountApprove ?? 0) > (t.amountReceived ?? 0))
        .length;

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
              color: AppColors.brandHeader,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.brandHeader.withOpacity(0.30),
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
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    final topPad = MediaQuery.of(context).padding.top;

    // Built here (not lazily in the sliver callback) so the ref.watch inside
    // registers as a dependency of this build.
    final pnlSummary = _buildPnlSummary();

    return Scaffold(
      backgroundColor: _C.bg,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          // Compact white identity bar pinned at the top, matching the
          // customer / driver history pages.
          SliverPersistentHeader(
            pinned: true,
            delegate: _StickyHeaderDelegate(
              height: topPad + 76,
              child: _buildHeader(),
            ),
          ),
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
              range: _range,
              customRange: _customRange,
              onRangeChanged: (r, c) => setState(() {
                _range = r;
                _customRange = c;
              }),
            ),
            _TxnTab(
              vehicle: widget.vehicle,
              kind: _TxnKind.revenue,
              range: _range,
              customRange: _customRange,
              onRangeChanged: (r, c) => setState(() {
                _range = r;
                _customRange = c;
              }),
            ),
            _TxnTab(
              vehicle: widget.vehicle,
              kind: _TxnKind.expense,
              range: _range,
              customRange: _customRange,
              onRangeChanged: (r, c) => setState(() {
                _range = r;
                _customRange = c;
              }),
            ),
            _MaintTab(
              vehicle: widget.vehicle,
              fmt: _fmt,
              range: _range,
              customRange: _customRange,
              onRangeChanged: (r, c) => setState(() {
                _range = r;
                _customRange = c;
              }),
              // FIX: pass null for new service, pass existing service for edit
              onEditService: (service) => _showAddServiceSheet(context, service),
            ),
          ],
        ),
      ),
      floatingActionButton: _fab(),
    );
  }



  // ── IDENTITY APP BAR ──────────────────────────────────────────────
  // Compact white bar (back · avatar · name/registration · status · edit),
  // pinned at the top — same style as the customer / driver history pages.
  Widget _buildHeader() {
    final top = MediaQuery.of(context).padding.top;
    final hasNumber =
        widget.vehicle.number != null && widget.vehicle.number!.trim().isNotEmpty;

    return Container(
      padding: EdgeInsets.fromLTRB(12, top + 8, 12, 10),
      decoration: BoxDecoration(
        color: _C.surface,
        border: const Border(bottom: BorderSide(color: _C.divider)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: FadeTransition(
        opacity: _headerFade,
        child: Row(
          children: [
            _navIconButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(width: 10),
            AnimatedBuilder(
              animation: _avatarAnim,
              builder: (_, child) => Transform.rotate(
                angle: _avatarRotate.value,
                child: Transform.scale(scale: _avatarScale.value, child: child),
              ),
              child: _smallAvatar(),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SlideTransition(
                position: _headerSlide,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.vehicle.name ?? 'Unknown Vehicle',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _C.text1,
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        if (hasNumber) ...[
                          const Icon(Icons.pin_outlined,
                              size: 12, color: _C.text2),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              widget.vehicle.number!.trim(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _C.text2,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Export this vehicle's report (PDF / Excel) for the active period.
            _exporting
                ? Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.brandSoft,
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(color: _C.divider, width: 1.2),
                    ),
                    padding: const EdgeInsets.all(10),
                    child: const CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation(_C.accent),
                    ),
                  )
                : _navIconButton(
                    icon: Icons.ios_share_rounded,
                    iconColor: _C.accent,
                    bgColor: AppColors.brandSoft,
                    onTap: _exportReport,
                  ),
            const SizedBox(width: 8),
            _navIconButton(
              icon: Icons.edit_rounded,
              iconColor: _C.accent,
              bgColor: AppColors.brandSoft,
              onTap: () async {
                final r = await Navigator.push(
                  context,
                  _slidePageRoute(
                    AddVehiclePage(vehicle: widget.vehicle, isEdit: true),
                  ),
                );
                if (r == true && mounted) setState(() {});
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _smallAvatar() {
    // Status dot mirrors the vehicle list: green = available, orange = engaged.
    final isEngaged = _currentStatus == 2;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: AppColors.brandPrimary,
          ),
          child: const Icon(
            Icons.directions_car_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
        Positioned(
          right: -2,
          bottom: -2,
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: isEngaged ? _C.orange : _C.green,
              shape: BoxShape.circle,
              border: Border.all(color: _C.surface, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _navIconButton({
    required IconData icon,
    required VoidCallback onTap,
    Color? iconColor,
    Color? bgColor,
  }) =>
      Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(11),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: bgColor ?? _C.bg,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: _C.divider, width: 1.2),
            ),
            child: Icon(icon, color: iconColor ?? _C.text1, size: 16),
          ),
        ),
      );

  // ── FAB ───────────────────────────────────────────────────────────
  Widget? _fab() {
    return ScaleTransition(
      scale: _fabScale,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AppColors.brandPrimary,
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
                    color: AppColors.surface,
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
            color: AppColors.brandPrimary,
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

  static const _labels = ['Overview', 'Trips', 'Revenue', 'Expense', 'Maintenance'];
  static const _icons = [
    Icons.dashboard_rounded,
    Icons.route_rounded,
    Icons.south_west_rounded,
    Icons.north_east_rounded,
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
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      dividerColor: Colors.transparent,
      indicator: BoxDecoration(
        color: AppColors.brandPrimary,
        borderRadius: BorderRadius.circular(8),
      ),
      indicatorSize: TabBarIndicatorSize.tab,
      indicatorPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
      labelColor: Colors.white,
      unselectedLabelColor: _C.text2,
      labelPadding: const EdgeInsets.symmetric(horizontal: 6),
      labelStyle: const TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.1,
      ),
      unselectedLabelStyle: const TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w500,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      tabs: List.generate(
        _labels.length,
        (i) => Tab(
          height: 50,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_icons[i], size: 13),
                const SizedBox(width: 4),
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
  final TripDateRange range;
  final DateTimeRange? customRange;
  final void Function(TripDateRange range, DateTimeRange? customRange)
      onRangeChanged;
  const _TripsTab({
    required this.vehicle,
    required this.fmt,
    required this.range,
    required this.customRange,
    required this.onRangeChanged,
  });

  @override
  ConsumerState<_TripsTab> createState() => _TripsTabState();
}

class _TripsTabState extends ConsumerState<_TripsTab> {
  _VehicleTripFilter _filter = _VehicleTripFilter.all;

  // Status dropdown + date filter (from the parent) + search toggle, mirroring
  // TripPage / CustomerHist / DriverHistory.
  static const Duration _searchDebounce = Duration(milliseconds: 250);
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  Timer? _debounceTimer;
  bool _searchVisible = false;
  String _query = '';

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
  void dispose() {
    _debounceTimer?.cancel();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_searchDebounce, () {
      if (!mounted) return;
      final normalized = value.trim().toLowerCase();
      if (normalized == _query) return;
      setState(() => _query = normalized);
    });
  }

  void _toggleSearch() {
    setState(() {
      _searchVisible = !_searchVisible;
      if (!_searchVisible) {
        _debounceTimer?.cancel();
        _searchCtrl.clear();
        _query = '';
        _searchFocus.unfocus();
      }
    });
    if (_searchVisible) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _searchFocus.requestFocus();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addVehicleViewModelProvider).fetchTripsByVehicleId;

    return state.when(
      loading: () => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
        children: const [
          TripCardSkeleton(),
          TripCardSkeleton(),
          TripCardSkeleton(),
          TripCardSkeleton(),
        ],
      ),
      error: (e, _) => NetworkErrorView(
        error: e,
        onRetry: () async => ref
            .read(addVehicleViewModelProvider.notifier)
            .getTripsByVehicle(widget.vehicle.vehicleId ?? 0),
      ),
      data: (allTrips) {
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

        // Date range + search narrow the list first; the status dropdown then
        // operates on what remains. Period membership uses the same agency
        // ledger as the P&L summary so the list and summary always agree on
        // which trips fall in the window. Falls back to the trip date if the
        // ledger hasn't loaded.
        final now = DateTime.now();
        final agencyId = ref.watch(loginViewModelProvider).agencyId ?? '';
        final ledger =
            ref.watch(vehicleReportLedgerProvider(agencyId)).asData?.value ??
                const <LedgerEntry>[];
        final ledgerLoaded = ledger.isNotEmpty;
        final vid = widget.vehicle.vehicleId;
        final inPeriodIds = ledger
            .where((e) =>
                e.vehicleId == vid &&
                widget.range
                    .matches(e.entryDate, now, customRange: widget.customRange))
            .map((e) => e.tripId)
            .whereType<int>()
            .toSet();
        final base = allTrips.where((t) {
          final inPeriod = ledgerLoaded
              ? inPeriodIds.contains(t.tripId)
              : widget.range
                  .matches(tripSortKey(t), now, customRange: widget.customRange);
          return inPeriod && tripMatchesQuery(t, _query);
        }).toList();
        final filtered = base.where((t) => _filter.matches(t)).toList();

        return Column(
          children: [
            _buildFilterRow(),
            Expanded(
              child: filtered.isEmpty
                  ? _filteredEmptyState()
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(0, 8, 0, 100),
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

  // ── Filter row: status dropdown + date filter + search toggle ───────────
  Widget _buildFilterRow() {
    return Container(
      decoration: const BoxDecoration(
        color: _C.surface,
        border: Border(bottom: BorderSide(color: _C.divider)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        transitionBuilder: (child, anim) =>
            FadeTransition(opacity: anim, child: child),
        child: _searchVisible ? _buildSearchRow() : _buildPrimaryRow(),
      ),
    );
  }

  Widget _buildPrimaryRow() {
    return Row(
      key: const ValueKey('primary'),
      children: [
        _buildStatusDropdown(),
        const Spacer(),
        TripDateFilterButton(
          range: widget.range,
          customRange: widget.customRange,
          onChanged: widget.onRangeChanged,
        ),
        const SizedBox(width: 2),
        IconButton(
          icon: Icon(Icons.search_rounded, color: _C.text2, size: 22),
          tooltip: 'Search',
          onPressed: _toggleSearch,
        ),
      ],
    );
  }

  Widget _buildSearchRow() {
    return Row(
      key: const ValueKey('search'),
      children: [
        IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: _C.text2),
          onPressed: _toggleSearch,
        ),
        Expanded(
          child: TripSearchField(
            controller: _searchCtrl,
            focusNode: _searchFocus,
            onChanged: _onSearchChanged,
          ),
        ),
      ],
    );
  }

  // Status filter as a dropdown, styled like TripPage's status dropdown.
  Widget _buildStatusDropdown() {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.brandPrimary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<_VehicleTripFilter>(
          value: _filter,
          isDense: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.white,
            size: 20,
          ),
          dropdownColor: AppColors.brandPrimary,
          borderRadius: BorderRadius.circular(10),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          selectedItemBuilder: (context) => [
            for (final f in _VehicleTripFilter.values)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.tune_rounded, size: 15, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    'Status: ${f.label}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
          ],
          items: [
            for (final f in _VehicleTripFilter.values)
              DropdownMenuItem(
                value: f,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(f.icon, size: 16, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(f.label),
                  ],
                ),
              ),
          ],
          onChanged: (value) {
            if (value != null) setState(() => _filter = value);
          },
        ),
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
// TABS 3 & 4 — REVENUE / EXPENSE (individual money transactions)
// A flat, date-grouped list of individual money transactions for this vehicle —
// one row per payment / expense — mirroring the agency-wide Transactions page,
// scoped to this vehicle and the shared period filter. Fed by the same agency
// ledger as the P&L summary so the figures always agree.
// ════════════════════════════════════════════════════════════════════════════

/// Which side of the daybook a [_TxnTab] shows.
enum _TxnKind { revenue, expense }

class _TxnTab extends ConsumerStatefulWidget {
  final Vehicles vehicle;
  final _TxnKind kind;
  final TripDateRange range;
  final DateTimeRange? customRange;
  final void Function(TripDateRange range, DateTimeRange? customRange)
      onRangeChanged;

  const _TxnTab({
    required this.vehicle,
    required this.kind,
    required this.range,
    required this.customRange,
    required this.onRangeChanged,
  });

  @override
  ConsumerState<_TxnTab> createState() => _TxnTabState();
}

class _TxnTabState extends ConsumerState<_TxnTab> {
  bool get _isRevenue => widget.kind == _TxnKind.revenue;

  @override
  void initState() {
    super.initState();
    // Trips are needed so a transaction row can open the full (editable) trip
    // sheet; the ledger itself is loaded by the watch below (shared provider).
    Future.microtask(() {
      ref
          .read(addVehicleViewModelProvider.notifier)
          .getTripsByVehicle(widget.vehicle.vehicleId ?? 0);
    });
  }

  String _money(double v) =>
      '₹${NumberFormat.decimalPattern('en_IN').format(v.round())}';

  bool _isExpense(LedgerEntry e) => e.isTripExpense || e.isMaintenance;

  bool _matchesKind(LedgerEntry e) => _isRevenue ? e.isPayment : _isExpense(e);

  double _amount(LedgerEntry e) {
    if (e.isPayment) return e.revenue ?? 0;
    if (e.isTripExpense) return e.tripExpense ?? 0;
    if (e.isMaintenance) return e.maintenance ?? 0;
    return 0;
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// First available human label: customer → maintenance → vehicle → generic.
  String _title(LedgerEntry e) {
    if (e.customerName != null) return e.customerName!;
    if (e.isMaintenance) return 'Maintenance';
    return e.vehicleName ?? 'Trip';
  }

  Future<void> _refresh() async {
    final aid = ref.read(loginViewModelProvider).agencyId ?? '';
    if (aid.isNotEmpty) ref.invalidate(vehicleReportLedgerProvider(aid));
    await ref
        .read(addVehicleViewModelProvider.notifier)
        .getTripsByVehicle(widget.vehicle.vehicleId ?? 0);
  }

  @override
  Widget build(BuildContext context) {
    final agencyId = ref.watch(loginViewModelProvider).agencyId ?? '';
    final ledgerAsync = ref.watch(vehicleReportLedgerProvider(agencyId));

    return Column(
      children: [
        // ── Date filter (shared with the other tabs) ─────────────────────
        Container(
          decoration: const BoxDecoration(
            color: _C.surface,
            border: Border(bottom: BorderSide(color: _C.divider)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            children: [
              const Icon(Icons.calendar_month_rounded,
                  size: 16, color: _C.text2),
              const SizedBox(width: 8),
              const Text(
                'Filter by date',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _C.text2,
                ),
              ),
              const Spacer(),
              TripDateFilterButton(
                range: widget.range,
                customRange: widget.customRange,
                onChanged: widget.onRangeChanged,
              ),
            ],
          ),
        ),
        Expanded(
          child: ledgerAsync.when(
            loading: () => ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
              children: const [
                SimpleCardSkeleton(
                  padding: EdgeInsets.fromLTRB(12, 11, 10, 11),
                  borderRadius: 13,
                  leadingSize: 38,
                  titleWidth: 130,
                  subtitleWidth: 150,
                  trailingWidth: 50,
                  trailingHeight: 14,
                  trailingRadius: 6,
                ),
                SimpleCardSkeleton(
                  padding: EdgeInsets.fromLTRB(12, 11, 10, 11),
                  borderRadius: 13,
                  leadingSize: 38,
                  titleWidth: 130,
                  subtitleWidth: 150,
                  trailingWidth: 50,
                  trailingHeight: 14,
                  trailingRadius: 6,
                ),
                SimpleCardSkeleton(
                  padding: EdgeInsets.fromLTRB(12, 11, 10, 11),
                  borderRadius: 13,
                  leadingSize: 38,
                  titleWidth: 130,
                  subtitleWidth: 150,
                  trailingWidth: 50,
                  trailingHeight: 14,
                  trailingRadius: 6,
                ),
              ],
            ),
            error: (e, _) => NetworkErrorView(error: e, onRetry: _refresh),
            data: (ledger) => _buildList(ledger),
          ),
        ),
      ],
    );
  }

  Widget _buildList(List<LedgerEntry> ledger) {
    final now = DateTime.now();
    final vid = widget.vehicle.vehicleId;
    final rows = ledger
        .where((e) =>
            e.vehicleId == vid &&
            _amount(e) > 0 &&
            _matchesKind(e) &&
            widget.range
                .matches(e.entryDate, now, customRange: widget.customRange))
        .toList()
      ..sort((a, b) =>
          (b.entryDate ?? DateTime(0)).compareTo(a.entryDate ?? DateTime(0)));

    if (rows.isEmpty) return _emptyState();

    final amountColor = _isRevenue ? _C.green : _C.red;

    return RefreshIndicator(
      color: _C.accent,
      backgroundColor: _C.surface,
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
        children: _daySections(rows, amountColor),
      ),
    );
  }

  // ── Day-grouped rows ───────────────────────────────────────────────────
  List<Widget> _daySections(List<LedgerEntry> rows, Color amountColor) {
    final groups = <({DateTime? day, List<LedgerEntry> items})>[];
    for (final e in rows) {
      final d = e.entryDate == null
          ? null
          : DateTime(e.entryDate!.year, e.entryDate!.month, e.entryDate!.day);
      if (groups.isEmpty ||
          (groups.last.day == null) != (d == null) ||
          (groups.last.day != null &&
              d != null &&
              !_sameDay(groups.last.day!, d))) {
        groups.add((day: d, items: <LedgerEntry>[e]));
      } else {
        groups.last.items.add(e);
      }
    }

    final widgets = <Widget>[];
    for (final g in groups) {
      widgets.add(
        _dayHeader(g.day, g.items.fold<double>(0, (s, e) => s + _amount(e))),
      );
      widgets.add(const SizedBox(height: 8));
      for (final e in g.items) {
        widgets.add(_row(e, amountColor));
      }
      widgets.add(const SizedBox(height: 6));
    }
    return widgets;
  }

  Widget _dayHeader(DateTime? day, double subtotal) {
    final label = day == null ? 'Undated' : _dayLabel(day);
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 4, 2, 0),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: _C.text2,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Container(height: 1, color: _C.divider)),
          const SizedBox(width: 8),
          Text(
            _money(subtotal),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _C.text3,
            ),
          ),
        ],
      ),
    );
  }

  String _dayLabel(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(DateTime(d.year, d.month, d.day)).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return DateFormat('EEE, dd MMM').format(d);
  }

  Widget _row(LedgerEntry e, Color amountColor) {
    final leadingColor =
        e.isMaintenance ? _C.orange : (_isRevenue ? _C.green : _C.orange);
    final leadingBg = e.isMaintenance
        ? _C.orangeSoft
        : (_isRevenue ? _C.greenSoft : _C.orangeSoft);
    final leadingIcon = e.isMaintenance
        ? Icons.build_rounded
        : (_isRevenue ? Icons.south_west_rounded : Icons.north_east_rounded);

    final hasRoute = e.pickup != null && e.drop != null;

    final chips = <Widget>[
      if (e.vehicleNumber != null)
        _metaChip(Icons.directions_car_rounded, e.vehicleNumber!, _C.text2),
      if (_isRevenue && e.paymentMode != null)
        _metaChip(
            Icons.account_balance_wallet_rounded, e.paymentMode!, _C.accent),
      if (!_isRevenue)
        _metaChip(
          e.isMaintenance
              ? Icons.build_rounded
              : Icons.local_gas_station_rounded,
          e.isMaintenance ? 'Maintenance' : 'Trip expense',
          _C.orange,
        ),
    ];

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _openTxnSheet(e),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.fromLTRB(12, 11, 10, 11),
        decoration: BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: _C.divider),
          boxShadow: [
            BoxShadow(
              color: _C.accent.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: leadingBg,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(leadingIcon, size: 18, color: leadingColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Line 1: name + amount ──────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          _title(e),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: _C.text1,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _money(_amount(e)),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: amountColor,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                  // ── Line 2: route ──────────────────────────────────
                  if (hasRoute) ...[
                    const SizedBox(height: 5),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 1),
                          child: Icon(Icons.alt_route_rounded,
                              size: 13, color: _C.text3),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            '${e.pickup} → ${e.drop}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _C.text2,
                              height: 1.25,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  // ── Line 3: meta chips ─────────────────────────────
                  if (chips.isNotEmpty) ...[
                    const SizedBox(height: 7),
                    Wrap(spacing: 6, runSpacing: 6, children: chips),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded, size: 18, color: _C.text3),
          ],
        ),
      ),
    );
  }

  Widget _metaChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  // ── Tap dispatch ───────────────────────────────────────────────────────
  /// Trip-backed rows open the full (editable) trip sheet from [TripCard];
  /// maintenance / no-trip rows fall back to a read-only ledger sheet.
  void _openTxnSheet(LedgerEntry e) {
    final tripId = e.tripId;
    if (tripId == null) {
      _openLedgerSheet(e);
      return;
    }
    final trips = ref.read(addVehicleViewModelProvider).fetchTripsByVehicleId
            .asData
            ?.value ??
        const <BookingInfo>[];
    BookingInfo? trip;
    for (final t in trips) {
      if (t.tripId == tripId) {
        trip = t;
        break;
      }
    }
    if (trip == null) {
      _openLedgerSheet(e);
      return;
    }
    TripCard(
      bookinginfo: trip,
      status: trip.status ?? 0,
      onTripUpdated: () async => _refresh(),
    ).showDetailSheet(context, ref);
  }

  // ── Read-only ledger sheet (maintenance / no-trip rows) ────────────────
  void _openLedgerSheet(LedgerEntry e) {
    final isRevenue = e.isPayment;
    final amtColor =
        e.isMaintenance ? _C.orange : (isRevenue ? _C.green : _C.red);
    final amtBg = e.isMaintenance
        ? _C.orangeSoft
        : (isRevenue ? _C.greenSoft : const Color(0xFFFEE2E2));
    final kindLabel = isRevenue
        ? 'Payment received'
        : (e.isMaintenance ? 'Maintenance' : 'Trip expense');
    final leadIcon = e.isMaintenance
        ? Icons.build_rounded
        : (isRevenue ? Icons.south_west_rounded : Icons.north_east_rounded);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.82,
          ),
          decoration: const BoxDecoration(
            color: _C.bg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: _C.text3.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: amtBg,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(leadIcon, size: 19, color: amtColor),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _title(e),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: _C.text1,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            kindLabel,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: _C.text2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close_rounded,
                          size: 20, color: _C.text2),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  children: [
                    _sheetAmountTile(e, amtColor, amtBg, kindLabel),
                    const SizedBox(height: 12),
                    _sheetDetailCard(e),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sheetAmountTile(
      LedgerEntry e, Color color, Color bg, String kindLabel) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            kindLabel,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _money(_amount(e)),
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: -0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sheetDetailCard(LedgerEntry e) {
    final rows = <Widget>[];
    void add(IconData icon, String label, String? value) {
      if (value == null || value.isEmpty) return;
      if (rows.isNotEmpty) {
        rows.add(const Divider(height: 16, color: _C.divider));
      }
      rows.add(_sheetDetailRow(icon, label, value));
    }

    add(Icons.person_outline_rounded, 'Customer', e.customerName);
    if (e.pickup != null && e.drop != null) {
      add(Icons.route_rounded, 'Route', '${e.pickup} → ${e.drop}');
    }
    add(Icons.directions_car_outlined, 'Vehicle',
        [e.vehicleName, e.vehicleNumber].where((s) => s != null).join(' · '));
    add(
        Icons.event_rounded,
        'Date',
        e.entryDate == null
            ? null
            : DateFormat('dd MMM yyyy').format(e.entryDate!));
    if (e.isPayment) {
      add(Icons.payment_rounded, 'Payment mode', e.paymentMode);
    }

    if (rows.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.divider),
      ),
      child: Column(children: rows),
    );
  }

  Widget _sheetDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: _C.text3),
        const SizedBox(width: 10),
        SizedBox(
          width: 84,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _C.text2,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: _C.text1,
            ),
          ),
        ),
      ],
    );
  }

  // ── Empty state (keeps the date filter visible above) ──────────────────
  Widget _emptyState() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: _isRevenue ? _C.greenSoft : _C.orangeSoft,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isRevenue
                            ? Icons.account_balance_wallet_outlined
                            : Icons.payments_outlined,
                        size: 32,
                        color: _isRevenue ? _C.green : _C.orange,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _isRevenue
                          ? 'No payments in this period'
                          : 'No expenses in this period',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: _C.text1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _isRevenue
                          ? 'Payments received will appear here.'
                          : 'Trip expenses and maintenance will appear here.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        color: _C.text2,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// TAB 4 — MAINTENANCE
// Maintenance service records (add / edit / delete).
// ════════════════════════════════════════════════════════════════════════════
class _MaintTab extends ConsumerStatefulWidget {
  final Vehicles vehicle;
  final String Function(double) fmt;
  final TripDateRange range;
  final DateTimeRange? customRange;
  final void Function(TripDateRange range, DateTimeRange? customRange)
      onRangeChanged;
  // FIX: callback now receives a Services object for edit, called with null for add
  final void Function(Services? service) onEditService;

  const _MaintTab({
    required this.vehicle,
    required this.fmt,
    required this.range,
    required this.customRange,
    required this.onRangeChanged,
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
      ref.read(addVehicleViewModelProvider.notifier).getServiceRecords(
            ref.read(loginViewModelProvider).agencyId ?? '',
            widget.vehicle.vehicleId ?? 0,
          );
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
    final now = DateTime.now();

    return Column(
      children: [
        // ── Date filter ──────────────────────────────────────────────────
        Container(
          decoration: const BoxDecoration(
            color: _C.surface,
            border: Border(bottom: BorderSide(color: _C.divider)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            children: [
              const Icon(Icons.calendar_month_rounded,
                  size: 16, color: _C.text2),
              const SizedBox(width: 8),
              const Text(
                'Filter by date',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _C.text2,
                ),
              ),
              const Spacer(),
              TripDateFilterButton(
                range: widget.range,
                customRange: widget.customRange,
                onChanged: widget.onRangeChanged,
              ),
            ],
          ),
        ),

        Expanded(
          child: serviceAsync.when(
            loading: () => ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
              children: const [
                SimpleCardSkeleton(
                  margin: EdgeInsets.symmetric(vertical: 5),
                  padding: EdgeInsets.all(16),
                  titleWidth: 150,
                  subtitleWidth: 110,
                  trailingWidth: 16,
                  trailingHeight: 16,
                  trailingRadius: 4,
                ),
                SimpleCardSkeleton(
                  margin: EdgeInsets.symmetric(vertical: 5),
                  padding: EdgeInsets.all(16),
                  titleWidth: 150,
                  subtitleWidth: 110,
                  trailingWidth: 16,
                  trailingHeight: 16,
                  trailingRadius: 4,
                ),
                SimpleCardSkeleton(
                  margin: EdgeInsets.symmetric(vertical: 5),
                  padding: EdgeInsets.all(16),
                  titleWidth: 150,
                  subtitleWidth: 110,
                  trailingWidth: 16,
                  trailingHeight: 16,
                  trailingRadius: 4,
                ),
              ],
            ),
            error: (e, _) => NetworkErrorView(
              error: e,
              onRetry: () async {
                final notifier =
                    ref.read(addVehicleViewModelProvider.notifier);
                await notifier.getServiceRecords(
                  ref.read(loginViewModelProvider).agencyId ?? '',
                  widget.vehicle.vehicleId ?? 0,
                );
                await notifier
                    .getTripsByVehicle(widget.vehicle.vehicleId ?? 0);
              },
            ),
            data: (services) {
              final filteredServices = services
                  .where((s) => widget.range
                      .matches(s.serviceDate, now, customRange: widget.customRange))
                  .toList();

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
                children: [
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
                            "No maintenance for ${widget.range.label}.",
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
         const SizedBox(height: 14),
        _specCard(
          title: 'Compliance',
          rows: [
            _SpecRow(
              Icons.eco_rounded,
              'PUC Expiry',
              _expiryText(v.pucExpiry),
            ),
            _SpecRow(
              Icons.verified_user_rounded,
              'Insurance Expiry',
              _expiryText(v.insuranceExpiry),
            ),
          ],
        ),
         const SizedBox(height: 14),
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
            _SpecRow(
              Icons.route_rounded,
              'Per-km Charge',
              v.perKmCharge != null
                  ? '₹ ${v.perKmCharge!.toStringAsFixed(0)} / km'
                  : '--',
            ),
            _SpecRow(
              Icons.verified_rounded,
              'Status',
              v.StatusName ?? '--',
            ),
          ],
        ),
       
        _buildDocumentsCard(context),
      ],
    );
  }

  // Formats a compliance expiry date as "dd MMM yyyy", appending a short status
  // hint ("Expired" / "in N days") so the operator sees at a glance whether a
  // certificate needs renewing. Returns "--" when the date isn't set.
  String _expiryText(DateTime? date) {
    if (date == null) return '--';
    final formatted = DateFormat('dd MMM yyyy').format(date);
    final today = DateTime.now();
    final day = DateTime(date.year, date.month, date.day);
    final diff = day.difference(DateTime(today.year, today.month, today.day)).inDays;
    if (diff < 0) return '$formatted · Expired';
    if (diff == 0) return '$formatted · Today';
    if (diff <= 30) return '$formatted · in $diff ${diff == 1 ? 'day' : 'days'}';
    return formatted;
  }

  // ── Documents card (RC document viewer) ──────────────────────────────
  Widget _buildDocumentsCard(BuildContext context) {
    final url = _normalizeRcUrl(vehicle.rcdocuments);
    if (url == null || url.isEmpty) return const SizedBox.shrink();
    final isPdf = _isPdfUrl(url);

    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
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
            'Documents',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: _C.text1,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _openDocument(context, url),
              icon: Icon(
                isPdf
                    ? Icons.picture_as_pdf_rounded
                    : Icons.visibility_rounded,
                size: 18,
              ),
              label: const Text('View RC Document'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _C.accent,
                side: const BorderSide(color: _C.accent),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Document helpers (mirror add_vehicle.dart) ───────────────────────
  bool _isPdfUrl(String? url) {
    if (url == null || url.trim().isEmpty) return false;
    final parsed = Uri.tryParse(url.trim());
    final path = Uri.decodeFull((parsed?.path ?? url)).toLowerCase();
    return path.endsWith('.pdf');
  }

  // Turns whatever the API stored (a serialized list, a bare filename, a
  // local path, or an absolute URL) into a fully-qualified document URL.
  String? _normalizeRcUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.trim().isEmpty) return null;
    var cleaned = rawUrl.trim();

    if (cleaned.startsWith('[') && cleaned.endsWith(']')) {
      cleaned = cleaned.substring(1, cleaned.length - 1);
    }
    cleaned = cleaned.replaceAll('"', '').replaceAll("'", '').trim();
    if (cleaned.contains(',')) {
      cleaned = cleaned
          .split(',')
          .map((e) => e.trim())
          .firstWhere((e) => e.isNotEmpty, orElse: () => cleaned);
    }

    cleaned = Uri.decodeFull(cleaned).replaceAll('\\', '/');

    if (cleaned.startsWith('http://') || cleaned.startsWith('https://')) {
      return cleaned;
    }

    final isFileNameOnly = !cleaned.contains('/') &&
        RegExp(r'\.(jpg|jpeg|png|webp|heic|pdf)$', caseSensitive: false)
            .hasMatch(cleaned);

    final uploadsIdx = cleaned.toLowerCase().indexOf('uploads/');
    if (uploadsIdx != -1) {
      cleaned = cleaned.substring(uploadsIdx);
    }
    if (cleaned.startsWith('./')) cleaned = cleaned.substring(2);

    final base = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;

    if (isFileNameOnly) return '$base/uploads/VehicleDocuments/$cleaned';
    if (cleaned.startsWith('/')) return '$base$cleaned';
    return '$base/$cleaned';
  }

  Future<void> _openDocument(BuildContext context, String url) async {
    // PDFs open in an external viewer/browser; images open fullscreen in-app.
    if (_isPdfUrl(url)) {
      final uri = Uri.tryParse(url);
      if (uri == null) {
        _snack(context, 'Invalid document URL');
        return;
      }
      final launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        final retry = await launchUrl(uri, mode: LaunchMode.platformDefault);
        if (!retry && context.mounted) {
          _snack(context, 'Could not open document');
        }
      }
      return;
    }
    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _FullscreenImagePage(networkUrl: url)),
    );
  }

  void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade600),
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
                      color: AppColors.brandPrimary,
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

/// Fixed-height pinned sliver header used to keep the vehicle identity bar
/// stuck to the top while the P&L summary and tabs scroll.
class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  _StickyHeaderDelegate({required this.height, required this.child});

  final double height;
  final Widget child;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) =>
      SizedBox.expand(child: child);

  @override
  bool shouldRebuild(covariant _StickyHeaderDelegate oldDelegate) =>
      oldDelegate.height != height || oldDelegate.child != child;
}

// ── Fullscreen image viewer (RC document images) ────────────────────────────
class _FullscreenImagePage extends StatelessWidget {
  final String networkUrl;

  const _FullscreenImagePage({required this.networkUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4,
          child: Image.network(
            networkUrl,
            fit: BoxFit.contain,
            headers: const {'Cache-Control': 'no-cache'},
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return const CircularProgressIndicator(color: Colors.white);
            },
            errorBuilder: (_, __, ___) => const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.broken_image_rounded,
                    color: Colors.white54, size: 48),
                SizedBox(height: 12),
                Text(
                  'Could not load document',
                  style: TextStyle(color: Colors.white54),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
