import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart' as share_plus;
import 'package:travel_agency_app/domain/models/reports_data.dart';
import 'package:travel_agency_app/presentation/providers/viewmodel_provider.dart';

// ─────────────────────────────────────────────────────────────
//  DESIGN TOKENS
// ─────────────────────────────────────────────────────────────
const _primary  = Color(0xFF3D5AFE);
const _darkBlue = Color(0xFF1A237E);
const _bg       = Color(0xFFF0F4FF);
const _white    = Color(0xFFFFFFFF);
const _textDark = Color(0xFF1A1A2E);
const _textGrey = Color(0xFF7A7A8A);
const _divLine  = Color(0xFFEEEEF2);
const _green    = Color(0xFF00BFA5);
const _orange   = Color(0xFFFF6D00);
const _purple   = Color(0xFFAB47BC);
const _red      = Color(0xFFE53935);

// ─────────────────────────────────────────────────────────────
//  DATE FILTER ENUM
// ─────────────────────────────────────────────────────────────
enum DateFilterType { today, monthly, yearly, custom }

extension DateFilterExt on DateFilterType {
  String get label {
    switch (this) {
      case DateFilterType.today:   return 'Today';
      case DateFilterType.monthly: return 'Monthly';
      case DateFilterType.yearly:  return 'Yearly';
      case DateFilterType.custom:  return 'Custom';
    }
  }
  IconData get icon {
    switch (this) {
      case DateFilterType.today:   return Icons.today_rounded;
      case DateFilterType.monthly: return Icons.calendar_month_rounded;
      case DateFilterType.yearly:  return Icons.calendar_today_rounded;
      case DateFilterType.custom:  return Icons.date_range_rounded;
    }
  }
}

// ─────────────────────────────────────────────────────────────
//  REPORT TAB ENUM
// ─────────────────────────────────────────────────────────────
enum ReportTabType { booking, driver, vehicle, customer, revenue }

extension ReportTabExt on ReportTabType {
  String get label {
    switch (this) {
      case ReportTabType.booking:  return 'Booking';
      case ReportTabType.driver:   return 'Driver';
      case ReportTabType.vehicle:  return 'Vehicle';
      case ReportTabType.customer: return 'Customer';
      case ReportTabType.revenue:  return 'Revenue';
    }
  }
  IconData get icon {
    switch (this) {
      case ReportTabType.booking:  return Icons.confirmation_number_outlined;
      case ReportTabType.driver:   return Icons.person_pin_outlined;
      case ReportTabType.vehicle:  return Icons.directions_car_outlined;
      case ReportTabType.customer: return Icons.people_alt_outlined;
      case ReportTabType.revenue:  return Icons.bar_chart_rounded;
    }
  }
  Color get color {
    switch (this) {
      case ReportTabType.booking:  return _primary;
      case ReportTabType.driver:   return _green;
      case ReportTabType.vehicle:  return _orange;
      case ReportTabType.customer: return _purple;
      case ReportTabType.revenue:  return _red;
    }
  }
  Color get bgColor {
    switch (this) {
      case ReportTabType.booking:  return const Color(0xFFE8EAFF);
      case ReportTabType.driver:   return const Color(0xFFE0F7F4);
      case ReportTabType.vehicle:  return const Color(0xFFFFF3E0);
      case ReportTabType.customer: return const Color(0xFFF3E5F5);
      case ReportTabType.revenue:  return const Color(0xFFFFEBEA);
    }
  }
  int get tabIndex {
    switch (this) {
      case ReportTabType.booking:  return 0;
      case ReportTabType.driver:   return 1;
      case ReportTabType.vehicle:  return 2;
      case ReportTabType.customer: return 3;
      case ReportTabType.revenue:  return 4;
    }
  }
  String get apiType {
    switch (this) {
      case ReportTabType.booking:  return 'trip';
      case ReportTabType.driver:   return 'driver';
      case ReportTabType.vehicle:  return 'vehicle';
      case ReportTabType.customer: return 'customer';
      case ReportTabType.revenue:  return 'revenue';
    }
  }
}

// ─────────────────────────────────────────────────────────────
//  AGGREGATION
// ─────────────────────────────────────────────────────────────
class _Agg {
  final String key;
  final String name;
  final String sub;
  double income, expense, profit, loss, net;
  int trips;
  final List<ReportData> tripRows = [];

  _Agg({required this.key, required this.name, this.sub = ''})
      : income = 0, expense = 0, profit = 0, loss = 0, net = 0, trips = 0;

  void add(ReportData d) {
    income  += d.income;
    expense += d.expense;
    profit  += d.profitVal;
    loss    += d.lossVal;
    net     += d.net;
    trips   += d.tripsCount;
    tripRows.add(d);
  }
}

List<_Agg> _aggregateDriver(List<ReportData> data) {
  final map = <String, _Agg>{};
  for (final d in data) {
    final key = d.driverId?.toString() ?? d.driverName ?? 'Unknown';
    map.putIfAbsent(key, () => _Agg(key: key, name: d.driverName ?? 'Unknown', sub: d.driverPhone ?? '-'));
    map[key]!.add(d);
  }
  return map.values.toList()..sort((a, b) => b.income.compareTo(a.income));
}

List<_Agg> _aggregateVehicle(List<ReportData> data) {
  final map = <String, _Agg>{};
  for (final d in data) {
    final key = d.vehicleId?.toString() ?? d.vehicleName ?? 'Unknown';
    map.putIfAbsent(key, () => _Agg(key: key, name: d.vehicleName ?? 'Unknown', sub: d.vehicleNumber ?? '-'));
    map[key]!.add(d);
  }
  return map.values.toList()..sort((a, b) => b.income.compareTo(a.income));
}

List<_Agg> _aggregateCustomer(List<ReportData> data) {
  final map = <String, _Agg>{};
  for (final d in data) {
    final key = d.customerId?.toString() ?? d.customerName ?? 'Unknown';
    map.putIfAbsent(key, () => _Agg(key: key, name: d.customerName ?? 'Unknown', sub: d.customerPhone ?? '-'));
    map[key]!.add(d);
  }
  return map.values.toList()..sort((a, b) => b.income.compareTo(a.income));
}

List<_Agg> _aggregateRevenue(List<ReportData> data) {
  final map = <String, _Agg>{};
  for (final d in data) {
    final key   = DateFormat('yyyy-MM-dd').format(d.safeDate);
    final label = DateFormat('dd MMM yyyy').format(d.safeDate);
    map.putIfAbsent(key, () => _Agg(key: key, name: label));
    map[key]!.add(d);
  }
  return map.values.toList()..sort((a, b) => b.key.compareTo(a.key));
}

// ─────────────────────────────────────────────────────────────
//  DATE FILTER
// ─────────────────────────────────────────────────────────────
List<ReportData> _applyDateFilter(
    List<ReportData> raw, DateFilterType filterType,
    DateTime? customStart, DateTime? customEnd) {
  final now = DateTime.now();
  DateTime? start;
  DateTime? end;
  switch (filterType) {
    case DateFilterType.today:
      start = DateTime(now.year, now.month, now.day);
      end   = DateTime(now.year, now.month, now.day);
      break;
    case DateFilterType.monthly:
      start = DateTime(now.year, now.month, 1);
      end   = DateTime(now.year, now.month + 1, 0);
      break;
    case DateFilterType.yearly:
      start = DateTime(now.year, 1, 1);
      end   = DateTime(now.year, 12, 31);
      break;
    case DateFilterType.custom:
      start = customStart;
      end   = customEnd;
      break;
  }
  if (start == null && end == null) return raw;
  return raw.where((e) {
    final d   = e.safeDate;
    final day = DateTime(d.year, d.month, d.day);
    if (start != null && day.isBefore(start)) return false;
    if (end   != null && day.isAfter(end))    return false;
    return true;
  }).toList();
}

// ─────────────────────────────────────────────────────────────
//  SHEET STATE — simple: nothing selected by default
// ─────────────────────────────────────────────────────────────
class _SheetState {
  // Per-section item selections — all EMPTY at start
  Map<ReportTabType, Set<String>> sel = {};
  // Which section accordion is open
  ReportTabType? openSection;

  _SheetState() {
    for (final tab in ReportTabType.values) {
      sel[tab] = {};
    }
  }

  bool get anySelected => ReportTabType.values.any((t) => sel[t]!.isNotEmpty);

  int get totalSelected => ReportTabType.values.fold(0, (s, t) => s + sel[t]!.length);

  // Is this section fully selected
  bool isAllSelected(ReportTabType tab, List<String> names) =>
      names.isNotEmpty && sel[tab]!.length == names.length;

  // Is partially selected
  bool isPartial(ReportTabType tab, List<String> names) =>
      sel[tab]!.isNotEmpty && sel[tab]!.length < names.length;
}

// ─────────────────────────────────────────────────────────────
//  MAIN REPORT PAGE
// ─────────────────────────────────────────────────────────────
class TravelReportPage extends ConsumerStatefulWidget {
  final String agencyId;
  
  const TravelReportPage({super.key, required this.agencyId});

  @override
  ConsumerState<TravelReportPage> createState() => _TravelReportPageState();
}

