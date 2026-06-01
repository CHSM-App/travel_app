import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_agency_app/core/network/error_messages.dart';
import 'package:travel_agency_app/core/theme/app_colors.dart';
import 'package:travel_agency_app/domain/models/booking_info.dart';
import 'package:travel_agency_app/domain/models/services.dart';
import 'package:travel_agency_app/domain/models/vehicles.dart';
import 'package:travel_agency_app/domain/viewModel/trippage_viewmodel.dart';
import 'package:travel_agency_app/presentation/providers/usecase_provider.dart';
import 'package:travel_agency_app/presentation/providers/viewmodel_provider.dart';

// ─── Design tokens ─────────────────────────────────────────────────────────
class _C {
  static const bg = Color(0xFFF5F7FB);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceLight = Color(0xFFF1F4FA);
  static const accent = AppColors.brandPrimary;
  static const accentLight = AppColors.brandPrimaryLight;
  static const accentDark = AppColors.brandPrimaryDark;
  static const accentSoft = AppColors.brandSoft;
  static const text1 = Color(0xFF0F1729);
  static const text2 = Color(0xFF6B7280);
  static const text3 = Color(0xFFA3ABBD);
  static const divider = Color(0xFFE6EAF2);
  static const dividerLight = Color(0xFFF1F4F9);
  static const green = Color(0xFF10B981);
  static const greenSoft = Color(0xFFD1FAE5);
  static const red = Color(0xFFEF4444);
  static const redSoft = Color(0xFFFEE2E2);
  static const bloodRed = Color(0xFF8B0000);
  static const orange = Color(0xFFF59E0B);
  static const orangeSoft = Color(0xFFFEF3C7);
  static const gold = Color(0xFFD4AF37);
}

/// Date-window filter applied to the trip ledger. Defaults to "This Month"
/// because that's the cadence the operator naturally thinks about money in.
enum VehicleReportPeriod { all, today, week, month }

extension on VehicleReportPeriod {
  String get label {
    switch (this) {
      case VehicleReportPeriod.all:
        return 'All';
      case VehicleReportPeriod.today:
        return 'Today';
      case VehicleReportPeriod.week:
        return 'Week';
      case VehicleReportPeriod.month:
        return 'Month';
    }
  }

  IconData get icon {
    switch (this) {
      case VehicleReportPeriod.all:
        return Icons.all_inclusive_rounded;
      case VehicleReportPeriod.today:
        return Icons.today_rounded;
      case VehicleReportPeriod.week:
        return Icons.view_week_rounded;
      case VehicleReportPeriod.month:
        return Icons.calendar_month_rounded;
    }
  }

  bool matches(DateTime? d, DateTime now) {
    if (this == VehicleReportPeriod.all) return true;
    if (d == null) return false;
    final dOnly = DateTime(d.year, d.month, d.day);
    final today = DateTime(now.year, now.month, now.day);
    switch (this) {
      case VehicleReportPeriod.today:
        return dOnly == today;
      case VehicleReportPeriod.week:
        final start = today.subtract(const Duration(days: 6));
        return !dOnly.isBefore(start) && !dOnly.isAfter(today);
      case VehicleReportPeriod.month:
        return d.year == now.year && d.month == now.month;
      case VehicleReportPeriod.all:
        return true;
    }
  }
}

class _VehicleStat {
  final Vehicles vehicle;
  final double revenue;
  // Expenses captured on the trip itself: toll + repairing + driver charges.
  final double tripExpense;
  // Service / maintenance costs (from the vehicle_details Maintenance tab),
  // attributed to the vehicle by serviceDate falling inside the report period.
  final double maintenanceExpense;
  final int tripCount;
  const _VehicleStat(
    this.vehicle,
    this.revenue,
    this.tripExpense,
    this.maintenanceExpense,
    this.tripCount,
  );
  double get expense => tripExpense + maintenanceExpense;
  double get net => revenue - expense;
}

class VehicleReportPage extends ConsumerStatefulWidget {
  final VehicleReportPeriod initialPeriod;

  const VehicleReportPage({
    super.key,
    this.initialPeriod = VehicleReportPeriod.month,
  });

  @override
  ConsumerState<VehicleReportPage> createState() => _VehicleReportPageState();
}

class _VehicleReportPageState extends ConsumerState<VehicleReportPage> {
  late VehicleReportPeriod _period = widget.initialPeriod;

  // Service records keyed by vehicleId. We hold the full unfiltered list and
  // apply the period filter at render time, so toggling chips is instant.
  Map<int, List<Services>> _servicesByVehicle = const {};

