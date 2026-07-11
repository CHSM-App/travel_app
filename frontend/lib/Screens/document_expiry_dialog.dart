import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:vego/Screens/add_vehicle.dart';
import 'package:vego/core/theme/app_colors.dart';
import 'package:vego/domain/models/vehicles.dart';
import 'package:vego/presentation/providers/viewmodel_provider.dart';

/// Non-dismissible reminder shown on app open (and resume) while any vehicle
/// has a PUC/insurance expiry within 7 days or already lapsed. It watches the
/// vehicle list itself, so it auto-shrinks as vehicles are fixed and closes
/// on its own once none remain — there is no manual "dismiss" affordance.
class DocumentExpiryDialog extends ConsumerWidget {
  final String agencyId;

  const DocumentExpiryDialog({super.key, required this.agencyId});

  static Future<void> show(BuildContext context, {required String agencyId}) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: AppColors.brandHeader.withOpacity(0.55),
      builder: (_) => DocumentExpiryDialog(agencyId: agencyId),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehiclesAsync = ref.watch(tripBookingViewModelProvider).fetchVehicleList;
    final vehicles = vehiclesAsync.asData?.value ?? const <Vehicles>[];
    final flagged = vehicles.where((v) => v.isDocumentExpiringSoon()).toList()
      ..sort((a, b) => _worstDaysLeft(a).compareTo(_worstDaysLeft(b)));

    if (flagged.isEmpty) {
      // Every flagged vehicle has been fixed (or the list refreshed clean) —
      // close automatically after this frame instead of mid-build.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Navigator.of(context).canPop()) Navigator.of(context).pop();
      });
      return const SizedBox.shrink();
    }

    final expiredCount = flagged.where((v) => _worstDaysLeft(v) <= 0).length;
    final headline = expiredCount > 0
        ? '$expiredCount of ${flagged.length} vehicle${flagged.length == 1 ? '' : 's'} overdue'
        : '${flagged.length} vehicle${flagged.length == 1 ? '' : 's'} due soon';

    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.brandHeader.withOpacity(0.25),
                  blurRadius: 30,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Header(headline: headline, hasExpired: expiredCount > 0),
                Flexible(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 4),
                    shrinkWrap: true,
                    itemCount: flagged.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) => _VehicleExpiryCard(
                      vehicle: flagged[index],
                      onUpdate: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AddVehiclePage(
                              vehicle: flagged[index],
                              isEdit: true,
                            ),
                          ),
                        );
                        // Refresh so the dialog re-evaluates with the saved date.
                        await ref
                            .read(tripBookingViewModelProvider.notifier)
                            .vehicleList(agencyId);
                      },
                    ),
                  ),
                ),
              
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.schedule_rounded, size: 17),
                      label: const Text('Remind me later'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.brandPrimaryDark,
                        backgroundColor: AppColors.brandSoft,
                        side: BorderSide(color: AppColors.brandPrimaryLight, width: 1.3),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(11),
                        ),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                        ),
                      ),
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

  static int _worstDaysLeft(Vehicles v) {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    int? days(DateTime? d) {
      if (d == null) return null;
      final target = DateTime(d.year, d.month, d.day);
      return target.difference(todayDate).inDays;
    }

    final candidates = [days(v.pucExpiry), days(v.insuranceExpiry)]
        .whereType<int>()
        .toList();
    if (candidates.isEmpty) return 9999;
    candidates.sort();
    return candidates.first;
  }
}

class _Header extends StatelessWidget {
  final String headline;
  final bool hasExpired;

  const _Header({required this.headline, required this.hasExpired});

  @override
  Widget build(BuildContext context) {
    final accent = hasExpired ? AppColors.danger : AppColors.warning;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      decoration: BoxDecoration(
        color: AppColors.brandHeader,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: accent,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Document renewal needed',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  headline,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VehicleExpiryCard extends StatelessWidget {
  final Vehicles vehicle;
  final VoidCallback onUpdate;

  const _VehicleExpiryCard({required this.vehicle, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.brandSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.directions_car_filled_rounded,
                  color: AppColors.brandPrimary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle.name ?? 'Vehicle',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      vehicle.number ?? '-',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ExpiryChip(
                icon: Icons.eco_rounded,
                label: 'PUC',
                date: vehicle.pucExpiry,
              ),
              _ExpiryChip(
                icon: Icons.shield_rounded,
                label: 'Insurance',
                date: vehicle.insuranceExpiry,
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onUpdate,
              icon: const Icon(Icons.edit_calendar_rounded, size: 17),
              label: const Text('Update now'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandPrimary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpiryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final DateTime? date;

  const _ExpiryChip({required this.icon, required this.label, required this.date});

  /// Whole calendar days between today and [d], ignoring time-of-day so a
  /// date that is literally "today" always reads as 0 regardless of what
  /// time the comparison runs.
  static int _calendarDaysLeft(DateTime d) {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final targetDate = DateTime(d.year, d.month, d.day);
    return targetDate.difference(todayDate).inDays;
  }

  @override
  Widget build(BuildContext context) {
    if (date == null) return const SizedBox.shrink();

    final daysLeft = _calendarDaysLeft(date!);
    // "Expiring today" reads as danger, not a soft warning — there's no
    // buffer left to act on it.
    final expired = daysLeft <= 0;
    final color = expired ? AppColors.danger : AppColors.warning;
    final softColor = expired ? AppColors.dangerSoft : AppColors.warningSoft;
    final statusText = daysLeft < 0
        ? '$label expired ${DateFormat('dd MMM').format(date!)}'
        : daysLeft == 0
            ? '$label expires today'
            : '$label · ${DateFormat('dd MMM').format(date!)}'
                '${daysLeft <= 7 ? ' ($daysLeft d)' : ''}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: softColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
