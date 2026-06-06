import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:travel_agency_app/Screens/driver_history.dart';
import 'package:travel_agency_app/core/theme/app_colors.dart';
import 'package:travel_agency_app/core/widgets/error_view.dart';
import 'package:travel_agency_app/core/widgets/trip_filter.dart' show tripSortKey;
import 'package:travel_agency_app/domain/models/booking_info.dart';
import 'package:travel_agency_app/domain/models/drivers.dart';
import 'package:travel_agency_app/presentation/providers/usecase_provider.dart';
import 'package:travel_agency_app/presentation/providers/viewmodel_provider.dart';

// ─── Design tokens (mirror vehicle_report.dart) ─────────────────────────────
class _C {
  static const bg = Color(0xFFF5F7FB);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceLight = Color(0xFFF1F4FA);
  static const accent = AppColors.brandPrimary;
  static const accentSoft = AppColors.brandSoft;
  static const header = AppColors.brandHeader;
  static const text1 = Color(0xFF0F1729);
  static const text2 = Color(0xFF6B7280);
  static const text3 = Color(0xFFA3ABBD);
  static const divider = Color(0xFFE6EAF2);
  static const dividerLight = Color(0xFFF1F4F9);
  static const green = Color(0xFF10B981);
  static const greenSoft = Color(0xFFD1FAE5);
  static const gold = Color(0xFFD4AF37);
}

/// Date-window filter for the driver ledger. Defaults to "Month" — the cadence
/// operators naturally reconcile driver payouts on.
enum DriverReportPeriod { month, year, custom }

extension on DriverReportPeriod {
  String get label {
    switch (this) {
      case DriverReportPeriod.month:
        return 'Monthly';
      case DriverReportPeriod.year:
        return 'Yearly';
      case DriverReportPeriod.custom:
        return 'Custom';
    }
  }

  IconData get icon {
    switch (this) {
      case DriverReportPeriod.month:
        return Icons.calendar_month_rounded;
      case DriverReportPeriod.year:
        return Icons.calendar_today_rounded;
      case DriverReportPeriod.custom:
        return Icons.date_range_rounded;
    }
  }

  /// Whether [d] falls in this preset window. Custom is guarded by the page and
  /// never routed through here.
  bool matches(DateTime? d, DateTime now) {
    if (d == null) return false;
    switch (this) {
      case DriverReportPeriod.month:
        return d.year == now.year && d.month == now.month;
      case DriverReportPeriod.year:
        return d.year == now.year;
      case DriverReportPeriod.custom:
        return true;
    }
  }

  /// Concrete [from, to] window. Custom returns (null, null) — bounds live on
  /// the page state.
  (DateTime?, DateTime?) range(DateTime now) {
    switch (this) {
      case DriverReportPeriod.month:
        return (
          DateTime(now.year, now.month, 1),
          DateTime(now.year, now.month + 1, 0),
        );
      case DriverReportPeriod.year:
        return (DateTime(now.year, 1, 1), DateTime(now.year, 12, 31));
      case DriverReportPeriod.custom:
        return (null, null);
    }
  }

  String rangeLabel(DateTime now) {
    final (start, end) = range(now);
    if (start == null || end == null) return 'All time';
    final fmt = DateFormat('dd MMM yyyy');
    return '${fmt.format(start)} - ${fmt.format(end)}';
  }
}

/// Formats a custom [start]–[end] window (either bound may be open).
String _formatCustomRange(DateTime? start, DateTime? end) {
  if (start == null && end == null) return 'Select dates';
  final fmt = DateFormat('dd MMM yyyy');
  bool sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
  if (start != null && end != null) {
    return sameDay(start, end)
        ? fmt.format(start)
        : '${fmt.format(start)} - ${fmt.format(end)}';
  }
  if (start != null) return 'From ${fmt.format(start)}';
  return 'Until ${fmt.format(end!)}';
}

/// Per-driver figures over the active period.
class _DriverStat {
  final Drivers driver;
  final List<BookingInfo> trips;

  const _DriverStat({required this.driver, required this.trips});

  int get tripCount => trips.length;
  double get received =>
      trips.fold<double>(0, (s, t) => s + (t.amountReceived ?? 0));
  double get driverPay =>
      trips.fold<double>(0, (s, t) => s + (t.driverCharges ?? 0));

