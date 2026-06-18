import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:vego/Screens/add_customer.dart';
import 'package:vego/Screens/trip_card.dart';
import 'package:vego/core/theme/app_colors.dart';
import 'package:vego/core/theme/app_scroll_behavior.dart';
import 'package:vego/core/utils/customer_report_export.dart';
import 'package:vego/core/widgets/error_view.dart';
import 'package:vego/core/widgets/paginated_list_view.dart';
import 'package:vego/core/widgets/skeleton.dart';
import 'package:vego/core/widgets/trip_filter.dart';
import 'package:vego/domain/models/booking_info.dart';
import 'package:vego/domain/models/customers.dart';
import 'package:vego/presentation/providers/viewmodel_provider.dart';

/// Per-customer trip status filter, mirroring [TripPage]'s status axis.
/// Status codes mirror those used in [TripCard]: 1=Active, 2=Unpaid,
/// 3=Upcoming, 4=Paid, 5=Cancelled. "Completed" merges the unpaid (2) and
/// fully paid (4) buckets; the [TripPaymentFilter] then narrows it.
enum _TripStatusFilter {
  all('All', Icons.list_alt_rounded),
  active('Active', Icons.directions_car_rounded),
  upcoming('Upcoming', Icons.schedule_rounded),
  completed('Completed', Icons.task_alt_rounded),
  cancelled('Cancelled', Icons.cancel_rounded);

  const _TripStatusFilter(this.label, this.icon);
  final String label;
  final IconData icon;

  bool matches(BookingInfo trip) {
    switch (this) {
      case _TripStatusFilter.all:
        return true;
      case _TripStatusFilter.active:
        return trip.status == 1;
      case _TripStatusFilter.upcoming:
        return trip.status == 3;
      case _TripStatusFilter.completed:
        return trip.status == 2 || trip.status == 4;
      case _TripStatusFilter.cancelled:
        return trip.status == 5;
    }
  }
}

class CustomerHist extends ConsumerStatefulWidget {
  final Customer customer;
  const CustomerHist({super.key, required this.customer});

  @override
  ConsumerState<CustomerHist> createState() => _CustomerHistState();
}

