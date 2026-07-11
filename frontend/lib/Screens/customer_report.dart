import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:vego/Screens/customer_hist.dart';
import 'package:vego/core/theme/app_colors.dart';
import 'package:vego/core/theme/app_scroll_behavior.dart';
import 'package:vego/core/utils/customer_report_export.dart';
import 'package:vego/core/widgets/error_view.dart';
import 'package:vego/core/widgets/trip_filter.dart' show tripSortKey;
import 'package:vego/domain/models/booking_info.dart';
import 'package:vego/domain/models/customers.dart';
import 'package:vego/presentation/providers/usecase_provider.dart';
import 'package:vego/presentation/providers/viewmodel_provider.dart';

// ─── Design tokens (mirror vehicle_report.dart / driver_report.dart) ─────────
class _C {
  static const bg = Color(0xFFF0F4FF);
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
  // Semantic money colors — the ONLY accent colors that carry meaning on this
  // page. Green = money received (paid); red = money owed (pending dues). Drawn
  // from the app theme so they match the rest of the app. Every other figure is
  // brand clay (structure) or neutral grey (descriptive).
  static const green = AppColors.success;
  static const red = AppColors.danger;
}

/// Date-window filter for the customer ledger. Defaults to "Month" — the cadence
/// operators naturally reconcile customer accounts on.
enum CustomerReportPeriod { month, year, custom }

extension on CustomerReportPeriod {
  String get label {
    switch (this) {
      case CustomerReportPeriod.month:
        return 'Monthly';
      case CustomerReportPeriod.year:
        return 'Yearly';
      case CustomerReportPeriod.custom:
        return 'Custom';
    }
  }

  IconData get icon {
    switch (this) {
      case CustomerReportPeriod.month:
        return Icons.calendar_month_rounded;
      case CustomerReportPeriod.year:
        return Icons.calendar_today_rounded;
      case CustomerReportPeriod.custom:
        return Icons.date_range_rounded;
    }
  }

  /// Whether [d] falls in this preset window. Custom is guarded by the page and
  /// never routed through here.
  bool matches(DateTime? d, DateTime now) {
    if (d == null) return false;
    switch (this) {
      case CustomerReportPeriod.month:
        return d.year == now.year && d.month == now.month;
      case CustomerReportPeriod.year:
        return d.year == now.year;
      case CustomerReportPeriod.custom:
        return true;
    }
  }

