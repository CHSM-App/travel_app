import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:travel_agency_app/Screens/trip_card.dart';
import 'package:travel_agency_app/core/theme/app_colors.dart';
import 'package:travel_agency_app/core/widgets/error_view.dart';
import 'package:travel_agency_app/domain/models/booking_info.dart';
import 'package:travel_agency_app/domain/models/ledger_entry.dart';
import 'package:travel_agency_app/presentation/providers/viewmodel_provider.dart';

/// Which side of the daybook to show. Revenue = money received, Expense =
/// trip expenses + maintenance.
enum TxnType { revenue, expense }

/// Date-window filter applied to the ledger, mirroring the Vehicle Report.
enum _Period { all, today, week, month, custom }

// ─── Design tokens ─────────────────────────────────────────────────────────
class _C {
  static const bg = Color(0xFFF5F7FB);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceLight = Color(0xFFF1F4FA);
  static const accent = AppColors.brandPrimary;
  static const header = AppColors.brandHeader;
  static const text1 = Color(0xFF0F1729);
  static const text2 = Color(0xFF6B7280);
  static const text3 = Color(0xFFA3ABBD);
  static const divider = Color(0xFFE6EAF2);
  static const green = Color(0xFF10B981);
  static const greenSoft = Color(0xFFD1FAE5);
  static const red = Color(0xFFEF4444);
  static const orange = Color(0xFFF59E0B);
  static const orangeSoft = Color(0xFFFEF3C7);
}

/// A flat, date-grouped list of individual money transactions — one row per
/// payment / expense — so the operator can see *who paid for which trip* and
/// *what each expense was for*. Fed by the agency ledger (each row is already a
/// single dated event), filtered by the period chips and the active [TxnType].
class TransactionsPage extends ConsumerStatefulWidget {
  /// Optional starting day. Pre-selects "Today" when it is today, otherwise
  /// pins the custom range to that single day.
  final DateTime? date;
  final TxnType initialType;

  const TransactionsPage({
    super.key,
    this.date,
    this.initialType = TxnType.revenue,
  });

  @override
  ConsumerState<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends ConsumerState<TransactionsPage> {
  late TxnType _type = widget.initialType;
  late _Period _period;
  DateTime? _customStart;
  DateTime? _customEnd;

  @override
  void initState() {
    super.initState();
    final d = widget.date;
    if (d == null) {
      _period = _Period.all;
    } else if (_sameDay(d, DateTime.now())) {
      _period = _Period.today;
    } else {
      _period = _Period.custom;
      _customStart = d;
      _customEnd = d;
    }
  }

  String _money(double v) =>
      '₹${NumberFormat.decimalPattern('en_IN').format(v.round())}';

  Future<void> _refresh() async {
    final aid = ref.read(loginViewModelProvider).agencyId ?? '';
    if (aid.isEmpty) return;
    ref.invalidate(vehicleReportLedgerProvider(aid));
  }

  // ── Period helpers ─────────────────────────────────────────────────
  String _periodLabel() {
    switch (_period) {
      case _Period.all:
        return 'All';
      case _Period.today:
        return 'Today';
      case _Period.week:
        return 'Week';
      case _Period.month:
        return 'Month';
      case _Period.custom:
        return 'Custom';
    }
  }

  IconData _periodIcon(_Period p) {
    switch (p) {
      case _Period.all:
        return Icons.all_inclusive_rounded;
      case _Period.today:
        return Icons.today_rounded;
      case _Period.week:
        return Icons.view_week_rounded;
      case _Period.month:
        return Icons.calendar_month_rounded;
      case _Period.custom:
        return Icons.date_range_rounded;
    }
  }

  String _periodChipLabel(_Period p) {
    if (p == _Period.custom && _customStart != null && _customEnd != null) {
      return '${_shortDate(_customStart!)} – ${_shortDate(_customEnd!)}';
    }
    switch (p) {
      case _Period.all:
        return 'All';
      case _Period.today:
        return 'Today';
      case _Period.week:
        return 'Week';
      case _Period.month:
        return 'Month';
      case _Period.custom:
        return 'Custom';
    }
  }

  String _shortDate(DateTime d) => DateFormat('dd MMM').format(d);

  /// Concrete date window for the active period (for the card / app bar).
  String _rangeLabel() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final fmt = DateFormat('dd MMM yyyy');
    switch (_period) {
      case _Period.all:
        return 'All time';
      case _Period.today:
        return fmt.format(today);
      case _Period.week:
        return '${fmt.format(today.subtract(const Duration(days: 6)))} - '
            '${fmt.format(today)}';
      case _Period.month:
        return DateFormat('MMMM yyyy').format(today);
      case _Period.custom:
        if (_customStart != null && _customEnd != null) {
          return _sameDay(_customStart!, _customEnd!)
              ? fmt.format(_customStart!)
              : '${fmt.format(_customStart!)} - ${fmt.format(_customEnd!)}';
        }
        return 'Select dates';
    }
  }