  @override
  void initState() {
    super.initState();
    Future.microtask(_refreshAll);
  }

  Future<void> _refreshAll() async {
    final aid = ref.read(loginViewModelProvider).agencyId ?? '';
    if (aid.isEmpty) return;
    final tn = ref.read(tripPageViewModelProvider.notifier);
    final vn = ref.read(tripBookingViewModelProvider.notifier);
    await Future.wait([
      tn.activeList(aid),
      tn.upcomingList(aid),
      tn.historyList(aid),
      tn.unpaidList(aid),
      tn.cancelledList(aid),
      vn.vehicleList(aid),
    ]);
    if (!mounted) return;
    // Services depend on the vehicle list — fetch them only after vehicles
    // are loaded so we know which vehicle ids to ask the API about.
    final vehicles =
        ref.read(tripBookingViewModelProvider).fetchVehicleList.asData?.value ??
            const <Vehicles>[];
    await _loadServices(aid, vehicles);
  }

  /// Pulls service records for every vehicle in parallel via the existing
  /// per-vehicle endpoint. Using the use case directly (not the view model)
  /// avoids overwriting the shared `fetchServiceRecords` state that the
  /// vehicle_details Maintenance tab relies on.
  Future<void> _loadServices(String agencyId, List<Vehicles> vehicles) async {
    if (agencyId.isEmpty || vehicles.isEmpty) return;
    final useCase = ref.read(addVehicleUseCaseProvider);
    final ids = vehicles
        .map((v) => v.vehicleId)
        .whereType<int>()
        .toList(growable: false);
    final results = await Future.wait(
      ids.map((id) async {
        try {
          return await useCase.getServiceRecords(agencyId, id);
        } catch (_) {
          // A single vehicle's service fetch failing shouldn't blank the
          // whole report — fall back to an empty list for that vehicle.
          return <Services>[];
        }
      }),
    );
    if (!mounted) return;
    final map = <int, List<Services>>{};
    for (var i = 0; i < ids.length; i++) {
      map[ids[i]] = results[i];
    }
    setState(() => _servicesByVehicle = map);
  }

  /// Total maintenance cost per vehicle, restricted to the current period.
  Map<int, double> _maintenanceByVehicle() {
    final now = DateTime.now();
    final out = <int, double>{};
    _servicesByVehicle.forEach((vehicleId, services) {
      double sum = 0;
      for (final s in services) {
        if (!_period.matches(s.serviceDate, now)) continue;
        sum += s.serviceCost ?? 0;
      }
      if (sum > 0) out[vehicleId] = sum;
    });
    return out;
  }

  // ── Data helpers ───────────────────────────────────────────────────
  List<BookingInfo> _getData(AsyncValue<List<BookingInfo>> v) => v.when(
        data: (r) => r,
        loading: () => const <BookingInfo>[],
        error: (_, __) => const <BookingInfo>[],
      );

  /// Pull every trip the agency has touched, deduplicated by tripId. The five
  /// lists overlap (a trip can be both "active" and "unpaid"), so we collapse
  /// on the trip key to avoid double-counting revenue or expenses.
  List<BookingInfo> _allTrips(TripPageState s) {
    final all = <BookingInfo>[
      ..._getData(s.activeList),
      ..._getData(s.upcomingList),
      ..._getData(s.historyList),
      ..._getData(s.unpaidList),
      ..._getData(s.cancelledList),
    ];
    final unique = <String, BookingInfo>{};
    for (final t in all) {
      final key = t.tripId?.toString() ??
          '${t.bookingDate?.toIso8601String() ?? ''}-${t.vehicleId ?? ''}-${t.customerId ?? ''}';
      unique[key] = t;
    }
    return unique.values.toList();
  }

  // Revenue = money actually collected, never the quoted fare. Unpaid trips
  // contribute 0 until payment is recorded.
  double _revenueOf(BookingInfo t) => t.amountReceived ?? 0.0;
  double _expenseOf(BookingInfo t) =>
      (t.tollCharges ?? 0.0) +
      (t.repairingCharges ?? 0.0) +
      (t.driverCharges ?? 0.0);