class _TravelReportPageState extends ConsumerState<TravelReportPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  ReportTabType  _activeTab  = ReportTabType.booking;
  DateFilterType _filterType = DateFilterType.today;
  DateTime?      _customStart;
  DateTime?      _customEnd;
  bool           _pdfLoading = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: ReportTabType.values.length, vsync: this)
      ..addListener(() {
        if (!_tabCtrl.indexIsChanging) return;
        final tab = ReportTabType.values[_tabCtrl.index];
        setState(() => _activeTab = tab);
        ref.read(reportViewModelProvider.notifier)
            .loadTab(widget.agencyId, tab.tabIndex);
      });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(reportViewModelProvider.notifier)
          .loadTab(widget.agencyId, ReportTabType.booking.tabIndex);
    });
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  DateTime? get _effectiveStart {
    final now = DateTime.now();
    switch (_filterType) {
      case DateFilterType.today:   return DateTime(now.year, now.month, now.day);
      case DateFilterType.monthly: return DateTime(now.year, now.month, 1);
      case DateFilterType.yearly:  return DateTime(now.year, 1, 1);
      case DateFilterType.custom:  return _customStart;
    }
  }

  DateTime? get _effectiveEnd {
    final now = DateTime.now();
    switch (_filterType) {
      case DateFilterType.today:   return DateTime(now.year, now.month, now.day);
      case DateFilterType.monthly: return DateTime(now.year, now.month + 1, 0);
      case DateFilterType.yearly:  return DateTime(now.year, 12, 31);
      case DateFilterType.custom:  return _customEnd;
    }
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now    = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? (_customStart ?? now) : (_customEnd ?? now),
      firstDate: DateTime(2020), lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(colorScheme: ColorScheme.light(
          primary: _activeTab.color, onPrimary: _white, surface: _white, onSurface: _textDark)),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _customStart = picked;
        if (_customEnd != null && _customEnd!.isBefore(picked)) _customEnd = null;
      } else {
        _customEnd = picked;
        if (_customStart != null && picked.isBefore(_customStart!)) _customStart = null;
      }
    });
  }

  // ── Names for each tab ───────────────────────────────────
  String _bookingLabel(ReportData e) {
    final id = e.tripId?.toString() ?? '-';
    final customer = (e.customerName == null || e.customerName!.trim().isEmpty)
        ? 'Customer'
        : e.customerName!.trim();
    return 'Trip #$id • $customer';
  }

  List<String> _namesFor(ReportTabType tab, List<ReportData> data) {
    switch (tab) {
      case ReportTabType.booking:
        return data.map(_bookingLabel).toList();
      case ReportTabType.driver:   return _aggregateDriver(data).map((a) => a.name).toList();
      case ReportTabType.vehicle:  return _aggregateVehicle(data).map((a) => a.name).toList();
      case ReportTabType.customer: return _aggregateCustomer(data).map((a) => a.name).toList();
      case ReportTabType.revenue:  return _aggregateRevenue(data).map((a) => a.name).toList();
    }
  }



  // ─────────────────────────────────────────────────────────
  //  DOWNLOAD SHEET  — Simple accordion, nothing pre-selected
  // ─────────────────────────────────────────────────────────
  Future<void> _showDownloadSheet(
    Map<ReportTabType, List<ReportData>> filteredByTab,
  ) async {
    if (_pdfLoading) return;

    // Pre-compute all names per section (cached, not recomputed on rebuild)
    final allNames = <ReportTabType, List<String>>{
      for (final t in ReportTabType.values)
        t: _namesFor(t, filteredByTab[t] ?? const []),
    };
    // Pre-compute income+trips map for fast subtitle rendering
    final aggCache = <ReportTabType, Map<String, _Agg>>{};
    for (final t in ReportTabType.values) {
      final tabData = filteredByTab[t] ?? const <ReportData>[];
      List<_Agg> aggs;
      switch (t) {
        case ReportTabType.driver:   aggs = _aggregateDriver(tabData);   break;
        case ReportTabType.vehicle:  aggs = _aggregateVehicle(tabData);  break;
        case ReportTabType.customer: aggs = _aggregateCustomer(tabData); break;
        case ReportTabType.revenue:  aggs = _aggregateRevenue(tabData);  break;
        case ReportTabType.booking:
          // booking: one item per trip
          aggs = tabData.map((row) {
            final a = _Agg(
              key: _bookingLabel(row),
              name: _bookingLabel(row),
              sub: row.driverName ?? '-',
            );
            a.add(row);
            return a;
          }).toList();
          break;
      }
      aggCache[t] = {for (final a in aggs) a.name: a};
    }

    final st = _SheetState(); // empty by default

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, ss) {

        // ── helper chips: which sections have selections ──
        final activeSections = ReportTabType.values.where((t) => st.sel[t]!.isNotEmpty).toList();

        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.88, minChildSize: 0.5, maxChildSize: 0.95,
          builder: (_, ctrl) => Column(children: [

            // ── TOP HANDLE + HEADER ───────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
              decoration: const BoxDecoration(
                color: _white,
                border: Border(bottom: BorderSide(color: _divLine)),
              ),
              child: Column(children: [
                Center(child: Container(width: 40, height: 4,
                    decoration: BoxDecoration(color: _divLine, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 14),
                Row(children: [
                  // PDF icon
                  Container(padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: const Color(0xFFE8EAFF), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.picture_as_pdf_rounded, color: _primary, size: 20)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Download Report', style: TextStyle(color: _textDark, fontSize: 15, fontWeight: FontWeight.w800)),
                    Text(
                      st.totalSelected == 0
                          ? 'Select sections & items below'
                          : '${st.totalSelected} item${st.totalSelected == 1 ? '' : 's'} selected',
                      style: TextStyle(
                        color: st.totalSelected == 0 ? _textGrey : _primary,
                        fontSize: 11, fontWeight: FontWeight.w500),
                    ),
                  ])),
                  // Select All button
                  GestureDetector(
                    onTap: () => ss(() {
                      for (final t in ReportTabType.values) {
                        st.sel[t]!..clear()..addAll(allNames[t]!);
                      }
                      // open no section after select all — just show badges
                      st.openSection = null;
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                          color: const Color(0xFFE8EAFF),
                          borderRadius: BorderRadius.circular(20)),
                      child: const Text('Select All', style: TextStyle(color: _primary, fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ]),

                // ── Selected section badges (shown only when something selected) ──
                if (activeSections.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(children: activeSections.map((t) {
                      final cnt  = st.sel[t]!.length;
                      final tot  = allNames[t]!.length;
                      return GestureDetector(
                        onTap: () => ss(() => st.sel[t]!.clear()),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                              color: t.bgColor, borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: t.color.withOpacity(0.3))),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(t.icon, size: 11, color: t.color),
                            const SizedBox(width: 5),
                            Text('${t.label}  $cnt/$tot',
                                style: TextStyle(color: t.color, fontSize: 11, fontWeight: FontWeight.w700)),
                            const SizedBox(width: 5),
                            Icon(Icons.close_rounded, size: 11, color: t.color.withOpacity(0.6)),
                          ]),
                        ),
                      );
                    }).toList()),
                  ),
                ],
              ]),
            ),

            // ── ACCORDION LIST ────────────────────────────
            Expanded(
              child: ListView.builder(
                controller: ctrl,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                itemCount: ReportTabType.values.length,
                itemBuilder: (_, idx) {
                  final tab      = ReportTabType.values[idx];
                  final names    = allNames[tab]!;
                  final tabSel   = st.sel[tab]!;
                  final isOpen   = st.openSection == tab;
                  final hasData  = names.isNotEmpty;
                  final selCount = tabSel.length;
                  final isAll    = st.isAllSelected(tab, names);
                  final isPart   = st.isPartial(tab, names);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: _white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selCount > 0 ? tab.color.withOpacity(0.4) : _divLine,
                        width: selCount > 0 ? 1.5 : 1,
                      ),
                      boxShadow: [BoxShadow(
                          color: (selCount > 0 ? tab.color : Colors.black).withOpacity(0.06),
                          blurRadius: 8, offset: const Offset(0, 2))],
                    ),
                    child: Column(children: [

                      // ── Section header row ────────────────
                      InkWell(
                        onTap: hasData ? () => ss(() {
                          st.openSection = isOpen ? null : tab;
                        }) : null,
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                          child: Row(children: [
                            // Section icon badge
                            Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(
                                  color: selCount > 0 ? tab.color.withOpacity(0.12) : tab.bgColor,
                                  borderRadius: BorderRadius.circular(11)),
                              alignment: Alignment.center,
                              child: Icon(tab.icon, color: selCount > 0 ? tab.color : _textGrey, size: 18),
                            ),
                            const SizedBox(width: 12),

                            // Label + subtitle
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(tab.label,
                                  style: TextStyle(
                                      color: hasData ? _textDark : _textGrey,
                                      fontSize: 14, fontWeight: FontWeight.w700)),
                              Text(
                                !hasData
                                    ? 'No data available'
                                    : selCount == 0
                                        ? '${names.length} item${names.length == 1 ? '' : 's'} available'
                                        : isAll
                                            ? 'All ${names.length} selected ✓'
                                            : '$selCount of ${names.length} selected',
                                style: TextStyle(
                                    color: !hasData
                                        ? _divLine
                                        : selCount == 0
                                            ? _textGrey
                                            : tab.color,
                                    fontSize: 11),
                              ),
                            ])),

                            // Right side: quick ALL button + chevron
                            if (hasData) ...[
                              // "All" quick select tap — doesn't open accordion
                              GestureDetector(
                                onTap: () => ss(() {
                                  if (isAll) {
                                    tabSel.clear();
                                  } else {
                                    tabSel..clear()..addAll(names);
                                  }
                                }),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                      color: isAll ? tab.color : tab.bgColor,
                                      borderRadius: BorderRadius.circular(20)),
                                  child: Text(
                                    isAll ? 'All ✓' : 'All',
                                    style: TextStyle(
                                        color: isAll ? _white : tab.color,
                                        fontSize: 11, fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],

                            AnimatedRotation(
                              turns: isOpen ? 0.5 : 0,
                              duration: const Duration(milliseconds: 200),
                              child: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: hasData ? (isOpen ? tab.color : _textGrey) : _divLine,
                                size: 22,
                              ),
                            ),
                          ]),
                        ),
                      ),

                      // ── Expanded item list ────────────────
                      AnimatedSize(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        child: isOpen
                            ? Container(
                                decoration: BoxDecoration(
                                    border: Border(top: BorderSide(color: tab.color.withOpacity(0.15)))),
                                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                                child: Column(children: [
                                  // Clear all row inside expanded
                                  if (selCount > 0)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Row(children: [
                                        Text('$selCount selected',
                                            style: TextStyle(color: tab.color, fontSize: 11, fontWeight: FontWeight.w700)),
                                        const Spacer(),
                                        GestureDetector(
                                          onTap: () => ss(() => tabSel.clear()),
                                          child: Text('Clear', style: const TextStyle(color: _textGrey, fontSize: 11, fontWeight: FontWeight.w600)),
                                        ),
                                      ]),
                                    ),
                                  ...names.map((name) {
                                    final isSel = tabSel.contains(name);
                                    final agg   = aggCache[tab]![name];
                                    final inc   = agg?.income ?? 0;
                                    final trps  = agg?.trips  ?? 0;

                                    Widget avatar;
                                    switch (tab) {
                                      case ReportTabType.vehicle:
                                        avatar = Icon(Icons.directions_car_rounded, size: 15, color: isSel ? tab.color : _textGrey);
                                        break;
                                      case ReportTabType.revenue:
                                        avatar = Icon(Icons.bar_chart_rounded, size: 15, color: isSel ? tab.color : _textGrey);
                                        break;
                                      default:
                                        avatar = Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                                            style: TextStyle(color: isSel ? tab.color : _textGrey, fontSize: 13, fontWeight: FontWeight.w800));
                                    }

                                    return GestureDetector(
                                      onTap: () => ss(() =>
                                          isSel ? tabSel.remove(name) : tabSel.add(name)),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 120),
                                        margin: const EdgeInsets.only(bottom: 6),
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: isSel ? tab.color.withOpacity(0.07) : _bg,
                                          borderRadius: BorderRadius.circular(11),
                                          border: Border.all(
                                              color: isSel ? tab.color.withOpacity(0.3) : _divLine),
                                        ),
                                        child: Row(children: [
                                          Container(
                                            width: 32, height: 32,
                                            decoration: BoxDecoration(
                                                color: isSel ? tab.color.withOpacity(0.12) : _divLine.withOpacity(0.3),
                                                borderRadius: BorderRadius.circular(9)),
                                            alignment: Alignment.center, child: avatar,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                            Text(name, style: TextStyle(
                                                color: isSel ? _textDark : _textGrey,
                                                fontSize: 12, fontWeight: FontWeight.w700),
                                                maxLines: 1, overflow: TextOverflow.ellipsis),
                                            if (trps > 0 || inc > 0)
                                              Text('$trps trip${trps == 1 ? '' : 's'}  ·  ₹${_fmt(inc)}',
                                                  style: TextStyle(color: isSel ? _textGrey : _divLine, fontSize: 10)),
                                          ])),
                                          // Checkbox
                                          AnimatedContainer(
                                            duration: const Duration(milliseconds: 120),
                                            width: 20, height: 20,
                                            decoration: BoxDecoration(
                                                color: isSel ? tab.color : _white,
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(
                                                    color: isSel ? tab.color : _divLine, width: 1.5)),
                                            child: isSel ? const Icon(Icons.check_rounded, size: 13, color: _white) : null,
                                          ),
                                        ]),
                                      ),
                                    );
                                  }),
                                ]),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ]),
                  );
                },
              ),
            ),

            // ── STICKY BOTTOM: Generate PDF button ───────
            Container(
              padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(ctx).viewInsets.bottom + 20),
              decoration: BoxDecoration(
                color: _white,
                border: const Border(top: BorderSide(color: _divLine)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, -3))],
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: st.anySelected ? _primary : _divLine,
                    foregroundColor: _white, elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: st.anySelected ? () async {
                    Navigator.of(ctx).pop();
                    await _generateAndShow(
                      filteredByTab: filteredByTab,
                      st: st,
                      allNames: allNames,
                    );
                  } : null,
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: Text(
                    st.anySelected
                        ? 'Generate PDF  (${st.totalSelected} items)'
                        : 'Select items to generate PDF',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),

          ]),
        );
      }),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  GENERATE
  Future<void> _generateAndShow({
    required Map<ReportTabType, List<ReportData>> filteredByTab,
    required _SheetState st,
    required Map<ReportTabType, List<String>> allNames,
  }) async {
    setState(() => _pdfLoading = true);
    try {
      // Per-section filtered data — only sections with selections
      final sectionData = <ReportTabType, List<ReportData>>{};
      for (final tab in ReportTabType.values) {
        final sel = st.sel[tab]!;
        if (sel.isEmpty) {
          sectionData[tab] = [];
          continue;
        }
        final tabData = filteredByTab[tab] ?? const <ReportData>[];
        final all = allNames[tab]!;
        sectionData[tab] = sel.length == all.length
            ? tabData
            : _filterByNames(tabData, tab, sel);
      }

      final allData = filteredByTab[ReportTabType.booking] ?? const <ReportData>[];
      final file = await _PdfGenerator.generate(
        allData: allData, sectionData: sectionData,
        startDate: _effectiveStart, endDate: _effectiveEnd,
        st: st, allNames: allNames,
      );

      if (!mounted) return;

      final badges = <_SectionBadge>[];
      for (final tab in ReportTabType.values) {
        final sel = st.sel[tab]!;
        if (sel.isEmpty) continue;
        final all = allNames[tab]!;
        badges.add(_SectionBadge(tab: tab, hint: sel.length < all.length ? '${sel.length}/${all.length}' : 'All'));
      }

      await showModalBottomSheet(
        context: context,
        backgroundColor: _white,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (_) => _PdfReadySheet(file: file, badges: badges),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Please try again.'), backgroundColor: _red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    } finally {
      if (mounted) setState(() => _pdfLoading = false);
    }
  }

  List<ReportData> _filterByNames(List<ReportData> data, ReportTabType tab, Set<String> sel) {
    switch (tab) {
      case ReportTabType.booking:
        return data.where((e) => sel.contains(_bookingLabel(e))).toList();
      case ReportTabType.customer:
        return data.where((e) => sel.contains(e.customerName ?? 'Unknown')).toList();
      case ReportTabType.driver:
        return data.where((e) => sel.contains(e.driverName ?? 'Unknown')).toList();
      case ReportTabType.vehicle:
        return data.where((e) => sel.contains(e.vehicleName ?? 'Unknown')).toList();
      case ReportTabType.revenue:
        return data.where((e) => sel.contains(DateFormat('dd MMM yyyy').format(e.safeDate))).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reportViewModelProvider);
    return Scaffold(
      backgroundColor: _bg,
      body: Column(children: [
        _ReportHeader(
          activeTab: _activeTab, pdfLoading: _pdfLoading,
          onDownload: () async {
            final notifier = ref.read(reportViewModelProvider.notifier);
            for (final tab in ReportTabType.values) {
              await notifier.loadTab(widget.agencyId, tab.tabIndex);
            }
            if (!mounted) return;

            final latestState = ref.read(reportViewModelProvider);
            final filteredByTab = <ReportTabType, List<ReportData>>{};
            var hasAnyData = false;

            for (final tab in ReportTabType.values) {
              final asyncVal = latestState.getByTab(tab.tabIndex);
              if (asyncVal.isLoading) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Report is still loading'),
                  behavior: SnackBarBehavior.floating,
                ));
                return;
              }
              if (asyncVal.hasError) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Cannot generate PDF: ${asyncVal.error}'),
                  backgroundColor: _red,
                  behavior: SnackBarBehavior.floating,
                ));
                return;
              }

              final raw = asyncVal.value ?? const <ReportData>[];
              final filtered = _applyDateFilter(
                raw,
                _filterType,
                _customStart,
                _customEnd,
              );
              filteredByTab[tab] = filtered;
              if (filtered.isNotEmpty) hasAnyData = true;
            }

            if (!hasAnyData) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('No data available for selected date filter'),
                behavior: SnackBarBehavior.floating,
              ));
              return;
            }

            _showDownloadSheet(filteredByTab);
          },
        ),
        _DateFilterBar(
          filterType: _filterType, customStart: _customStart, customEnd: _customEnd,
          activeColor: _activeTab.color, effectiveStart: _effectiveStart, effectiveEnd: _effectiveEnd,
          onTypeChanged: (t) => setState(() {
            _filterType = t;
            if (t != DateFilterType.custom) { _customStart = null; _customEnd = null; }
          }),
          onPickStart: () => _pickDate(isStart: true),
          onPickEnd:   () => _pickDate(isStart: false),
        ),
        _ReportTabBar(controller: _tabCtrl, activeTab: _activeTab),
        const SizedBox(height: 4),
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: ReportTabType.values.map((tab) {
              final asyncVal = state.getByTab(tab.tabIndex);
              return asyncVal.when(
                loading: () => _LoadingView(color: tab.color),
                error: (e, _) => _ErrorView(color: tab.color, errorMessage: e.toString(),
                    onRetry: () => ref.read(reportViewModelProvider.notifier).reloadTab(widget.agencyId, tab.tabIndex)),
                data: (rawList) {
                  final filtered = _applyDateFilter(rawList, _filterType, _customStart, _customEnd);
                  switch (tab) {
                    case ReportTabType.booking:  return _BookingTab(data: filtered,  filterType: _filterType);
                    case ReportTabType.driver:   return _DriverTab(data: filtered,   filterType: _filterType);
                    case ReportTabType.vehicle:  return _VehicleTab(data: filtered,  filterType: _filterType);
                    case ReportTabType.customer: return _CustomerTab(data: filtered, filterType: _filterType);
                    case ReportTabType.revenue:  return _RevenueTab(data: filtered,  filterType: _filterType);
                  }
                },
              );
            }).toList(),
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  PDF READY SHEET  (Open + Share)
// ─────────────────────────────────────────────────────────────
class _SectionBadge {
  final ReportTabType tab;
  final String hint;
  const _SectionBadge({required this.tab, required this.hint});
}

