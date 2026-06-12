
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_agency_app/domain/models/reports_data.dart';
import 'package:travel_agency_app/domain/usecase/report_usecase.dart';

// ─────────────────────────────────────────────────────────────
//  STATE
// ─────────────────────────────────────────────────────────────
class ReportState {
  final AsyncValue<List<ReportData>> tripReport;
  final AsyncValue<List<ReportData>> driverReport;
  final AsyncValue<List<ReportData>> vehicleReport;
  final AsyncValue<List<ReportData>> customerReport;
  final AsyncValue<List<ReportData>> revenueReport;

  const ReportState({
    this.tripReport     = const AsyncValue.data([]),
    this.driverReport   = const AsyncValue.data([]),
    this.vehicleReport  = const AsyncValue.data([]),
    this.customerReport = const AsyncValue.data([]),
    this.revenueReport  = const AsyncValue.data([]),
  });

  ReportState copyWith({
    AsyncValue<List<ReportData>>? tripReport,
    AsyncValue<List<ReportData>>? driverReport,
    AsyncValue<List<ReportData>>? vehicleReport,
    AsyncValue<List<ReportData>>? customerReport,
    AsyncValue<List<ReportData>>? revenueReport,
  }) {
    return ReportState(
      tripReport:     tripReport     ?? this.tripReport,
      driverReport:   driverReport   ?? this.driverReport,
      vehicleReport:  vehicleReport  ?? this.vehicleReport,
      customerReport: customerReport ?? this.customerReport,
      revenueReport:  revenueReport  ?? this.revenueReport,
    );
  }

  // ── Get AsyncValue by tab index ───────────────────────────
  AsyncValue<List<ReportData>> getByTab(int tabIndex) {
    switch (tabIndex) {
      case 0:  return tripReport;
      case 1:  return driverReport;
      case 2:  return vehicleReport;
      case 3:  return customerReport;
      case 4:  return revenueReport;
      default: return tripReport;
    }
  }
}

// ─────────────────────────────────────────────────────────────
//  VIEW MODEL
// ─────────────────────────────────────────────────────────────
class ReportViewModel extends StateNotifier<ReportState> {
  final Ref ref;
  final ReportUsecase usecase;

  // Track loaded tabs for lazy loading
  final Set<int> _loadedTabs = {};
  String? _loadedAgencyId;

  ReportViewModel(this.ref, this.usecase) : super(const ReportState());

  // ── Load tab (lazy — fetches only once per tab) ───────────
  Future<void> loadTab(String agencyId, int tabIndex) async {
    _ensureAgency(agencyId);
    if (_loadedTabs.contains(tabIndex)) return;
    _loadedTabs.add(tabIndex);
    await _fetch(agencyId, _typeFromIndex(tabIndex), tabIndex);
  }

  // ── Force reload tab (retry / pull-to-refresh) ────────────
  Future<void> reloadTab(String agencyId, int tabIndex) async {
    _ensureAgency(agencyId);
    _loadedTabs.remove(tabIndex);
    await loadTab(agencyId, tabIndex);
  }

  void _ensureAgency(String agencyId) {
    if (_loadedAgencyId == agencyId) return;
    _loadedAgencyId = agencyId;
    _loadedTabs.clear();
    state = const ReportState();
  }

  // ── Internal fetch ────────────────────────────────────────
  Future<void> _fetch(
    String agencyId,
    String reportType,
    int tabIndex,
  ) async {
    _setState(tabIndex, const AsyncValue.loading());

    try {
      final result = await usecase.getReport(agencyId, reportType);
      _setState(tabIndex, AsyncValue.data(result));
    } catch (e, st) {
      // ignore: avoid_print
      print('❌ ReportViewModel [tab:$tabIndex type:$reportType] → $e');
      _loadedTabs.remove(tabIndex); // allow retry
      _setState(tabIndex, AsyncValue.error(e, st));
    }
  }

  // ── Apply state per tab ───────────────────────────────────
  void _setState(int tabIndex, AsyncValue<List<ReportData>> value) {
    switch (tabIndex) {
      case 0: state = state.copyWith(tripReport:     value); break;
      case 1: state = state.copyWith(driverReport:   value); break;
      case 2: state = state.copyWith(vehicleReport:  value); break;
      case 3: state = state.copyWith(customerReport: value); break;
      case 4: state = state.copyWith(revenueReport:  value); break;
    }
  }

  // ── Tab index → report type string ───────────────────────
  String _typeFromIndex(int index) {
    switch (index) {
      case 0:  return 'trip';
      case 1:  return 'driver';
      case 2:  return 'vehicle';
      case 3:  return 'customer';
      case 4:  return 'revenue';
      default: return 'trip';
    }
  }
}