  bool _accept(DateTime? d, DateTime now) {
    if (_period == _Period.all) return true;
    if (d == null) return false;
    final dOnly = DateTime(d.year, d.month, d.day);
    final today = DateTime(now.year, now.month, now.day);
    switch (_period) {
      case _Period.today:
        return dOnly == today;
      case _Period.week:
        final start = today.subtract(const Duration(days: 6));
        return !dOnly.isBefore(start) && !dOnly.isAfter(today);
      case _Period.month:
        return d.year == now.year && d.month == now.month;
      case _Period.custom:
        final s = _customStart, e = _customEnd;
        if (s == null && e == null) return true;
        if (s != null && dOnly.isBefore(DateTime(s.year, s.month, s.day))) {
          return false;
        }
        if (e != null && dOnly.isAfter(DateTime(e.year, e.month, e.day))) {
          return false;
        }
        return true;
      case _Period.all:
        return true;
    }
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
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: initial,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(
                primary: _C.accent,
                onPrimary: Colors.white,
              ),
        ),
        child: child!,
      ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _customStart = picked.start;
      _customEnd = picked.end;
      _period = _Period.custom;
    });
  }

  // ── Per-entry helpers ──────────────────────────────────────────────
  bool _isExpense(LedgerEntry e) => e.isTripExpense || e.isMaintenance;

  bool _matchesType(LedgerEntry e) =>
      _type == TxnType.revenue ? e.isPayment : _isExpense(e);

  double _amount(LedgerEntry e) {
    if (e.isPayment) return e.revenue ?? 0;
    if (e.isTripExpense) return e.tripExpense ?? 0;
    if (e.isMaintenance) return e.maintenance ?? 0;
    return 0;
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// First available human label: customer → vehicle → generic.
  String _title(LedgerEntry e) {
    if (e.customerName != null) return e.customerName!;
    if (e.isMaintenance) return 'Maintenance';
    return e.vehicleName ?? 'Trip';
  }

  @override
  Widget build(BuildContext context) {
    final aid = ref.watch(loginViewModelProvider).agencyId ?? '';
    final ledgerAsync = ref.watch(vehicleReportLedgerProvider(aid));

    return Scaffold(
      backgroundColor: _C.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            _buildPeriodChips(),
            Expanded(
              child: ledgerAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation(_C.accent),
                  ),
                ),
                error: (e, _) => NetworkErrorView(error: e, onRetry: _refresh),
                data: (ledger) => _buildBody(ledger),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Body: overall card + tabs + list ───────────────────────────────
  Widget _buildBody(List<LedgerEntry> ledger) {
    final now = DateTime.now();
    final inPeriod =
        ledger.where((e) => _amount(e) > 0 && _accept(e.entryDate, now)).toList();

    final revenue = inPeriod
        .where((e) => e.isPayment)
        .fold<double>(0, (s, e) => s + _amount(e));
    final expense = inPeriod
        .where(_isExpense)
        .fold<double>(0, (s, e) => s + _amount(e));

    final rows = inPeriod.where(_matchesType).toList()
      ..sort((a, b) =>
          (b.entryDate ?? DateTime(0)).compareTo(a.entryDate ?? DateTime(0)));

    final amountColor = _type == TxnType.revenue ? _C.green : _C.red;

    return RefreshIndicator(
      color: _C.accent,
      backgroundColor: _C.surface,
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
        children: [
          _overallCard(revenue, expense, inPeriod.length),
          const SizedBox(height: 14),
          _buildTypeTabs(),
          const SizedBox(height: 14),
          if (rows.isEmpty)
            _inlineEmpty()
          else
            ..._daySections(rows, amountColor),
        ],
      ),
    );
  }

  // ── Overall card (net · revenue · expense), like the Vehicle Report ─
  Widget _overallCard(double revenue, double expense, int count) {
    final net = revenue - expense;
    final isProfit = net >= 0;
    final margin = revenue > 0 ? (net / revenue * 100) : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: _C.header,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _C.header.withValues(alpha: 0.30),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
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
                child: const Icon(Icons.account_balance_wallet_rounded,
                    color: Colors.white, size: 12),
              ),
              const SizedBox(width: 8),
              Text(
                'Overall · ${_periodLabel()}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
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
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.event_rounded,
                  size: 12, color: Colors.white.withValues(alpha: 0.82)),
              const SizedBox(width: 5),
              Text(
                _rangeLabel(),
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
                '${isProfit ? '' : '−'}${_money(net.abs())}',
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
          Row(
            children: [
              Expanded(
                child: _pnlStat(
                    'Revenue', revenue, Icons.south_west_rounded),
              ),
              _pnlDivider(),
              Expanded(
                child: _pnlStat(
                    'Expense', expense, Icons.north_east_rounded),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _footerChip(
            Icons.receipt_long_rounded,
            '$count transaction${count == 1 ? '' : 's'}',
          ),
        ],
      ),
    );
  }

  Widget _pnlDivider() => Container(
        width: 1,
        height: 32,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        color: Colors.white.withValues(alpha: 0.18),
      );

  Widget _pnlStat(String label, double value, IconData icon) {
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
          _money(value),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15.5,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
            height: 1.1,
          ),
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
                  'Transactions',
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
                  'Who paid for which trip',
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

  // ── Period filter chips (scrollable), like the Vehicle Report ───────
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
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final p in _Period.values) ...[
                _periodChip(p),
                if (p != _Period.values.last) const SizedBox(width: 4),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _periodChip(_Period p) {
    final active = p == _period;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (p == _Period.custom) {
          _pickCustomRange();
        } else {
          setState(() => _period = p);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 14),
        decoration: BoxDecoration(
          color: active ? _C.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_periodIcon(p),
                size: 13, color: active ? Colors.white : _C.text2),
            const SizedBox(width: 4),
            Text(
              _periodChipLabel(p),
              maxLines: 1,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: active ? Colors.white : _C.text2,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Revenue / Expense tabs ─────────────────────────────────────────
  Widget _buildTypeTabs() {
    return Container(
      height: 42,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _C.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.divider),
      ),
      child: Row(
        children: [
          _tabPill(TxnType.revenue, 'Revenue', Icons.south_west_rounded),
          _tabPill(TxnType.expense, 'Expense', Icons.north_east_rounded),
        ],
      ),
    );
  }

  Widget _tabPill(TxnType type, String label, IconData icon) {
    final selected = _type == type;
    final color = type == TxnType.revenue ? _C.green : _C.orange;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _type = type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: selected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: selected ? Colors.white : _C.text2),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: selected ? Colors.white : _C.text2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Day-grouped rows ───────────────────────────────────────────────
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
    final isRevenue = _type == TxnType.revenue;
    final leadingColor = e.isMaintenance ? _C.orange : (isRevenue ? _C.green : _C.orange);
    final leadingBg =
        e.isMaintenance ? _C.orangeSoft : (isRevenue ? _C.greenSoft : _C.orangeSoft);
    final leadingIcon = e.isMaintenance
        ? Icons.build_rounded
        : (isRevenue ? Icons.south_west_rounded : Icons.north_east_rounded);

    final hasRoute = e.pickup != null && e.drop != null;

    // Distinct meta chips so each fact reads on its own.
    final chips = <Widget>[
      if (e.vehicleNumber != null)
        _metaChip(Icons.directions_car_rounded, e.vehicleNumber!, _C.text2),
      if (isRevenue && e.paymentMode != null)
        _metaChip(Icons.account_balance_wallet_rounded, e.paymentMode!, _C.accent),
      if (!isRevenue)
        _metaChip(
          e.isMaintenance ? Icons.build_rounded : Icons.local_gas_station_rounded,
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
              color: _C.accent.withValues(alpha: 0.03),
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

  /// A small tinted pill so each metadata fact (vehicle, payment mode, expense
  /// kind) reads as its own distinct token instead of a run-on text string.
  Widget _metaChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
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

  // ── Tap dispatch ───────────────────────────────────────────────────
  /// Trip-backed rows open the full (editable) trip sheet from [TripCard];
  /// maintenance rows (no trip) fall back to a read-only ledger sheet.
  void _openTxnSheet(LedgerEntry e) {
    if (e.tripId != null) {
      _openTripSheet(e.tripId!);
    } else {
      _openLedgerSheet(e);
    }
  }

  /// Loads the agency trips (once), finds the one matching [tripId], and opens
  /// the same bottom sheet the trip list uses — with payment, end-trip and
  /// cancel actions. Falls back to a message if the trip can't be located.
  Future<void> _openTripSheet(int tripId) async {
    final notifier = ref.read(tripPageViewModelProvider.notifier);
    List<BookingInfo>? all =
        ref.read(tripPageViewModelProvider).allList.asData?.value;

    if (all == null || all.isEmpty) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: CircularProgressIndicator(color: _C.accent),
        ),
      );
      final aid = ref.read(loginViewModelProvider).agencyId ?? '';
      if (aid.isNotEmpty) await notifier.allTrips(aid);
      if (mounted) Navigator.pop(context); // close the spinner
      all = ref.read(tripPageViewModelProvider).allList.asData?.value;
    }
    if (!mounted) return;

    BookingInfo? trip;
    for (final t in all ?? const <BookingInfo>[]) {
      if (t.tripId == tripId) {
        trip = t;
        break;
      }
    }
    if (trip == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trip details are not available')),
      );
      return;
    }

    TripCard(
      bookinginfo: trip,
      status: trip.status ?? 0,
      onTripUpdated: () async => _refresh(),
    ).showDetailSheet(context, ref);
  }

  // ── Read-only ledger sheet (maintenance / no-trip rows) ────────────
  /// Sheet for entries that aren't tied to a trip: amount + context only.
  void _openLedgerSheet(LedgerEntry e) {
    final tripId = e.tripId;
    if (tripId != null) {
      ref.read(tripPageViewModelProvider.notifier).paymentHistory(tripId);
    }
    final isRevenue = e.isPayment;
    final amtColor =
        e.isMaintenance ? _C.orange : (isRevenue ? _C.green : _C.red);
    final amtBg = e.isMaintenance
        ? _C.orangeSoft
        : (isRevenue ? _C.greenSoft : Color(0xFFFEE2E2));
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
                  color: _C.text3.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              // Header
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
                    if (tripId != null) ...[
                      const SizedBox(height: 12),
                      _sheetPaymentHistory(),
                    ],
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
        rows.add(Divider(height: 16, color: _C.divider));
      }
      rows.add(_sheetDetailRow(icon, label, value));
    }

    add(Icons.person_outline_rounded, 'Customer', e.customerName);
    if (e.pickup != null && e.drop != null) {
      add(Icons.route_rounded, 'Route', '${e.pickup} → ${e.drop}');
    }
    add(Icons.directions_car_outlined, 'Vehicle',
        [e.vehicleName, e.vehicleNumber].where((s) => s != null).join(' · '));
    add(Icons.event_rounded, 'Date',
        e.entryDate == null ? null : DateFormat('dd MMM yyyy').format(e.entryDate!));
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

  Widget _sheetPaymentHistory() {
    Widget shell(Widget child) => Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: _C.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _C.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.receipt_long_rounded, size: 15, color: _C.accent),
                  SizedBox(width: 7),
                  Text(
                    'PAYMENT HISTORY',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: _C.accent,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              child,
            ],
          ),
        );

    return Consumer(
      builder: (context, innerRef, _) {
        final async = innerRef
            .watch(tripPageViewModelProvider.select((s) => s.paymentHistory));
        return async.when(
          loading: () => shell(
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.2, color: _C.accent),
                ),
              ),
            ),
          ),
          error: (_, __) => shell(
            const Text(
              "Couldn't load payment history",
              style: TextStyle(fontSize: 12, color: _C.text2),
            ),
          ),
          data: (payments) {
            if (payments.isEmpty) {
              return shell(
                const Text(
                  'No payments recorded yet',
                  style: TextStyle(fontSize: 12, color: _C.text2),
                ),
              );
            }
            final total =
                payments.fold<double>(0, (s, p) => s + (p.Amount ?? 0));
            return shell(
              Column(
                children: [
                  for (var i = 0; i < payments.length; i++) ...[
                    if (i > 0) Divider(height: 14, color: _C.divider),
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: _C.greenSoft,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet_rounded,
                            size: 16,
                            color: _C.green,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                payments[i].PaymentMode?.isNotEmpty == true
                                    ? payments[i].PaymentMode!
                                    : 'Payment',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: _C.text1,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                payments[i].PaymentDate == null
                                    ? '--'
                                    : DateFormat('dd MMM yyyy, h:mm a')
                                        .format(payments[i].PaymentDate!),
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  color: _C.text2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          _money(payments[i].Amount ?? 0),
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: _C.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                  Divider(height: 18, color: _C.divider),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total paid',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: _C.text1,
                        ),
                      ),
                      Text(
                        _money(total),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: _C.accent,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ── Inline empty (keeps the card + tabs visible) ───────────────────
  Widget _inlineEmpty() {
    final isRevenue = _type == TxnType.revenue;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: isRevenue ? _C.greenSoft : _C.orangeSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isRevenue
                  ? Icons.account_balance_wallet_outlined
                  : Icons.payments_outlined,
              size: 32,
              color: isRevenue ? _C.green : _C.orange,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isRevenue
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
            isRevenue
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
    );
  }
}