class _PdfReadySheet extends StatelessWidget {
  final File file;
  final List<_SectionBadge> badges;
  const _PdfReadySheet({required this.file, required this.badges});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 40, height: 4, decoration: BoxDecoration(color: _divLine, borderRadius: BorderRadius.circular(2))),
      const SizedBox(height: 18),
      Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFFE8EAFF), borderRadius: BorderRadius.circular(16)),
          child: const Icon(Icons.picture_as_pdf_rounded, color: _primary, size: 36)),
      const SizedBox(height: 12),
      const Text('Report Ready!', style: TextStyle(color: _textDark, fontSize: 17, fontWeight: FontWeight.w800)),
      const SizedBox(height: 10),
      // Section badges
      Wrap(spacing: 8, runSpacing: 6,
        children: badges.map((b) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(color: b.tab.bgColor, borderRadius: BorderRadius.circular(20),
              border: Border.all(color: b.tab.color.withOpacity(0.25))),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(b.tab.icon, size: 11, color: b.tab.color), const SizedBox(width: 4),
            Text('${b.tab.label}  ${b.hint}',
                style: TextStyle(color: b.tab.color, fontSize: 11, fontWeight: FontWeight.w700)),
          ]),
        )).toList(),
      ),
      const SizedBox(height: 8),
      Text(file.path.split('/').last, style: const TextStyle(color: _textGrey, fontSize: 10), textAlign: TextAlign.center),
      const SizedBox(height: 18),
      // Open PDF
      SizedBox(width: double.infinity, child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: _white, elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
        onPressed: () { Navigator.of(context).pop(); OpenFile.open(file.path); },
        icon: const Icon(Icons.open_in_new_rounded, size: 18),
        label: const Text('Open PDF', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
      )),
      const SizedBox(height: 10),
      // Share
      SizedBox(width: double.infinity, child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(foregroundColor: _primary,
            side: const BorderSide(color: Color(0x663D5AFE)),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
        onPressed: () {
          Navigator.of(context).pop();
          share_plus.Share.shareXFiles([share_plus.XFile(file.path)], subject: 'Travel Agency Report');
        },
        icon: const Icon(Icons.share_rounded, size: 18),
        label: const Text('Share', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
      )),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────
//  PDF GENERATOR  — multi-section
// ─────────────────────────────────────────────────────────────
class _PdfGenerator {
  static final _hc  = PdfColor.fromHex('#3D5AFE');
  static final _gc  = PdfColor.fromHex('#00BFA5');
  static final _rc  = PdfColor.fromHex('#E53935');
  static final _oc  = PdfColor.fromHex('#FF6D00');
  static final _pc  = PdfColor.fromHex('#AB47BC');
  static final _tg  = PdfColor.fromHex('#7A7A8A');
  static final _td  = PdfColor.fromHex('#1A1A2E');
  static final _dl  = PdfColor.fromHex('#EEEEEE');
  static final _bgP = PdfColor.fromHex('#F0F4FF');

  static PdfColor _tc(ReportTabType tab) {
    switch (tab) {
      case ReportTabType.booking:  return _hc;
      case ReportTabType.driver:   return _gc;
      case ReportTabType.vehicle:  return _oc;
      case ReportTabType.customer: return _pc;
      case ReportTabType.revenue:  return _rc;
    }
  }

  static String _f(double v) {
    if (v >= 1e7) return '${(v / 1e7).toStringAsFixed(2)} Cr';
    if (v >= 1e5) return '${(v / 1e5).toStringAsFixed(2)} L';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(2)} K';
    return v.toStringAsFixed(0);
  }

  static pw.Widget _c(String t, pw.TextStyle s, {pw.TextAlign a = pw.TextAlign.left}) =>
      pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5), child: pw.Text(t, style: s, textAlign: a));

  static pw.Widget _hdr(String title, String dateStr, PdfColor color) => pw.Container(
    padding: const pw.EdgeInsets.only(bottom: 10),
    decoration: pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: color, width: 2))),
    child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
      pw.Row(children: [pw.Container(width: 5, height: 18, color: color), pw.SizedBox(width: 8), pw.Text(title, style: pw.TextStyle(color: _td, fontSize: 14, fontWeight: pw.FontWeight.bold))]),
      pw.Text(dateStr, style: pw.TextStyle(color: _tg, fontSize: 9)),
    ]),
  );

  static pw.Widget _ftr(pw.Context ctx, String section) => pw.Container(
    padding: const pw.EdgeInsets.only(top: 8),
    decoration: pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(color: _dl))),
    child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
      pw.Text(section, style: pw.TextStyle(color: _tg, fontSize: 8)),
      pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}', style: pw.TextStyle(color: _tg, fontSize: 8)),
    ]),
  );

  static pw.Widget _kpi(String label, String value, PdfColor color) => pw.Expanded(child: pw.Container(
    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    decoration: pw.BoxDecoration(color: PdfColors.white, borderRadius: pw.BorderRadius.circular(8), border: pw.Border.all(color: _dl)),
    child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Text(value, style: pw.TextStyle(color: color, fontSize: 13, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 3),
      pw.Text(label, style: pw.TextStyle(color: _tg, fontSize: 8)),
    ]),
  ));

  static Future<File> generate({
    required List<ReportData> allData,
    required Map<ReportTabType, List<ReportData>> sectionData,
    required DateTime? startDate,
    required DateTime? endDate,
    required _SheetState st,
    required Map<ReportTabType, List<String>> allNames,
  }) async {
    final pdf = pw.Document();
    final dateStr = startDate == null && endDate == null ? 'All time'
        : '${startDate != null ? DateFormat('dd MMM yyyy').format(startDate) : '...'} – ${endDate != null ? DateFormat('dd MMM yyyy').format(endDate) : '...'}';

    final totalIncome  = allData.fold(0.0, (s, e) => s + e.income);
    final totalExpense = allData.fold(0.0, (s, e) => s + e.expense);
    final totalNet     = allData.fold(0.0, (s, e) => s + e.net);
    final hStyle     = pw.TextStyle(color: PdfColors.white, fontSize: 9, fontWeight: pw.FontWeight.bold);
    final rStyle     = pw.TextStyle(color: _td, fontSize: 9);
    final gStyle     = pw.TextStyle(color: _tg, fontSize: 9);
    final greenStyle = pw.TextStyle(color: _gc, fontSize: 9, fontWeight: pw.FontWeight.bold);

    // ── COVER PAGE ────────────────────────────────────────
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(0),
      build: (ctx) => pw.Column(children: [
        pw.Container(
          height: 150,
          decoration: pw.BoxDecoration(gradient: pw.LinearGradient(
              colors: [_hc, PdfColor.fromHex('#1A237E')],
              begin: pw.Alignment.topLeft, end: pw.Alignment.bottomRight)),
          padding: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 30),
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, mainAxisAlignment: pw.MainAxisAlignment.center, children: [
            pw.Text('Travel Agency Report', style: pw.TextStyle(color: PdfColors.white, fontSize: 26, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            pw.Text('Period: $dateStr', style: pw.TextStyle(color: PdfColors.white, fontSize: 10)),
            pw.SizedBox(height: 4),
            pw.Text('Generated: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}', style: pw.TextStyle(color: PdfColors.white, fontSize: 10)),
          ]),
        ),
        pw.Padding(padding: const pw.EdgeInsets.all(40), child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Row(children: [
            _kpi('Total Income',   'Rs. ${_f(totalIncome)}',  _gc),  pw.SizedBox(width: 10),
            _kpi('Total Expense',  'Rs. ${_f(totalExpense)}', _oc),  pw.SizedBox(width: 10),
            _kpi(totalNet >= 0 ? 'Total Profit' : 'Total Loss', 'Rs. ${_f(totalNet.abs())}', totalNet >= 0 ? _gc : _rc), pw.SizedBox(width: 10),
            _kpi('Total Records',  allData.length.toString(),  _hc),
          ]),
          pw.SizedBox(height: 28),
          // Section index
          pw.Row(children: [pw.Container(width: 4, height: 15, color: _hc), pw.SizedBox(width: 8), pw.Text('Report Sections', style: pw.TextStyle(color: _td, fontSize: 12, fontWeight: pw.FontWeight.bold))]),
          pw.SizedBox(height: 10),
          pw.Table(
            border: pw.TableBorder.all(color: _dl, width: 0.5),
            columnWidths: {0: const pw.FlexColumnWidth(0.5), 1: const pw.FlexColumnWidth(2), 2: const pw.FlexColumnWidth(2), 3: const pw.FlexColumnWidth(1.5)},
            children: [
              pw.TableRow(decoration: pw.BoxDecoration(color: _hc), children: [
                _c('Page', hStyle), _c('Section', hStyle), _c('Selection', hStyle), _c('Records', hStyle, a: pw.TextAlign.center),
              ]),
              ...() {
                int pn = 2;
                final rows = <pw.TableRow>[];
                for (final tab in ReportTabType.values) {
                  final data = sectionData[tab]!;
                  if (data.isEmpty) continue;
                  final sel    = st.sel[tab]!;
                  final allCnt = allNames[tab]!.length;
                  final hint   = sel.length < allCnt ? '${sel.length}/$allCnt selected' : 'All';
                  final even   = rows.length % 2 == 0;
                  rows.add(pw.TableRow(
                    decoration: pw.BoxDecoration(color: even ? PdfColors.white : _bgP),
                    children: [
                      _c('Page $pn', pw.TextStyle(color: _tc(tab), fontSize: 9, fontWeight: pw.FontWeight.bold)),
                      _c(tab.label, rStyle), _c(hint, gStyle),
                      _c('${data.length}', gStyle, a: pw.TextAlign.center),
                    ],
                  ));
                  pn++;
                }
                return rows;
              }(),
            ],
          ),
        ])),
      ]),
    ));

    // ── SECTION PAGES ─────────────────────────────────────
    for (final tab in ReportTabType.values) {
      final data = sectionData[tab]!;
      if (data.isEmpty) continue;

      final tabColor   = _tc(tab);
      final sel        = st.sel[tab]!;
      final allCnt     = allNames[tab]!.length;
      final selHint    = sel.length < allCnt ? '${sel.length}/$allCnt' : 'All';
      final secIncome  = data.fold(0.0, (s, e) => s + e.income);
      final secExpense = data.fold(0.0, (s, e) => s + e.expense);
      final secNet     = data.fold(0.0, (s, e) => s + e.net);

      if (tab == ReportTabType.booking) {
        pdf.addPage(pw.MultiPage(
          pageFormat: PdfPageFormat.a4, margin: const pw.EdgeInsets.all(40),
          header: (ctx) => _hdr('${tab.label} Report  [$selHint]', dateStr, tabColor),
          footer: (ctx) => _ftr(ctx, tab.label),
          build: (ctx) => [
            pw.SizedBox(height: 12),
            pw.Row(children: [
              _kpi('Records', data.length.toString(), tabColor), pw.SizedBox(width: 8),
              _kpi('Income', 'Rs. ${_f(secIncome)}', _gc), pw.SizedBox(width: 8),
              _kpi('Expense', 'Rs. ${_f(secExpense)}', _oc), pw.SizedBox(width: 8),
              _kpi(secNet >= 0 ? 'Profit' : 'Loss', 'Rs. ${_f(secNet.abs())}', secNet >= 0 ? _gc : _rc),
            ]),
            pw.SizedBox(height: 14),
            ...data.asMap().entries.expand((e) {
              final trip = e.value;
              final net = trip.net;
              final netStyle = pw.TextStyle(
                color: net >= 0 ? _gc : _rc,
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
              );

              return <pw.Widget>[
                pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 10),
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: e.key % 2 == 0 ? PdfColors.white : _bgP,
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.Border.all(color: _dl),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'Trip #${trip.tripId ?? e.key + 1}',
                            style: pw.TextStyle(
                              color: tabColor,
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.Text(
                            DateFormat('dd MMM yyyy').format(trip.safeDate),
                            style: gStyle,
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 6),
                      pw.Row(
                        children: [
                          pw.Expanded(
                            child: pw.Text(
                              'Customer: ${trip.customerName ?? '-'}',
                              style: rStyle,
                            ),
                          ),
                          pw.SizedBox(width: 10),
                          pw.Expanded(
                            child: pw.Text(
                              'Driver: ${trip.driverName ?? '-'}',
                              style: rStyle,
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text('Vehicle: ${trip.vehicleName ?? '-'}', style: rStyle),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        'Pickup: ${trip.pickupLocation ?? '-'}',
                        style: pw.TextStyle(color: _td, fontSize: 9),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        'Drop: ${trip.dropLocation ?? '-'}',
                        style: pw.TextStyle(color: _td, fontSize: 9),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.white,
                          borderRadius: pw.BorderRadius.circular(6),
                          border: pw.Border.all(color: _dl),
                        ),
                        child: pw.Row(
                          children: [
                            pw.Expanded(
                              child: pw.Text(
                                'Trip Charge: Rs. ${_f(trip.income)}',
                                style: greenStyle,
                              ),
                            ),
                            pw.Expanded(
                              child: pw.Text(
                                'Expense: Rs. ${_f(trip.expense)}',
                                style: gStyle,
                                textAlign: pw.TextAlign.center,
                              ),
                            ),
                            pw.Expanded(
                              child: pw.Text(
                                'Net: Rs. ${_f(net.abs())}',
                                style: netStyle,
                                textAlign: pw.TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ];
            }),
          ],
        ));
      } else {
        List<_Agg> aggs;
        String col1;
        switch (tab) {
          case ReportTabType.driver:   aggs = _aggregateDriver(data);   col1 = 'Driver';   break;
          case ReportTabType.vehicle:  aggs = _aggregateVehicle(data);  col1 = 'Vehicle';  break;
          case ReportTabType.customer: aggs = _aggregateCustomer(data); col1 = 'Customer'; break;
          default:                     aggs = _aggregateRevenue(data);  col1 = 'Date';
        }
        final grand = aggs.fold(0.0, (s, a) => s + a.income);

        pdf.addPage(pw.MultiPage(
          pageFormat: PdfPageFormat.a4, margin: const pw.EdgeInsets.all(40),
          header: (ctx) => _hdr('${tab.label} Report  [$selHint]', dateStr, tabColor),
          footer: (ctx) => _ftr(ctx, tab.label),
          build: (ctx) => [
            pw.SizedBox(height: 12),
            pw.Row(children: [
              _kpi(col1, aggs.length.toString(), tabColor), pw.SizedBox(width: 8),
              _kpi('Income', 'Rs. ${_f(secIncome)}', _gc), pw.SizedBox(width: 8),
              _kpi(secNet >= 0 ? 'Profit' : 'Loss', 'Rs. ${_f(secNet.abs())}', secNet >= 0 ? _gc : _rc),
            ]),
            pw.SizedBox(height: 14),
            pw.Table(
              border: pw.TableBorder.all(color: _dl, width: 0.5),
              columnWidths: {0: const pw.FlexColumnWidth(0.5), 1: const pw.FlexColumnWidth(2.5), 2: const pw.FlexColumnWidth(0.8), 3: const pw.FlexColumnWidth(1.5), 4: const pw.FlexColumnWidth(1.5), 5: const pw.FlexColumnWidth(1.2), 6: const pw.FlexColumnWidth(1.0)},
              children: [
                pw.TableRow(decoration: pw.BoxDecoration(color: tabColor), children: [
                  _c('#', hStyle), _c(col1, hStyle), _c('Trips', hStyle, a: pw.TextAlign.center),
                  _c('Income', hStyle, a: pw.TextAlign.right), _c('Expense', hStyle, a: pw.TextAlign.right),
                  _c('Net', hStyle, a: pw.TextAlign.right), _c('Share%', hStyle, a: pw.TextAlign.right),
                ]),
                ...aggs.asMap().entries.map((e) {
                  final net = e.value.net;
                  final pct = grand > 0 ? e.value.income / grand * 100 : 0.0;
                  return pw.TableRow(
                    decoration: pw.BoxDecoration(color: e.key % 2 == 0 ? PdfColors.white : _bgP),
                    children: [
                      _c('${e.key + 1}', gStyle, a: pw.TextAlign.center), _c(e.value.name, rStyle),
                      _c('${e.value.trips}', gStyle, a: pw.TextAlign.center),
                      _c('Rs. ${_f(e.value.income)}', greenStyle, a: pw.TextAlign.right),
                      _c('Rs. ${_f(e.value.expense)}', gStyle, a: pw.TextAlign.right),
                      _c('Rs. ${_f(net.abs())}', pw.TextStyle(color: net >= 0 ? _gc : _rc, fontSize: 9, fontWeight: pw.FontWeight.bold), a: pw.TextAlign.right),
                      _c('${pct.toStringAsFixed(1)}%', gStyle, a: pw.TextAlign.right),
                    ],
                  );
                }),
                // Total row
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColor.fromHex('#E8F8F1')),
                  children: [
                    _c('', gStyle),
                    _c('TOTAL', pw.TextStyle(color: _td, fontSize: 9, fontWeight: pw.FontWeight.bold)),
                    _c('${aggs.fold(0, (s, a) => s + a.trips)}', pw.TextStyle(color: _td, fontSize: 9, fontWeight: pw.FontWeight.bold), a: pw.TextAlign.center),
                    _c('Rs. ${_f(secIncome)}', pw.TextStyle(color: _gc, fontSize: 9, fontWeight: pw.FontWeight.bold), a: pw.TextAlign.right),
                    _c('Rs. ${_f(secExpense)}', gStyle, a: pw.TextAlign.right),
                    _c('Rs. ${_f(secNet.abs())}', pw.TextStyle(color: secNet >= 0 ? _gc : _rc, fontSize: 9, fontWeight: pw.FontWeight.bold), a: pw.TextAlign.right),
                    _c('100%', gStyle, a: pw.TextAlign.right),
                  ],
                ),
              ],
            ),
            // if (tab == ReportTabType.revenue) ...[
            //   pw.SizedBox(height: 14),
            //   pw.Row(children: [
            //     pw.Container(width: 4, height: 14, color: tabColor),
            //     pw.SizedBox(width: 8),
            //     pw.Text('Trip Details', style: pw.TextStyle(color: _td, fontSize: 11, fontWeight: pw.FontWeight.bold)),
            //   ]),
            //   pw.SizedBox(height: 8),
            //   pw.Table(
            //     border: pw.TableBorder.all(color: _dl, width: 0.5),
            //     columnWidths: {
            //       0: const pw.FlexColumnWidth(0.5),
            //       1: const pw.FlexColumnWidth(1.0),
            //       2: const pw.FlexColumnWidth(1.5),
            //       3: const pw.FlexColumnWidth(1.3),
            //       4: const pw.FlexColumnWidth(1.2),
            //       5: const pw.FlexColumnWidth(2.0),
            //       6: const pw.FlexColumnWidth(1.0),
            //       7: const pw.FlexColumnWidth(1.0),
            //       8: const pw.FlexColumnWidth(1.0),
            //     },
            //     children: [
            //       pw.TableRow(decoration: pw.BoxDecoration(color: tabColor), children: [
            //         _c('#', hStyle),
            //         _c('Date', hStyle),
            //         _c('Customer', hStyle),
            //         _c('Driver', hStyle),
            //         _c('Vehicle', hStyle),
            //         _c('Route', hStyle),
            //         _c('Charge', hStyle, a: pw.TextAlign.right),
            //         _c('Exp', hStyle, a: pw.TextAlign.right),
            //         _c('Net', hStyle, a: pw.TextAlign.right),
            //       ]),
            //       ...data.asMap().entries.map((e) {
            //         final trip = e.value;
            //         final net = trip.net;
            //         final route = '${trip.pickupLocation ?? '-'} -> ${trip.dropLocation ?? '-'}';
            //         return pw.TableRow(
            //           decoration: pw.BoxDecoration(color: e.key % 2 == 0 ? PdfColors.white : _bgP),
            //           children: [
            //             _c('${e.key + 1}', gStyle, a: pw.TextAlign.center),
            //             _c(DateFormat('dd MMM yy').format(trip.safeDate), gStyle),
            //             _c(trip.customerName ?? '-', rStyle),
            //             _c(trip.driverName ?? '-', rStyle),
            //             _c(trip.vehicleName ?? '-', rStyle),
            //             _c(route, gStyle),
            //             _c('Rs. ${_f(trip.income)}', greenStyle, a: pw.TextAlign.right),
            //             _c('Rs. ${_f(trip.expense)}', gStyle, a: pw.TextAlign.right),
            //             _c(
            //               'Rs. ${_f(net.abs())}',
            //               pw.TextStyle(color: net >= 0 ? _gc : _rc, fontSize: 9, fontWeight: pw.FontWeight.bold),
            //               a: pw.TextAlign.right,
            //             ),
            //           ],
            //         );
            //       }),
            //     ],
            //   ),
            // ],
          ],
        ));
      }
    }

    final dir  = await getTemporaryDirectory();
    final ts   = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${dir.path}/travel_report_$ts.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }
}

// ─────────────────────────────────────────────────────────────
//  HEADER
// ─────────────────────────────────────────────────────────────
class _ReportHeader extends StatelessWidget {
  final ReportTabType activeTab; final bool pdfLoading; final VoidCallback onDownload;
  const _ReportHeader({required this.activeTab, required this.pdfLoading, required this.onDownload});

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 300),
    decoration: BoxDecoration(gradient: LinearGradient(colors: [activeTab.color, Color.lerp(activeTab.color, _darkBlue, 0.45)!], begin: Alignment.topLeft, end: Alignment.bottomRight)),
    padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 10, left: 16, right: 16, bottom: 18),
    child: Row(children: [
      IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _white, size: 18), onPressed: () => Navigator.of(context).maybePop(), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
      const SizedBox(width: 10),
      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Reports', style: TextStyle(color: _white, fontSize: 20, fontWeight: FontWeight.w800)),
        Text('Booking • Driver • Vehicle • Customer • Revenue', style: TextStyle(color: Colors.white70, fontSize: 11), overflow: TextOverflow.ellipsis),
      ])),
      GestureDetector(
        onTap: pdfLoading ? null : onDownload,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white30)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            pdfLoading ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: _white, strokeWidth: 2)) : const Icon(Icons.picture_as_pdf_rounded, color: _white, size: 16),
            const SizedBox(width: 6),
            Text(pdfLoading ? 'Generating…' : 'Download', style: const TextStyle(color: _white, fontSize: 12, fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────
//  DATE FILTER BAR
// ─────────────────────────────────────────────────────────────
class _DateFilterBar extends StatelessWidget {
  final DateFilterType filterType; final DateTime? customStart, customEnd, effectiveStart, effectiveEnd;
  final Color activeColor; final ValueChanged<DateFilterType> onTypeChanged; final VoidCallback onPickStart, onPickEnd;
  const _DateFilterBar({required this.filterType, required this.customStart, required this.customEnd, required this.activeColor, required this.effectiveStart, required this.effectiveEnd, required this.onTypeChanged, required this.onPickStart, required this.onPickEnd});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(16, 14, 16, 0), padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: _white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: activeColor.withOpacity(0.10), blurRadius: 12, offset: const Offset(0, 3))],
        border: filterType != DateFilterType.today ? Border.all(color: activeColor.withOpacity(0.25)) : null),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: DateFilterType.values.map((t) {
        final sel = filterType == t;
        return Expanded(child: GestureDetector(onTap: () => onTypeChanged(t),
          child: AnimatedContainer(duration: const Duration(milliseconds: 180), margin: const EdgeInsets.symmetric(horizontal: 3), padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(color: sel ? activeColor : _bg, borderRadius: BorderRadius.circular(10), border: sel ? null : Border.all(color: _divLine)),
            child: Column(children: [Icon(t.icon, size: 14, color: sel ? _white : _textGrey), const SizedBox(height: 3), Text(t.label, style: TextStyle(fontSize: 9, fontWeight: sel ? FontWeight.w700 : FontWeight.w500, color: sel ? _white : _textGrey), textAlign: TextAlign.center)]))));
      }).toList()),
      if (filterType == DateFilterType.custom) ...[
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _DatePill(label: 'From', value: customStart == null ? 'Select date' : DateFormat('dd MMM yyyy').format(customStart!), selected: customStart != null, color: activeColor, onTap: onPickStart)),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Icon(Icons.arrow_forward_rounded, color: _textGrey.withOpacity(0.5), size: 16)),
          Expanded(child: _DatePill(label: 'To', value: customEnd == null ? 'Select date' : DateFormat('dd MMM yyyy').format(customEnd!), selected: customEnd != null, color: activeColor, onTap: onPickEnd)),
        ]),
      ],
      if (effectiveStart != null || effectiveEnd != null) ...[
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: activeColor.withOpacity(0.10), borderRadius: BorderRadius.circular(20)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.filter_alt_rounded, color: activeColor, size: 13), const SizedBox(width: 5),
            Text(
              (effectiveStart != null && effectiveEnd != null && effectiveStart == effectiveEnd)
                  ? DateFormat('dd MMM yyyy').format(effectiveStart!)
                  : '${effectiveStart != null ? DateFormat('dd MMM').format(effectiveStart!) : '...'}  →  ${effectiveEnd != null ? DateFormat('dd MMM yyyy').format(effectiveEnd!) : '...'}',
              style: TextStyle(color: activeColor, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ]),
        ),
      ],
    ]),
  );
}