  List<_VehicleStat> _statsByVehicle(
    List<Vehicles> vehicles,
    List<BookingInfo> trips,
    Map<int, double> maintenanceByVehicle,
  ) {
    final byId = <int, _VehicleStat>{};
    // Seed every vehicle so idle vehicles still appear in the report.
    for (final v in vehicles) {
      final id = v.vehicleId;
      if (id == null) continue;
      byId[id] = _VehicleStat(v, 0, 0, maintenanceByVehicle[id] ?? 0, 0);
    }
    for (final t in trips) {
      final id = t.vehicleId;
      if (id == null) continue;
      final cur = byId[id];
      if (cur == null) continue;
      byId[id] = _VehicleStat(
        cur.vehicle,
        cur.revenue + _revenueOf(t),
        cur.tripExpense + _expenseOf(t),
        cur.maintenanceExpense,
        cur.tripCount + 1,
      );
    }
    final list = byId.values.toList();
    // Any financial activity in the period — a booked trip OR a maintenance
    // record — promotes a vehicle above truly idle ones. Within the active
    // set we sort by net desc so the most profitable surfaces first.
    bool active(_VehicleStat s) => s.tripCount > 0 || s.maintenanceExpense > 0;
    list.sort((a, b) {
      final aActive = active(a);
      final bActive = active(b);
      if (aActive != bActive) return aActive ? -1 : 1;
      if (aActive) return b.net.compareTo(a.net);
      return (a.vehicle.name ?? '').compareTo(b.vehicle.name ?? '');
    });
    return list;
  }

