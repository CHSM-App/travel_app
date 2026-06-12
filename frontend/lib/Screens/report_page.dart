import 'package:flutter/material.dart';
import 'package:travel_agency_app/Screens/customer_report.dart';
import 'package:travel_agency_app/Screens/driver_report.dart';
import 'package:travel_agency_app/Screens/transactions_page.dart';
import 'package:travel_agency_app/Screens/vehicle_report.dart';
import 'package:travel_agency_app/core/theme/app_colors.dart';

/// Reports hub. A simple launcher that lists the four report types —
/// Transaction, Vehicle, Customer and Driver — and routes to each on tap.
/// It holds no data of its own; it is purely a redirection screen.
class ReportPage extends StatelessWidget {
  const ReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    final options = <_ReportOption>[
      _ReportOption(
        title: 'Transaction Report',
        subtitle: 'Payments, expenses & daily cash flow',
        icon: Icons.receipt_long_rounded,
        color: AppColors.brandPrimary,
        bg: AppColors.brandSoft,
        builder: (_) => const TransactionsPage(),
      ),
      _ReportOption(
        title: 'Vehicle Report',
        subtitle: 'Per-vehicle revenue & expenses',
        icon: Icons.directions_car_rounded,
        color: AppColors.info,
        bg: AppColors.infoSoft,
        builder: (_) => const VehicleReportPage(),
      ),
      _ReportOption(
        title: 'Customer Report',
        subtitle: 'Customer-wise bookings & dues',
        icon: Icons.people_alt_rounded,
        color: AppColors.success,
        bg: AppColors.successSoft,
        builder: (_) => const CustomerReportPage(),
      ),
      _ReportOption(
        title: 'Driver Report',
        subtitle: 'Per-driver trips & payouts',
        icon: Icons.person_pin_rounded,
        color: AppColors.warning,
        bg: AppColors.warningSoft,
        builder: (_) => const DriverReportPage(),
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppColors.textPrimary,
        centerTitle: false,
        title: const Text(
          'Reports',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          itemCount: options.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) => _ReportCard(option: options[i]),
        ),
      ),
    );
  }
}

class _ReportOption {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color bg;
  final WidgetBuilder builder;

  const _ReportOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.bg,
    required this.builder,
  });
}

class _ReportCard extends StatelessWidget {
  final _ReportOption option;
  const _ReportCard({required this.option});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: option.builder),
        ),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: option.color.withValues(alpha: 0.10),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: option.bg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(option.icon, color: option.color, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        option.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        option.subtitle,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                          height: 1.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: option.bg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: option.color,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
