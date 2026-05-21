import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_agency_app/Screens/add_customer.dart';
import 'package:travel_agency_app/Screens/add_driver.dart';
import 'package:travel_agency_app/Screens/add_tripbooking.dart';
import 'package:travel_agency_app/Screens/add_vehicle.dart';
import 'package:travel_agency_app/Screens/reports.dart';
import 'package:travel_agency_app/core/widgets/skeleton.dart';
import 'package:travel_agency_app/domain/models/booking_info.dart';
import 'package:travel_agency_app/domain/viewModel/trippage_viewmodel.dart';
import 'package:travel_agency_app/presentation/providers/viewmodel_provider.dart';

class TravelAdminDashboard extends ConsumerStatefulWidget {
  const TravelAdminDashboard({super.key});

  static const primaryColor = Color(0xFF3D5AFE);
  static const darkBlue = Color(0xFF1A237E);

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
    final notifier = ref.read(TripPageViewModelProvider.notifier);
    notifier.activeList(agencyId);
    notifier.upcomingList(agencyId);
    notifier.historyList(agencyId);
    notifier.unpaidList(agencyId);
    notifier.cancelledList(agencyId);
  }

  // Triggered by RefreshIndicator. Awaits all five fetches so the spinner
  // stays until the data is genuinely back, not just dispatched.
  Future<void> _refresh() async {
    final agencyId = ref.read(loginViewModelProvider).agencyId ?? '';
    if (agencyId.trim().isEmpty) return;
    final notifier = ref.read(TripPageViewModelProvider.notifier);
    await Future.wait([
      notifier.activeList(agencyId),
      notifier.upcomingList(agencyId),
      notifier.historyList(agencyId),
      notifier.unpaidList(agencyId),
      notifier.cancelledList(agencyId),
    ]);
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

  _DashboardStats _todayStats(List<BookingInfo> rows) {
    final now = DateTime.now();
    var bookings = 0;
    var revenue = 0.0;
    var expenditure = 0.0;

    for (final row in rows) {
      final date = row.bookingDate;
      if (date == null || !_isSameDay(date, now)) continue;
      bookings += 1;
      revenue += row.amountReceived ?? row.amountApprove ?? 0.0;
      expenditure += (row.tollCharges ?? 0.0) +
          (row.repairingCharges ?? 0.0) +
          (row.driverCharges ?? 0.0);
    }

    return _DashboardStats(
      bookings: bookings,
      revenue: revenue,
      expenditure: expenditure,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tripState = ref.watch(TripPageViewModelProvider);
    final mergedTrips = _mergedTrips(tripState);
    final anyLoading = tripState.activeList.isLoading ||
        tripState.upcomingList.isLoading ||
        tripState.historyList.isLoading ||
        tripState.unpaidList.isLoading ||
        tripState.cancelledList.isLoading;
    final anyError = tripState.activeList.hasError ||
        tripState.upcomingList.hasError ||
        tripState.historyList.hasError ||
        tripState.unpaidList.hasError ||
        tripState.cancelledList.hasError;
    final todayStats = mergedTrips.isNotEmpty
        ? _todayStats(mergedTrips)
        : _DashboardStats(isLoading: anyLoading, hasError: anyError);

    final sw = MediaQuery.of(context).size.width;
    final isSmall = sw < 340;
    final hPad = isSmall ? 12.0 : 20.0;
    final sectionGap = isSmall ? 18.0 : 28.0;

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
                color: const Color(0xFF536DFE).withOpacity(0.06),
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
                top: 18,
                bottom: 110,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PageTitle(isSmall: isSmall),
                  SizedBox(height: sectionGap - 6),
                  _StatsRow(isSmall: isSmall, stats: todayStats),
                  SizedBox(height: sectionGap),
                  _SectionTitle(title: "Quick Actions", isSmall: isSmall),
                  SizedBox(height: isSmall ? 10 : 14),
                  _QuickActionsGrid(isSmall: isSmall),
                  SizedBox(height: sectionGap),
                  _SectionTitle(title: "Reports", isSmall: isSmall),
                  SizedBox(height: isSmall ? 10 : 14),
                  _BookingReportBanner(isSmall: isSmall),
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
// BOOKING REPORT BANNER
// ─────────────────────────────────────────────────────────
class _BookingReportBanner extends ConsumerWidget {
  final bool isSmall;
  const _BookingReportBanner({required this.isSmall});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TravelReportPage(
              agencyId: ref.read(loginViewModelProvider).agencyId ?? "",
            ),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(isSmall ? 18 : 22),
          boxShadow: [
            BoxShadow(
              color: TravelAdminDashboard.primaryColor.withOpacity(0.10),
              blurRadius: 20,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(isSmall ? 14 : 18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left: gradient icon box
              Container(
                width: isSmall ? 52 : 64,
                height: isSmall ? 52 : 64,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3D5AFE), Color(0xFF7986CB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(isSmall ? 13 : 16),
                  boxShadow: [
                    BoxShadow(
                      color: TravelAdminDashboard.primaryColor.withOpacity(0.30),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.bar_chart_outlined,
                  color: Colors.white,
                  size: isSmall ? 24 : 30,
                ),
              ),
              SizedBox(width: isSmall ? 12 : 16),

              // Middle: text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8EAFF),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "REPORTS",
                        style: TextStyle(
                          fontSize: isSmall ? 8 : 9,
                          fontWeight: FontWeight.w800,
                          color: TravelAdminDashboard.primaryColor,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    SizedBox(height: isSmall ? 5 : 7),

                    // Title
                    Text(
                      "Booking Report",
                      style: TextStyle(
                        fontSize: isSmall ? 16 : 20,
                        fontWeight: FontWeight.w900,
                        color: TravelAdminDashboard.darkBlue,
                        letterSpacing: -0.4,
                        height: 1.1,
                      ),
                    ),
                    SizedBox(height: isSmall ? 4 : 5),

                    // Subtitle
                    Text(
                      
                       "Bookings, drivers, vehicles,\ncustomers & revenue",
                      style: TextStyle(
                        fontSize: isSmall ? 10 : 11,
                        color: Colors.grey.shade500,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: isSmall ? 10 : 14),

                    // Chips
                    Row(
                      children: [
                        _ReportChip(
                          icon: Icons.bar_chart_rounded,
                          label: "Analytics",
                          color: TravelAdminDashboard.primaryColor,
                          bg: const Color(0xFFE8EAFF),
                          isSmall: isSmall,
                        ),
                        SizedBox(width: isSmall ? 6 : 8),
                        // _ReportChip(
                        //   icon: Icons.download_rounded,
                        //   label: "Export",
                        //   color: const Color(0xFF00897B),
                        //   bg: const Color(0xFFE0F7F4),
                        //   isSmall: isSmall,
                        // ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: isSmall ? 10 : 14),

              // Right: arrow button
              Container(
                width: isSmall ? 34 : 40,
                height: isSmall ? 34 : 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8EAFF),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: TravelAdminDashboard.primaryColor,
                  size: isSmall ? 16 : 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// REPORT CHIP (replaces _StatChip for this widget)
// ─────────────────────────────────────────────────────────
class _ReportChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bg;
  final bool isSmall;

  const _ReportChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.bg,
    required this.isSmall,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 8 : 10,
        vertical: isSmall ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: isSmall ? 10 : 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: isSmall ? 9 : 10,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
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
// PAGE TITLE
// ─────────────────────────────────────────────────────────
class _PageTitle extends StatelessWidget {
  final bool isSmall;
  const _PageTitle({required this.isSmall});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final dateStr = "${now.day} ${months[now.month - 1]}";

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Dashboard",
                style: TextStyle(
                  fontSize: isSmall ? 20 : 26,
                  fontWeight: FontWeight.w800,
                  color: TravelAdminDashboard.darkBlue,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                "Your agency at a glance",
                style: TextStyle(
                  fontSize: isSmall ? 11 : 13,
                  color: Colors.grey.shade500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isSmall ? 8 : 12,
            vertical: 7,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: TravelAdminDashboard.primaryColor.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: isSmall ? 11 : 13,
                color: TravelAdminDashboard.primaryColor,
              ),
              const SizedBox(width: 4),
              Text(
                dateStr,
                style: TextStyle(
                  fontSize: isSmall ? 10 : 11,
                  fontWeight: FontWeight.w600,
                  color: TravelAdminDashboard.primaryColor,
                ),
              ),
            ],
          ),
        ),
      ],
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

    final statItems = [
      _StatData(
        'Today Bookings',
        bookingsVal,
        Icons.confirmation_number_outlined,
        const Color(0xFF00BFA5),
        const Color(0xFFE0F7F4),
        isLoading: stats.isLoading,
        hasError: stats.hasError,
      ),
      _StatData(
        'Today Revenue',
        revenueVal,
        Icons.currency_rupee_rounded,
        const Color(0xFFFF6D00),
        const Color(0xFFFFF3E0),
        isLoading: stats.isLoading,
        hasError: stats.hasError,
      ),
      _StatData(
        'Today Expenditure',
        expenditureVal,
        Icons.trending_down_rounded,
        TravelAdminDashboard.primaryColor,
        const Color(0xFFE8EAFF),
        isLoading: stats.isLoading,
        hasError: stats.hasError,
      ),
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: statItems.asMap().entries.map((entry) {
        final i = entry.key;
        final s = entry.value;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: i == 0 ? 0 : (isSmall ? 6 : 12)),
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
    return Container(
      padding: EdgeInsets.all(isSmall ? 10 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isSmall ? 14 : 18),
        boxShadow: [
          BoxShadow(
            color: data.color.withOpacity(0.12),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: isSmall ? 30 : 36,
            height: isSmall ? 30 : 36,
            decoration: BoxDecoration(
              color: data.bgColor,
              borderRadius: BorderRadius.circular(isSmall ? 8 : 10),
            ),
            child: Icon(data.icon, color: data.color, size: isSmall ? 15 : 18),
          ),
          SizedBox(height: isSmall ? 7 : 10),
          if (data.isLoading)
            SkeletonBox(
              width: isSmall ? 50 : 64,
              height: isSmall ? 16 : 18,
            )
          else
            Text(
              data.hasError ? '—' : data.value,
              style: TextStyle(
                fontSize: isSmall ? 13 : 15,
                fontWeight: FontWeight.w800,
                color: TravelAdminDashboard.darkBlue,
                letterSpacing: -0.3,
              ),
            ),
          const SizedBox(height: 2),
          Text(
            data.title,
            style: TextStyle(
              fontSize: isSmall ? 9 : 11,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
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
    final actions = [
      _ActionData("New Booking", Icons.add_card_rounded,
          const Color(0xFF00BFA5), const Color(0xFFE0F7F4)),
      _ActionData("New Vehicle", Icons.directions_car_rounded,
          const Color(0xFFFF6D00), const Color(0xFFFFF3E0)),
      _ActionData("New Driver", Icons.person_pin_rounded,
          TravelAdminDashboard.primaryColor, const Color(0xFFE8EAFF)),
      _ActionData("New Customer", Icons.people_alt_rounded,
          const Color(0xFFAB47BC), const Color(0xFFF3E5F5)),
    ];

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _ActionCard(data: actions[0], isSmall: isSmall)),
            SizedBox(width: isSmall ? 8 : 14),
            Expanded(child: _ActionCard(data: actions[1], isSmall: isSmall)),
          ],
        ),
        SizedBox(height: isSmall ? 8 : 14),
        Row(
          children: [
            Expanded(child: _ActionCard(data: actions[2], isSmall: isSmall)),
            SizedBox(width: isSmall ? 8 : 14),
            Expanded(child: _ActionCard(data: actions[3], isSmall: isSmall)),
          ],
        ),
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
    final iconSize = isSmall ? 36.0 : 44.0;
    final iconInner = isSmall ? 17.0 : 22.0;
    final pad = isSmall ? 10.0 : 14.0;

    return InkWell(
      onTap: () => _navigate(context),
      borderRadius: BorderRadius.circular(isSmall ? 14 : 18),
      child: Container(
        padding: EdgeInsets.all(pad),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(isSmall ? 14 : 18),
          boxShadow: [
            BoxShadow(
              color: data.color.withOpacity(0.12),
              blurRadius: 14,
              offset: const Offset(0, 5),
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
                borderRadius: BorderRadius.circular(isSmall ? 10 : 13),
              ),
              child: Icon(data.icon, color: data.color, size: iconInner),
            ),
            SizedBox(width: isSmall ? 8 : 12),
            Expanded(
              child: Text(
                data.title,
                style: TextStyle(
                  fontSize: isSmall ? 11 : 13,
                  fontWeight: FontWeight.w700,
                  color: TravelAdminDashboard.darkBlue,
                  height: 1.3,
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
          const Color(0xFFE8EAFF), "New Order Received", "Today, 10:30 AM"),
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
  const _StatData(
    this.title,
    this.value,
    this.icon,
    this.color,
    this.bgColor, {
    this.isLoading = false,
    this.hasError = false,
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

