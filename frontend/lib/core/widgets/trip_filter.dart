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

/// Payment status filter applied on top of the trip-status list, mirroring
/// TripPage. Matches on the trip's lowercase `payment_status` string; "All"
/// matches everything.
enum TripPaymentFilter {
  all('All', Icons.account_balance_wallet_rounded, null),
  paid('Paid', Icons.check_circle_rounded, 'paid'),
  unpaid('Unpaid', Icons.error_outline_rounded, 'unpaid'),
  partiallyPaid('Partially Paid', Icons.timelapse_rounded, 'partially paid');

  const TripPaymentFilter(this.label, this.icon, this.statusKey);

  final String label;
  final IconData icon;

  /// The lowercase `payment_status` value this filter matches, or null for
  /// "All" (matches everything).
  final String? statusKey;

  bool matches(String? paymentStatus) {
    final key = statusKey;
    if (key == null) return true;
    return (paymentStatus?.toLowerCase() ?? '') == key;
  }
}

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
      color: Colors.white,
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
        textCapitalization: TextCapitalization.words,
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

/// Always-visible search bar with focus styling, ported from [TripPage]'s
/// header search field so the customer / driver / vehicle screens present the
/// exact same search affordance. The parent owns the [controller] and is
/// notified of changes via [onChanged].
class TripSearchBar extends StatefulWidget {
  const TripSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    this.hint = 'Search trips...',
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hint;

  @override
  State<TripSearchBar> createState() => _TripSearchBarState();
}

class _TripSearchBarState extends State<TripSearchBar> {
  final FocusNode _focus = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!mounted) return;
      setState(() => _focused = _focus.hasFocus);
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      height: 44,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _focused ? AppColors.brandPrimary : Colors.grey.shade300,
          width: _focused ? 1.5 : 1,
        ),
        boxShadow: _focused
            ? [
                BoxShadow(
                  color: AppColors.brandPrimary.withValues(alpha: 0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ]
            : [],
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _focus,
        onChanged: widget.onChanged,
        textCapitalization: TextCapitalization.words,
        textAlignVertical: TextAlignVertical.center,
        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          isDense: true,
          hintText: widget.hint,
          hintStyle: TextStyle(
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w400,
            fontSize: 13.5,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: _focused ? AppColors.brandPrimary : Colors.grey.shade600,
            size: 20,
          ),
          // Listen to the controller directly so toggling the clear button
          // doesn't rebuild the whole page on every keystroke.
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: widget.controller,
            builder: (_, value, __) {
              if (value.text.isEmpty) return const SizedBox.shrink();
              return GestureDetector(
                onTap: () {
                  widget.controller.clear();
                  widget.onChanged('');
                },
                child: Container(
                  margin: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    color: Colors.grey.shade700,
                    size: 14,
                  ),
                ),
              );
            },
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        ),
      ),
    );
  }
}

/// Single filter entry point, ported from [TripPage]: a 44×44 icon button that
/// turns brand-coloured and shows a count badge when any non-default filter is
/// active, and opens the full filter sheet on tap.
class TripFilterButton extends StatelessWidget {
  const TripFilterButton({
    super.key,
    required this.activeCount,
    required this.onTap,
  });