class _DatePill extends StatelessWidget {
  final String label, value; final bool selected; final Color color; final VoidCallback onTap;
  const _DatePill({required this.label, required this.value, required this.selected, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(onTap: onTap, child: AnimatedContainer(
    duration: const Duration(milliseconds: 200), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    decoration: BoxDecoration(color: selected ? color.withOpacity(0.08) : _bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: selected ? color.withOpacity(0.4) : _divLine)),
    child: Row(children: [
      Icon(Icons.calendar_today_rounded, color: selected ? color : _textGrey, size: 13), const SizedBox(width: 7),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(color: selected ? color : _textGrey, fontSize: 10, fontWeight: FontWeight.w600)),
        Text(value, style: TextStyle(color: selected ? _textDark : _textGrey, fontSize: 11, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
      ])),
    ]),
  ));
}

// ─────────────────────────────────────────────────────────────
//  TAB BAR
// ─────────────────────────────────────────────────────────────
class _ReportTabBar extends StatelessWidget {
  final TabController controller; final ReportTabType activeTab;
  const _ReportTabBar({required this.controller, required this.activeTab});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(16, 14, 16, 0), height: 46,
    decoration: BoxDecoration(color: _white, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 8, offset: const Offset(0, 2))]),
    child: TabBar(controller: controller, isScrollable: true, tabAlignment: TabAlignment.start,
      indicator: BoxDecoration(color: activeTab.color, borderRadius: BorderRadius.circular(11)),
      indicatorSize: TabBarIndicatorSize.tab, indicatorPadding: const EdgeInsets.all(3),
      labelColor: _white, unselectedLabelColor: _textGrey,
      labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
      unselectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
      dividerColor: Colors.transparent, padding: const EdgeInsets.all(3),
      tabs: ReportTabType.values.map((tab) => Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(tab.icon, size: 13), const SizedBox(width: 5), Text(tab.label)]))).toList()),
  );
}

