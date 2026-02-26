import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_agency_app/Screens/trip_card.dart';
import 'package:travel_agency_app/domain/models/booking_info.dart';
import 'package:travel_agency_app/domain/models/customers.dart';
import 'package:travel_agency_app/presentation/providers/viewmodel_provider.dart';

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
  static const Color _accent        = Color(0xFF3D5AFE);
  static const Color _accentSoft    = Color(0xFFEEF1FF);
  static const Color _textPrimary   = Color(0xFF1A1D2E);
  static const Color _textSecondary = Color(0xFF7B82A0);
  static const Color _divider       = Color(0xFFE4E8F0);
  static const Color _success       = Color(0xFF2DB976);
  static const Color _successSoft   = Color(0xFFE8F8F1);

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

    Future.microtask(() {
      ref
          .read(customerViewModelProvider.notifier)
          .fetchCustomershist(widget.customer.customerId ?? 0);
    });
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  String _getInitials(String? name) {
    if (name == null || name.trim().isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(customerViewModelProvider);

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          // ── STATIC HEADER ─────────────────────────────────────
          _buildStaticHeader(state.Customerhist),

          // ── SCROLLABLE CONTENT ────────────────────────────────
          Expanded(
            child: _buildTripList(state.Customerhist),
          ),
        ],
      ),
    );
  }

  // ── STATIC HEADER ──────────────────────────────────────────────────
  Widget _buildStaticHeader(AsyncValue<List<BookingInfo>> tripState) {
    final customer = widget.customer;
    final topPad = MediaQuery.of(context).padding.top;

    return Container(
      padding: EdgeInsets.fromLTRB(20, topPad + 12, 20, 20),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3D5AFE).withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative blob top-right
          Positioned(
            top: -16,
            right: -16,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  _accent.withOpacity(0.07),
                  _accent.withOpacity(0.0),
                ]),
              ),
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Top bar: Back + label ──────────────────────
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: _surfaceLight,
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(color: _divider, width: 1.2),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: _textPrimary,
                        size: 15,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "Customer's History",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _textSecondary,
                      letterSpacing: 1.4,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ── Avatar + Name + Phone ─────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Glowing Avatar
                  ScaleTransition(
                    scale: _avatarScale,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6378FF), Color(0xFF3D5AFE)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _accent.withOpacity(0.30),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          _getInitials(customer.name),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 14),

                  // Name + Phone
                  SlideTransition(
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
                          Row(
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
                                customer.phone ?? '--',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // ── Compact Stats Strip ───────────────────────
              _buildCompactStats(tripState),
            ],
          ),
        ],
      ),
    );
  }

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
              backgroundColor: _accent.withOpacity(0.1),
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
        final formatted = totalValue >= 1000
            ? '₹${(totalValue / 1000).toStringAsFixed(1)}k'
            : '₹${totalValue.toStringAsFixed(0)}';

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
                const Color(0xFFE67E22),
                const Color(0xFFFEF0E6),
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: _accent,
              backgroundColor: _accent.withOpacity(0.1),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "Loading trips...",
            style: TextStyle(
              color: _textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
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
            GestureDetector(
              onTap: () => ref
                  .read(customerViewModelProvider.notifier)
                  .fetchCustomershist(widget.customer.customerId ?? 0),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6378FF), Color(0xFF3D5AFE)],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: _accent.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Text(
                  "Retry",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _accentSoft,
              shape: BoxShape.circle,
              border: Border.all(color: _accent.withOpacity(0.15), width: 2),
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
    );
  }

  Widget _tripsData(List<BookingInfo> trips) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section label
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 3,
                    height: 14,
                    decoration: BoxDecoration(
                      color: _accent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "TRIP HISTORY",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: _textSecondary,
                      letterSpacing: 2.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _accentSoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "${trips.length} trips",
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _accent,
                  ),
                ),
              ),
            ],
          ),
        ),

        // TripCards
        Expanded(
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: trips.length,
            itemBuilder: (_, i) => TripCard(
              key: ValueKey(trips[i].tripId),
              bookinginfo: trips[i],
              ref: ref, status: trips[i].status ?? 0,
            ),
          ),
        ),
      ],
    );
  }
}