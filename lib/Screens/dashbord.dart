import 'package:flutter/material.dart';
import 'package:travel_agency_app/Screens/add_customer.dart';
import 'package:travel_agency_app/Screens/add_driver.dart';
import 'package:travel_agency_app/Screens/add_tripbooking.dart';
import 'package:travel_agency_app/Screens/add_vehicle.dart';

class TravelAdminDashboard extends StatelessWidget {
  const TravelAdminDashboard({super.key});

  static const primaryColor = Color(0xFF3D5AFE);
  static const darkBlue = Color(0xFF1A237E);

  @override
  Widget build(BuildContext context) {
    // ── Responsive values based on screen width ──────────
    final sw = MediaQuery.of(context).size.width;
    final isSmall = sw < 340;          // very small screens
    final hPad = isSmall ? 12.0 : 20.0;
    final sectionGap = isSmall ? 18.0 : 28.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: Stack(
        children: [
          // ── Decorative blobs (scaled for screen) ──────
          Positioned(
            top: -60,
            right: -50,
            child: Container(
              width: sw * 0.55,
              height: sw * 0.55,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryColor.withOpacity(0.09),
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
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.only(
                left: hPad,
                right: hPad,
                top: 18,
                bottom: 110,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Page Title ─────────────────────────
                  _PageTitle(isSmall: isSmall),
                  SizedBox(height: sectionGap - 6),

                  // ── Stats ──────────────────────────────
                  _StatsRow(isSmall: isSmall),
                  SizedBox(height: sectionGap),

                  // ── Quick Actions ──────────────────────
                  _SectionTitle(title: "Quick Actions", isSmall: isSmall),
                  SizedBox(height: isSmall ? 10 : 14),
                  _QuickActionsGrid(isSmall: isSmall),
                  SizedBox(height: sectionGap),

                  // ── Reports ────────────────────────────
                  _SectionTitle(title: "Reports", isSmall: isSmall),
                  SizedBox(height: isSmall ? 10 : 14),
                  _ReportsGrid(isSmall: isSmall),
                  SizedBox(height: sectionGap),

                  // ── Recent Activity ────────────────────
                  _SectionTitle(title: "Recent Activity", isSmall: isSmall),
                  SizedBox(height: isSmall ? 10 : 14),
                  _RecentActivity(isSmall: isSmall),
                ],
              ),
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
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
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
// STATS ROW — uses IntrinsicHeight + Flexible to avoid overflow
// ─────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final bool isSmall;
  const _StatsRow({required this.isSmall});

  @override
  Widget build(BuildContext context) {
    final stats = [
      _StatData("Bookings",    "25K",    Icons.confirmation_number_outlined, const Color(0xFF00BFA5), const Color(0xFFE0F7F4)),
      _StatData("Revenue",     "₹12K",   Icons.currency_rupee_rounded,       const Color(0xFFFF6D00), const Color(0xFFFFF3E0)),
      _StatData("Expenditure", "₹45K",   Icons.trending_down_rounded,        TravelAdminDashboard.primaryColor, const Color(0xFFE8EAFF)),
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: stats.asMap().entries.map((entry) {
        final i = entry.key;
        final s = entry.value;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              left: i == 0 ? 0 : (isSmall ? 6 : 12),
            ),
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
          Text(
            data.value,
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
      _ActionData("New Booking",  Icons.add_card_rounded,       const Color(0xFF00BFA5), const Color(0xFFE0F7F4)),
      _ActionData("New Vehicle",  Icons.directions_car_rounded,  const Color(0xFFFF6D00), const Color(0xFFFFF3E0)),
      _ActionData("New Driver",   Icons.person_pin_rounded,      TravelAdminDashboard.primaryColor, const Color(0xFFE8EAFF)),
      _ActionData("New Customer", Icons.people_alt_rounded,      const Color(0xFFAB47BC), const Color(0xFFF3E5F5)),
    ];

    // Build 2×2 manually to avoid GridView childAspectRatio overflow
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
        Navigator.push(context, MaterialPageRoute(builder: (_) => TripBookingForm()));
        break;
      case 'New Vehicle':
        Navigator.push(context, MaterialPageRoute(builder: (_) => AddVehiclePage()));
        break;
      case 'New Driver':
        Navigator.push(context, MaterialPageRoute(builder: (_) => AddDriverPage()));
        break;
      case 'New Customer':
        Navigator.push(context, MaterialPageRoute(builder: (_) => AddCustomerPage()));
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
// REPORTS GRID
// ─────────────────────────────────────────────────────────
class _ReportsGrid extends StatelessWidget {
  final bool isSmall;
  const _ReportsGrid({required this.isSmall});

  @override
  Widget build(BuildContext context) {
    final reports = [
      _ReportData("Booking\nReport",  "Trip bookings summary",     Icons.confirmation_number_rounded, const Color(0xFF00BFA5), const Color(0xFFE0F7F4), [const Color(0xFF00BFA5), const Color(0xFF00E5CC)]),
      _ReportData("Revenue\nReport",  "Income & payments",          Icons.currency_rupee_rounded,       const Color(0xFFFF6D00), const Color(0xFFFFF3E0), [const Color(0xFFFF6D00), const Color(0xFFFFAB40)]),
      _ReportData("Vehicle\nReport",  "Fleet usage & status",       Icons.directions_car_rounded,        TravelAdminDashboard.primaryColor, const Color(0xFFE8EAFF), [TravelAdminDashboard.primaryColor, const Color(0xFF7986CB)]),
      _ReportData("Driver\nReport",   "Driver activity & trips",    Icons.person_pin_rounded,            const Color(0xFFAB47BC), const Color(0xFFF3E5F5), [const Color(0xFFAB47BC), const Color(0xFFCE93D8)]),
    ];

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _ReportCard(data: reports[0], isSmall: isSmall)),
            SizedBox(width: isSmall ? 8 : 14),
            Expanded(child: _ReportCard(data: reports[1], isSmall: isSmall)),
          ],
        ),
        SizedBox(height: isSmall ? 8 : 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _ReportCard(data: reports[2], isSmall: isSmall)),
            SizedBox(width: isSmall ? 8 : 14),
            Expanded(child: _ReportCard(data: reports[3], isSmall: isSmall)),
          ],
        ),
      ],
    );
  }
}

class _ReportCard extends StatelessWidget {
  final _ReportData data;
  final bool isSmall;
  const _ReportCard({required this.data, required this.isSmall});

