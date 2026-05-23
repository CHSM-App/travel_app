import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_agency_app/core/theme/app_colors.dart';
import 'package:travel_agency_app/domain/models/booking_info.dart';
import 'package:travel_agency_app/domain/models/services.dart';
import 'package:travel_agency_app/domain/models/vehicles.dart';
import 'package:travel_agency_app/domain/viewModel/trippage_viewmodel.dart';
import 'package:travel_agency_app/presentation/providers/usecase_provider.dart';
import 'package:travel_agency_app/presentation/providers/viewmodel_provider.dart';

class _C {
  static const bg = Color(0xFFF2F4F8);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceLight = Color(0xFFF0F3FA);
  static const accent = AppColors.brandPrimary;
  static const accentSoft = AppColors.brandSoft;
  static const text1 = Color(0xFF1A1D2E);
  static const text2 = Color(0xFF7B82A0);
  static const divider = Color(0xFFE4E8F0);
  static const green = Color(0xFF2DB976);
  static const greenSoft = Color(0xFFE8F8F1);
  static const red = Color(0xFFE53935);
  static const redSoft = Color(0xFFFFEBEE);
  static const orange = Color(0xFFE67E22);
  static const orangeSoft = Color(0xFFFEF0E6);
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
        return 'This Week';
      case VehicleReportPeriod.month:
        return 'This Month';
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

  double _revenueOf(BookingInfo t) =>
      t.amountReceived ?? t.amountApprove ?? 0.0;
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
                loading: () => const Center(
                  child: CircularProgressIndicator(color: _C.accent),
                ),
                error: (e, _) =>
                    _errorState('Failed to load vehicles\n$e'),
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
                  final inPeriod = allTrips
                      .where((t) => _period.matches(t.bookingDate, now))
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
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
                      children: [
                        _OverallCard(
                          revenue: totalRev,
                          expense: totalExp,
                          activeVehicles: activeVehicles,
                          totalVehicles: vehicles.length,
                          tripCount: tripCount,
                          period: _period,
                        ),
                        const SizedBox(height: 18),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Row(
                            children: [
                              const Text(
                                'Per Vehicle',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: _C.text1,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _C.surfaceLight,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: _C.divider),
                                ),
                                child: Text(
                                  '${stats.length}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: _C.text2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        for (var i = 0; i < stats.length; i++)
                          _VehicleRevenueCard(stat: stats[i], index: i),
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

  Widget _buildAppBar() {
    return Container(
      color: _C.surface,
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            color: _C.text1,
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 4),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Vehicle Report',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: _C.text1,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Revenue and expenses by vehicle',
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
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _C.accentSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.insights_rounded,
              size: 18,
              color: _C.accent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodChips() {
    return Container(
      color: _C.surface,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final p in VehicleReportPeriod.values) ...[
              _periodChip(p),
              const SizedBox(width: 8),
            ],
          ],
        ),
      ),
    );
  }