class _CustomerHistState extends ConsumerState<CustomerHist>
    with TickerProviderStateMixin {
  late AnimationController _entryController;
  late Animation<double> _avatarScale;
  late Animation<Offset> _slideUp;
  late Animation<double> _fadeIn;

  // ── Light Palette ──────────────────────────────────────────────────
  static const Color _bg            = Color(0xFFF0F4FF);
  static const Color _surface       = Color(0xFFFFFFFF);
  static const Color _surfaceLight  = Color(0xFFF0F3FA);
  static const Color _accent        = AppColors.brandPrimary;
  static const Color _accentSoft    = AppColors.brandSoft;
  static const Color _textPrimary   = Color(0xFF1A1D2E);
  static const Color _textSecondary = Color(0xFF7B82A0);
  static const Color _divider       = Color(0xFFE4E8F0);
  static const Color _success       = Color(0xFF2DB976);
  static const Color _warning       = Color(0xFFE67E22);

  static final NumberFormat _money = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  _TripStatusFilter _filter = _TripStatusFilter.all;
  TripPaymentFilter _payment = TripPaymentFilter.all;

  // Date-range + free-text search applied on top of the status filter,
  // mirroring TripPage's always-visible search bar + filter sheet.
  static const Duration _searchDebounce = Duration(milliseconds: 250);
  TripDateRange _range = TripDateRange.all;
  DateTimeRange? _customRange;
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounceTimer;
  String _query = '';

  // Index of the "Completed" status — the only status for which the payment
  // filter is meaningful, matching TripPage.
  static final int _completedIndex =
      _TripStatusFilter.values.indexOf(_TripStatusFilter.completed);

  // True while a PDF/Excel file is being generated for this customer.
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _avatarScale = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    );
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
    ));
    _fadeIn = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
    );
    _entryController.forward();

    Future.microtask(_load);
  }

  @override
  void dispose() {
    _entryController.dispose();
    _debounceTimer?.cancel();
    _searchCtrl.dispose();
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

  /// Number of non-default filters active — drives the filter button's badge.
  int get _activeFilterCount =>
      (_filter != _TripStatusFilter.all ? 1 : 0) +
      (_payment != TripPaymentFilter.all ? 1 : 0) +
      (_range != TripDateRange.all ? 1 : 0);

  /// Opens the shared TripPage-style filter sheet and commits the result.
  Future<void> _openFilterSheet() async {
    final result = await showTripFilterSheet(
      context: context,
      statuses: [
        for (final f in _TripStatusFilter.values)
          TripStatusOption(f.label, f.icon),
      ],
      statusIndex: _filter.index,
      payment: _payment,
      range: _range,
      customRange: _customRange,
      completedIndex: _completedIndex,
    );
    if (result == null || !mounted) return;
    setState(() {
      _filter = _TripStatusFilter.values[result.statusIndex];
      _payment = result.payment;
      _range = result.range;
      _customRange = result.customRange;
    });
  }

  Future<void> _load() async {
    final id = widget.customer.customerId;
    if (id == null) return;
    await ref.read(customerViewModelProvider.notifier).fetchCustomershist(id);
  }

  // ─────────────────────────────────────────────────────────────
  // EXPORT (single customer)
  // ─────────────────────────────────────────────────────────────

  /// Human-readable label for the active date window, mirroring the figures
  /// the report card shows.
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

  /// Builds a single-customer [CustomerReportSnapshot] from the loaded trips,
  /// filtered to the active date range + search, then runs the shared export.
  Future<void> _exportReport() async {
    if (_exporting) return;
    final trips =
        ref.read(customerViewModelProvider).customerHist.asData?.value ??
            const <BookingInfo>[];
    final now = DateTime.now();
    final periodTrips = _dateAndQueryFiltered(trips)
      ..sort((a, b) => (tripSortKey(b) ?? DateTime(0))
          .compareTo(tripSortKey(a) ?? DateTime(0)));

    final stat =
        CustomerReportStat(customer: widget.customer, trips: periodTrips);
    final snap = CustomerReportSnapshot(
      title: '${widget.customer.name ?? 'Customer'} Report',
      periodLabel: _range.label,
      dateRangeLabel: _rangeLabel(now),
      stats: [stat],
      totalReceived: stat.received,
      totalApproved: stat.approved,
      activeCustomers: stat.hasActivity ? 1 : 0,
      totalCustomers: 1,
      tripCount: stat.tripCount,
    );

    setState(() => _exporting = true);
    await runCustomerReportExport(context, snap);
    if (mounted) setState(() => _exporting = false);
  }

  Future<void> _editCustomer() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddCustomerPage(isEdit: true, customer: widget.customer),
      ),
    );
    if (!mounted) return;
    if (result != null) Navigator.pop(context, true);
  }

  void _deleteCustomer() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: _surface,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.person_remove_rounded,
                    color: Colors.red.shade400, size: 30),
              ),
              const SizedBox(height: 16),
              const Text('Delete Customer',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _textPrimary,
                  )),
              const SizedBox(height: 8),
              Text(
                'Are you sure you want to delete "${widget.customer.name ?? 'this customer'}"?\nThis action cannot be undone.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 13, color: _textSecondary, height: 1.6),
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
                            borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(color: _divider),
                      ),
                      child: const Text('Cancel',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, color: _textPrimary)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        final id = widget.customer.customerId;
                        if (id == null) return;
                        final result = await ref
                            .read(customerViewModelProvider.notifier)
                            .deleteCustomer(id);
                        if (!mounted) return;
                        final ok = result['success'] == true;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(result['message']?.toString() ??
                                (ok ? 'Customer deleted' : 'Delete failed')),
                            backgroundColor: ok ? _success : Colors.red.shade400,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            margin: const EdgeInsets.all(16),
                          ),
                        );
                        if (ok) Navigator.pop(context, true);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.red.shade400,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Delete',
                          style: TextStyle(fontWeight: FontWeight.w700)),
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

  // Trips passing the date-range + search filters, before the status filter is
  // applied. Drives both the visible list and the status-chip counts so the
  // counts always reflect what the date/search filters allow through.
  List<BookingInfo> _dateAndQueryFiltered(List<BookingInfo> trips) {
    final now = DateTime.now();
    return trips
        .where((t) =>
            _range.matches(tripSortKey(t), now, customRange: _customRange) &&
            tripMatchesQuery(t, _query))
        .toList();
  }

  // Status narrows first; the payment filter then narrows the completed bucket
  // (it stays "All" for every other status, so it's a no-op there).
  List<BookingInfo> _applyFilter(List<BookingInfo> trips) => trips
      .where((t) => _filter.matches(t) && _payment.matches(t.payment_status))
      .toList();

  String _getInitials(String? name) {
    if (name == null || name.trim().isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    final single = parts[0];
    return (single.length >= 2 ? single.substring(0, 2) : single).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(customerViewModelProvider);
    final topPad = MediaQuery.of(context).padding.top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: _bg,
        // Identity bar (name / phone / address + actions) stays pinned at the
        // top; the report card scrolls away with the trip list below it so the
        // list gets maximum visibility.
        body: NestedScrollView(
          headerSliverBuilder: (context, _) => [
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyHeaderDelegate(
                height: topPad + 64,
                child: _buildIdentityBar(topPad),
              ),
            ),
            // Filter chip row pinned directly under the identity bar so the
            // status / date / search controls stay at the top while scrolling.
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyHeaderDelegate(
                height: 64,
                child: _buildFilterRow(),
              ),
            ),
            SliverToBoxAdapter(
              child: _buildReportSection(state.customerHist),
            ),
          ],
          body: _buildTripList(state.customerHist),
        ),
      ),
    );
  }

  // ── STICKY IDENTITY BAR ────────────────────────────────────────────
  // Pinned at the top of the scroll view: back/edit/delete actions plus the
  // customer's name, phone and address — always visible while scrolling.
  Widget _buildIdentityBar(double topPad) {
    final customer = widget.customer;
    final hasAddress =
        customer.address != null && customer.address!.trim().isNotEmpty;

    return Container(
      padding: EdgeInsets.fromLTRB(12, topPad + 8, 12, 8),
      decoration: BoxDecoration(
        color: _surface,
        border: const Border(bottom: BorderSide(color: _divider)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _iconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            label: 'Back',
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(width: 10),
          ScaleTransition(scale: _avatarScale, child: _smallAvatar(customer.name)),
          const SizedBox(width: 10),
          Expanded(
            child: SlideTransition(
              position: _slideUp,
              child: FadeTransition(
                opacity: _fadeIn,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      customer.name ?? 'Customer',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: _textPrimary,
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.phone_rounded,
                            size: 11, color: _textSecondary),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            customer.phone ?? '--',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _textSecondary,
                            ),
                          ),
                        ),
                        if (hasAddress) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.location_on_rounded,
                              size: 11, color: _textSecondary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              customer.address!.trim(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: _textSecondary,
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
          ),
          const SizedBox(width: 8),
          // Export this customer's report (PDF / Excel) for the active range.
          _exporting
              ? Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: _surfaceLight,
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: _divider, width: 1.2),
                  ),
                  padding: const EdgeInsets.all(10),
                  child: const CircularProgressIndicator(
                    strokeWidth: 2.2,
                    valueColor: AlwaysStoppedAnimation(_accent),
                  ),
                )
              : _iconButton(
                  icon: Icons.ios_share_rounded,
                  label: 'Export report',
                  iconColor: _accent,
                  bgColor: _accentSoft,
                  onTap: _exportReport,
                ),
          const SizedBox(width: 8),
          _iconButton(
            icon: Icons.edit_rounded,
            label: 'Edit customer',
            iconColor: _accent,
            bgColor: _accentSoft,
            onTap: _editCustomer,
          ),
          const SizedBox(width: 8),
          _iconButton(
            icon: Icons.delete_outline_rounded,
            label: 'Delete customer',
            iconColor: Colors.red.shade500,
            bgColor: Colors.red.shade50,
            onTap: _deleteCustomer,
          ),
        ],
      ),
    );
  }

  Widget _smallAvatar(String? name) => Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.brandPrimary,
          boxShadow: [
            BoxShadow(
              color: _accent.withValues(alpha: 0.30),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            _getInitials(name),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ),
      );

  Widget _iconButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? iconColor,
    Color? bgColor,
  }) =>
      Semantics(
        button: true,
        label: label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(11),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: bgColor ?? _surfaceLight,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: _divider, width: 1.2),
              ),
              child: Icon(icon, color: iconColor ?? _textPrimary, size: 16),
            ),
          ),
        ),
      );

  // Scrollable section beneath the pinned identity bar — holds the report
  // card, which scrolls away as the trip list scrolls.
  Widget _buildReportSection(AsyncValue<List<BookingInfo>> tripState) {
    return FadeTransition(
      opacity: _fadeIn,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
        child: _buildReportCard(tripState),
      ),
    );
  }

  // ── REPORT CARD ────────────────────────────────────────────────────
  // Account summary: revenue *received* (not approved) as the hero figure,
  // with approved total, plus trips / paid / pending breakdown tiles.
  Widget _buildReportCard(AsyncValue<List<BookingInfo>> tripState) {
    return tripState.when(
      loading: () => Container(
        height: 132,
        decoration: BoxDecoration(
          color: _surfaceLight,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _divider),
        ),
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _accent,
              backgroundColor: _accent.withValues(alpha: 0.1),
            ),
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (allTrips) {
        // The summary reflects the active date range + search, so the figures
        // change as the date filter changes.
        final trips = _dateAndQueryFiltered(allTrips);
        final total = trips.length;
        final paidCount = trips
            .where((t) =>
                (t.amountReceived ?? 0) >= (t.amountApprove ?? 0) &&
                (t.amountApprove ?? 0) > 0)
            .length;
        final approved =
            trips.fold<double>(0, (sum, t) => sum + (t.amountApprove ?? 0));
        final received =
            trips.fold<double>(0, (sum, t) => sum + (t.amountReceived ?? 0));
        double pending = 0;
        for (final t in trips) {
          final due = (t.amountApprove ?? 0) - (t.amountReceived ?? 0);
          if (due > 0) pending += due;
        }

        return Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _divider, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: _accent.withValues(alpha: 0.07),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              // ── Hero: revenue received ──────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                decoration: const BoxDecoration(
                  color: AppColors.brandHeader,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.trending_up_rounded,
                                size: 13,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'Revenue Received',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withValues(alpha: 0.85),
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _money.format(received),
                              style: const TextStyle(
                                fontSize: 23,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.5,
                                height: 1,
                              ),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'of ${_money.format(approved)} approved',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.78),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Breakdown tiles ─────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                child: Row(
                  children: [
                    _reportTile(
                      Icons.route_rounded,
                      'Trips',
                      '$total',
                      _accent,
                    ),
                    _tileDivider(),
                    _reportTile(
                      Icons.check_circle_outline_rounded,
                      'Paid',
                      '$paidCount',
                      _success,
                    ),
                    _tileDivider(),
                    _reportTile(
                      Icons.pending_actions_rounded,
                      'Pending',
                      _money.format(pending),
                      pending > 0 ? _warning : _textSecondary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _reportTile(IconData icon, String label, String value, Color color) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(height: 7),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: _textPrimary,
                  height: 1.1,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10.5,
                color: _textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tileDivider() {
    return Container(
      width: 1,
      height: 40,
      color: _divider,
    );
  }

  // ── TRIP LIST ──────────────────────────────────────────────────────
  Widget _buildTripList(AsyncValue<List<BookingInfo>> state) {
    return state.when(
      loading: _loadingState,
      error: (e, _) => NetworkErrorView(error: e, onRetry: _load),
      data: (trips) => trips.isEmpty ? _emptyState() : _tripsData(trips),
    );
  }

  Widget _loadingState() {
    return RefreshIndicator(
      onRefresh: _load,
      color: _accent,
      child: ListView(
        physics: kBouncyAlwaysScrollable,
        padding: const EdgeInsets.fromLTRB(0, 16, 0, 24),
        children: const [
          TripCardSkeleton(),
          TripCardSkeleton(),
          TripCardSkeleton(),
          TripCardSkeleton(),
        ],
      ),
    );
  }


  Widget _emptyState() {
    return RefreshIndicator(
      onRefresh: _load,
      color: _accent,
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: kBouncyAlwaysScrollable,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: _accentSoft,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: _accent.withValues(alpha: 0.15), width: 2),
                  ),
                  child: const Icon(
                    Icons.directions_car_outlined,
                    size: 32,
                    color: _accent,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  "No Trips Yet",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "No travel history for this customer.",
                  style: TextStyle(fontSize: 13, color: _textSecondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tripsData(List<BookingInfo> trips) {
    final base = _dateAndQueryFiltered(trips);
    final filtered = _applyFilter(base);
    if (filtered.isEmpty) {
      // Keep the list pull-to-refreshable even when the active filter hides
      // every trip, by making the empty message scroll over full height.
      return RefreshIndicator(
        onRefresh: _load,
        color: _accent,
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            physics: kBouncyAlwaysScrollable,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: _filteredEmptyState(),
            ),
          ),
        ),
      );
    }
    return PaginatedListView<BookingInfo>(
      items: filtered,
      onRefresh: _load,
      resetToken: '$_filter|$_payment|$_range|$_customRange|$_query',
      // 8px here + each TripCard's own 8px margin = 16px side inset, matching
      // the report card, filter row and loading skeletons above.
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 24),
      itemLabel: 'trips',
      itemBuilder: (_, trip, i) => TripCard(
        key: ValueKey(trip.tripId),
        bookinginfo: trip,
        status: trip.status ?? 0,
        onTripUpdated: _load,
      ),
    );
  }

  // Filter row: always-visible search bar + single filter button (with
  // active-count badge) that opens the shared TripPage-style filter sheet.
  Widget _buildFilterRow() {
    return Container(
      decoration: const BoxDecoration(
        color: _surface,
        border: Border(bottom: BorderSide(color: _divider)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: TripSearchBar(
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
            ),
          ),
          const SizedBox(width: 8),
          TripFilterButton(
            activeCount: _activeFilterCount,
            onTap: _openFilterSheet,
          ),
        ],
      ),
    );
  }

  Widget _filteredEmptyState() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: _accentSoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(_filter.icon, size: 28, color: _accent),
              ),
              const SizedBox(height: 14),
              Text(
                'No ${_filter.label} Trips',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: _textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Try a different filter above.',
                style: TextStyle(fontSize: 12, color: _textSecondary),
              ),
            ],
          ),
        ),
      );
}

/// Fixed-height pinned sliver header used to keep the customer identity bar
/// stuck to the top while the report card and trip list scroll.
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