  /// Concrete [from, to] window. Custom returns (null, null) — bounds live on
  /// the page state.
  (DateTime?, DateTime?) range(DateTime now) {
    switch (this) {
      case CustomerReportPeriod.month:
        return (
          DateTime(now.year, now.month, 1),
          DateTime(now.year, now.month + 1, 0),
        );
      case CustomerReportPeriod.year:
        return (DateTime(now.year, 1, 1), DateTime(now.year, 12, 31));
      case CustomerReportPeriod.custom:
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

/// Per-customer figures over the active period.
class _CustomerStat {
  final Customer customer;
  final List<BookingInfo> trips;

  const _CustomerStat({required this.customer, required this.trips});

  int get tripCount => trips.length;
  double get received =>
      trips.fold<double>(0, (s, t) => s + (t.amountReceived ?? 0));
  double get approved =>
      trips.fold<double>(0, (s, t) => s + (t.amountApprove ?? 0));
  double get pending {
    double p = 0;
    for (final t in trips) {
      final due = (t.amountApprove ?? 0) - (t.amountReceived ?? 0);
      if (due > 0) p += due;
    }
    return p;
  }

  bool get hasActivity => tripCount > 0;
}

class CustomerReportPage extends ConsumerStatefulWidget {
  final CustomerReportPeriod initialPeriod;

  const CustomerReportPage({
    super.key,
    this.initialPeriod = CustomerReportPeriod.month,
  });

  @override
  ConsumerState<CustomerReportPage> createState() => _CustomerReportPageState();
}

class _CustomerReportPageState extends ConsumerState<CustomerReportPage> {
  late CustomerReportPeriod _period = widget.initialPeriod;

  // Bounds for the "Custom" period (date-only).
  DateTime? _customStart;
  DateTime? _customEnd;

  // Trips keyed by customerId. The full unfiltered set is held and the period
  // filter is applied at render time so toggling chips is instant.
  Map<int, List<BookingInfo>> _tripsByCustomer = const {};
  bool _loadingTrips = false;

  // True while a PDF/Excel file is being generated, to block double taps and
  // drive the export button's spinner.
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_refreshAll);
  }

  Future<void> _refreshAll() async {
    final aid = ref.read(loginViewModelProvider).agencyId ?? '';
    if (aid.isEmpty) return;
    await ref
        .read(customerViewModelProvider.notifier)
        .fetchCustomerslist(aid);
    if (!mounted) return;
    final customers =
        ref.read(customerViewModelProvider).customerList.asData?.value ??
            const <Customer>[];
    await _loadTrips(customers);
  }

  /// Pulls trip history for every customer in parallel via the per-customer
  /// endpoint. Using the use case directly (not the view model) avoids
  /// overwriting the shared `customerHist` state that the customer history
  /// screen relies on.
  Future<void> _loadTrips(List<Customer> customers) async {
    if (customers.isEmpty) return;
    final useCase = ref.read(customerUseCaseProvider);
    final ids = customers
        .map((c) => c.customerId)
        .whereType<int>()
        .toList(growable: false);
    if (ids.isEmpty) return;
    setState(() => _loadingTrips = true);
    final results = await Future.wait(
      ids.map((id) async {
        try {
          final res = await useCase.customerhist(id);
          return res is List ? res.cast<BookingInfo>() : <BookingInfo>[];
        } catch (_) {
          // A single customer's history failing shouldn't blank the report.
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
      _tripsByCustomer = map;
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
    if (_period != CustomerReportPeriod.custom) return _period.matches(d, now);
    final (start, end) = _customWindow();
    if (start == null && end == null) return true;
    if (d == null) return false;
    final day = DateTime(d.year, d.month, d.day);
    if (start != null && day.isBefore(start)) return false;
    if (end != null && day.isAfter(end)) return false;
    return true;
  }

  String _activeRangeLabel(DateTime now) {
    if (_period != CustomerReportPeriod.custom) return _period.rangeLabel(now);
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
      _period = CustomerReportPeriod.custom;
    });
  }

  /// Period-filtered per-customer stats, sorted with active customers first then
  /// by revenue received desc so the top account surfaces.
  List<_CustomerStat> _statsFor(List<Customer> customers) {
    final now = DateTime.now();
    final list = <_CustomerStat>[];
    for (final c in customers) {
      final id = c.customerId;
      final all = id == null
          ? const <BookingInfo>[]
          : (_tripsByCustomer[id] ?? const <BookingInfo>[]);
      final periodTrips = all
          .where((t) => _accept(tripSortKey(t), now))
          .toList()
        ..sort((a, b) => (tripSortKey(b) ?? DateTime(0))
            .compareTo(tripSortKey(a) ?? DateTime(0)));
      list.add(_CustomerStat(customer: c, trips: periodTrips));
    }
    list.sort((a, b) {
      if (a.hasActivity != b.hasActivity) return a.hasActivity ? -1 : 1;
      if (a.hasActivity) return b.received.compareTo(a.received);
      return (a.customer.name ?? '').compareTo(b.customer.name ?? '');
    });
    return list;
  }

  void _openCustomer(Customer customer) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CustomerHist(customer: customer)),
    );
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? const Color(0xFFEF4444) : _C.text1,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  /// Builds the period-filtered snapshot the exporter consumes from the same
  /// per-customer stats that drive the on-screen cards, so the file matches UI.
  CustomerReportSnapshot _buildSnapshot(List<Customer> customers) {
    final now = DateTime.now();
    final stats = _statsFor(customers);
    final exportStats = stats
        .map((s) => CustomerReportStat(customer: s.customer, trips: s.trips))
        .toList();
    return CustomerReportSnapshot(
      title: 'Customer Report',
      periodLabel: _period.label,
      dateRangeLabel: _activeRangeLabel(now),
      stats: exportStats,
      totalReceived: exportStats.fold<double>(0, (s, e) => s + e.received),
      totalApproved: exportStats.fold<double>(0, (s, e) => s + e.approved),
      activeCustomers: exportStats.where((s) => s.hasActivity).length,
      totalCustomers: customers.length,
      tripCount: exportStats.fold<int>(0, (s, e) => s + e.tripCount),
    );
  }

  /// Entry point from the app-bar button: validates data is ready, then hands
  /// off to the shared chooser → generate → save → open/share flow.
  Future<void> _onExportTap() async {
    if (_exporting) return;
    final customers =
        ref.read(customerViewModelProvider).customerList.asData?.value;
    if (customers == null || customers.isEmpty) {
      _snack('No customers available to export');
      return;
    }
    if (_loadingTrips && _tripsByCustomer.isEmpty) {
      _snack('Trips are still loading. Please wait a moment.');
      return;
    }
    final snap = _buildSnapshot(customers);
    setState(() => _exporting = true);
    await runCustomerReportExport(context, snap);
    if (mounted) setState(() => _exporting = false);
  }

  // ── Build ──────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final customerState =
        ref.watch(customerViewModelProvider).customerList;

    return Scaffold(
      backgroundColor: _C.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            _buildPeriodChips(),
            Expanded(
              child: customerState.when(
                loading: () => _loadingState(),
                error: (e, _) =>
                    NetworkErrorView(error: e, onRetry: _refreshAll),
                data: (customers) {
                  if (customers.isEmpty) {
                    return RefreshIndicator(
                      onRefresh: _refreshAll,
                      color: _C.accent,
                      backgroundColor: _C.surface,
                      child: ListView(
                        physics: kBouncyAlwaysScrollable,
                        children: [
                          SizedBox(
                            height:
                                MediaQuery.of(context).size.height * 0.6,
                            child: _emptyState(
                              Icons.people_rounded,
                              'No customers yet',
                              'Add a customer to start tracking trips and dues',
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  final now = DateTime.now();
                  final stats = _statsFor(customers);
                  final totalReceived =
                      stats.fold<double>(0, (s, e) => s + e.received);
                  final totalPending =
                      stats.fold<double>(0, (s, e) => s + e.pending);
                  final tripCount =
                      stats.fold<int>(0, (s, e) => s + e.tripCount);
                  final activeCustomers =
                      stats.where((s) => s.hasActivity).length;

                  return RefreshIndicator(
                    onRefresh: _refreshAll,
                    color: _C.accent,
                    backgroundColor: _C.surface,
                    child: ListView(
                      physics: kBouncyAlwaysScrollable,
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 110),
                      children: [
                        _OverallCard(
                          received: totalReceived,
                          pending: totalPending,
                          activeCustomers: activeCustomers,
                          totalCustomers: customers.length,
                          tripCount: tripCount,
                          periodLabel: _period.label,
                          dateRangeLabel: _activeRangeLabel(now),
                        ),
                        const SizedBox(height: 16),
                        _perCustomerHeader(stats.length),
                        const SizedBox(height: 8),
                        if (_loadingTrips && _tripsByCustomer.isEmpty)
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
                            _CustomerRevenueCard(
                              stat: stats[i],
                              index: i,
                              isTopPerformer: i == 0 && stats[i].received > 0,
                              onTap: () => _openCustomer(stats[i].customer),
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

  Widget _perCustomerHeader(int count) {
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
            'Per Customer',
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
                  'Customer Report',
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
                  'Track trips and dues per customer',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: _C.text2,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Export button — opens the PDF / Excel chooser for the selected
          // period. Shows a spinner while a file is being generated.
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: _exporting ? null : _onExportTap,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _C.accent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: _C.accent.withValues(alpha: 0.30),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: _exporting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Icon(
                        Icons.ios_share_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
              ),
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
            for (final p in CustomerReportPeriod.values)
              Expanded(child: _periodChip(p)),
          ],
        ),
      ),
    );
  }

  Widget _periodChip(CustomerReportPeriod p) {
    final active = p == _period;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (p == CustomerReportPeriod.custom) {
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
  final double pending;
  final int activeCustomers;
  final int totalCustomers;
  final int tripCount;
  final String periodLabel;
  final String dateRangeLabel;

  const _OverallCard({
    required this.received,
    required this.pending,
    required this.activeCustomers,
    required this.totalCustomers,
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
                              '$activeCustomers/$totalCustomers',
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
                    label: 'Pending Dues',
                    value: '₹${_formatCompact(pending)}',
                    icon: Icons.pending_actions_rounded,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _footerChip(
                        Icons.person_rounded,
                        '$activeCustomers/$totalCustomers active',
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
// PER-CUSTOMER CARD
// ─────────────────────────────────────────────────────────
class _CustomerRevenueCard extends StatelessWidget {
  final _CustomerStat stat;
  final int index;
  final bool isTopPerformer;
  final VoidCallback? onTap;
  const _CustomerRevenueCard({
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
    final c = stat.customer;
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
                  ? _C.accent.withValues(alpha: 0.45)
                  : _C.divider,
              width: isTopPerformer ? 1.3 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: _C.accent
                    .withValues(alpha: isTopPerformer ? 0.10 : 0.04),
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
                      color: _C.accent,
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(7),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _C.accent.withValues(alpha: 0.30),
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
                    _header(c, isActive),
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

  Widget _header(Customer c, bool isActive) {
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
            _initials(c.name),
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
                c.name ?? 'Unknown',
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
              if (c.phone != null && c.phone!.trim().isNotEmpty) ...[
                const SizedBox(height: 3),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.phone_rounded,
                        size: 11, color: _C.text2),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        c.phone!.trim(),
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
    // Received (money in / paid) → green. Pending dues are what the operator
    // chases, so they turn red the moment any money is owed; a zero balance
    // stays neutral grey so a fully-settled customer reads as calm.
    final hasDue = stat.pending > 0;
    return Row(
      children: [
        Expanded(
          child: _miniStat(
            label: 'Received',
            value: '₹${_formatCompact(stat.received)}',
            state: _C.green,
            icon: Icons.south_west_rounded,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _miniStat(
            label: 'Pending',
            value: '₹${_formatCompact(stat.pending)}',
            state: hasDue ? _C.red : null,
            icon: Icons.pending_actions_rounded,
          ),
        ),
      ],
    );
  }

  /// A compact figure tile. [state] tints the tile only when the figure carries
  /// meaning (green = money in / paid, red = money owed). Left null, the tile is
  /// a neutral grey so settled / descriptive figures don't compete for attention.
  Widget _miniStat({
    required String label,
    required String value,
    required IconData icon,
    Color? state,
  }) {
    final fg = state ?? _C.text2;
    final valueColor = state ?? _C.text1;
    final bg = state == null ? _C.surfaceLight : state.withValues(alpha: 0.10);
    final border = state == null ? _C.divider : state.withValues(alpha: 0.22);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 10, color: fg),
              const SizedBox(width: 3),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: fg,
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
              color: valueColor,
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
  return NumberFormat.decimalPattern('en_IN').format(v.round());
}