// ─────────────────────────────────────────────────────────────
//  SUMMARY ROW / FINANCE / PROGRESS
// ─────────────────────────────────────────────────────────────
class _SumItem { final IconData icon; final String label, value; final Color color; const _SumItem(this.icon, this.label, this.value, this.color); }

class _SummaryRow extends StatelessWidget {
  final List<_SumItem> items; const _SummaryRow({required this.items});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(16, 12, 16, 2), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
    decoration: BoxDecoration(color: _white, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 8, offset: const Offset(0, 2))]),
    child: Row(children: items.asMap().entries.expand((e) {
      final ws = <Widget>[Expanded(child: Column(children: [Icon(e.value.icon, color: e.value.color, size: 16), const SizedBox(height: 3), Text(e.value.value, style: TextStyle(color: e.value.color, fontSize: 13, fontWeight: FontWeight.w800)), Text(e.value.label, style: const TextStyle(color: _textGrey, fontSize: 10))]))];
      if (e.key < items.length - 1) ws.add(Container(width: 1, height: 32, color: _divLine));
      return ws;
    }).toList()),
  );
}

Widget _financeRow({required double income, required double expense, required double net}) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(10)),
  child: Row(children: [_finChip('Income', income, _green), const SizedBox(width: 8), _finChip('Expense', expense, _orange), const SizedBox(width: 8), _finChip(net >= 0 ? 'Profit' : 'Loss', net.abs(), net >= 0 ? _green : _red)]),
);
Widget _finChip(String label, double val, Color color) => Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(color: _textGrey, fontSize: 9)), Text('₹${_fmt(val)}', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700))]));
Widget _progressBar(double pct, Color color) => TweenAnimationBuilder<double>(tween: Tween(begin: 0, end: pct), duration: const Duration(milliseconds: 650), curve: Curves.easeOut, builder: (_, v, __) => ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: v, minHeight: 5, backgroundColor: _divLine, valueColor: AlwaysStoppedAnimation(color))));

