import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_agency_app/core/network/error_messages.dart';
import 'package:travel_agency_app/core/theme/app_colors.dart';
import 'package:travel_agency_app/core/widgets/skeleton.dart';
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
  // ─── Design Tokens ────────────────────────────────────────────────────────m
  static const _bg          = Color(0xFFF4F6FB);
  static const _surface     = Colors.white;
  static const _surfaceAlt  = Color(0xFFF0F3FA);
  static const _accent      = AppColors.brandPrimary;
  static const _accentLight = AppColors.brandSoft;
  static const _accentGrad1 = AppColors.brandPrimaryLight;
  static const _text1       = Color(0xFF1A1D2E);
  static const _text2       = Color(0xFF7B82A0);
  static const _divider     = Color(0xFFE8EBF4);
  static const _red         = Color(0xFFE53935);
  static const _redSoft     = Color(0xFFFFEBEE);
  static const _redGrad1    = Color(0xFFFF6B6B);
  static const _green       = Color(0xFF2DB976);
  static const _greenSoft   = Color(0xFFE8F8F1);
  static const _diesel      = Color(0xFF1D4ED8);
  static const _dieselSoft  = Color(0xFFDBEAFE);
  static const _petrol      = Color(0xFF7C3AED);
  static const _petrolSoft  = Color(0xFFEDE9FE);
  static const _cardRadius  = 16.0;
  static const _chipRadius  = 8.0;

  late final TabController _tabController;
  final _searchCtrl  = TextEditingController();
  final _searchFocus = FocusNode();
  bool _searchVisible = false;

  bool get _isVehicleTab => _tabController.index == 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadDeletedItems();
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

  // ─── Helpers ──────────────────────────────────────────────────────────────
  String _initials(String? name) {
    if (name == null || name.trim().isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.length >= 2
        ? '${parts.first[0]}${parts[1][0]}'.toUpperCase()
        : parts.first[0].toUpperCase();
  }

  // ─── Widgets ──────────────────────────────────────────────────────────────

  /// Top section: tab bar + optional search + titles
  Widget _header() {
    return Container(
      color: _surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                // ── Tab bar ──────────────────────────────────────────────
                Expanded(
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: _surfaceAlt,
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: _divider),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_accentGrad1, _accent],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(11),
                        boxShadow: [
                          BoxShadow(
                            color: _accent.withOpacity(0.30),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      indicatorPadding: const EdgeInsets.all(3),
                      labelColor: Colors.white,
                      unselectedLabelColor: _text2,
                      labelStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      dividerColor: Colors.transparent,
                      onTap: (_) {
                        _searchCtrl.clear();
                        setState(() => _searchVisible = false);
                      },
                      tabs: const [
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.directions_car_rounded, size: 15),
                              SizedBox(width: 5),
                              Text('Vehicles'),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.person_rounded, size: 15),
                              SizedBox(width: 5),
                              Text('Drivers'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // ── Search toggle ─────────────────────────────────────────
                _SearchToggleButton(
                  isActive: _searchVisible,
                  onTap: () => setState(() {
                    _searchVisible = !_searchVisible;
                    if (!_searchVisible) {
                      _searchCtrl.clear();
                    } else {
                      Future.delayed(
                        const Duration(milliseconds: 120),
                        () => _searchFocus.requestFocus(),
                      );
                    }
                  }),
                ),
              ],
            ),
          ),

          // ── Animated search field ────────────────────────────────────
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            child: _searchVisible
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: TextField(
                      controller: _searchCtrl,
                      focusNode: _searchFocus,
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(
                        fontSize: 13,
                        color: _text1,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        hintText: _isVehicleTab
                            ? 'Search deleted vehicles…'
                            : 'Search deleted drivers…',
                        hintStyle: const TextStyle(
                          fontSize: 13,
                          color: _text2,
                          fontWeight: FontWeight.w400,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          size: 18,
                          color: _text2,
                        ),
                        suffixIcon: _searchCtrl.text.isNotEmpty
                            ? GestureDetector(
                                onTap: () => setState(() => _searchCtrl.clear()),
                                child: const Icon(
                                  Icons.cancel_rounded,
                                  size: 16,
                                  color: _text2,
                                ),
                              )
                            : null,
                        filled: true,
                        fillColor: _surfaceAlt,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 13,
                        ),
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
                          borderSide:
                              const BorderSide(color: _accent, width: 1.5),
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          // ── Page titles ──────────────────────────────────────────────
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 2),
            child: Text(
              'Deleted Vehicles & Drivers',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _text1,
                letterSpacing: -0.3,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Text(
              'View items removed from your active list.',
              style: TextStyle(fontSize: 12, color: _text2, height: 1.4),
            ),
          ),
          const Divider(height: 1, color: _divider),
        ],
      ),
    );
  }

  /// Stats banner shown at top of each list
  Widget _statsBanner(int count, {required bool vehicle}) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _divider),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _redSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              vehicle
                  ? Icons.no_transfer_rounded
                  : Icons.person_remove_alt_1_rounded,
              color: _red,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '$count deleted ${vehicle ? 'vehicle${count != 1 ? 's' : ''}' : 'driver${count != 1 ? 's' : ''}'}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _text1,
            ),
          ),
          const Spacer(),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _redSoft,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Archived',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: _red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Vehicle card
  Widget _vehicleCard(Vehicles v, int i) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 200 + i * 40),
      curve: Curves.easeOutCubic,
      builder: (_, val, child) => Opacity(
        opacity: val,
        child: Transform.translate(
          offset: Offset(0, 14 * (1 - val)),
          child: child,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(_cardRadius),
          border: Border.all(color: _divider, width: 1),
          boxShadow: [
            BoxShadow(
              color: _accent.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(_cardRadius),
          child: InkWell(
            borderRadius: BorderRadius.circular(_cardRadius),
            onTap: () {}, // optional: show detail
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Row 1: gradient icon + name + plate + Deleted badge
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_redGrad1, _red],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: _red.withOpacity(0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.directions_car_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              v.name ?? 'Unknown vehicle',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: _text1,
                                letterSpacing: -0.2,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            if (v.number != null) ...[
                              const SizedBox(height: 3),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.credit_card_rounded,
                                    size: 11,
                                    color: _text2,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    v.number!,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: _text2,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _deletedBadge(),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(height: 1, color: _divider),
                  const SizedBox(height: 10),
                  // Row 2: stat chips (wrap so they never overflow)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            _statChip(
                              Icons.event_seat_rounded,
                              '${v.capacity ?? "--"}',
                              'Seats',
                            ),
                            _statChip(
                              Icons.speed_rounded,
                              v.mileage != null ? '${v.mileage}' : '--',
                              'km/l',
                            ),
                            _fuelBadge(v.FuelType ?? v.Type),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Driver card
  Widget _driverCard(Drivers d, int i) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 200 + i * 40),
      curve: Curves.easeOutCubic,
      builder: (_, val, child) => Opacity(
        opacity: val,
        child: Transform.translate(
          offset: Offset(0, 10 * (1 - val)),
          child: child,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _divider, width: 1),
          boxShadow: [
            BoxShadow(
              color: _accent.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {},
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  // Gradient initials avatar
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_redGrad1, _red],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: _red.withOpacity(0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        _initials(d.name),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
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
                          d.name ?? 'Unknown driver',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: _text1,
                            letterSpacing: -0.1,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (d.phone != null && d.phone!.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              const Icon(
                                Icons.phone_rounded,
                                size: 11,
                                color: _red,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                d.phone!,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _text2,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _deletedBadge(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _statChip(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: _surfaceAlt,
        borderRadius: BorderRadius.circular(_chipRadius),
        border: Border.all(color: _divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: _accent),
          const SizedBox(width: 4),
          Text(
            '$value $label',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: _text1,
            ),
          ),
        ],
      ),
    );
  }

  /// Fuel-type badge — same colour mapping as the active Fleet page.
  Widget _fuelBadge(String? fuelType) {
    final fuel = (fuelType ?? '').toLowerCase();
    Color bg, fg;
    IconData icon;

    if (fuel.contains('ev') || fuel.contains('electric')) {
      bg = _greenSoft;
      fg = _green;
      icon = Icons.bolt_rounded;
    } else if (fuel.contains('petrol')) {
      bg = _petrolSoft;
      fg = _petrol;
      icon = Icons.local_gas_station_rounded;
    } else if (fuel.contains('cng')) {
      bg = _greenSoft;
      fg = _green;
      icon = Icons.local_gas_station_rounded;
    } else {
      bg = _dieselSoft;
      fg = _diesel;
      icon = Icons.opacity_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: fg),
          const SizedBox(width: 3),
          Text(
            fuelType ?? 'N/A',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
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
      child: const Text(
        'Deleted',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: _red,
        ),
      ),
    );
  }

  // ─── State widgets ────────────────────────────────────────────────────────

  Widget _loadingState(String message) {
    return RefreshIndicator(
      onRefresh: () async => _loadDeletedItems(),
      color: _accent,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
        children: const [
          SkeletonListItem(hasTrailingLine: false),
          SkeletonListItem(hasTrailingLine: false),
          SkeletonListItem(hasTrailingLine: false),
          SkeletonListItem(hasTrailingLine: false),
          SkeletonListItem(hasTrailingLine: false),
        ],
      ),
    );
  }

  Widget _errorState(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: _redSoft,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: _red,
                size: 28,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _text1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              friendlyErrorMessage(error),
              textAlign: TextAlign.center,
              style: const TextStyle(color: _text2, fontSize: 12, height: 1.5),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: _loadDeletedItems,
              style: TextButton.styleFrom(
                backgroundColor: _accentLight,
                foregroundColor: _accent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Retry',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _accentLight,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(icon, color: _accent, size: 32),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: _text1,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: _text2,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Tab content builders ─────────────────────────────────────────────────

  Widget _vehiclesContent(List<Vehicles> vehicles) {
    final q = _searchCtrl.text.toLowerCase();
    final filtered = vehicles
        .where((v) =>
            (v.name?.toLowerCase().contains(q) ?? false) ||
            (v.number?.toLowerCase().contains(q) ?? false))
        .toList();

    if (filtered.isEmpty) {
      return _emptyState(
        icon: Icons.directions_car_rounded,
        title: q.isNotEmpty ? 'No results found' : 'No deleted vehicles',
        subtitle: q.isNotEmpty
            ? 'Try a different search term.'
            : 'Deleted vehicles will appear here.',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDeletedItems,
      color: _accent,
      child: Column(
        children: [
          _statsBanner(filtered.length, vehicle: true),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              itemCount: filtered.length,
              itemBuilder: (_, i) => _vehicleCard(filtered[i], i),
            ),
          ),
        ],
      ),
    );
  }

  Widget _driversContent(List<Drivers> drivers) {
    final q = _searchCtrl.text.toLowerCase();
    final filtered = drivers
        .where((d) =>
            (d.name?.toLowerCase().contains(q) ?? false) ||
            (d.phone?.toLowerCase().contains(q) ?? false))
        .toList();

    if (filtered.isEmpty) {
      return _emptyState(
        icon: Icons.person_rounded,
        title: q.isNotEmpty ? 'No results found' : 'No deleted drivers',
        subtitle: q.isNotEmpty
            ? 'Try a different search term.'
            : 'Deleted drivers will appear here.',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDeletedItems,
      color: _accent,
      child: Column(
        children: [
          _statsBanner(filtered.length, vehicle: false),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              itemCount: filtered.length,
              itemBuilder: (_, i) => _driverCard(filtered[i], i),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state       = ref.watch(tripBookingViewModelProvider);
    final vehicleState = state.fetchVehicleList;
    final driverState  = state.fetchDriverList;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text(
          'Deleted Records',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 17,
            letterSpacing: -0.2,
          ),
        ),
        backgroundColor: _surface,
        foregroundColor: _text1,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _divider),
        ),
      ),
      body: Column(
        children: [
          _header(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                vehicleState.when(
                  loading: () => _loadingState('Loading deleted vehicles…'),
                  error: (e, _) => _errorState(e),
                  data: _vehiclesContent,
                ),
                driverState.when(
                  loading: () => _loadingState('Loading deleted drivers…'),
                  error: (e, _) => _errorState(e),
                  data: _driversContent,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Search Toggle Button (extracted widget for cleanliness) ──────────────────

class _SearchToggleButton extends StatelessWidget {
  const _SearchToggleButton({
    required this.isActive,
    required this.onTap,
  });

  final bool isActive;
  final VoidCallback onTap;

  static const _accent     = AppColors.brandPrimary;
  static const _accentLight = AppColors.brandSoft;
  static const _surfaceAlt = Color(0xFFF0F3FA);
  static const _divider    = Color(0xFFE8EBF4);
  static const _text2      = Color(0xFF7B82A0);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: isActive ? _accentLight : _surfaceAlt,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: isActive ? _accent : _divider,
            width: isActive ? 1.5 : 1.0,
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: Icon(
            isActive ? Icons.close_rounded : Icons.search_rounded,
            key: ValueKey(isActive),
            color: isActive ? _accent : _text2,
            size: 20,
          ),
        ),
      ),
    );
  }
}