  final int activeCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasActive = activeCount > 0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: hasActive ? AppColors.brandPrimary : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      hasActive ? AppColors.brandPrimary : Colors.grey.shade300,
                ),
              ),
              child: Icon(
                Icons.filter_alt_rounded,
                size: 22,
                color: hasActive ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ),
        ),
        if (hasActive)
          Positioned(
            right: -4,
            top: -4,
            child: Container(
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              decoration: BoxDecoration(
                color: Colors.red.shade500,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              alignment: Alignment.center,
              child: Text(
                '$activeCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// One selectable status option for [showTripFilterSheet]. Screens map their
/// own status enum's values to this so the sheet stays decoupled from each
/// screen's status codes.
class TripStatusOption {
  const TripStatusOption(this.label, this.icon);
  final String label;
  final IconData icon;
}

/// The selections committed when the user taps "Apply Filters" in
/// [showTripFilterSheet]. [statusIndex] indexes into the `statuses` list that
/// was passed in.
class TripFilterResult {
  const TripFilterResult({
    required this.statusIndex,
    required this.payment,
    required this.range,
    required this.customRange,
  });

  final int statusIndex;
  final TripPaymentFilter payment;
  final TripDateRange range;
  final DateTimeRange? customRange;
}

/// Opens the shared trip filter bottom sheet — Trip Status / Payment Status /
/// Date Range — exactly as [TripPage]. Selections are staged locally and only
/// returned when "Apply Filters" is tapped (returns null if dismissed).
///
/// The payment section is only shown when [completedIndex] is non-null and the
/// currently-staged status equals it, matching TripPage where payment status is
/// only meaningful for completed trips.
Future<TripFilterResult?> showTripFilterSheet({
  required BuildContext context,
  required List<TripStatusOption> statuses,
  required int statusIndex,
  required TripPaymentFilter payment,
  required TripDateRange range,
  required DateTimeRange? customRange,
  int? completedIndex,
}) {
  int tempStatus = statusIndex;
  TripPaymentFilter tempPayment = payment;
  TripDateRange tempRange = range;
  DateTimeRange? tempCustom = customRange;

  Future<DateTimeRange?> pickRange(BuildContext ctx, DateTimeRange? initial) {
    final now = DateTime.now();
    final start = initial ??
        DateTimeRange(start: now.subtract(const Duration(days: 6)), end: now);
    return showDateRangePicker(
      context: ctx,
      initialDateRange: start,
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
  }

  return showModalBottomSheet<TripFilterResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final maxHeight = MediaQuery.of(ctx).size.height * 0.85;
      return StatefulBuilder(
        builder: (ctx, setSheetState) {
          Widget choiceChip({
            required String label,
            required IconData icon,
            required bool selected,
            required VoidCallback onTap,
          }) {
            return GestureDetector(
              onTap: onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color:
                      selected ? AppColors.brandPrimary : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected
                        ? AppColors.brandPrimary
                        : Colors.grey.shade300,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 15,
                      color: selected ? Colors.white : Colors.grey.shade700,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                        color: selected ? Colors.white : Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          Widget section({
            required IconData icon,
            required String title,
            required List<Widget> chips,
          }) {
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, size: 15, color: AppColors.brandPrimary),
                      const SizedBox(width: 6),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Colors.grey.shade600,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(spacing: 8, runSpacing: 8, children: chips),
                ],
              ),
            );
          }

          final showPayment =
              completedIndex != null && tempStatus == completedIndex;

          return Container(
            constraints: BoxConstraints(maxHeight: maxHeight),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 8,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 14,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.tune_rounded,
                        size: 18, color: AppColors.brandPrimary),
                    const SizedBox(width: 8),
                    const Text(
                      'Filters',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: const Size(0, 32),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () => setSheetState(() {
                        tempStatus = 0;
                        tempPayment = TripPaymentFilter.all;
                        tempRange = TripDateRange.all;
                        tempCustom = null;
                      }),
                      child: Text(
                        'Reset',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      children: [
                        // ── Trip status ───────────────────────────────
                        section(
                          icon: Icons.local_taxi_rounded,
                          title: 'TRIP STATUS',
                          chips: [
                            for (var i = 0; i < statuses.length; i++)
                              choiceChip(
                                label: statuses[i].label,
                                icon: statuses[i].icon,
                                selected: tempStatus == i,
                                onTap: () => setSheetState(() {
                                  tempStatus = i;
                                  // Payment status only applies to completed
                                  // trips, so drop it when switching away.
                                  if (i != completedIndex) {
                                    tempPayment = TripPaymentFilter.all;
                                  }
                                }),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // ── Payment status ────────────────────────────
                        if (showPayment) ...[
                          section(
                            icon: Icons.payments_rounded,
                            title: 'PAYMENT STATUS',
                            chips: [
                              for (final p in TripPaymentFilter.values)
                                choiceChip(
                                  label: p.label,
                                  icon: p.icon,
                                  selected: tempPayment == p,
                                  onTap: () =>
                                      setSheetState(() => tempPayment = p),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],

                        // ── Date range ────────────────────────────────
                        section(
                          icon: Icons.calendar_today_rounded,
                          title: 'DATE RANGE',
                          chips: [
                            for (final r in TripDateRange.values)
                              choiceChip(
                                label: (r == TripDateRange.custom &&
                                        tempCustom != null)
                                    ? '${_shortDate(tempCustom!.start)} – ${_shortDate(tempCustom!.end)}'
                                    : r.label,
                                icon: r.icon,
                                selected: tempRange == r,
                                onTap: () async {
                                  if (r == TripDateRange.custom) {
                                    final picked =
                                        await pickRange(ctx, tempCustom);
                                    if (picked != null) {
                                      setSheetState(() {
                                        tempRange = TripDateRange.custom;
                                        tempCustom = picked;
                                      });
                                    }
                                  } else {
                                    setSheetState(() {
                                      tempRange = r;
                                      tempCustom = null;
                                    });
                                  }
                                },
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(
                      ctx,
                      TripFilterResult(
                        statusIndex: tempStatus,
                        payment: tempPayment,
                        range: tempRange,
                        customRange: tempCustom,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Apply Filters',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