// ─────────────────────────────────────────────────────────────
//  BOOKING TAB
// ─────────────────────────────────────────────────────────────
class _BookingTab extends StatelessWidget {
  final List<ReportData> data; final DateFilterType filterType;
  const _BookingTab({required this.data, required this.filterType});
  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return _noData(filterType, _primary);
    final totalIncome = data.fold(0.0, (s, e) => s + e.income);
    final totalNet    = data.fold(0.0, (s, e) => s + e.net);
    return Column(children: [
      _SummaryRow(items: [_SumItem(Icons.confirmation_number_outlined, 'Bookings', data.length.toString(), _primary), _SumItem(Icons.currency_rupee_rounded, 'Income', '₹${_fmt(totalIncome)}', _green), _SumItem(Icons.trending_up_rounded, 'Net', '₹${_fmt(totalNet.abs())}', totalNet >= 0 ? _green : _red)]),
      Expanded(child: ListView.separated(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), itemCount: data.length, separatorBuilder: (_, __) => const SizedBox(height: 10), itemBuilder: (_, i) => _BookingCard(item: data[i], index: i))),
    ]);
  }
}

class _BookingCard extends StatelessWidget {
  final ReportData item; final int index;
  const _BookingCard({required this.item, required this.index});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: _white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: _primary.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 3))]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 36, height: 36, decoration: BoxDecoration(color: const Color(0xFFE8EAFF), borderRadius: BorderRadius.circular(10)), alignment: Alignment.center, child: Text('#${item.tripId ?? index + 1}', style: const TextStyle(color: _primary, fontSize: 11, fontWeight: FontWeight.w800))),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item.customerName ?? 'Customer', style: const TextStyle(color: _textDark, fontSize: 13, fontWeight: FontWeight.w700)), Text(DateFormat('dd MMM yyyy').format(item.safeDate), style: const TextStyle(color: _textGrey, fontSize: 11))])),
        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: const Color(0xFFE0F7F4), borderRadius: BorderRadius.circular(10)), child: Text('₹${_fmt(item.income)}', style: const TextStyle(color: _green, fontSize: 13, fontWeight: FontWeight.w800))),
      ]),
      const SizedBox(height: 10),
      Row(children: [const Icon(Icons.my_location_rounded, size: 12, color: _green), const SizedBox(width: 4), Expanded(child: Text(item.pickupLocation ?? '-', style: const TextStyle(color: _textGrey, fontSize: 11), overflow: TextOverflow.ellipsis)), const Icon(Icons.arrow_forward_rounded, size: 12, color: _textGrey), const SizedBox(width: 4), const Icon(Icons.location_on_rounded, size: 12, color: _red), const SizedBox(width: 4), Expanded(child: Text(item.dropLocation ?? '-', style: const TextStyle(color: _textGrey, fontSize: 11), overflow: TextOverflow.ellipsis))]),
      const SizedBox(height: 8),
      Row(children: [const Icon(Icons.person_rounded, size: 12, color: _textGrey), const SizedBox(width: 4), Text(item.driverName ?? '-', style: const TextStyle(color: _textGrey, fontSize: 11)), const SizedBox(width: 12), const Icon(Icons.directions_car_rounded, size: 12, color: _textGrey), const SizedBox(width: 4), Expanded(child: Text(item.vehicleName ?? '-', style: const TextStyle(color: _textGrey, fontSize: 11), overflow: TextOverflow.ellipsis))]),
      const SizedBox(height: 10),
      _financeRow(income: item.income, expense: item.expense, net: item.net),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────
