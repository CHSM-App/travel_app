import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:travel_agency_app/Screens/add_customer.dart';
import 'package:travel_agency_app/Screens/trip_card.dart';
import 'package:travel_agency_app/core/theme/app_colors.dart';
import 'package:travel_agency_app/core/widgets/skeleton.dart';
import 'package:travel_agency_app/domain/models/booking_info.dart';
import 'package:travel_agency_app/domain/models/customers.dart';
import 'package:travel_agency_app/presentation/providers/viewmodel_provider.dart';

/// Per-customer trip status filter. Status codes mirror those used in
/// [TripCard]: 1=Active, 2=Unpaid, 3=Upcoming, 4=Paid, 5=Cancelled.
enum _TripStatusFilter {
  all('All', Icons.list_alt_rounded, null),
  active('Active', Icons.directions_car_rounded, 1),
  upcoming('Upcoming', Icons.schedule_rounded, 3),
  unpaid('Unpaid', Icons.payment_rounded, 2),
  paid('Paid', Icons.check_circle_rounded, 4),
  cancelled('Cancelled', Icons.cancel_rounded, 5);

  const _TripStatusFilter(this.label, this.icon, this.status);
  final String label;
  final IconData icon;
  final int? status;

  bool matches(BookingInfo trip) =>
      status == null || trip.status == status;
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
  static const Color _bg            = Color(0xFFF2F4F8);
  static const Color _surface       = Color(0xFFFFFFFF);
  static const Color _surfaceLight  = Color(0xFFF0F3FA);
  static const Color _accent        = AppColors.brandPrimary;
  static const Color _accentSoft    = AppColors.brandSoft;
  static const Color _textPrimary   = Color(0xFF1A1D2E);
  static const Color _textSecondary = Color(0xFF7B82A0);
  static const Color _divider       = Color(0xFFE4E8F0);
  static const Color _success       = Color(0xFF2DB976);
  static const Color _successSoft   = Color(0xFFE8F8F1);
  static const Color _warning       = Color(0xFFE67E22);
  static const Color _warningSoft   = Color(0xFFFEF0E6);

  static final NumberFormat _currency = NumberFormat.compactCurrency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 1,
  );

  _TripStatusFilter _filter = _TripStatusFilter.all;

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
    super.dispose();
  }

  Future<void> _load() async {
    final id = widget.customer.customerId;
    if (id == null) return;
    await ref.read(customerViewModelProvider.notifier).fetchCustomershist(id);
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

  List<BookingInfo> _applyFilter(List<BookingInfo> trips) =>
      _filter == _TripStatusFilter.all
          ? trips
          : trips.where(_filter.matches).toList();

  int _countFor(_TripStatusFilter f, List<BookingInfo> trips) =>
      f == _TripStatusFilter.all
          ? trips.length
          : trips.where(f.matches).length;

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

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: _bg,
        body: Column(
          children: [
            // ── STATIC HEADER ─────────────────────────────────────
            _buildStaticHeader(state.customerHist),

            // ── SCROLLABLE CONTENT ────────────────────────────────
            Expanded(
              child: _buildTripList(state.customerHist),
            ),
          ],
        ),
      ),
    );
  }

  // ── STATIC HEADER ──────────────────────────────────────────────────
  Widget _buildStaticHeader(AsyncValue<List<BookingInfo>> tripState) {
    final topPad = MediaQuery.of(context).padding.top;

    return Container(
      padding: EdgeInsets.fromLTRB(20, topPad + 12, 20, 20),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: _accent.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          _decorativeBlob(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _topBar(),
              const SizedBox(height: 20),
              _avatarAndName(),
              const SizedBox(height: 18),
              _buildCompactStats(tripState),
            ],
          ),
        ],
      ),
    );
  }

  Widget _decorativeBlob() => Positioned(
        top: -16,
        right: -16,
        child: Container(
          width: 130,
          height: 130,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [
              _accent.withValues(alpha: 0.07),
              _accent.withValues(alpha: 0.0),
            ]),
          ),
        ),
      );

  Widget _topBar() => Row(
        children: [
          _iconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            label: 'Back',
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              "Customer's History",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _textSecondary,
                letterSpacing: 1.4,
              ),
            ),
          ),
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

  Widget _avatarAndName() {
    final customer = widget.customer;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _glowingAvatar(customer.name),
        const SizedBox(width: 14),
        Expanded(
          child: SlideTransition(
            position: _slideUp,
            child: FadeTransition(
              opacity: _fadeIn,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer.name ?? 'Customer',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: _textPrimary,
                      letterSpacing: 0.1,
                    ),
                  ),
                  const SizedBox(height: 5),
                  _phoneChip(customer.phone),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _glowingAvatar(String? name) => ScaleTransition(
        scale: _avatarScale,
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [AppColors.brandPrimaryLight, AppColors.brandPrimary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: _accent.withValues(alpha: 0.30),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: Text(
              _getInitials(name),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
        ),
      );

  Widget _phoneChip(String? phone) => Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: _accentSoft,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.phone_rounded,
              size: 11,
              color: _accent,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            phone ?? '--',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _textSecondary,
            ),
          ),
        ],
      );

  // ── COMPACT STATS ──────────────────────────────────────────────────
  Widget _buildCompactStats(AsyncValue<List<BookingInfo>> tripState) {
    return tripState.when(
      loading: () => Container(
        height: 52,
        decoration: BoxDecoration(
          color: _surfaceLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _divider),
        ),
        child: Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _accent,
              backgroundColor: _accent.withValues(alpha: 0.1),
            ),
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (trips) {
        final total = trips.length;
        final settled = trips
            .where((t) =>
                (t.amountReceived ?? 0) >= (t.amountApprove ?? 0) &&
                (t.amountApprove ?? 0) > 0)
            .length;
        final totalValue = trips.fold<double>(
            0, (sum, t) => sum + (t.amountApprove ?? 0));
        final formatted = _currency.format(totalValue);

        return Container(
          decoration: BoxDecoration(
            color: _surfaceLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _divider, width: 1.2),
          ),
          child: Row(
            children: [
              _compactStat(
                "$total",
                "Total Trips",
                Icons.route_rounded,
                _accent,
                _accentSoft,
              ),
              _compactDivider(),
              _compactStat(
                "$settled",
                "Paid",
                Icons.check_circle_outline_rounded,
                _success,
                _successSoft,
              ),
              _compactDivider(),
              _compactStat(
                formatted,
                "Revenue",
                Icons.currency_rupee_rounded,
                _warning,
                _warningSoft,
              ),
            ],
          ),
        );
      },
    );
  }

