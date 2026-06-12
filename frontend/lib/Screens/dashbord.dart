import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_agency_app/Screens/add_customer.dart';
import 'package:travel_agency_app/Screens/add_driver.dart';
import 'package:travel_agency_app/Screens/add_tripbooking.dart';
import 'package:travel_agency_app/Screens/add_vehicle.dart';
import 'package:travel_agency_app/Screens/reports.dart';
import 'package:travel_agency_app/Screens/transactions_page.dart';
import 'package:travel_agency_app/core/theme/app_colors.dart';
import 'package:travel_agency_app/core/widgets/skeleton.dart';
import 'package:travel_agency_app/domain/models/booking_info.dart';
import 'package:travel_agency_app/domain/models/ledger_entry.dart';
import 'package:travel_agency_app/domain/models/vehicles.dart';
import 'package:travel_agency_app/domain/viewModel/trippage_viewmodel.dart';
import 'package:travel_agency_app/presentation/providers/viewmodel_provider.dart';

class TravelAdminDashboard extends ConsumerStatefulWidget {
  const TravelAdminDashboard({super.key});

  static const primaryColor = AppColors.brandPrimary;
  // Primary text color. Points at the shared neutral token so the dashboard
  // uses one dark text colour rather than a separate navy.
  static const darkBlue = AppColors.textPrimary;

  @override
  ConsumerState<TravelAdminDashboard> createState() =>
      _TravelAdminDashboardState();
}

