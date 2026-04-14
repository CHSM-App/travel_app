import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_agency_app/domain/models/drivers.dart';
import 'package:travel_agency_app/domain/models/vehicles.dart';
import 'package:travel_agency_app/presentation/providers/viewmodel_provider.dart';

class DeletedRecordsPage extends ConsumerStatefulWidget {
  const DeletedRecordsPage({super.key});

  @override
  ConsumerState<DeletedRecordsPage> createState() => _DeletedRecordsPageState();
}

class _DeletedRecordsPageState extends ConsumerState<DeletedRecordsPage>
    with SingleTickerProviderStateMixin {
  static const _bg = Color(0xFFF2F4F8);
  static const _surface = Colors.white;
  static const _surfaceLight = Color(0xFFF0F3FA);
  static const _accent = Color(0xFF3D5AFE);
  static const _text1 = Color(0xFF1A1D2E);
  static const _text2 = Color(0xFF7B82A0);
  static const _divider = Color(0xFFE4E8F0);
  static const _red = Color(0xFFE53935);
  static const _redSoft = Color(0xFFFFEBEE);

  late final TabController _tabController;
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  bool _searchVisible = false;

  bool get _isVehicleTab => _tabController.index == 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadDeletedItems();
      }
    });
  }

  Future<void> _loadDeletedItems() async {
    final agencyId = ref.read(loginViewModelProvider).agencyId ?? '';
    if (agencyId.isEmpty) return;
    await Future.wait([
      ref.read(tripBookingViewModelProvider.notifier).deletedVehicleList(agencyId),
      ref.read(tripBookingViewModelProvider.notifier).deletedDriverList(agencyId),
    ]);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  String _initials(String? name) {
    if (name == null || name.trim().isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.length >= 2
        ? '${parts.first[0]}${parts[1][0]}'.toUpperCase()
        : parts.first[0].toUpperCase();
  }

  Widget _sectionHeader() {
    return Container(
      color: _surface,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: _surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _divider),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6378FF), _accent],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      indicatorPadding: const EdgeInsets.all(3),
                      labelColor: Colors.white,
                      unselectedLabelColor: _text2,
                      dividerColor: Colors.transparent,
                      onTap: (_) {
                        _searchCtrl.clear();
                        setState(() => _searchVisible = false);
                      },
                      tabs: const [
                        Tab(text: 'Vehicles', icon: Icon(Icons.directions_car_rounded, size: 16)),
                        Tab(text: 'Drivers', icon: Icon(Icons.person_rounded, size: 16)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _searchVisible = !_searchVisible;
                      if (!_searchVisible) {
                        _searchCtrl.clear();
                      } else {
                        Future.delayed(
                          const Duration(milliseconds: 100),
                          () => _searchFocus.requestFocus(),
                        );
                      }
                    });
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _searchVisible ? const Color(0xFFEEF1FF) : _surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _searchVisible ? _accent : _divider,
                      ),
                    ),
                    child: Icon(
                      _searchVisible ? Icons.close_rounded : Icons.search_rounded,
                      color: _searchVisible ? _accent : _text2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_searchVisible)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: TextField(
                controller: _searchCtrl,
                focusNode: _searchFocus,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: _isVehicleTab ? 'Search deleted vehicles...' : 'Search deleted drivers...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 18),
                  filled: true,
                  fillColor: _surfaceLight,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _divider),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _accent, width: 1.5),
                  ),
                ),
              ),
            ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Deleted Vehicles & Drivers',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _text1),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'View items removed from your active list.',
                style: TextStyle(fontSize: 12, color: _text2),
              ),
            ),
          ),
          const Divider(height: 1, color: _divider),
        ],
      ),
    );
  }

  Widget _stats(int count, {required bool vehicle}) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _divider),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _redSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(vehicle ? Icons.delete_outline_rounded : Icons.person_remove_alt_1_rounded, color: _red, size: 16),
          ),
          const SizedBox(width: 10),
          Text(
            '$count deleted ${vehicle ? 'vehicles' : 'drivers'}',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _text1),
          ),
        ],
      ),
    );
  }

  Widget _vehicleCard(Vehicles v) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _divider),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _red,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.directions_car_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(v.name ?? 'Unknown vehicle', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _text1)),
                const SizedBox(height: 4),
                Text(v.number ?? 'No number available', style: const TextStyle(fontSize: 11, color: _text2, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _chip(Icons.local_gas_station_rounded, v.Type ?? 'N/A'),
                    _chip(Icons.people_alt_rounded, '${v.capacity ?? 0} seats'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _deletedBadge(),
        ],
      ),
    );
  }

  Widget _driverCard(Drivers d) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _divider),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _red,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(_initials(d.name), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(d.name ?? 'Unknown driver', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _text1)),
                const SizedBox(height: 4),
                Text(d.phone?.isNotEmpty == true ? d.phone! : 'No phone available', style: const TextStyle(fontSize: 11, color: _text2, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _deletedBadge(),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: _surfaceLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: _accent),
          const SizedBox(width: 4),
          Text(value, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _text1)),
        ],
      ),
    );
  }

  Widget _deletedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _redSoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text('Deleted', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _red)),
    );
  }

  Widget _loading(String msg) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const CircularProgressIndicator(color: _accent), const SizedBox(height: 12), Text(msg, style: const TextStyle(color: _text2))]));

  Widget _error(Object e) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(e.toString(), textAlign: TextAlign.center, style: const TextStyle(color: _text2))));

  Widget _empty(IconData icon, String title, String sub) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(radius: 34, backgroundColor: const Color(0xFFEEF1FF), child: Icon(icon, color: _accent, size: 30)),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _text1)),
            const SizedBox(height: 6),
            Text(sub, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: _text2)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tripBookingViewModelProvider);
    final vehicleState = state.fetchVehicleList;
    final driverState = state.fetchDriverList;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('Deleted Records', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: _surface,
        foregroundColor: _text1,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: Column(
        children: [
          _sectionHeader(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                vehicleState.when(
                  loading: () => _loading('Loading deleted vehicles...'),
                  error: (e, _) => _error(e),
                  data: (vehicles) {
                    final q = _searchCtrl.text.toLowerCase();
                    final filtered = vehicles.where((v) => (v.name?.toLowerCase().contains(q) ?? false) || (v.number?.toLowerCase().contains(q) ?? false)).toList();
                    if (filtered.isEmpty) {
                      return _empty(Icons.directions_car_rounded, q.isNotEmpty ? 'No results' : 'No deleted vehicles', q.isNotEmpty ? 'Try a different search term.' : 'Deleted vehicles will appear here.');
                    }
                    return RefreshIndicator(
                      onRefresh: _loadDeletedItems,
                      child: Column(
                        children: [
                          _stats(filtered.length, vehicle: true),
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                              itemCount: filtered.length,
                              itemBuilder: (_, i) => _vehicleCard(filtered[i]),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                driverState.when(
                  loading: () => _loading('Loading deleted drivers...'),
                  error: (e, _) => _error(e),
                  data: (drivers) {
                    final q = _searchCtrl.text.toLowerCase();
                    final filtered = drivers.where((d) => (d.name?.toLowerCase().contains(q) ?? false) || (d.phone?.toLowerCase().contains(q) ?? false)).toList();
                    if (filtered.isEmpty) {
                      return _empty(Icons.person_rounded, q.isNotEmpty ? 'No results' : 'No deleted drivers', q.isNotEmpty ? 'Try a different search term.' : 'Deleted drivers will appear here.');
                    }
                    return RefreshIndicator(
                      onRefresh: _loadDeletedItems,
                      child: Column(
                        children: [
                          _stats(filtered.length, vehicle: false),
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.only(bottom: 24),
                              itemCount: filtered.length,
                              itemBuilder: (_, i) => _driverCard(filtered[i]),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
