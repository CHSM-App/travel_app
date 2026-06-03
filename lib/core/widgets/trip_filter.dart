import 'package:flutter/material.dart';
import 'package:travel_agency_app/core/theme/app_colors.dart';
import 'package:travel_agency_app/domain/models/booking_info.dart';

/// Shared trip-list filtering controls, ported from [TripPage] so the
/// customer-history, driver-history and vehicle-revenue screens all expose the
/// same date-range + search behaviour on top of their own status filters.

/// Date-range quick filter. `windowDays = null` means no date filter (all) or a
/// user-supplied custom range; `0` means today only; otherwise it's a trailing
/// window of N days ending today (inclusive).
enum TripDateRange {
  all('All', null, Icons.all_inclusive_rounded),
  today('Today', 0, Icons.today_rounded),
  week('Last 7 Days', 7, Icons.view_week_rounded),
  month('Last 30 Days', 30, Icons.calendar_month_rounded),
  custom('Custom', null, Icons.date_range_rounded);

  const TripDateRange(this.label, this.windowDays, this.icon);

  final String label;
  final int? windowDays;
  final IconData icon;

  bool matches(DateTime? d, DateTime now, {DateTimeRange? customRange}) {
    if (this == TripDateRange.all) return true;
    if (d == null) return false;
    final dayOnly = DateTime(d.year, d.month, d.day);
    if (this == TripDateRange.custom) {
      if (customRange == null) return true;
      final start = DateTime(
          customRange.start.year, customRange.start.month, customRange.start.day);
      final end = DateTime(
          customRange.end.year, customRange.end.month, customRange.end.day);
      return !dayOnly.isBefore(start) && !dayOnly.isAfter(end);
    }
    final today = DateTime(now.year, now.month, now.day);
    if (this == TripDateRange.today) return today == dayOnly;
    final cutoff = today.subtract(Duration(days: windowDays! - 1));
    return !dayOnly.isBefore(cutoff) && !dayOnly.isAfter(today);
  }
}

/// The date a trip is bucketed under (start → booking → end), matching TripPage.
DateTime? tripSortKey(BookingInfo t) =>
    t.startDateTime ?? t.bookingDate ?? t.endDateTime;

/// True when [trip] matches the free-text [query]. [query] must already be
/// trimmed and lower-cased. Empty query matches everything.
bool tripMatchesQuery(BookingInfo trip, String query) {
  if (query.isEmpty) return true;
  return (trip.customer_name?.toLowerCase().contains(query) ?? false) ||
      (trip.vehicle_info?.toLowerCase().contains(query) ?? false) ||
      (trip.driver_name?.toLowerCase().contains(query) ?? false) ||
      (trip.pickupLocation?.toLowerCase().contains(query) ?? false) ||
      (trip.dropLocation?.toLowerCase().contains(query) ?? false) ||
      (trip.payment_status?.toLowerCase().contains(query) ?? false);
}

const _monthAbbr = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _shortDate(DateTime d) {
  final mo = _monthAbbr[d.month - 1];
  final now = DateTime.now();
  if (d.year == now.year) return '${d.day} $mo';
  return '${d.day} $mo ${d.year}';
}

/// Pill-style date-range filter button with a popup menu. Mirrors the date
/// filter in [TripPage]. The parent owns the selected [range] / [customRange]
/// and is notified via [onChanged]; picking "Custom" opens a range picker.
class TripDateFilterButton extends StatelessWidget {
  const TripDateFilterButton({
    super.key,
    required this.range,
    required this.customRange,
    required this.onChanged,
  });

  final TripDateRange range;
  final DateTimeRange? customRange;
  final void Function(TripDateRange range, DateTimeRange? customRange) onChanged;

  Future<void> _handleSelection(BuildContext context, TripDateRange r) async {
    if (r != TripDateRange.custom) {
      onChanged(r, null);
      return;
    }
    final now = DateTime.now();
    final initial = customRange ??
        DateTimeRange(start: now.subtract(const Duration(days: 6)), end: now);
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: initial,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: AppColors.brandPrimary,
                onPrimary: Colors.white,
              ),
        ),
        child: child!,
      ),
    );
    if (picked != null) onChanged(TripDateRange.custom, picked);
  }

  String get _activeLabel {
    if (range == TripDateRange.custom && customRange != null) {
      return '${_shortDate(customRange!.start)} – ${_shortDate(customRange!.end)}';
    }
    return range.label;
  }

  @override
  Widget build(BuildContext context) {
    final isDefault = range == TripDateRange.all ||
        (range == TripDateRange.custom && customRange == null);

    return PopupMenuButton<TripDateRange>(
      tooltip: 'Date filter',
      initialValue: range,
      position: PopupMenuPosition.under,
      offset: const Offset(0, 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (r) => _handleSelection(context, r),
      itemBuilder: (context) => [
        for (final r in TripDateRange.values)
          PopupMenuItem<TripDateRange>(
            value: r,
            child: _DateMenuRow(
              range: r,
              selected: r == range,
              customRange: r == TripDateRange.custom ? customRange : null,
            ),
          ),
      ],
      child: Container(
        constraints: const BoxConstraints(maxWidth: 180),
        height: 40,
        padding: EdgeInsets.symmetric(horizontal: isDefault ? 10 : 12),
        decoration: BoxDecoration(
          color: isDefault
              ? Colors.grey.shade100
              : AppColors.brandPrimary.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDefault ? Colors.grey.shade300 : AppColors.brandPrimary,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.filter_alt_rounded,
              size: 18,
              color: isDefault ? Colors.grey.shade700 : AppColors.brandPrimary,
            ),
            if (!isDefault) ...[
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  _activeLabel,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.brandPrimary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DateMenuRow extends StatelessWidget {
  const _DateMenuRow({
    required this.range,
    required this.selected,
    required this.customRange,
  });

  final TripDateRange range;
  final bool selected;
  final DateTimeRange? customRange;

  @override
  Widget build(BuildContext context) {
    final hasCustomRange = range == TripDateRange.custom && customRange != null;
    final label = hasCustomRange
        ? '${_shortDate(customRange!.start)} – ${_shortDate(customRange!.end)}'
        : range.label;
    final caption = range == TripDateRange.custom
        ? (hasCustomRange ? 'Tap to change' : 'Pick a start and end date')
        : null;
    final color = selected ? AppColors.brandPrimary : Colors.grey.shade800;

    return Row(
      children: [
        Icon(range.icon, size: 18, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                ),
              ),
              if (caption != null)
                Text(
                  caption,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
            ],
          ),
        ),
        if (selected)
          const Icon(Icons.check_rounded,
              size: 18, color: AppColors.brandPrimary),
      ],
    );
  }
}

/// Compact always-visible search field for trip lists. The parent owns the
/// [controller] and is notified of changes via [onChanged].
class TripSearchField extends StatelessWidget {
  const TripSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    this.focusNode,
    this.hint = 'Search trips...',
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final FocusNode? focusNode;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          isDense: true,
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          prefixIcon:
              Icon(Icons.search_rounded, color: Colors.grey.shade600, size: 20),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (_, value, __) {
              if (value.text.isEmpty) return const SizedBox.shrink();
              return IconButton(
                icon: Icon(Icons.clear_rounded,
                    color: Colors.grey.shade600, size: 18),
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
              );
            },
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
    );
  }
}