class _TravelAdminDashboardState extends ConsumerState<TravelAdminDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAll();
    });
  }

  void _loadAll() {
    final agencyId = ref.read(loginViewModelProvider).agencyId ?? '';
    if (agencyId.trim().isEmpty) return;
    final notifier = ref.read(tripPageViewModelProvider.notifier);
    notifier.activeList(agencyId);
    notifier.upcomingList(agencyId);
    notifier.historyList(agencyId);
    notifier.unpaidList(agencyId);
    notifier.cancelledList(agencyId);
    // Vehicle list + agency ledger drive today's revenue/expenditure so the
    // dashboard figures match the Vehicle Report's "Today" filter exactly.
    // The ledger itself is fetched lazily by watching its provider in build().
    ref.read(tripBookingViewModelProvider.notifier).vehicleList(agencyId);
  }

  // Triggered by RefreshIndicator. Awaits all fetches so the spinner stays
  // until the data is genuinely back, not just dispatched. The ledger is a
  // cached FutureProvider, so invalidating it forces a re-fetch on next watch.
  Future<void> _refresh() async {
    final agencyId = ref.read(loginViewModelProvider).agencyId ?? '';
    if (agencyId.trim().isEmpty) return;
    final notifier = ref.read(tripPageViewModelProvider.notifier);
    ref.invalidate(vehicleReportLedgerProvider(agencyId));
    await Future.wait([
      notifier.activeList(agencyId),
      notifier.upcomingList(agencyId),
      notifier.historyList(agencyId),
      notifier.unpaidList(agencyId),
      notifier.cancelledList(agencyId),
      ref.read(tripBookingViewModelProvider.notifier).vehicleList(agencyId),
    ]);
  }

  // Today's revenue & expenditure from the same agency ledger the Vehicle
  // Report uses, so the two screens always agree. Revenue = PAYMENT_RECEIVED
  // rows dated today; expenditure = TRIP_EXPENSE + MAINTENANCE rows dated today.
  // Entries are scoped to vehicles still in the list (matching the report);
  // before that list loads we sum everything so the figure isn't briefly blank.
  ({double revenue, double expense}) _todayLedgerTotals(
    List<Vehicles> vehicles,
    List<LedgerEntry> ledger,
  ) {
    final now = DateTime.now();
    final ids = vehicles.map((v) => v.vehicleId).whereType<int>().toSet();
    var revenue = 0.0;
    var expense = 0.0;
    for (final e in ledger) {
      if (ids.isNotEmpty) {
        final id = e.vehicleId;
        if (id == null || !ids.contains(id)) continue;
      }
      final d = e.entryDate;
      if (d == null || !_isSameDay(d, now)) continue;
      if (e.isPayment) {
        revenue += e.revenue ?? 0;
      } else if (e.isTripExpense) {
        expense += e.tripExpense ?? 0;
      } else if (e.isMaintenance) {
        expense += e.maintenance ?? 0;
      }
    }
    return (revenue: revenue, expense: expense);
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
  List<BookingInfo> _getData(AsyncValue<List<BookingInfo>> value) {
    return value.when(
      data: (rows) => rows,
      loading: () => const <BookingInfo>[],
      error: (_, __) => const <BookingInfo>[],
    );
  }

  List<BookingInfo> _mergedTrips(TripPageState state) {
    final all = <BookingInfo>[
      ..._getData(state.activeList),
      ..._getData(state.upcomingList),
      ..._getData(state.historyList),
      ..._getData(state.unpaidList),
      ..._getData(state.cancelledList),
    ];

    final unique = <String, BookingInfo>{};
    for (final trip in all) {
      final key = trip.tripId?.toString() ??
          '${trip.bookingDate?.toIso8601String() ?? ''}-${trip.customerId ?? ''}-${trip.vehicleId ?? ''}-${trip.driverId ?? ''}';
      unique[key] = trip;
    }
    return unique.values.toList();
  }

  // "Today Bookings" = trips booked today, regardless of payment. Revenue and
  // expenditure no longer come from here — they're read from the agency ledger
  // so they stay in lock-step with the Vehicle Report. See [_todayLedgerTotals].
  int _todayBookings(List<BookingInfo> rows) {
    final now = DateTime.now();
    var bookings = 0;
    for (final row in rows) {
      final booked = row.bookingDate;
      if (booked != null && _isSameDay(booked, now)) {
        bookings += 1;
      }
    }
    return bookings;
  }

  @override
  Widget build(BuildContext context) {
    final tripState = ref.watch(tripPageViewModelProvider);
    final mergedTrips = _mergedTrips(tripState);
    final agencyId = ref.watch(loginViewModelProvider).agencyId ?? '';
    final ledgerAsync = ref.watch(vehicleReportLedgerProvider(agencyId));
    final vehicleState =
        ref.watch(tripBookingViewModelProvider).fetchVehicleList;
    final vehicles = vehicleState.asData?.value ?? const <Vehicles>[];
    final ledger = ledgerAsync.asData?.value ?? const <LedgerEntry>[];

    final anyLoading = tripState.activeList.isLoading ||
        tripState.upcomingList.isLoading ||
        tripState.historyList.isLoading ||
        tripState.unpaidList.isLoading ||
        tripState.cancelledList.isLoading ||
        ledgerAsync.isLoading ||
        vehicleState.isLoading;
    final anyError = tripState.activeList.hasError ||
        tripState.upcomingList.hasError ||
        tripState.historyList.hasError ||
        tripState.unpaidList.hasError ||
        tripState.cancelledList.hasError ||
        ledgerAsync.hasError ||
        vehicleState.hasError;
    final ledgerTotals = _todayLedgerTotals(vehicles, ledger);
    final todayStats = (mergedTrips.isNotEmpty || ledger.isNotEmpty)
        ? _DashboardStats(
            bookings: _todayBookings(mergedTrips),
            revenue: ledgerTotals.revenue,
            expenditure: ledgerTotals.expense,
          )
        : _DashboardStats(isLoading: anyLoading, hasError: anyError);

    final sw = MediaQuery.of(context).size.width;
    final isSmall = sw < 340;
    final hPad = isSmall ? 12.0 : 16.0;
    final sectionGap = isSmall ? 12.0 : 16.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: Stack(
        children: [
          Positioned(
            top: -60,
            right: -50,
            child: Container(
              width: sw * 0.55,
              height: sw * 0.55,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: TravelAdminDashboard.primaryColor.withOpacity(0.09),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            left: -40,
            child: Container(
              width: sw * 0.40,
              height: sw * 0.40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.brandPrimaryLight.withOpacity(0.06),
              ),
            ),
          ),
          SafeArea(
            child: RefreshIndicator(
              onRefresh: _refresh,
              color: TravelAdminDashboard.primaryColor,
              backgroundColor: Colors.white,
              child: SingleChildScrollView(
                // AlwaysScrollable so the pull-to-refresh works even when
                // the content is shorter than the viewport.
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
              padding: EdgeInsets.only(
                left: hPad,
                right: hPad,
                top: 12,
                bottom: 110,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _NewBookingHero(isSmall: isSmall),
                  SizedBox(height: sectionGap),
                  _ActionNeededCard(
                    isSmall: isSmall,
                    tripState: tripState,
                    isLoading: anyLoading,
                  ),
                  SizedBox(height: sectionGap),
                  _StatsRow(isSmall: isSmall, stats: todayStats),
                  SizedBox(height: sectionGap),
                  _SectionTitle(title: "Quick Actions", isSmall: isSmall),
                  SizedBox(height: isSmall ? 6 : 8),
                  _QuickActionsGrid(isSmall: isSmall),
                  SizedBox(height: sectionGap),
                  _SectionTitle(title: "Reports", isSmall: isSmall),
                  // SizedBox(height: isSmall ? 6 : 8),
                  // _BookingReportBanner(isSmall: isSmall),
                  SizedBox(height: isSmall ? 8 : 10),
                  _TransactionsBanner(isSmall: isSmall),
                  SizedBox(height: sectionGap),
                  // _SectionTitle(title: "Recent Activity", isSmall: isSmall),
                  // SizedBox(height: isSmall ? 10 : 14),
                  // _ReycentActivity(isSmall: isSmall),
                ],
              ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
// ─────────────────────────────────────────────────────────
// ACTION NEEDED CARD
// ─────────────────────────────────────────────────────────
class _ActionNeededCard extends ConsumerWidget {
  final bool isSmall;
  final TripPageState tripState;
  final bool isLoading;

  const _ActionNeededCard({
    required this.isSmall,
    required this.tripState,
    required this.isLoading,
  });

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unpaid = tripState.unpaidList.valueOrNull ?? const <BookingInfo>[];
    final upcoming = tripState.upcomingList.valueOrNull ?? const <BookingInfo>[];
    final active = tripState.activeList.valueOrNull ?? const <BookingInfo>[];

    // Outstanding dues: sum of pending_amount across unpaid + partially-paid
    // trips. We also count unique customers so the row reads "₹X across N".
    var duesTotal = 0.0;
    final dueCustomers = <Object>{};
    for (final t in unpaid) {
      final status = t.payment_status?.toLowerCase() ?? '';
      if (status != 'unpaid' && status != 'partially paid') continue;
      duesTotal += t.pendingAmount ?? 0.0;
      dueCustomers.add(t.customerId ?? 'c-${t.tripId ?? t.customer_name}');
    }

    final now = DateTime.now();
    // The "Upcoming Trips" row surfaces tomorrow's pickups so the operator can
    // prepare a day ahead — count trips whose start (or booking) day is tomorrow.
    final tomorrow = DateTime(now.year, now.month, now.day)
        .add(const Duration(days: 1));
    final startsTomorrow = upcoming.where((t) {
      final d = t.startDateTime ?? t.bookingDate;
      return d != null && _isSameDay(d, tomorrow);
    }).length;

    final activeCount = active.length;

    final totalAttention = (duesTotal > 0 ? 1 : 0) +
        (startsTomorrow > 0 ? 1 : 0) +
        (activeCount > 0 ? 1 : 0);

    // [date] pins the destination list to that day and everything after it;
    // null clears any prior date filter back to "All".
    void goToTrips(String filter, {DateTime? date}) {
      ref.read(tripPageInitialDateProvider.notifier).state = date;
      ref.read(tripPageInitialFilterProvider.notifier).state = filter;
      ref.read(bottomNavIndexProvider.notifier).state = 1;
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isSmall ? 14 : 16),
        boxShadow: [
          BoxShadow(
            color: TravelAdminDashboard.primaryColor.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          isSmall ? 10 : 12,
          isSmall ? 8 : 10,
          isSmall ? 10 : 12,
          isSmall ? 4 : 6,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.notifications_active_rounded,
                  color: AppColors.brandPrimary,
                  size: isSmall ? 14 : 16,
                ),
                SizedBox(width: isSmall ? 6 : 8),
                Expanded(
                  child: Text(
                    'Action Needed',
                    style: TextStyle(
                      fontSize: isSmall ? 12 : 13,
                      fontWeight: FontWeight.w800,
                      color: TravelAdminDashboard.darkBlue,
                      letterSpacing: -0.1,
                    ),
                  ),
                ),
                if (totalAttention > 0)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmall ? 6 : 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.dangerSoft,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$totalAttention',
                      style: TextStyle(
                        fontSize: isSmall ? 9 : 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.danger,
                      ),
                    ),
                  )
                else
                  Text(
                    'All caught up',
                    style: TextStyle(
                      fontSize: isSmall ? 9 : 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade500,
                    ),
                  ),
              ],
            ),
            SizedBox(height: isSmall ? 4 : 6),
            _ActionRow(
              isSmall: isSmall,
              icon: Icons.currency_rupee_rounded,
              color: AppColors.danger,
              bg: AppColors.dangerSoft,
              title: 'Outstanding dues',
              value: '₹${_formatCompact(duesTotal)}',
              subtitle: dueCustomers.isEmpty
                  ? 'No dues pending'
                  : 'Across ${dueCustomers.length} '
                      '${dueCustomers.length == 1 ? 'customer' : 'customers'}',
              isLoading: isLoading && unpaid.isEmpty,
              muted: duesTotal <= 0,
              onTap: () => goToTrips('unpaid'),
            ),
            _RowDivider(),
         
            _ActionRow(
              isSmall: isSmall,
              icon: Icons.directions_car_rounded,
              color: AppColors.info,
              bg: AppColors.infoSoft,
              title: 'Active trips right now',
              value: '$activeCount',
              subtitle: activeCount == 0
                  ? 'No trips on the road'
                  : activeCount == 1
                      ? '1 vehicle on the road'
                      : '$activeCount vehicles on the road',
              isLoading: isLoading && active.isEmpty,
              muted: activeCount == 0,
              onTap: () => goToTrips('active'),
            ),
               _RowDivider(),
               _ActionRow(
              isSmall: isSmall,
              icon: Icons.event_available_rounded,
              color: AppColors.warning,
              bg: AppColors.warningSoft,
              title: 'Upcoming Trips',
              value: '$startsTomorrow',
              subtitle: startsTomorrow == 0
                  ? 'Nothing scheduled for tomorrow'
                  : startsTomorrow == 1
                      ? '1 pickup tomorrow'
                      : '$startsTomorrow pickups tomorrow',
              isLoading: isLoading && upcoming.isEmpty,
              muted: startsTomorrow == 0,
              onTap: () => goToTrips('upcoming', date: tomorrow),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final bool isSmall;
  final IconData icon;
  final Color color;
  final Color bg;
  final String title;
  final String value;
  final String subtitle;
  final bool isLoading;
  final bool muted;
  final VoidCallback onTap;

  const _ActionRow({
    required this.isSmall,
    required this.icon,
    required this.color,
    required this.bg,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.isLoading,
    required this.muted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isSmall ? 2 : 4,
          vertical: isSmall ? 6 : 8,
        ),
        child: Row(
          children: [
            Container(
              width: isSmall ? 28 : 32,
              height: isSmall ? 28 : 32,
              decoration: BoxDecoration(
                color: muted ? Colors.grey.shade100 : bg,
                borderRadius: BorderRadius.circular(isSmall ? 8 : 9),
              ),
              child: Icon(
                icon,
                color: muted ? Colors.grey.shade400 : color,
                size: isSmall ? 14 : 16,
              ),
            ),
            SizedBox(width: isSmall ? 8 : 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: isSmall ? 11 : 12,
                      fontWeight: FontWeight.w700,
                      color: TravelAdminDashboard.darkBlue,
                      height: 1.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: isSmall ? 9 : 10,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            SizedBox(width: isSmall ? 4 : 6),
            if (isLoading)
              SkeletonBox(
                width: isSmall ? 34 : 48,
                height: isSmall ? 12 : 14,
              )
            else
              Text(
                value,
                style: TextStyle(
                  fontSize: isSmall ? 13 : 15,
                  fontWeight: FontWeight.w800,
                  color: muted ? Colors.grey.shade400 : color,
                  letterSpacing: -0.2,
                ),
              ),
            Icon(
              Icons.chevron_right_rounded,
              size: isSmall ? 14 : 16,
              color: Colors.grey.shade300,
            ),
          ],
        ),
      ),
    );
  }
}

class _RowDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.grey.shade100,
    );
  }
}

// ─────────────────────────────────────────────────────────
// NEW BOOKING HERO
// Attention-grabbing CTA at the top — gradient surface with
// a soft decorative ring, large icon, headline, and an arrow
// pill. Tap anywhere on the card opens the trip-booking form.
// ─────────────────────────────────────────────────────────
class _NewBookingHero extends StatelessWidget {
  final bool isSmall;
  const _NewBookingHero({required this.isSmall});

  /// Airtel brand red — used only for this "New Booking" hero CTA so it stands
  /// out as the primary call-to-action against the warm-charcoal headers.
  static const Color _airtelRed = Color(0xFFED1C24);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(isSmall ? 16 : 20),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TripBookingForm()),
        ),
        child: Ink(
          decoration: BoxDecoration(
            color: _airtelRed,
            borderRadius: BorderRadius.circular(isSmall ? 16 : 20),
            boxShadow: [
              BoxShadow(
                color: _airtelRed.withOpacity(0.30),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Decorative ring — soft brand-tinted circle peeking from the
              // right edge. Adds depth without competing with the headline.
              Positioned(
                right: -28,
                top: -22,
                child: Container(
                  width: isSmall ? 110 : 130,
                  height: isSmall ? 110 : 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.10),
                  ),
                ),
              ),
              Positioned(
                right: 28,
                bottom: -36,
                child: Container(
                  width: isSmall ? 72 : 84,
                  height: isSmall ? 72 : 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.06),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  isSmall ? 14 : 18,
                  isSmall ? 14 : 16,
                  isSmall ? 14 : 18,
                  isSmall ? 14 : 16,
                ),
                child: Row(
                  children: [
                    Container(
                      width: isSmall ? 44 : 52,
                      height: isSmall ? 44 : 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius:
                            BorderRadius.circular(isSmall ? 12 : 14),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.30),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.add_road_rounded,
                        color: Colors.white,
                        size: isSmall ? 22 : 26,
                      ),
                    ),
                    SizedBox(width: isSmall ? 12 : 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'New Booking',
                            style: TextStyle(
                              fontSize: isSmall ? 17 : 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.4,
                              height: 1.1,
                            ),
                          ),
                          SizedBox(height: isSmall ? 3 : 4),
                          Text(
                            'Book a trip in seconds',
                            style: TextStyle(
                              fontSize: isSmall ? 11 : 12.5,
                              color: Colors.white.withOpacity(0.85),
                              fontWeight: FontWeight.w500,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: isSmall ? 8 : 10),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmall ? 10 : 12,
                        vertical: isSmall ? 7 : 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(isSmall ? 20 : 22),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Start',
                            style: TextStyle(
                              fontSize: isSmall ? 11 : 12,
                              fontWeight: FontWeight.w800,
                              color: _airtelRed,
                              letterSpacing: 0.1,
                            ),
                          ),
                          SizedBox(width: isSmall ? 3 : 4),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: isSmall ? 13 : 15,
                            color: _airtelRed,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// // ─────────────────────────────────────────────────────────
// // BOOKING REPORT BANNER
// // ─────────────────────────────────────────────────────────
// class _BookingReportBanner extends ConsumerWidget {
//   final bool isSmall;
//   const _BookingReportBanner({required this.isSmall});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     return GestureDetector(
//       onTap: () {
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (_) => TravelReportPage(
//               agencyId: ref.read(loginViewModelProvider).agencyId ?? "",
//             ),
//           ),
//         );
//       },
//       child: Container(
//         width: double.infinity,
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(isSmall ? 14 : 16),
//           boxShadow: [
//             BoxShadow(
//               color: TravelAdminDashboard.primaryColor.withOpacity(0.08),
//               blurRadius: 12,
//               offset: const Offset(0, 4),
//             ),
//           ],
//         ),
//         child: Padding(
//           padding: EdgeInsets.all(isSmall ? 10 : 12),
//           child: Row(
//             crossAxisAlignment: CrossAxisAlignment.center,
//             children: [
//               Container(
//                 width: isSmall ? 36 : 42,
//                 height: isSmall ? 36 : 42,
//                 decoration: BoxDecoration(
//                   gradient: const LinearGradient(
//                     colors: [AppColors.brandPrimary, AppColors.brandPrimaryLight],
//                     begin: Alignment.topLeft,
//                     end: Alignment.bottomRight,
//                   ),
//                   borderRadius: BorderRadius.circular(isSmall ? 9 : 11),
//                   boxShadow: [
//                     BoxShadow(
//                       color: TravelAdminDashboard.primaryColor.withOpacity(0.25),
//                       blurRadius: 6,
//                       offset: const Offset(0, 2),
//                     ),
//                   ],
//                 ),
//                 child: Icon(
//                   Icons.bar_chart_outlined,
//                   color: Colors.white,
//                   size: isSmall ? 18 : 22,
//                 ),
//               ),
//               SizedBox(width: isSmall ? 10 : 12),

//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Text(
//                       "Booking Report",
//                       style: TextStyle(
//                         fontSize: isSmall ? 13 : 15,
//                         fontWeight: FontWeight.w800,
//                         color: TravelAdminDashboard.darkBlue,
//                         letterSpacing: -0.2,
//                         height: 1.1,
//                       ),
//                     ),
//                     SizedBox(height: isSmall ? 2 : 3),
//                     Text(
//                       "Bookings, drivers, vehicles & revenue",
//                       style: TextStyle(
//                         fontSize: isSmall ? 9 : 10,
//                         color: Colors.grey.shade500,
//                         height: 1.3,
//                         fontWeight: FontWeight.w500,
//                       ),
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ],
//                 ),
//               ),
//               SizedBox(width: isSmall ? 6 : 8),

//               Container(
//                 width: isSmall ? 26 : 30,
//                 height: isSmall ? 26 : 30,
//                 decoration: const BoxDecoration(
//                   color: AppColors.brandSoft,
//                   shape: BoxShape.circle,
//                 ),
//                 child: Icon(
//                   Icons.arrow_forward_rounded,
//                   color: TravelAdminDashboard.primaryColor,
//                   size: isSmall ? 14 : 16,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// ─────────────────────────────────────────────────────────
// TRANSACTIONS BANNER
// Routes to the Transactions daybook — a date-grouped ledger of
// every payment received and expense incurred. Shares the brand
// accent with the other report cards; told apart by its icon and
// title rather than a separate hue.
// ─────────────────────────────────────────────────────────
class _TransactionsBanner extends StatelessWidget {
  final bool isSmall;
  const _TransactionsBanner({required this.isSmall});

  @override
  Widget build(BuildContext context) {
    const accent = AppColors.brandPrimary;
    const accentSoft = AppColors.brandSoft;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const TransactionsPage(),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(isSmall ? 14 : 16),
          boxShadow: [
            BoxShadow(
              color: accent.withOpacity(0.10),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(isSmall ? 10 : 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: isSmall ? 36 : 42,
                height: isSmall ? 36 : 42,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(isSmall ? 9 : 11),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withOpacity(0.30),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.receipt_long_rounded,
                  color: Colors.white,
                  size: isSmall ? 18 : 22,
                ),
              ),
              SizedBox(width: isSmall ? 10 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Transaction History",
                      style: TextStyle(
                        fontSize: isSmall ? 13 : 15,
                        fontWeight: FontWeight.w800,
                        color: TravelAdminDashboard.darkBlue,
                        letterSpacing: -0.2,
                        height: 1.1,
                      ),
                    ),
                    SizedBox(height: isSmall ? 2 : 3),
                    Text(
                      "Payments, expenses & daily cash flow",
                      style: TextStyle(
                        fontSize: isSmall ? 9 : 10,
                        color: Colors.grey.shade500,
                        height: 1.3,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              SizedBox(width: isSmall ? 6 : 8),
              Container(
                width: isSmall ? 26 : 30,
                height: isSmall ? 26 : 30,
                decoration: const BoxDecoration(
                  color: accentSoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: accent,
                  size: isSmall ? 14 : 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSmall;
  const _StatChip(
      {required this.icon, required this.label, required this.isSmall});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 8 : 10,
        vertical: isSmall ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: isSmall ? 10 : 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: isSmall ? 9 : 10,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}



// ─────────────────────────────────────────────────────────
// SECTION TITLE
// ─────────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String title;
  final bool isSmall;
  const _SectionTitle({required this.title, required this.isSmall});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: isSmall ? 15 : 18,
          decoration: BoxDecoration(
            color: TravelAdminDashboard.primaryColor,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: isSmall ? 14 : 16,
            fontWeight: FontWeight.w700,
            color: TravelAdminDashboard.darkBlue,
            letterSpacing: 0.1,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
// STATS ROW
// ─────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final bool isSmall;
  final _DashboardStats stats;
  const _StatsRow({required this.isSmall, required this.stats});

  @override
  Widget build(BuildContext context) {
    final bookingsVal = stats.bookings.toString();
    final revenueVal = '₹${_formatCompact(stats.revenue)}';
    final expenditureVal = '₹${_formatCompact(stats.expenditure)}';

    // The money tiles deep-link into today's Transactions (daybook) — tapping a
    // number is the natural "show me which client paid for which trip" gesture.
    // Revenue opens the Revenue list, Expenditure opens the Expense list.
    void openTodayTransactions(TxnType type) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TransactionsPage(
            date: DateTime.now(),
            initialType: type,
          ),
        ),
      );
    }

    final statItems = [
      _StatData(
        'Today Bookings',
        bookingsVal,
        Icons.confirmation_number_outlined,
        AppColors.brandPrimary,
        AppColors.brandSoft,
        isLoading: stats.isLoading,
        hasError: stats.hasError,
      ),
      _StatData(
        'Today Revenue',
        revenueVal,
        Icons.currency_rupee_rounded,
        AppColors.success,
        AppColors.successSoft,
        isLoading: stats.isLoading,
        hasError: stats.hasError,
        onTap: () => openTodayTransactions(TxnType.revenue),
      ),
      _StatData(
        'Today Expenditure',
        expenditureVal,
        Icons.trending_down_rounded,
        AppColors.danger,
        AppColors.dangerSoft,
        isLoading: stats.isLoading,
        hasError: stats.hasError,
        onTap: () => openTodayTransactions(TxnType.expense),
      ),
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: statItems.asMap().entries.map((entry) {
        final i = entry.key;
        final s = entry.value;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: i == 0 ? 0 : (isSmall ? 6 : 8)),
            child: _StatCard(data: s, isSmall: isSmall),
          ),
        );
      }).toList(),
    );
  }
}
class _StatCard extends StatelessWidget {
  final _StatData data;
  final bool isSmall;
  const _StatCard({required this.data, required this.isSmall});

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(isSmall ? 12 : 14);
    return Material(
      color: Colors.white,
      borderRadius: borderRadius,
      child: InkWell(
        borderRadius: borderRadius,
        onTap: data.onTap,
        child: Ink(
          padding: EdgeInsets.all(isSmall ? 8 : 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: borderRadius,
            boxShadow: [
              BoxShadow(
                color: data.color.withOpacity(0.10),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
          Container(
            width: isSmall ? 24 : 28,
            height: isSmall ? 24 : 28,
            decoration: BoxDecoration(
              color: data.bgColor,
              borderRadius: BorderRadius.circular(isSmall ? 7 : 8),
            ),
            child: Icon(data.icon, color: data.color, size: isSmall ? 13 : 15),
          ),
          SizedBox(height: isSmall ? 5 : 7),
          if (data.isLoading)
            SkeletonBox(
              width: isSmall ? 44 : 56,
              height: isSmall ? 14 : 16,
            )
          else
            Text(
              data.hasError ? '—' : data.value,
              style: TextStyle(
                fontSize: isSmall ? 12 : 14,
                fontWeight: FontWeight.w800,
                color: TravelAdminDashboard.darkBlue,
                letterSpacing: -0.3,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          const SizedBox(height: 1),
          Text(
            data.title,
            style: TextStyle(
              fontSize: isSmall ? 8 : 10,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// QUICK ACTIONS GRID
// ─────────────────────────────────────────────────────────
class _QuickActionsGrid extends StatelessWidget {
  final bool isSmall;
  const _QuickActionsGrid({required this.isSmall});

  @override
  Widget build(BuildContext context) {
    // "New Booking" lives in the hero CTA at the top of the dashboard, so the
    // Quick Actions row only carries the three secondary entity-creation flows.
    final actions = [
      _ActionData("New Vehicle", Icons.directions_car_rounded,
          AppColors.brandPrimary, AppColors.brandSoft),
      _ActionData("New Driver", Icons.person_pin_rounded,
          AppColors.brandPrimary, AppColors.brandSoft),
      _ActionData("New Customer", Icons.people_alt_rounded,
          AppColors.brandPrimary, AppColors.brandSoft),
    ];

    return Row(
      children: [
        for (var i = 0; i < actions.length; i++) ...[
          if (i > 0) SizedBox(width: isSmall ? 6 : 8),
          Expanded(child: _ActionCard(data: actions[i], isSmall: isSmall)),
        ],
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final _ActionData data;
  final bool isSmall;
  const _ActionCard({required this.data, required this.isSmall});

  void _navigate(BuildContext context) {
    switch (data.title) {
      case 'New Booking':
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => TripBookingForm()));
        break;
      case 'New Vehicle':
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => AddVehiclePage()));
        break;
      case 'New Driver':
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => AddDriverPage()));
        break;
      case 'New Customer':
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => AddCustomerPage()));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final iconSize = isSmall ? 30.0 : 34.0;
    final iconInner = isSmall ? 15.0 : 17.0;
    final pad = isSmall ? 8.0 : 10.0;

    return InkWell(
      onTap: () => _navigate(context),
      borderRadius: BorderRadius.circular(isSmall ? 12 : 14),
      child: Container(
        padding: EdgeInsets.all(pad),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(isSmall ? 12 : 14),
          boxShadow: [
            BoxShadow(
              color: data.color.withOpacity(0.10),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                color: data.bgColor,
                borderRadius: BorderRadius.circular(isSmall ? 8 : 10),
              ),
              child: Icon(data.icon, color: data.color, size: iconInner),
            ),
            SizedBox(width: isSmall ? 6 : 8),
            Expanded(
              child: Text(
                data.title,
                style: TextStyle(
                  fontSize: isSmall ? 10 : 12,
                  fontWeight: FontWeight.w700,
                  color: TravelAdminDashboard.darkBlue,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// RECENT ACTIVITY
// ─────────────────────────────────────────────────────────
class _RecentActivity extends StatelessWidget {
  final bool isSmall;
  const _RecentActivity({required this.isSmall});

  @override
  Widget build(BuildContext context) {
    final activities = [
      _ActivityData(Icons.check_circle_rounded, const Color(0xFF00BFA5),
          const Color(0xFFE0F7F4), "Invoice #1021 Paid", "2 hours ago"),
      _ActivityData(Icons.shopping_bag_rounded, TravelAdminDashboard.primaryColor,
          AppColors.brandSoft, "New Order Received", "Today, 10:30 AM"),
      _ActivityData(Icons.directions_car_rounded, const Color(0xFFFF6D00),
          const Color(0xFFFFF3E0), "Vehicle Added", "Yesterday"),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isSmall ? 14 : 20),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.07),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(activities.length, (index) {
          final a = activities[index];
          final avatarSize = isSmall ? 36.0 : 42.0;
          final iconSize = isSmall ? 17.0 : 20.0;

          return Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmall ? 12 : 16,
                  vertical: isSmall ? 10 : 14,
                ),
                child: Row(
                  children: [
                    Container(
                      width: avatarSize,
                      height: avatarSize,
                      decoration: BoxDecoration(
                        color: a.iconBg,
                        borderRadius: BorderRadius.circular(isSmall ? 10 : 12),
                      ),
                      child: Icon(a.icon, color: a.iconColor, size: iconSize),
                    ),
                    SizedBox(width: isSmall ? 10 : 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            a.title,
                            style: TextStyle(
                              fontSize: isSmall ? 12 : 14,
                              fontWeight: FontWeight.w600,
                              color: TravelAdminDashboard.darkBlue,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            a.subtitle,
                            style: TextStyle(
                              fontSize: isSmall ? 10 : 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded,
                        color: Colors.grey.shade300,
                        size: isSmall ? 16 : 20),
                  ],
                ),
              ),
              if (index < activities.length - 1)
                Divider(
                  height: 1,
                  color: Colors.grey.shade100,
                  indent: isSmall ? 58 : 70,
                  endIndent: 12,
                ),
            ],
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// DATA MODELS
// ─────────────────────────────────────────────────────────
class _StatData {
  final String title, value;
  final IconData icon;
  final Color color, bgColor;
  final bool isLoading;
  final bool hasError;
  // When non-null the card becomes tappable — used to deep-link the Revenue
  // and Expenditure stats into the Vehicle Report filtered to today.
  final VoidCallback? onTap;
  const _StatData(
    this.title,
    this.value,
    this.icon,
    this.color,
    this.bgColor, {
    this.isLoading = false,
    this.hasError = false,
    this.onTap,
  });
}

class _ActionData {
  final String title;
  final IconData icon;
  final Color color, bgColor;
  const _ActionData(this.title, this.icon, this.color, this.bgColor);
}

class _ActivityData {
  final IconData icon;
  final Color iconColor, iconBg;
  final String title, subtitle;
  const _ActivityData(
      this.icon, this.iconColor, this.iconBg, this.title, this.subtitle);
}

class _DashboardStats {
  final int bookings;
  final double revenue;
  final double expenditure;
  final bool isLoading;
  final bool hasError;

  const _DashboardStats({
    this.bookings = 0,
    this.revenue = 0,
    this.expenditure = 0,
    this.isLoading = false,
    this.hasError = false,
  });
}

String _formatCompact(double v) {
  if (v >= 1e7) return '${(v / 1e7).toStringAsFixed(2)}Cr';
  if (v >= 1e5) return '${(v / 1e5).toStringAsFixed(2)}L';
  if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(2)}K';
  return v.toStringAsFixed(0);
}