//  TRIP MINI CARD
// ─────────────────────────────────────────────────────────────
class _TripMiniCard extends StatelessWidget {
  final ReportData trip; final int index; final Color color;
  const _TripMiniCard({required this.trip, required this.index, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: color.withOpacity(0.04), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.18))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), decoration: BoxDecoration(color: color.withOpacity(0.13), borderRadius: BorderRadius.circular(6)), child: Text('Trip #${trip.tripId ?? index + 1}', style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800))),
        const SizedBox(width: 8), Expanded(child: Text(DateFormat('dd MMM yyyy').format(trip.safeDate), style: const TextStyle(color: _textGrey, fontSize: 10))),
        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: const Color(0xFFE0F7F4), borderRadius: BorderRadius.circular(6)), child: Text('₹${_fmt(trip.income)}', style: const TextStyle(color: _green, fontSize: 11, fontWeight: FontWeight.w800))),
      ]),
      const SizedBox(height: 8),
      if (trip.customerName != null) ...[Row(children: [const Icon(Icons.person_outline_rounded, size: 11, color: _textGrey), const SizedBox(width: 4), Text(trip.customerName!, style: const TextStyle(color: _textDark, fontSize: 11, fontWeight: FontWeight.w600))]), const SizedBox(height: 4)],
      if (trip.pickupLocation != null || trip.dropLocation != null)
        Row(children: [const Icon(Icons.my_location_rounded, size: 11, color: _green), const SizedBox(width: 3), Expanded(child: Text(trip.pickupLocation ?? '-', style: const TextStyle(color: _textGrey, fontSize: 10), overflow: TextOverflow.ellipsis)), const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Icon(Icons.arrow_forward_rounded, size: 10, color: _textGrey)), const Icon(Icons.location_on_rounded, size: 11, color: _red), const SizedBox(width: 3), Expanded(child: Text(trip.dropLocation ?? '-', style: const TextStyle(color: _textGrey, fontSize: 10), overflow: TextOverflow.ellipsis))]),
      const SizedBox(height: 6),
      Row(children: [
        if (trip.driverName != null) ...[const Icon(Icons.person_rounded, size: 11, color: _textGrey), const SizedBox(width: 3), Expanded(child: Text(trip.driverName!, style: const TextStyle(color: _textGrey, fontSize: 10), overflow: TextOverflow.ellipsis))],
        if (trip.vehicleName != null) ...[const SizedBox(width: 8), const Icon(Icons.directions_car_rounded, size: 11, color: _textGrey), const SizedBox(width: 3), Expanded(child: Text(trip.vehicleName!, style: const TextStyle(color: _textGrey, fontSize: 10), overflow: TextOverflow.ellipsis))],
      ]),
      const SizedBox(height: 6),
      Row(children: [_miniFinChip('Income', trip.income, _green), const SizedBox(width: 6), _miniFinChip('Expense', trip.expense, _orange), const SizedBox(width: 6), _miniFinChip(trip.net >= 0 ? 'Profit' : 'Loss', trip.net.abs(), trip.net >= 0 ? _green : _red)]),
    ]),
  );
}
Widget _miniFinChip(String label, double val, Color color) => Expanded(child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5), decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(6)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: TextStyle(color: color.withOpacity(0.7), fontSize: 8)), Text('₹${_fmt(val)}', style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700))])));

// ─────────────────────────────────────────────────────────────
//  AGG CARD
// ─────────────────────────────────────────────────────────────
class _AggCard extends StatefulWidget {
  final _Agg agg; final double grand; final Color color; final Widget avatar;
  const _AggCard({required this.agg, required this.grand, required this.color, required this.avatar});
  @override State<_AggCard> createState() => _AggCardState();
}
class _AggCardState extends State<_AggCard> {
  bool _expanded = false;
  @override
  Widget build(BuildContext context) {
    final pct   = widget.grand > 0 ? widget.agg.income / widget.grand : 0.0;
    final trips = widget.agg.tripRows..sort((a, b) => b.safeDate.compareTo(a.safeDate));
    return Container(
      decoration: BoxDecoration(color: _white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: widget.color.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 3))]),
      child: Column(children: [
        Material(color: Colors.transparent, child: InkWell(onTap: () => setState(() => _expanded = !_expanded), borderRadius: BorderRadius.circular(14),
          child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              widget.avatar, const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(widget.agg.name, style: const TextStyle(color: _textDark, fontSize: 14, fontWeight: FontWeight.w700)), Text('${widget.agg.sub.isNotEmpty ? '${widget.agg.sub}  •  ' : ''}${widget.agg.trips} trip${widget.agg.trips == 1 ? '' : 's'}', style: const TextStyle(color: _textGrey, fontSize: 11))])),
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: const Color(0xFFE0F7F4), borderRadius: BorderRadius.circular(10)), child: Text('₹${_fmt(widget.agg.income)}', style: const TextStyle(color: _green, fontSize: 13, fontWeight: FontWeight.w800))),
              const SizedBox(width: 6),
              AnimatedRotation(turns: _expanded ? 0.5 : 0, duration: const Duration(milliseconds: 220), child: const Icon(Icons.keyboard_arrow_down_rounded, color: _textGrey, size: 20)),
            ]),
            const SizedBox(height: 10), _progressBar(pct, widget.color), const SizedBox(height: 4),
            Text('${(pct * 100).toStringAsFixed(1)}% of total income', style: const TextStyle(color: _textGrey, fontSize: 10)),
          ])))),
        AnimatedSize(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut,
          child: _expanded ? Container(
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: _divLine))),
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _financeRow(income: widget.agg.income, expense: widget.agg.expense, net: widget.agg.net),
              const SizedBox(height: 14),
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: widget.color.withOpacity(0.10), borderRadius: BorderRadius.circular(20)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.history_rounded, color: widget.color, size: 13), const SizedBox(width: 5), Text('Trip History  (${trips.length})', style: TextStyle(color: widget.color, fontSize: 11, fontWeight: FontWeight.w700))])),
              const SizedBox(height: 10),
              ...trips.asMap().entries.map((e) => _TripMiniCard(trip: e.value, index: e.key, color: widget.color)),
            ]),
          ) : const SizedBox.shrink()),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  DRIVER / VEHICLE / CUSTOMER / REVENUE TABS