  Widget _periodChip(VehicleReportPeriod p) {
    final active = p == _period;
    return GestureDetector(
      onTap: () => setState(() => _period = p),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? _C.accent : _C.surfaceLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? _C.accent : _C.divider,
          ),
        ),
        child: Text(
          p.label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: active ? Colors.white : _C.text2,
          ),
        ),
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
              width: 78,
              height: 78,
              decoration: const BoxDecoration(
                color: _C.accentSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 34, color: _C.accent),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: _C.text1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              sub,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 12.5, color: _C.text2, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorState(String msg) => Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Text(
            msg,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _C.red),
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────
// OVERALL SUMMARY CARD
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
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.brandPrimary, AppColors.brandPrimaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandPrimary.withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.account_balance_wallet_rounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Overall · ${period.label}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _overallStat(
                  label: 'Revenue',
                  value: '₹${_formatCompact(revenue)}',
                  icon: Icons.south_west_rounded,
                ),
              ),
              _vDivider(),
              Expanded(
                child: _overallStat(
                  label: 'Expense',
                  value: '₹${_formatCompact(expense)}',
                  icon: Icons.north_east_rounded,
                ),
              ),
              _vDivider(),
              Expanded(
                child: _overallStat(
                  label: 'Net',
                  value:
                      '${isProfit ? '' : '−'}₹${_formatCompact(net.abs())}',
                  icon: isProfit
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  emphasised: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.directions_car_rounded,
                    size: 13, color: Colors.white),
                const SizedBox(width: 5),
                Text(
                  '$activeVehicles of $totalVehicles vehicles active',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(Icons.receipt_long_rounded,
                    size: 13, color: Colors.white),
                const SizedBox(width: 5),
                Text(
                  '$tripCount trip${tripCount == 1 ? '' : 's'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _overallStat({
    required String label,
    required String value,
    required IconData icon,
    bool emphasised = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: Colors.white.withValues(alpha: 0.85)),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: emphasised ? 18 : 16,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _vDivider() => Container(
        width: 1,
        height: 36,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        color: Colors.white.withValues(alpha: 0.20),
      );
}

// ─────────────────────────────────────────────────────────
// PER-VEHICLE CARD
// ─────────────────────────────────────────────────────────
class _VehicleRevenueCard extends StatelessWidget {
  final _VehicleStat stat;
  final int index;
  const _VehicleRevenueCard({required this.stat, required this.index});

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
      duration: Duration(milliseconds: 220 + (index.clamp(0, 10)) * 35),
      curve: Curves.easeOutCubic,
      builder: (_, val, child) => Opacity(
        opacity: val,
        child: Transform.translate(
          offset: Offset(0, 10 * (1 - val)),
          child: child,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _C.divider),
          boxShadow: [
            BoxShadow(
              color: _C.accent.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header: icon + name + plate + trip count ──
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isActive
                          ? const [
                              AppColors.brandPrimaryLight,
                              _C.accent,
                            ]
                          : [Colors.grey.shade300, Colors.grey.shade400],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.directions_car_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 11),
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        v.number ?? 'No plate',
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: _C.text2,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: isActive ? _C.accentSoft : _C.surfaceLight,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isActive ? _C.accent : _C.divider,
                      width: isActive ? 1 : 1,
                    ),
                  ),
                  child: Text(
                    hasTrips
                        ? '${stat.tripCount} trip${stat.tripCount == 1 ? '' : 's'}'
                        : (stat.maintenanceExpense > 0
                            ? 'Service only'
                            : 'No activity'),
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: isActive ? _C.accent : _C.text2,
                    ),
                  ),
                ),
              ],
            ),
            if (isActive) ...[
              const SizedBox(height: 12),
              Container(height: 1, color: _C.divider),
              const SizedBox(height: 12),
              Row(
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
                  const SizedBox(width: 8),
                  Expanded(
                    child: _miniStat(
                      label: 'Expense',
                      value: '₹${_formatCompact(stat.expense)}',
                      color: _C.orange,
                      bg: _C.orangeSoft,
                      icon: Icons.north_east_rounded,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _miniStat(
                      label: 'Net',
                      value:
                          '${isProfit ? '' : '−'}₹${_formatCompact(net.abs())}',
                      color: isProfit ? _C.green : _C.red,
                      bg: isProfit ? _C.greenSoft : _C.redSoft,
                      icon: isProfit
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Expense-share meter: the orange slice = expense as a share of
              // revenue. A nearly-full bar means the vehicle is barely earning.
              _ExpenseShareBar(share: expenseShare),
              if (stat.maintenanceExpense > 0) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.build_rounded,
                      size: 11,
                      color: _C.text2,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        'Includes ₹${_formatCompact(stat.maintenanceExpense)} in maintenance',
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: _C.text2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
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
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: -0.2,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}

class _ExpenseShareBar extends StatelessWidget {
  final double share;
  const _ExpenseShareBar({required this.share});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Stack(
              children: [
                Container(height: 6, color: _C.greenSoft),
                FractionallySizedBox(
                  widthFactor: share,
                  child: Container(height: 6, color: _C.orange),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${(share * 100).toStringAsFixed(0)}% spent',
          style: const TextStyle(
            fontSize: 10.5,
            color: _C.text2,
            fontWeight: FontWeight.w600,
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