  bool get hasActivity => tripCount > 0;
}

class DriverReportPage extends ConsumerStatefulWidget {
  final DriverReportPeriod initialPeriod;

  const DriverReportPage({
    super.key,
    this.initialPeriod = DriverReportPeriod.month,
  });

  @override
  ConsumerState<DriverReportPage> createState() => _DriverReportPageState();
}

class _DriverReportPageState extends ConsumerState<DriverReportPage> {
  late DriverReportPeriod _period = widget.initialPeriod;

  // Bounds for the "Custom" period (date-only).
  DateTime? _customStart;
  DateTime? _customEnd;

  // Trips keyed by driverId. The full unfiltered set is held and the period
  // filter is applied at render time so toggling chips is instant.
  Map<int, List<BookingInfo>> _tripsByDriver = const {};
  bool _loadingTrips = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_refreshAll);
  }

  Future<void> _refreshAll() async {
    final aid = ref.read(loginViewModelProvider).agencyId ?? '';
    if (aid.isEmpty) return;
    await ref.read(tripBookingViewModelProvider.notifier).driverList(aid);
    if (!mounted) return;
    final drivers =
        ref.read(tripBookingViewModelProvider).fetchDriverList.asData?.value ??
            const <Drivers>[];
    await _loadTrips(drivers);
  }

  /// Pulls trip history for every driver in parallel via the per-driver
  /// endpoint. Using the use case directly (not the view model) avoids
  /// overwriting the shared `fetchTripsByDriverId` state that the driver
  /// history screen relies on.
  Future<void> _loadTrips(List<Drivers> drivers) async {
    if (drivers.isEmpty) return;
    final useCase = ref.read(addDriverUseCaseProvider);
    final ids = drivers
        .map((d) => d.driverId)
        .whereType<int>()
        .toList(growable: false);
    if (ids.isEmpty) return;
    setState(() => _loadingTrips = true);
    final results = await Future.wait(
      ids.map((id) async {
        try {
          return await useCase.fetchDriverHistory(id);
        } catch (_) {
          // A single driver's history failing shouldn't blank the report.
          return <BookingInfo>[];
        }
      }),
    );
    if (!mounted) return;
    final map = <int, List<BookingInfo>>{};
    for (var i = 0; i < ids.length; i++) {
      map[ids[i]] = results[i];
    }
    setState(() {
      _tripsByDriver = map;
      _loadingTrips = false;
    });
  }

  /// Date-only custom window, normalised so time-of-day never affects filtering.
  (DateTime?, DateTime?) _customWindow() {
    final s = _customStart, e = _customEnd;
    return (
      s == null ? null : DateTime(s.year, s.month, s.day),
      e == null ? null : DateTime(e.year, e.month, e.day),
    );
  }

  /// Whether [d] falls inside the active period.
  bool _accept(DateTime? d, DateTime now) {
    if (_period != DriverReportPeriod.custom) return _period.matches(d, now);
    final (start, end) = _customWindow();
    if (start == null && end == null) return true;
    if (d == null) return false;
    final day = DateTime(d.year, d.month, d.day);
    if (start != null && day.isBefore(start)) return false;
    if (end != null && day.isAfter(end)) return false;
    return true;
  }

  String _activeRangeLabel(DateTime now) {
    if (_period != DriverReportPeriod.custom) return _period.rangeLabel(now);
    return _formatCustomRange(_customStart, _customEnd);
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final initial = (_customStart != null && _customEnd != null)
        ? DateTimeRange(start: _customStart!, end: _customEnd!)
        : DateTimeRange(
            start: DateTime(now.year, now.month, 1),
            end: DateTime(now.year, now.month, now.day),
          );
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: initial,
      helpText: 'Select report range',
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(
            primary: _C.accent,
            onPrimary: Colors.white,
            surface: _C.surface,
            onSurface: _C.text1,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _customStart = picked.start;
      _customEnd = picked.end;
      _period = DriverReportPeriod.custom;
    });
  }

  /// Period-filtered per-driver stats, sorted with active drivers first then by
  /// revenue received desc so the top earner surfaces.
  List<_DriverStat> _statsFor(List<Drivers> drivers) {
    final now = DateTime.now();
    final list = <_DriverStat>[];
    for (final d in drivers) {
      final id = d.driverId;
      final all = id == null ? const <BookingInfo>[] : (_tripsByDriver[id] ?? const <BookingInfo>[]);
      final periodTrips = all
          .where((t) => _accept(tripSortKey(t), now))
          .toList()
        ..sort((a, b) => (tripSortKey(b) ?? DateTime(0))
            .compareTo(tripSortKey(a) ?? DateTime(0)));
      list.add(_DriverStat(driver: d, trips: periodTrips));
    }
    list.sort((a, b) {
      if (a.hasActivity != b.hasActivity) return a.hasActivity ? -1 : 1;
      if (a.hasActivity) return b.received.compareTo(a.received);
      return (a.driver.name ?? '').compareTo(b.driver.name ?? '');
    });
    return list;
  }

  void _openDriver(Drivers driver) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DriverHistoryPage(driver: driver)),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final driverState =
        ref.watch(tripBookingViewModelProvider).fetchDriverList;

    return Scaffold(
      backgroundColor: _C.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            _buildPeriodChips(),
            Expanded(
              child: driverState.when(
                loading: () => _loadingState(),
                error: (e, _) =>
                    NetworkErrorView(error: e, onRetry: _refreshAll),
                data: (drivers) {
                  if (drivers.isEmpty) {
                    return _emptyState(
                      Icons.person_rounded,
                      'No drivers yet',
                      'Add a driver to start tracking trips and payouts',
                    );
                  }
                  final now = DateTime.now();
                  final stats = _statsFor(drivers);
                  final totalReceived =
                      stats.fold<double>(0, (s, e) => s + e.received);
                  final totalPay =
                      stats.fold<double>(0, (s, e) => s + e.driverPay);
                  final tripCount =
                      stats.fold<int>(0, (s, e) => s + e.tripCount);
                  final activeDrivers =
                      stats.where((s) => s.hasActivity).length;

                  return RefreshIndicator(
                    onRefresh: _refreshAll,
                    color: _C.accent,
                    backgroundColor: _C.surface,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 110),
                      children: [
                        _OverallCard(
                          received: totalReceived,
                          driverPay: totalPay,
                          activeDrivers: activeDrivers,
                          totalDrivers: drivers.length,
                          tripCount: tripCount,
                          periodLabel: _period.label,
                          dateRangeLabel: _activeRangeLabel(now),
                        ),
                        const SizedBox(height: 16),
                        _perDriverHeader(stats.length),
                        const SizedBox(height: 8),
                        if (_loadingTrips && _tripsByDriver.isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(top: 30),
                            child: Center(
                              child: SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.6,
                                  valueColor:
                                      AlwaysStoppedAnimation(_C.accent),
                                ),
                              ),
                            ),
                          )
                        else
                          for (var i = 0; i < stats.length; i++)
                            _DriverRevenueCard(
                              stat: stats[i],
                              index: i,
                              isTopPerformer: i == 0 && stats[i].received > 0,
                              onTap: () => _openDriver(stats[i].driver),
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

  Widget _perDriverHeader(int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: _C.accent,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'Per Driver',
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
              Icon(Icons.swap_vert_rounded, size: 13, color: _C.text3),
              SizedBox(width: 3),
              Text(
                'Sorted by revenue',
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
                  'Driver Report',
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
                  'Track trips and payouts per driver',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: _C.text2,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
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
            for (final p in DriverReportPeriod.values)
              Expanded(child: _periodChip(p)),
          ],
        ),
      ),
    );
  }

  Widget _periodChip(DriverReportPeriod p) {
    final active = p == _period;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (p == DriverReportPeriod.custom) {
          _pickCustomRange();
        } else {
          setState(() => _period = p);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 2),
        decoration: BoxDecoration(
          color: active ? _C.accent : Colors.transparent,
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
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  p.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: active ? Colors.white : _C.text2,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── States ──────────────────────────────────────────────────────────
  Widget _loadingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation(_C.accent),
            ),
          ),
          SizedBox(height: 14),
          Text(
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
                color: _C.accentSoft,
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
}

// ─────────────────────────────────────────────────────────
// OVERALL SUMMARY CARD
// ─────────────────────────────────────────────────────────
class _OverallCard extends StatelessWidget {
  final double received;
  final double driverPay;
  final int activeDrivers;
  final int totalDrivers;
  final int tripCount;
  final String periodLabel;
  final String dateRangeLabel;

  const _OverallCard({
    required this.received,
    required this.driverPay,
    required this.activeDrivers,
    required this.totalDrivers,
    required this.tripCount,
    required this.periodLabel,
    required this.dateRangeLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _C.header,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: _C.header.withValues(alpha: 0.32),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
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
                        'Overall · $periodLabel',
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
                            const Icon(
                              Icons.groups_rounded,
                              color: Colors.white,
                              size: 11,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '$activeDrivers/$totalDrivers',
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
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.event_rounded,
                        size: 12,
                        color: Colors.white.withValues(alpha: 0.82),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        dateRangeLabel,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '₹${_formatCompact(received)}',
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
                          'revenue received',
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
                  _subStat(
                    label: 'Driver Pay',
                    value: '₹${_formatCompact(driverPay)}',
                    icon: Icons.payments_rounded,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _footerChip(
                        Icons.person_rounded,
                        '$activeDrivers/$totalDrivers active',
                      ),
                      const SizedBox(width: 6),
                      _footerChip(
                        Icons.route_rounded,
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
// PER-DRIVER CARD
// ─────────────────────────────────────────────────────────
class _DriverRevenueCard extends StatelessWidget {
  final _DriverStat stat;
  final int index;
  final bool isTopPerformer;
  final VoidCallback? onTap;
  const _DriverRevenueCard({
    required this.stat,
    required this.index,
    this.isTopPerformer = false,
    this.onTap,
  });

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

  @override
  Widget build(BuildContext context) {
    final d = stat.driver;
    final isActive = stat.hasActivity;

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
                      color: _C.gold,
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
                    _header(d, isActive),
                    if (isActive) ...[
                      const SizedBox(height: 9),
                      Container(height: 1, color: _C.dividerLight),
                      const SizedBox(height: 9),
                      _statsRow(),
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

  Widget _header(Drivers d, bool isActive) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: isActive ? _C.accent : Colors.grey.shade400,
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
          alignment: Alignment.center,
          child: Text(
            _initials(d.name),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                d.name ?? 'Unknown',
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: _C.text1,
                  letterSpacing: -0.1,
                  height: 1.15,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (d.phone != null && d.phone!.trim().isNotEmpty) ...[
                const SizedBox(height: 3),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.phone_rounded,
                        size: 11, color: _C.text2),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        d.phone!.trim(),
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: _C.text2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isActive ? _C.accentSoft : _C.surfaceLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive ? _C.accent.withValues(alpha: 0.30) : _C.divider,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                stat.tripCount > 0
                    ? Icons.route_rounded
                    : Icons.do_not_disturb_alt_rounded,
                size: 10,
                color: isActive ? _C.accent : _C.text3,
              ),
              const SizedBox(width: 3),
              Text(
                stat.tripCount > 0
                    ? '${stat.tripCount} trip${stat.tripCount == 1 ? '' : 's'}'
                    : 'Idle',
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

  Widget _statsRow() {
    return Row(
      children: [
        Expanded(
          child: _miniStat(
            label: 'Revenue',
            value: '₹${_formatCompact(stat.received)}',
            color: _C.green,
            bg: _C.greenSoft,
            icon: Icons.south_west_rounded,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _miniStat(
            label: 'Driver Pay',
            value: '₹${_formatCompact(stat.driverPay)}',
            color: _C.accent,
            bg: _C.accentSoft,
            icon: Icons.payments_rounded,
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
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
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
        children: const [
          Icon(Icons.inbox_outlined, size: 16, color: _C.text3),
          SizedBox(width: 8),
          Text(
            'No trips in this period',
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
}

String _formatCompact(double v) {
  if (v.abs() >= 1e7) return '${(v / 1e7).toStringAsFixed(2)}Cr';
  if (v.abs() >= 1e5) return '${(v / 1e5).toStringAsFixed(2)}L';
  if (v.abs() >= 1e3) return '${(v / 1e3).toStringAsFixed(2)}K';
  return v.toStringAsFixed(0);
}