  @override
  Widget build(BuildContext context) {
    final iconSize = isSmall ? 38.0 : 46.0;
    final iconInner = isSmall ? 17.0 : 22.0;
    final pad = isSmall ? 12.0 : 16.0;

    return InkWell(
      onTap: () {
        // TODO: Navigate to respective report page
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                "${data.title.replaceAll('\n', ' ')} opening..."),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      },
      borderRadius: BorderRadius.circular(isSmall ? 14 : 20),
      child: Container(
        padding: EdgeInsets.all(pad),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(isSmall ? 14 : 20),
          boxShadow: [
            BoxShadow(
              color: data.color.withOpacity(0.13),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Gradient icon
            Container(
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: data.gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(isSmall ? 11 : 14),
                boxShadow: [
                  BoxShadow(
                    color: data.color.withOpacity(0.32),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(data.icon, color: Colors.white, size: iconInner),
            ),

            SizedBox(height: isSmall ? 10 : 14),

            // Title
            Text(
              data.title,
              style: TextStyle(
                fontSize: isSmall ? 12 : 14,
                fontWeight: FontWeight.w800,
                color: TravelAdminDashboard.darkBlue,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            SizedBox(height: isSmall ? 4 : 6),

            // Subtitle + arrow
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    data.subtitle,
                    style: TextStyle(
                      fontSize: isSmall ? 9 : 11,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  width: isSmall ? 20 : 24,
                  height: isSmall ? 20 : 24,
                  decoration: BoxDecoration(
                    color: data.bgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: isSmall ? 11 : 13,
                    color: data.color,
                  ),
                ),
              ],
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
      _ActivityData(Icons.check_circle_rounded, const Color(0xFF00BFA5), const Color(0xFFE0F7F4), "Invoice #1021 Paid",   "2 hours ago"),
      _ActivityData(Icons.shopping_bag_rounded,  TravelAdminDashboard.primaryColor, const Color(0xFFE8EAFF), "New Order Received",    "Today, 10:30 AM"),
      _ActivityData(Icons.directions_car_rounded, const Color(0xFFFF6D00), const Color(0xFFFFF3E0), "Vehicle Added",        "Yesterday"),
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
  const _StatData(this.title, this.value, this.icon, this.color, this.bgColor);
}

class _ActionData {
  final String title;
  final IconData icon;
  final Color color, bgColor;
  const _ActionData(this.title, this.icon, this.color, this.bgColor);
}

class _ReportData {
  final String title, subtitle;
  final IconData icon;
  final Color color, bgColor;
  final List<Color> gradientColors;
  const _ReportData(this.title, this.subtitle, this.icon, this.color,
      this.bgColor, this.gradientColors);
}

class _ActivityData {
  final IconData icon;
  final Color iconColor, iconBg;
  final String title, subtitle;
  const _ActivityData(
      this.icon, this.iconColor, this.iconBg, this.title, this.subtitle);
}