Widget _compactStat(
  String value,
  String label,
  IconData icon,
  Color color,
  Color bgColor,
) {
  return Expanded(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 13, color: color),
          ),
          const SizedBox(width: 6),

          /// 👇 THIS FIXES OVERFLOW
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _textPrimary,
                    height: 1.1,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    color: _textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _compactDivider() {
    return Container(
      width: 1,
      height: 32,
      color: _divider,
    );
  }

  // ── TRIP LIST ──────────────────────────────────────────────────────
  Widget _buildTripList(AsyncValue<List<BookingInfo>> state) {
    return state.when(
      loading: _loadingState,
      error: (e, _) => _errorState(e),
      data: (trips) => trips.isEmpty ? _emptyState() : _tripsData(trips),
    );
  }

  Widget _loadingState() {
    return RefreshIndicator(
      onRefresh: _load,
      color: _accent,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(0, 16, 0, 24),
        children: const [
          SkeletonListItem(),
          SkeletonListItem(),
          SkeletonListItem(),
          SkeletonListItem(),
        ],
      ),
    );
  }

  Widget _errorState(Object e) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.cloud_off_rounded,
                  color: Colors.red.shade300, size: 28),
            ),
            const SizedBox(height: 14),
            const Text(
              "Couldn't load trips",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$e',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: _textSecondary),
            ),
            const SizedBox(height: 20),
            Semantics(
              button: true,
              label: 'Retry loading trips',
              child: Material(
                color: Colors.transparent,
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.brandPrimaryLight, AppColors.brandPrimary],
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: _accent.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: InkWell(
                    onTap: _load,
                    borderRadius: BorderRadius.circular(30),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: 28, vertical: 12),
                      child: Text(
                        "Retry",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return RefreshIndicator(
      onRefresh: _load,
      color: _accent,
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
    final filtered = _applyFilter(trips);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _filterPillBar(trips),
        Expanded(
          child: filtered.isEmpty
              ? _filteredEmptyState()
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => TripCard(
                    key: ValueKey(filtered[i].tripId),
                    bookinginfo: filtered[i],
                    status: filtered[i].status ?? 0,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _filterPillBar(List<BookingInfo> trips) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: SizedBox(
        height: 34,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _TripStatusFilter.values.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final f = _TripStatusFilter.values[i];
            return _filterPill(f, _countFor(f, trips));
          },
        ),
      ),
    );
  }

  Widget _filterPill(_TripStatusFilter f, int count) {
    final selected = f == _filter;
    final fg = selected ? Colors.white : _textSecondary;
    final bg = selected ? _accent : _surfaceLight;
    return Semantics(
      button: true,
      selected: selected,
      label: '${f.label}, $count trips',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => setState(() => _filter = f),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected ? _accent : _divider,
                width: 1,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: _accent.withValues(alpha: 0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(f.icon, size: 13, color: fg),
                const SizedBox(width: 6),
                Text(
                  f.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: fg,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.white.withValues(alpha: 0.22)
                        : _divider,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: selected ? Colors.white : _textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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