  /// Opens the full single-page report for one vehicle: its trips, the expense
  /// breakdown and its maintenance records — all filtered by the same period.
  void _openVehicleDetail(_VehicleStat stat) {
    final vid = stat.vehicle.vehicleId;
    final allTrips = _allTrips(ref.read(tripPageViewModelProvider));
    final vehicleTrips =
        allTrips.where((t) => t.vehicleId == vid).toList();
    final services = _servicesByVehicle[vid] ?? const <Services>[];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VehicleReportDetailPage(
          vehicle: stat.vehicle,
          trips: vehicleTrips,
          services: services,
          initialPeriod: _period,
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final tripState = ref.watch(tripPageViewModelProvider);
    final vehicleState =
        ref.watch(tripBookingViewModelProvider).fetchVehicleList;

    return Scaffold(
      backgroundColor: _C.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            _buildPeriodChips(),
            Expanded(
              child: vehicleState.when(
                loading: () => _loadingState(),
                error: (e, _) => _errorState(
                  friendlyErrorMessage(e),
                  offline: isNetworkError(e),
                ),
                data: (vehicles) {
                  if (vehicles.isEmpty) {
                    return _emptyState(
                      Icons.directions_car_rounded,
                      'No vehicles yet',
                      'Add a vehicle to start tracking revenue and expenses',
                    );
                  }
                  final now = DateTime.now();
                  final allTrips = _allTrips(tripState);
                  // Attribute financial activity to the day payment was
                  // collected (paymentDate), so this matches the dashboard's
                  // payment-based revenue. For the "all" period every trip is
                  // included regardless of payment state.
                  final inPeriod = allTrips
                      .where((t) => _period.matches(t.paymentDate, now))
                      .toList();
                  final maintenance = _maintenanceByVehicle();
                  final stats =
                      _statsByVehicle(vehicles, inPeriod, maintenance);
                  final totalRev =
                      stats.fold<double>(0, (s, e) => s + e.revenue);
                  final totalExp =
                      stats.fold<double>(0, (s, e) => s + e.expense);
                  final activeVehicles =
                      stats.where((s) => s.tripCount > 0).length;
                  final tripCount = inPeriod.length;

                  return RefreshIndicator(
                    onRefresh: _refreshAll,
                    color: _C.accent,
                    backgroundColor: _C.surface,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 110),
                      children: [
                        _OverallCard(
                          revenue: totalRev,
                          expense: totalExp,
                          activeVehicles: activeVehicles,
                          totalVehicles: vehicles.length,
                          tripCount: tripCount,
                          period: _period,
                        ),
                        const SizedBox(height: 16),
                        _perVehicleHeader(stats.length),
                        const SizedBox(height: 8),
                        for (var i = 0; i < stats.length; i++)
                          _VehicleRevenueCard(
                            stat: stats[i],
                            index: i,
                            isTopPerformer:
                                i == 0 && stats[i].revenue > 0,
                            onTap: () => _openVehicleDetail(stats[i]),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Per-vehicle section header ─────────────────────────────────────
  Widget _perVehicleHeader(int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_C.accentLight, _C.accent],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'Per Vehicle',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: _C.text1,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _C.accentSoft,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: _C.accent,
              ),
            ),
          ),
          const Spacer(),
          Row(
            children: const [
              Icon(
                Icons.swap_vert_rounded,
                size: 13,
                color: _C.text3,
              ),
              SizedBox(width: 3),
              Text(
                'Sorted by net',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: _C.text3,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── App bar ────────────────────────────────────────────────────────
  Widget _buildAppBar() {
    return Container(
      decoration: BoxDecoration(
        color: _C.surface,
        boxShadow: [
          BoxShadow(
            color: _C.accent.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(10, 10, 16, 14),
      child: Row(
        children: [
          Material(
            color: _C.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 16,
                  color: _C.text1,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Vehicle Report',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _C.text1,
                    letterSpacing: -0.4,
                    height: 1.1,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Track performance per vehicle',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: _C.text2,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_C.accentLight, _C.accent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: _C.accent.withValues(alpha: 0.30),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.analytics_rounded,
              size: 18,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ── Period segmented control ───────────────────────────────────────
  Widget _buildPeriodChips() {
    return Container(
      color: _C.surface,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: _C.surfaceLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _C.divider),
        ),
        child: Row(
          children: [
            for (final p in VehicleReportPeriod.values)
              Expanded(child: _periodChip(p)),
          ],
        ),
      ),
    );
  }

  Widget _periodChip(VehicleReportPeriod p) {
    final active = p == _period;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _period = p),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          gradient: active
              ? const LinearGradient(
                  colors: [_C.accentLight, _C.accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: active ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: _C.accent.withValues(alpha: 0.25),
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
              Icon(
                p.icon,
                size: 13,
                color: active ? Colors.white : _C.text2,
              ),
              const SizedBox(width: 5),
              Text(
                p.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: active ? Colors.white : _C.text2,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── States: loading / empty / error ────────────────────────────────
  Widget _loadingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation(_C.accent),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Crunching the numbers...',
            style: TextStyle(
              fontSize: 12,
              color: _C.text2,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(IconData icon, String title, String sub) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _C.accentSoft,
                    _C.accentSoft.withValues(alpha: 0.5),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _C.accent.withValues(alpha: 0.10),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, size: 38, color: _C.accent),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: _C.text1,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              sub,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12.5,
                color: _C.text2,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorState(String msg, {bool offline = false}) => Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: offline ? Colors.grey.shade100 : _C.redSoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  offline ? Icons.wifi_off_rounded : Icons.cloud_off_rounded,
                  color: offline ? Colors.grey.shade500 : _C.red,
                  size: 30,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                offline ? 'You appear to be offline' : 'Something went wrong',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: _C.text1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                msg,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: _C.text2,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────
// OVERALL SUMMARY CARD
// Premium gradient surface with a hero net display, sub-row
// for Revenue/Expense, a margin badge, and footer chips for
// vehicle/trip counts. Decorative blobs add depth without
// competing with the data.
// ─────────────────────────────────────────────────────────
class _OverallCard extends StatelessWidget {
  final double revenue;
  final double expense;
  final int activeVehicles;
  final int totalVehicles;
  final int tripCount;
  final VehicleReportPeriod period;

  const _OverallCard({
    required this.revenue,
    required this.expense,
    required this.activeVehicles,
    required this.totalVehicles,
    required this.tripCount,
    required this.period,
  });

  @override
  Widget build(BuildContext context) {
    final net = revenue - expense;
    final isProfit = net >= 0;
    // Margin = profit as a percentage of revenue. When revenue is zero we
    // fall back to a flat 0% so the badge still renders cleanly.
    final margin = revenue > 0 ? (net / revenue * 100) : 0.0;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            _C.accent,
            _C.accentDark,
            _C.accent,
          ],
          stops: [0.0, 0.55, 1.0],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: _C.accent.withValues(alpha: 0.32),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            // Decorative blobs — soft, subtle depth without distracting.
            Positioned(
              right: -36,
              top: -36,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned(
              right: 48,
              bottom: -50,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row: label + margin pill
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_rounded,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Overall · ${period.label}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.20),
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
                              '${isProfit ? '+' : ''}'
                              '${margin.toStringAsFixed(1)}%',
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
                  const SizedBox(height: 10),
                  // Hero net: label + value inline for compactness
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '${isProfit ? '' : '−'}₹${_formatCompact(net.abs())}',
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
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          isProfit ? 'net profit' : 'net loss',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.82),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Sub stats: Revenue / Expense
                  Row(
                    children: [
                      Expanded(
                        child: _subStat(
                          label: 'Revenue',
                          value: '₹${_formatCompact(revenue)}',
                          icon: Icons.south_west_rounded,
                        ),
                      ),
                      _vDivider(),
                      Expanded(
                        child: _subStat(
                          label: 'Expense',
                          value: '₹${_formatCompact(expense)}',
                          icon: Icons.north_east_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Footer chips
                  Row(
                    children: [
                      _footerChip(
                        Icons.directions_car_rounded,
                        '$activeVehicles/$totalVehicles active',
                      ),
                      const SizedBox(width: 6),
                      _footerChip(
                        Icons.receipt_long_rounded,
                        '$tripCount trip${tripCount == 1 ? '' : 's'}',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _subStat({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(icon, size: 11, color: Colors.white.withValues(alpha: 0.85)),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.82),
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15.5,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
            height: 1.1,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _vDivider() => Container(
        width: 1,
        height: 32,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        color: Colors.white.withValues(alpha: 0.18),
      );

  Widget _footerChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// PER-VEHICLE CARD
// Modern card with a rank badge for the top performer, refined
// stat tiles, an expense-share meter, and a maintenance footnote
// when service costs are part of the picture.
// ─────────────────────────────────────────────────────────
class _VehicleRevenueCard extends StatelessWidget {
  final _VehicleStat stat;
  final int index;
  final bool isTopPerformer;
  final VoidCallback? onTap;
  const _VehicleRevenueCard({
    required this.stat,
    required this.index,
    this.isTopPerformer = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final v = stat.vehicle;
    // A maintenance-only vehicle (service in the period but no trips) still
    // has a real financial story — show the stat panel for it too. The trip
    // chip up top stays bound to tripCount so the label reads honestly.
    final hasTrips = stat.tripCount > 0;
    final hasActivity = hasTrips || stat.maintenanceExpense > 0;
    final isActive = hasActivity;
    final net = stat.net;
    final isProfit = net >= 0;
    // Share of expense relative to revenue, clamped — drives the thin meter
    // under the numbers so big spenders pop visually.
    final expenseShare = stat.revenue > 0
        ? (stat.expense / stat.revenue).clamp(0.0, 1.0)
        : (stat.expense > 0 ? 1.0 : 0.0);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 240 + (index.clamp(0, 10)) * 35),
      curve: Curves.easeOutCubic,
      builder: (_, val, child) => Opacity(
        opacity: val,
        child: Transform.translate(
          offset: Offset(0, 12 * (1 - val)),
          child: child,
        ),
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: isTopPerformer
                ? _C.gold.withValues(alpha: 0.45)
                : _C.divider,
            width: isTopPerformer ? 1.3 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: (isTopPerformer ? _C.gold : _C.accent)
                  .withValues(alpha: isTopPerformer ? 0.09 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            if (isTopPerformer)
              Positioned(
                top: 0,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2.5,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF5C038), _C.gold],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(7),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _C.gold.withValues(alpha: 0.30),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.workspace_premium_rounded,
                        size: 9,
                        color: Colors.white,
                      ),
                      SizedBox(width: 2),
                      Text(
                        'TOP',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.7,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                12,
                isTopPerformer ? 11 : 10,
                12,
                10,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _header(v, isActive),
                  if (isActive) ...[
                    const SizedBox(height: 9),
                    Container(height: 1, color: _C.dividerLight),
                    const SizedBox(height: 9),
                    _statsRow(isProfit, net),
                    const SizedBox(height: 9),
                    _ExpenseShareBar(share: expenseShare),
                    if (stat.maintenanceExpense > 0) ...[
                      const SizedBox(height: 7),
                      _maintenanceNote(),
                    ],
                  ] else ...[
                    const SizedBox(height: 9),
                    Container(height: 1, color: _C.dividerLight),
                    const SizedBox(height: 9),
                    _noRecordBlock(),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _header(Vehicles v, bool isActive) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isActive
                  ? const [_C.accentLight, _C.accent]
                  : [Colors.grey.shade300, Colors.grey.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(9),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: _C.accent.withValues(alpha: 0.22),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: const Icon(
            Icons.directions_car_rounded,
            color: Colors.white,
            size: 17,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Vehicle name + number — single blood-red pill card
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFB71C1C), _C.bloodRed],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: _C.bloodRed.withValues(alpha: 0.30),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      v.name ?? 'Unknown',
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.2,
                        height: 1.15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.credit_card_rounded,
                          size: 10,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            v.number ?? 'No plate',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white.withValues(alpha: 0.92),
                              letterSpacing: 0.6,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isActive ? _C.accentSoft : _C.surfaceLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive
                  ? _C.accent.withValues(alpha: 0.30)
                  : _C.divider,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                stat.tripCount > 0
                    ? Icons.route_rounded
                    : (stat.maintenanceExpense > 0
                        ? Icons.build_rounded
                        : Icons.do_not_disturb_alt_rounded),
                size: 10,
                color: isActive ? _C.accent : _C.text3,
              ),
              const SizedBox(width: 3),
              Text(
                stat.tripCount > 0
                    ? '${stat.tripCount} trip${stat.tripCount == 1 ? '' : 's'}'
                    : (stat.maintenanceExpense > 0
                        ? 'Service'
                        : 'Idle'),
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  color: isActive ? _C.accent : _C.text3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statsRow(bool isProfit, double net) {
    return Row(
      children: [
        Expanded(
          child: _miniStat(
            label: 'Revenue',
            value: '₹${_formatCompact(stat.revenue)}',
            color: _C.green,
            bg: _C.greenSoft,
            icon: Icons.south_west_rounded,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _miniStat(
            label: 'Expense',
            value: '₹${_formatCompact(stat.expense)}',
            color: _C.orange,
            bg: _C.orangeSoft,
            icon: Icons.north_east_rounded,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _miniStat(
            label: 'Net',
            value: '${isProfit ? '' : '−'}₹${_formatCompact(net.abs())}',
            color: isProfit ? _C.green : _C.red,
            bg: isProfit ? _C.greenSoft : _C.redSoft,
            icon: isProfit
                ? Icons.trending_up_rounded
                : Icons.trending_down_rounded,
          ),
        ),
      ],
    );
  }

  Widget _miniStat({
    required String label,
    required String value,
    required Color color,
    required Color bg,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 10, color: color),
              const SizedBox(width: 3),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: -0.3,
              height: 1.1,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  // Shown for idle vehicles — no trips and no maintenance in the period.
  // A neutral placeholder so the card still reads as intentional, not broken.
  Widget _noRecordBlock() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: _C.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _C.divider),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 16,
            color: _C.text3,
          ),
          const SizedBox(width: 8),
          Text(
            'No records available',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: _C.text3,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _maintenanceNote() {
    return Row(
      children: [
        const Icon(Icons.build_rounded, size: 10, color: _C.orange),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            'Includes ₹${_formatCompact(stat.maintenanceExpense)} in maintenance',
            style: const TextStyle(
              fontSize: 10,
              color: _C.text2,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
// EXPENSE-SHARE METER
// Orange fraction of the bar = expense as a share of revenue.
// A near-full bar means the vehicle is barely earning.
// ─────────────────────────────────────────────────────────
class _ExpenseShareBar extends StatelessWidget {
  final double share;
  const _ExpenseShareBar({required this.share});

  @override
  Widget build(BuildContext context) {
    final pct = (share * 100).clamp(0, 100).toStringAsFixed(0);
    final isHeavy = share >= 0.7;
    return Row(
      children: [
        const Text(
          'Spent',
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            color: _C.text2,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                Container(height: 5, color: _C.dividerLight),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: share),
                  duration: const Duration(milliseconds: 450),
                  curve: Curves.easeOutCubic,
                  builder: (_, w, __) => FractionallySizedBox(
                    widthFactor: w,
                    child: Container(
                      height: 5,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isHeavy
                              ? const [_C.red, Color(0xFFD63030)]
                              : const [_C.orange, Color(0xFFD97706)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$pct%',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: isHeavy ? _C.red : _C.text1,
          ),
        ),
      ],
    );
  }
}

String _formatCompact(double v) {
  if (v.abs() >= 1e7) return '${(v / 1e7).toStringAsFixed(2)}Cr';
  if (v.abs() >= 1e5) return '${(v / 1e5).toStringAsFixed(2)}L';
  if (v.abs() >= 1e3) return '${(v / 1e3).toStringAsFixed(2)}K';
  return v.toStringAsFixed(0);
}

// ═════════════════════════════════════════════════════════════════════
// VEHICLE REPORT DETAIL
// Everything about one vehicle on a single page: a hero P&L summary, a
// full expense breakdown (toll / repair / driver / maintenance), the
// vehicle's trip ledger and its maintenance records — all driven by the
// same period filter the operator was already using.
// ═════════════════════════════════════════════════════════════════════
class VehicleReportDetailPage extends StatefulWidget {
  final Vehicles vehicle;
  final List<BookingInfo> trips; // all trips for this vehicle (unfiltered)
  final List<Services> services; // all maintenance records (unfiltered)
  final VehicleReportPeriod initialPeriod;

  const VehicleReportDetailPage({
    super.key,
    required this.vehicle,
    required this.trips,
    required this.services,
    this.initialPeriod = VehicleReportPeriod.month,
  });

  @override
  State<VehicleReportDetailPage> createState() =>
      _VehicleReportDetailPageState();
}

class _VehicleReportDetailPageState extends State<VehicleReportDetailPage> {
  late VehicleReportPeriod _period = widget.initialPeriod;

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  String _fmtDate(DateTime? d) =>
      d == null ? '--' : '${d.day} ${_months[d.month - 1]} ${d.year}';

  double _rev(BookingInfo t) => t.amountReceived ?? 0.0;
  double _toll(BookingInfo t) => t.tollCharges ?? 0.0;
  double _repair(BookingInfo t) => t.repairingCharges ?? 0.0;
  double _driver(BookingInfo t) => t.driverCharges ?? 0.0;
  double _tripExp(BookingInfo t) => _toll(t) + _repair(t) + _driver(t);

  DateTime? _tripKey(BookingInfo t) =>
      t.paymentDate ?? t.startDateTime ?? t.bookingDate;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    final trips = widget.trips
        .where((t) => _period.matches(t.paymentDate, now))
        .toList()
      ..sort((a, b) {
        final da = _tripKey(a);
        final db = _tripKey(b);
        if (da == null && db == null) return 0;
        if (da == null) return 1;
        if (db == null) return -1;
        return db.compareTo(da);
      });

    final services = widget.services
        .where((s) => _period.matches(s.serviceDate, now))
        .toList()
      ..sort((a, b) {
        final da = a.serviceDate;
        final db = b.serviceDate;
        if (da == null && db == null) return 0;
        if (da == null) return 1;
        if (db == null) return -1;
        return db.compareTo(da);
      });

    final revenue = trips.fold<double>(0, (s, t) => s + _rev(t));
    final toll = trips.fold<double>(0, (s, t) => s + _toll(t));
    final repair = trips.fold<double>(0, (s, t) => s + _repair(t));
    final driver = trips.fold<double>(0, (s, t) => s + _driver(t));
    final maintenance =
        services.fold<double>(0, (s, e) => s + (e.serviceCost ?? 0));
    final expense = toll + repair + driver + maintenance;
    final net = revenue - expense;

    return Scaffold(
      backgroundColor: _C.bg,
      body: SafeArea(
        child: Column(
          children: [
            _appBar(),
            _periodChips(),
            Expanded(
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 40),
                children: [
                  _hero(revenue, expense, net, trips.length),
                  const SizedBox(height: 14),
                  _breakdownCard(toll, repair, driver, maintenance, expense),
                  const SizedBox(height: 16),
                  _sectionHeader('Trips', trips.length, Icons.route_rounded),
                  const SizedBox(height: 8),
                  if (trips.isEmpty)
                    _emptyMini('No trips in this period')
                  else
                    for (final t in trips) _tripRow(t),
                  const SizedBox(height: 16),
                  _sectionHeader(
                      'Maintenance', services.length, Icons.build_rounded),
                  const SizedBox(height: 8),
                  if (services.isEmpty)
                    _emptyMini('No maintenance in this period')
                  else
                    for (final s in services) _serviceRow(s),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── App bar ────────────────────────────────────────────────────────
  Widget _appBar() {
    final v = widget.vehicle;
    return Container(
      decoration: BoxDecoration(
        color: _C.surface,
        boxShadow: [
          BoxShadow(
            color: _C.accent.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(10, 10, 16, 14),
      child: Row(
        children: [
          Material(
            color: _C.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    size: 16, color: _C.text1),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  v.name ?? 'Vehicle',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _C.text1,
                    letterSpacing: -0.4,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  v.number ?? 'No plate',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: _C.text2,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_C.accentLight, _C.accent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.directions_car_rounded,
                size: 18, color: Colors.white),
          ),
        ],
      ),
    );
  }

  // ── Period chips ───────────────────────────────────────────────────
  Widget _periodChips() {
    return Container(
      color: _C.surface,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: _C.surfaceLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _C.divider),
        ),
        child: Row(
          children: [
            for (final p in VehicleReportPeriod.values)
              Expanded(child: _periodChip(p)),
          ],
        ),
      ),
    );
  }

  Widget _periodChip(VehicleReportPeriod p) {
    final active = p == _period;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _period = p),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          gradient: active
              ? const LinearGradient(
                  colors: [_C.accentLight, _C.accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          borderRadius: BorderRadius.circular(10),
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

  // ── Hero P&L summary ───────────────────────────────────────────────
  Widget _hero(double revenue, double expense, double net, int tripCount) {
    final isProfit = net >= 0;
    final margin = revenue > 0 ? (net / revenue * 100) : 0.0;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_C.accent, _C.accentDark, _C.accent],
          stops: [0.0, 0.55, 1.0],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: _C.accent.withValues(alpha: 0.30),
            blurRadius: 20,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${isProfit ? '' : '−'}₹${_formatCompact(net.abs())}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
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
                    color: Colors.white.withValues(alpha: 0.82),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${isProfit ? '+' : ''}${margin.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _heroStat('Revenue', '₹${_formatCompact(revenue)}',
                    Icons.south_west_rounded),
              ),
              Container(
                width: 1,
                height: 30,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                color: Colors.white.withValues(alpha: 0.18),
              ),
              Expanded(
                child: _heroStat('Expense', '₹${_formatCompact(expense)}',
                    Icons.north_east_rounded),
              ),
              Container(
                width: 1,
                height: 30,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                color: Colors.white.withValues(alpha: 0.18),
              ),
              Expanded(
                child: _heroStat('Trips', '$tripCount',
                    Icons.receipt_long_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroStat(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(icon, size: 11, color: Colors.white.withValues(alpha: 0.85)),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.82),
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

  // ── Expense breakdown ──────────────────────────────────────────────
  Widget _breakdownCard(double toll, double repair, double driver,
      double maintenance, double expense) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Expense Breakdown',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: _C.text1,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 10),
          _breakdownRow('Toll charges', toll, Icons.toll_rounded),
          _breakdownRow('Repair charges', repair, Icons.build_rounded),
          _breakdownRow('Driver charges', driver, Icons.payments_rounded),
          _breakdownRow(
              'Maintenance', maintenance, Icons.handyman_rounded),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1, color: _C.dividerLight),
          ),
          Row(
            children: [
              const Text(
                'Total expense',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: _C.text1,
                ),
              ),
              const Spacer(),
              Text(
                '₹${_formatCompact(expense)}',
                style: const TextStyle(
                  fontSize: 14,
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
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: _C.orangeSoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 13, color: _C.orange),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _C.text2,
              ),
            ),
          ),
          Text(
            '₹${_formatCompact(value)}',
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: _C.text1,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  // ── Section header ─────────────────────────────────────────────────
  Widget _sectionHeader(String title, int count, IconData icon) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_C.accentLight, _C.accent],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: _C.text1,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: _C.accentSoft,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: _C.accent,
            ),
          ),
        ),
      ],
    );
  }

  // ── Trip row ───────────────────────────────────────────────────────
  Widget _tripRow(BookingInfo t) {
    final received = _rev(t);
    final exp = _tripExp(t);
    final approve = t.amountApprove ?? 0;
    String payLabel;
    Color payColor;
    Color payBg;
    if (approve > 0 && received >= approve) {
      payLabel = 'Paid';
      payColor = _C.green;
      payBg = _C.greenSoft;
    } else if (received > 0) {
      payLabel = 'Partial';
      payColor = _C.orange;
      payBg = _C.orangeSoft;
    } else {
      payLabel = 'Unpaid';
      payColor = _C.red;
      payBg = _C.redSoft;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: _C.divider),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.trip_origin_rounded,
                        size: 11, color: _C.green),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        t.pickupLocation ?? '--',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: _C.text1,
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(Icons.arrow_forward_rounded,
                          size: 11, color: _C.text3),
                    ),
                    Flexible(
                      child: Text(
                        t.dropLocation ?? '--',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: _C.text1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: payBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  payLabel,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: payColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded,
                  size: 11, color: _C.text3),
              const SizedBox(width: 5),
              Text(
                _fmtDate(_tripKey(t)),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: _C.text2,
                ),
              ),
              const Spacer(),
              _amountTag('Received', received, _C.green),
              if (exp > 0) ...[
                const SizedBox(width: 8),
                _amountTag('Expense', exp, _C.orange),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _amountTag(String label, double value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label ',
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: _C.text3,
          ),
        ),
        Text(
          '₹${_formatCompact(value)}',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: color,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }

  // ── Maintenance row ────────────────────────────────────────────────
  Widget _serviceRow(Services s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: _C.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: _C.orangeSoft,
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.build_rounded, size: 15, color: _C.orange),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  s.serviceName ?? 'Service',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: _C.text1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _fmtDate(s.serviceDate),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: _C.text2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '₹${_formatCompact(s.serviceCost ?? 0)}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: _C.orange,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyMini(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: _C.divider),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          color: _C.text2,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