// ─────────────────────────────────────────────────────────────
class _DriverTab extends StatelessWidget {
  final List<ReportData> data; final DateFilterType filterType;
  const _DriverTab({required this.data, required this.filterType});
  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return _noData(filterType, _green);
    final drivers = _aggregateDriver(data); final grand = drivers.fold(0.0, (s, d) => s + d.income);
    return Column(children: [
      _SummaryRow(items: [_SumItem(Icons.person_pin_outlined, 'Drivers', drivers.length.toString(), _green), _SumItem(Icons.confirmation_number_outlined, 'Trips', drivers.fold(0, (s, d) => s + d.trips).toString(), _textGrey), _SumItem(Icons.currency_rupee_rounded, 'Total', '₹${_fmt(grand)}', _green)]),
      Expanded(child: ListView.separated(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), itemCount: drivers.length, separatorBuilder: (_, __) => const SizedBox(height: 10), itemBuilder: (_, i) => _AggCard(agg: drivers[i], grand: grand, color: _green, avatar: CircleAvatar(radius: 18, backgroundColor: _green.withOpacity(0.13), child: Text(drivers[i].name.isNotEmpty ? drivers[i].name[0].toUpperCase() : '?', style: const TextStyle(color: _green, fontSize: 14, fontWeight: FontWeight.w800)))))),
    ]);
  }
}

class _VehicleTab extends StatelessWidget {
  final List<ReportData> data; final DateFilterType filterType;
  const _VehicleTab({required this.data, required this.filterType});
  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return _noData(filterType, _orange);
    final vehicles = _aggregateVehicle(data); final grand = vehicles.fold(0.0, (s, v) => s + v.income);
    return Column(children: [
      _SummaryRow(items: [_SumItem(Icons.directions_car_outlined, 'Vehicles', vehicles.length.toString(), _orange), _SumItem(Icons.confirmation_number_outlined, 'Trips', vehicles.fold(0, (s, v) => s + v.trips).toString(), _textGrey), _SumItem(Icons.currency_rupee_rounded, 'Total', '₹${_fmt(grand)}', _green)]),
      Expanded(child: ListView.separated(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), itemCount: vehicles.length, separatorBuilder: (_, __) => const SizedBox(height: 10), itemBuilder: (_, i) => _AggCard(agg: vehicles[i], grand: grand, color: _orange, avatar: Container(width: 36, height: 36, decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(10)), alignment: Alignment.center, child: const Icon(Icons.directions_car_rounded, color: _orange, size: 18))))),
    ]);
  }
}

class _CustomerTab extends StatelessWidget {
  final List<ReportData> data; final DateFilterType filterType;
  const _CustomerTab({required this.data, required this.filterType});
  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return _noData(filterType, _purple);
    final customers = _aggregateCustomer(data); final grand = customers.fold(0.0, (s, c) => s + c.income);
    return Column(children: [
      _SummaryRow(items: [_SumItem(Icons.people_alt_outlined, 'Customers', customers.length.toString(), _purple), _SumItem(Icons.confirmation_number_outlined, 'Trips', customers.fold(0, (s, c) => s + c.trips).toString(), _textGrey), _SumItem(Icons.currency_rupee_rounded, 'Total', '₹${_fmt(grand)}', _green)]),
      Expanded(child: ListView.separated(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), itemCount: customers.length, separatorBuilder: (_, __) => const SizedBox(height: 10), itemBuilder: (_, i) => _AggCard(agg: customers[i], grand: grand, color: _purple, avatar: CircleAvatar(radius: 18, backgroundColor: _purple.withOpacity(0.13), child: Text(customers[i].name.isNotEmpty ? customers[i].name[0].toUpperCase() : '?', style: const TextStyle(color: _purple, fontSize: 14, fontWeight: FontWeight.w800)))))),
    ]);
  }
}

class _RevenueTab extends StatelessWidget {
  final List<ReportData> data; final DateFilterType filterType;
  const _RevenueTab({required this.data, required this.filterType});
  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return _noData(filterType, _red);
    final days = _aggregateRevenue(data); final totalIncome = days.fold(0.0, (s, d) => s + d.income); final totalNet = days.fold(0.0, (s, d) => s + d.net);
    return Column(children: [
      _SummaryRow(items: [_SumItem(Icons.calendar_today_rounded, 'Days', days.length.toString(), _red), _SumItem(Icons.currency_rupee_rounded, 'Income', '₹${_fmt(totalIncome)}', _green), _SumItem(Icons.trending_up_rounded, 'Net', '₹${_fmt(totalNet.abs())}', totalNet >= 0 ? _green : _red)]),
      Expanded(child: ListView.separated(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), itemCount: days.length, separatorBuilder: (_, __) => const SizedBox(height: 10), itemBuilder: (_, i) => _RevenueDayCard(day: days[i], grand: totalIncome))),
    ]);
  }
}

class _RevenueDayCard extends StatefulWidget {
  final _Agg day; final double grand;
  const _RevenueDayCard({required this.day, required this.grand});
  @override
  State<_RevenueDayCard> createState() => _RevenueDayCardState();
}

class _RevenueDayCardState extends State<_RevenueDayCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final pct = widget.grand > 0 ? widget.day.income / widget.grand : 0.0;
    final date = DateTime.tryParse(widget.day.key) ?? DateTime.now();
    final trips = widget.day.tripRows..sort((a, b) => b.safeDate.compareTo(a.safeDate));
    return Container(
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: _red.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(width: 36, height: 36, decoration: BoxDecoration(color: const Color(0xFFFFEBEA), borderRadius: BorderRadius.circular(10)), alignment: Alignment.center, child: Text(DateFormat('dd').format(date), style: const TextStyle(color: _red, fontSize: 14, fontWeight: FontWeight.w800))),
                  const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(widget.day.name, style: const TextStyle(color: _textDark, fontSize: 13, fontWeight: FontWeight.w700)), Text('${widget.day.trips} trip${widget.day.trips == 1 ? '' : 's'}', style: const TextStyle(color: _textGrey, fontSize: 11))])),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: const Color(0xFFE0F7F4), borderRadius: BorderRadius.circular(10)), child: Text('₹${_fmt(widget.day.income)}', style: const TextStyle(color: _green, fontSize: 13, fontWeight: FontWeight.w800))),
                  const SizedBox(width: 6),
                  AnimatedRotation(turns: _expanded ? 0.5 : 0, duration: const Duration(milliseconds: 220), child: const Icon(Icons.keyboard_arrow_down_rounded, color: _textGrey, size: 20)),
                ]),
                const SizedBox(height: 10), _progressBar(pct, _red), const SizedBox(height: 8),
                _financeRow(income: widget.day.income, expense: widget.day.expense, net: widget.day.net),
              ]),
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: _expanded
              ? Container(
                  decoration: const BoxDecoration(border: Border(top: BorderSide(color: _divLine))),
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: _red.withOpacity(0.10), borderRadius: BorderRadius.circular(20)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.history_rounded, color: _red, size: 13),
                        const SizedBox(width: 5),
                        Text('Trip Details  (${trips.length})', style: const TextStyle(color: _red, fontSize: 11, fontWeight: FontWeight.w700)),
                      ]),
                    ),
                    const SizedBox(height: 10),
                    ...trips.asMap().entries.map((e) => _TripMiniCard(trip: e.value, index: e.key, color: _red)),
                  ]),
                )
              : const SizedBox.shrink(),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  LOADING / ERROR / NO DATA
// ─────────────────────────────────────────────────────────────
class _LoadingView extends StatelessWidget {
  final Color color; const _LoadingView({required this.color});
  @override
  Widget build(BuildContext context) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [CircularProgressIndicator(color: color, strokeWidth: 2.5), const SizedBox(height: 14), const Text('Loading report…', style: TextStyle(color: _textGrey, fontSize: 13))]));
}

class _ErrorView extends StatelessWidget {
  final Color color; final String? errorMessage; final VoidCallback onRetry;
  const _ErrorView({required this.color, required this.onRetry, this.errorMessage});
  @override
  Widget build(BuildContext context) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Icon(Icons.error_outline_rounded, color: color, size: 48), const SizedBox(height: 12),
    const Text('Something went wrong', style: TextStyle(color: _textDark, fontSize: 14, fontWeight: FontWeight.w600)),
    if (errorMessage != null && errorMessage!.trim().isNotEmpty) ...[const SizedBox(height: 6), Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Text(errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: _textGrey, fontSize: 12), maxLines: 3, overflow: TextOverflow.ellipsis))],
    const SizedBox(height: 8), TextButton(onPressed: onRetry, child: Text('Retry', style: TextStyle(color: color, fontWeight: FontWeight.w700))),
  ]));
}

Widget _noData(DateFilterType ft, Color color) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
  Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(Icons.search_off_rounded, color: color, size: 36)),
  const SizedBox(height: 14),
  Text(ft == DateFilterType.today ? 'No trips today' : ft == DateFilterType.monthly ? 'No trips this month' : ft == DateFilterType.yearly ? 'No trips this year' : 'No data in selected range', style: const TextStyle(color: _textDark, fontSize: 14, fontWeight: FontWeight.w600)),
  const SizedBox(height: 6), const Text('Try selecting a different date range', style: TextStyle(color: _textGrey, fontSize: 12)),
]));

// ─────────────────────────────────────────────────────────────
//  UTILITY
// ─────────────────────────────────────────────────────────────
String _fmt(double v) {
  if (v >= 1e7) return '${(v / 1e7).toStringAsFixed(2)}Cr';
  if (v >= 1e5) return '${(v / 1e5).toStringAsFixed(2)}L';
  if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(2)}K';
  return v.toStringAsFixed(0);
}

