import 'dart:async';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vego/Screens/add_tripbooking.dart';
import 'package:vego/Screens/trip_card.dart';
import 'package:vego/core/network/error_messages.dart';
import 'package:vego/core/theme/app_colors.dart';
import 'package:vego/core/theme/app_scroll_behavior.dart';
import 'package:vego/core/widgets/paginated_list_view.dart';
import 'package:vego/core/widgets/skeleton.dart';
import 'package:vego/core/network/network_state_notifier.dart';
import 'package:vego/domain/models/booking_info.dart';
import 'package:vego/domain/viewModel/trippage_viewmodel.dart';
import 'package:vego/presentation/providers/viewmodel_provider.dart';

/// Trip status filter. `key` is the wire value used by the cross-screen
/// [tripPageInitialFilterProvider] deep-link signal. Payment is a separate,
/// orthogonal axis — see [PaymentFilter].
enum TripFilter {
  all('all', 'All', Icons.list_alt_rounded,
      'No Trips', 'No trips have been booked yet'),
  active('active', 'Active', Icons.directions_car_rounded,
      'No Active Trips', "You don't have any active trips right now"),
  upcoming('upcoming', 'Upcoming', Icons.schedule_rounded,
      'No Upcoming Trips', 'No trips scheduled for the future'),
  completed('completed', 'Completed', Icons.task_alt_rounded,
      'No Completed Trips', 'Completed trips will appear here'),
  cancelled('cancelled', 'Cancelled', Icons.cancel_rounded,
      'No Cancelled Trips', "You haven't cancelled any trips");

  const TripFilter(
    this.key,
    this.label,
    this.icon,
    this.emptyTitle,
    this.emptySubtitle,
  );

  final String key;
  final String label;
  final IconData icon;
  final String emptyTitle;
  final String emptySubtitle;

  static TripFilter? fromKey(String? key) {
    if (key == null) return null;
    for (final f in values) {
      if (f.key == key) return f;
    }
    return null;
  }

  // The list to render for this filter. "Completed" merges the paid (history)
  // and unpaid buckets so it shows every finished trip regardless of payment;
  // the [PaymentFilter] then narrows it to paid / unpaid / partially paid.
  AsyncValue<List<BookingInfo>> listFrom(TripPageState state) {
    switch (this) {
      case TripFilter.all:
        return state.allList;
      case TripFilter.active:
        return state.activeList;
      case TripFilter.upcoming:
        return state.upcomingList;
      case TripFilter.completed:
        return _mergeCompleted(state.historyList, state.unpaidList);
      case TripFilter.cancelled:
        return state.cancelledList;
    }
  }
}

/// Merges the paid (history) and unpaid buckets into the single "Completed"
/// list. Shows data as soon as either bucket has loaded, de-dupes by trip id,
/// and only surfaces loading/error while nothing usable is available yet.
AsyncValue<List<BookingInfo>> _mergeCompleted(
  AsyncValue<List<BookingInfo>> history,
  AsyncValue<List<BookingInfo>> unpaid,
) {
  if (history.hasValue || unpaid.hasValue) {
    final byId = <int, BookingInfo>{};
    final noId = <BookingInfo>[];
    for (final list in [
      history.asData?.value ?? const <BookingInfo>[],
      unpaid.asData?.value ?? const <BookingInfo>[],
    ]) {
      for (final trip in list) {
        final id = trip.tripId;
        if (id == null) {
          noId.add(trip);
        } else {
          byId.putIfAbsent(id, () => trip);
        }
      }
    }
    return AsyncValue.data([...byId.values, ...noId]);
  }
  if (history.hasError) return history;
  if (unpaid.hasError) return unpaid;
  return const AsyncValue.loading();
}

/// Payment status filter applied on top of the trip-status list. Matches on the
/// trip's lowercase `payment_status` string; "All" matches everything.
enum PaymentFilter {
  all('All', Icons.account_balance_wallet_rounded, null),
  paid('Paid', Icons.check_circle_rounded, 'paid'),
  unpaid('Unpaid', Icons.error_outline_rounded, 'unpaid'),
  partiallyPaid('Partially Paid', Icons.timelapse_rounded, 'partially paid');

  const PaymentFilter(this.label, this.icon, this.statusKey);

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

/// Date-range quick filters applied on top of the status filter.
/// `windowDays = null` means either no date filter (all) or a user-supplied
/// custom range; `0` means today only; otherwise it's a trailing window of N
/// days ending today (inclusive).
enum DateRange {
  all('All', null, Icons.all_inclusive_rounded),
  today('Today', 0, Icons.today_rounded),
  week('Last 7 Days', 7, Icons.view_week_rounded),
  month('Last 30 Days', 30, Icons.calendar_month_rounded),
  custom('Custom', null, Icons.date_range_rounded);

  const DateRange(this.label, this.windowDays, this.icon);

  final String label;
  final int? windowDays;
  final IconData icon;

  bool matches(DateTime? d, DateTime now, {DateTimeRange? customRange}) {
    if (this == DateRange.all) return true;
    if (d == null) return false;
    final dayOnly = DateTime(d.year, d.month, d.day);
    if (this == DateRange.custom) {
      if (customRange == null) return true;
      final start = DateTime(customRange.start.year, customRange.start.month,
          customRange.start.day);
      final end = DateTime(
          customRange.end.year, customRange.end.month, customRange.end.day);
      return !dayOnly.isBefore(start) && !dayOnly.isAfter(end);
    }
    final today = DateTime(now.year, now.month, now.day);
    if (this == DateRange.today) return today == dayOnly;
    final cutoff = today.subtract(Duration(days: windowDays! - 1));
    return !dayOnly.isBefore(cutoff) && !dayOnly.isAfter(today);
  }
}

class TripPage extends ConsumerStatefulWidget {
  const TripPage({super.key});

  @override
  ConsumerState<TripPage> createState() => _TripPageState();
}

class _TripPageState extends ConsumerState<TripPage> {
  static const Duration _searchDebounce = Duration(milliseconds: 250);

  // Trip status and payment status are independent axes that combine freely.
  // Both default to "All" so the page opens showing every trip, and selecting
  // any one filter (status, payment, or date) — or any combination — narrows
  // the same underlying list.
  TripFilter _selectedFilter = TripFilter.all;
  PaymentFilter _selectedPayment = PaymentFilter.all;
  DateRange _selectedRange = DateRange.all;
  DateTimeRange? _customRange;
  String _searchQuery = '';
  bool _searchFocused = false;

  // True while the current filter selection was set by a dashboard "Action
  // Needed" deep link and hasn't been touched manually since. Lets us reset
  // the filters back to defaults the moment the user backs out to the
  // dashboard from that specific visit, without disturbing filters the user
  // picked themselves.
  bool _filterFromDeepLink = false;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();

    _searchFocus.addListener(() {
      if (!mounted) return;
      setState(() => _searchFocused = _searchFocus.hasFocus);
    });

    // If someone (e.g. the dashboard's Action Needed card) requested a specific
    // filter before this page was mounted, honour it. ref.listen below catches
    // requests that arrive after mount; this branch is needed because listen
    // doesn't fire on the value already present at subscription time.
    final resolved = _resolveDeepLink(ref.read(tripPageInitialFilterProvider));
    if (resolved != null) {
      _selectedFilter = resolved.status;
      _selectedPayment = resolved.payment;
      // A companion date signal pins the list to everything on/after that day
      // (e.g. tomorrow-and-onwards pickups from the dashboard's "Upcoming
      // Trips" row).
      final initialDate = ref.read(tripPageInitialDateProvider);
      if (initialDate != null) {
        _selectedRange = DateRange.custom;
        _customRange = _fromDayRange(initialDate);
      }
      _filterFromDeepLink = true;
      ref.read(tripPageInitialFilterProvider.notifier).state = null;
      ref.read(tripPageInitialDateProvider.notifier).state = null;
    }

    Future.microtask(() => _loadListForFilter(_selectedFilter));
  }

  /// Translates a [tripPageInitialFilterProvider] key into a (status, payment)
  /// pair. The payment-based `'paid'`/`'unpaid'` deep-links land on Trip Status
  /// "All" with the matching Payment Status filter applied, so they show every
  /// matching trip regardless of status; every other key resolves to a trip
  /// status with the payment filter left at "All".
  ({TripFilter status, PaymentFilter payment})? _resolveDeepLink(String? key) {
    if (key == null) return null;
    if (key == 'paid') {
      return (status: TripFilter.all, payment: PaymentFilter.paid);
    }
    if (key == 'unpaid') {
      return (status: TripFilter.all, payment: PaymentFilter.unpaid);
    }
    final status = TripFilter.fromKey(key);
    if (status == null) return null;
    return (status: status, payment: PaymentFilter.all);
  }

  /// An open-ended [DateTimeRange] starting at [day] and running far into the
  /// future, used to pin the date filter to "this day and everything after it"
  /// (e.g. the dashboard's "Upcoming Trips" row → tomorrow and onwards).
  DateTimeRange _fromDayRange(DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    return DateTimeRange(start: start, end: DateTime(start.year + 5, 12, 31));
  }

  /// Applies a deep-link's companion date signal: pin to [day]-and-onwards when
  /// [day] is set, otherwise reset the range back to "All". Always wrapped in
  /// setState since it runs after the page is mounted.
  void _applyDeepLinkDate(DateTime? day) {
    setState(() {
      if (day == null) {
        _selectedRange = DateRange.all;
        _customRange = null;
      } else {
        _selectedRange = DateRange.custom;
        _customRange = _fromDayRange(day);
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _loadListForFilter(TripFilter filter) async {
    final agencyId = ref.read(loginViewModelProvider).agencyId ?? '';
    if (agencyId.isEmpty) return;
    final notifier = ref.read(tripPageViewModelProvider.notifier);
    switch (filter) {
      case TripFilter.all:
        await notifier.allTrips(agencyId);
        break;
      case TripFilter.active:
        await notifier.activeList(agencyId);
        break;
      case TripFilter.upcoming:
        await notifier.upcomingList(agencyId);
        break;
      case TripFilter.completed:
        // Completed merges the paid (history) and unpaid buckets, so fetch
        // both. They resolve independently and the merge surfaces whatever is
        // ready first.
        await Future.wait([
          notifier.historyList(agencyId),
          notifier.unpaidList(agencyId),
        ]);
        break;
      case TripFilter.cancelled:
        await notifier.cancelledList(agencyId);
        break;
    }
  }

  void _applyFilter(TripFilter filter, PaymentFilter payment) {
    final filterChanged = filter != _selectedFilter;
    if (!filterChanged && payment == _selectedPayment) return;
    setState(() {
      _selectedFilter = filter;
      _selectedPayment = payment;
    });
    if (filterChanged) _loadListForFilter(filter);
  }

  /// Resets every filter axis back to "All", used when backing out to the
  /// dashboard from a deep-linked visit so the next manual visit to Trips
  /// starts clean.
  void _resetFilters() {
    setState(() {
      _selectedFilter = TripFilter.all;
      _selectedPayment = PaymentFilter.all;
      _selectedRange = DateRange.all;
      _customRange = null;
    });
    _loadListForFilter(TripFilter.all);
  }

  /// Commits the filter selections made in the bottom sheet back to the page,
  /// reloading the list only when the status filter actually changed (the
  /// payment and date filters are applied client-side, so they don't re-fetch).
  void _applyFromSheet(
    TripFilter filter,
    PaymentFilter payment,
    DateRange range,
    DateTimeRange? customRange,
  ) {
    final filterChanged = filter != _selectedFilter;
    setState(() {
      _selectedFilter = filter;
      _selectedPayment = payment;
      _selectedRange = range;
      _customRange = customRange;
      _filterFromDeepLink = false;
    });
    if (filterChanged) _loadListForFilter(filter);
  }

  /// Opens the material date-range picker and returns the chosen range (or null
  /// if cancelled). Used by the "Custom" chip inside the filter sheet.
  Future<DateTimeRange?> _showRangePicker(
    BuildContext ctx,
    DateTimeRange? initialRange,
  ) {
    final now = DateTime.now();
    final initial = initialRange ??
        DateTimeRange(
          start: now.subtract(const Duration(days: 6)),
          end: now,
        );
    return showDateRangePicker(
      context: ctx,
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
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_searchDebounce, () {
      if (!mounted) return;
      final normalized = value.trim().toLowerCase();
      if (normalized == _searchQuery) return;
      setState(() => _searchQuery = normalized);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tripPageViewModelProvider);

    // Deep-link from elsewhere (e.g. the dashboard's Action Needed rows).
    // IndexedStack keeps TripPage mounted across tab switches, so initState
    // can't catch a filter request that arrives after first build — we listen
    // here as well. The provider is cleared after consumption so a later
    // manual visit defaults back to whatever the user last picked.
    ref.listen<String?>(tripPageInitialFilterProvider, (prev, next) {
      final resolved = _resolveDeepLink(next);
      if (resolved == null) return;
      _applyFilter(resolved.status, resolved.payment);
      // Apply (or clear) the companion date filter so the deep-linked list lands
      // in a predictable state — pinned to a single day, or back to "All".
      _applyDeepLinkDate(ref.read(tripPageInitialDateProvider));
      _filterFromDeepLink = true;
      ref.read(tripPageInitialFilterProvider.notifier).state = null;
      ref.read(tripPageInitialDateProvider.notifier).state = null;
    });

    // Backing out to the dashboard (tab switches to Home) right after a
    // deep-linked visit should leave Trips clean for next time — but only
    // that one visit; once the user touches a filter manually the flag is
    // cleared and this listener leaves their selection alone.
    ref.listen<int>(bottomNavIndexProvider, (prev, next) {
      if (next == 0 && prev != 0 && _filterFromDeepLink) {
        _filterFromDeepLink = false;
        _resetFilters();
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      // Let the list flow under the floating pill nav. SafeArea handles the
      // status bar; bottom is intentionally disabled so the ListView reaches
      // the actual screen edge and items pass behind the transparent nav.
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _buildTripList(_selectedFilter.listFrom(state)),
                ),
              ],
            ),

            // Add-trip FAB, positioned above the floating pill nav to match the
            // Customers / Fleet tabs' add buttons.
            Positioned(
              right: 20,
              bottom: 90,
              child: FloatingActionButton(
                heroTag: 'tripAddFab',
                onPressed: _openAddTrip,
                backgroundColor: AppColors.brandPrimary,
                shape: const CircleBorder(),
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Opens the booking form to create a new trip, then refreshes the currently
  /// selected list so the new booking shows up without a manual pull-to-refresh.
  Future<void> _openAddTrip() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TripBookingForm()),
    );
    if (!mounted) return;
    _loadListForFilter(_selectedFilter);
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Column(
        children: [
          // Always-visible search bar with a single filter entry point.
          Row(
            children: [
              Expanded(child: _buildSearchField()),
              const SizedBox(width: 8),
              _buildFilterButton(),
            ],
          ),
        ],
      ),
    );
  }

  /// Single filter entry point. Shows the brand colour + a count badge when any
  /// non-default filter is active, and opens the full filter sheet on tap.
  Widget _buildFilterButton() {
    final activeCount = (_selectedFilter != TripFilter.all ? 1 : 0) +
        (_selectedPayment != PaymentFilter.all ? 1 : 0) +
        (_selectedRange != DateRange.all ? 1 : 0);
    final hasActive = activeCount > 0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: hasActive ? AppColors.brandPrimary : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: _openFilterSheet,
            child: Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: hasActive
                      ? AppColors.brandPrimary
                      : Colors.grey.shade300,
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

  /// Bottom sheet holding every filter — trip status, payment status and date
  /// range — stacked into clearly-labelled sections. Selections are staged
  /// locally and only committed when "Apply Filters" is tapped.
  void _openFilterSheet() {
    TripFilter tempFilter = _selectedFilter;
    PaymentFilter tempPayment = _selectedPayment;
    DateRange tempRange = _selectedRange;
    DateTimeRange? tempCustom = _customRange;

    showModalBottomSheet(
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
                    color: selected
                        ? AppColors.brandPrimary
                        : Colors.grey.shade100,
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
                          color:
                              selected ? Colors.white : Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            // One labelled group: a small header followed by its wrap of chips,
            // wrapped in a soft surface so the three sections read as distinct
            // cards rather than one long list.
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
                          tempFilter = TripFilter.all;
                          tempPayment = PaymentFilter.all;
                          tempRange = DateRange.all;
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

                  // Scrollable so the three sections never overflow on small
                  // screens or with the keyboard up.
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
                              for (final f in TripFilter.values)
                                choiceChip(
                                  label: f.label,
                                  icon: f.icon,
                                  selected: tempFilter == f,
                                  onTap: () => setSheetState(() {
                                    tempFilter = f;
                                    // Payment status only applies to completed
                                    // trips, so drop it when switching away.
                                    if (f != TripFilter.completed) {
                                      tempPayment = PaymentFilter.all;
                                    }
                                  }),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // ── Payment status ────────────────────────────
                          // Only meaningful for completed trips, so shown
                          // exclusively when the Completed status is selected.
                          if (tempFilter == TripFilter.completed) ...[
                            section(
                              icon: Icons.payments_rounded,
                              title: 'PAYMENT STATUS',
                              chips: [
                                for (final p in PaymentFilter.values)
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
                              for (final r in DateRange.values)
                                choiceChip(
                                  label: (r == DateRange.custom &&
                                          tempCustom != null)
                                      ? '${_shortDate(tempCustom!.start)} – ${_shortDate(tempCustom!.end)}'
                                      : r.label,
                                  icon: r.icon,
                                  selected: tempRange == r,
                                  onTap: () async {
                                    if (r == DateRange.custom) {
                                      final picked = await _showRangePicker(
                                          ctx, tempCustom);
                                      if (picked != null) {
                                        setSheetState(() {
                                          tempRange = DateRange.custom;
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
                      onPressed: () {
                        Navigator.pop(ctx);
                        _applyFromSheet(
                            tempFilter, tempPayment, tempRange, tempCustom);
                      },
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

  Widget _buildSearchField() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      height: 44,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _searchFocused
              ? AppColors.brandPrimary
              : Colors.grey.shade300,
          width: _searchFocused ? 1.5 : 1,
        ),
        boxShadow: _searchFocused
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
        controller: _searchController,
        focusNode: _searchFocus,
        textCapitalization: TextCapitalization.words,
        onChanged: _onSearchChanged,
        textAlignVertical: TextAlignVertical.center,
        style: const TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          isDense: true,
          hintText: 'Search trips...',
          hintStyle: TextStyle(
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w400,
            fontSize: 13.5,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: _searchFocused
                ? AppColors.brandPrimary
                : Colors.grey.shade600,
            size: 20,
          ),
          // Listen to the controller directly so toggling the clear button
          // doesn't rebuild the whole page on every keystroke.
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: _searchController,
            builder: (_, value, __) {
              if (value.text.isEmpty) return const SizedBox.shrink();
              return GestureDetector(
                onTap: () {
                  _searchController.clear();
                  _onSearchChanged('');
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
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 0,
          ),
        ),
      ),
    );
  }

  Widget _buildTripList(AsyncValue<List<BookingInfo>> state) {
    final filter = _selectedFilter;
    return state.when(
      loading: () => RefreshIndicator(
        onRefresh: () => _loadListForFilter(filter),
        color: AppColors.brandPrimary,
        child: ListView(
          physics: kBouncyAlwaysScrollable,
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 110),
          children: const [
            TripCardSkeleton(),
            TripCardSkeleton(),
            TripCardSkeleton(),
            TripCardSkeleton(),
            TripCardSkeleton(),
          ],
        ),
      ),
      error: (e, _) {
        final isOffline = !ref.watch(networkStateProvider).isConnected;
        final isNetworkError = e is DioException &&
            (e.type == DioExceptionType.connectionError ||
                e.type == DioExceptionType.connectionTimeout ||
                e.type == DioExceptionType.sendTimeout ||
                e.type == DioExceptionType.receiveTimeout);

        if (isOffline || isNetworkError) {
          return _buildMessageState(
            filter: filter,
            icon: Icons.wifi_off_rounded,
            iconColor: AppColors.brandPrimary,
            title: 'You appear to be offline',
            subtitle:
                'Check your connection and pull to refresh, or tap retry.',
          );
        }

        return _buildMessageState(
          filter: filter,
          icon: Icons.error_outline_rounded,
          iconColor: AppColors.brandPrimary,
          title: 'Error loading trips',
          subtitle: friendlyErrorMessage(e),
        );
      },
      data: (trips) {
        final filtered = _filterAndSearch(trips);
        if (filtered.isEmpty) return _buildEmptyState(filter);

        final items = _groupByDay(filtered);

        return PaginatedListView<_RowItem>(
          items: items,
          // Extra bottom padding so the last card scrolls clear of the
          // floating pill nav (nav height ~64 + margin + safety).
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 110),
          onRefresh: () => _loadListForFilter(filter),
          resetToken:
              '$_searchQuery|${filter.key}|${_selectedPayment.label}|${_selectedRange.label}|${_customRange?.start}|${_customRange?.end}',
          itemLabel: 'trips',
          itemBuilder: (_, item, i) {
            if (item.isHeader) {
              return _buildSectionHeader(
                  item.headerLabel!, item.headerCount!);
            }
            final trip = item.trip!;
            return TripCard(
              key: ValueKey(trip.tripId ?? i),
              bookinginfo: trip,
              status: trip.status ?? 0,
              onTripUpdated: () => _loadListForFilter(filter),
            );
          },
        );
      },
    );
  }

  Widget _buildSectionHeader(String label, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade800,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(width: 8),
          // Trip count for this day group.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.brandPrimary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count ${count == 1 ? 'trip' : 'trips'}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.brandPrimary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 1,
              color: Colors.grey.shade200,
            ),
          ),
        ],
      ),
    );
  }

  List<BookingInfo> _filterAndSearch(List<BookingInfo> trips) {
    final payment = _selectedPayment;
    final query = _searchQuery;
    final hasQuery = query.isNotEmpty;
    final range = _selectedRange;
    final now = DateTime.now();

    return trips.where((trip) {
      if (!payment.matches(trip.payment_status)) return false;
      if (!range.matches(_sortKey(trip), now, customRange: _customRange)) {
        return false;
      }

      if (!hasQuery) return true;
      return (trip.customer_name?.toLowerCase().contains(query) ?? false) ||
          (trip.vehicle_info?.toLowerCase().contains(query) ?? false) ||
          (trip.driver_name?.toLowerCase().contains(query) ?? false) ||
          (trip.pickupLocation?.toLowerCase().contains(query) ?? false) ||
          (trip.dropLocation?.toLowerCase().contains(query) ?? false) ||
          (trip.payment_status?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  /// Sort descending by day, then build a flat list of section headers
  /// interleaved with trip rows. Headers render "Today", "Yesterday", or a
  /// short weekday/date label; trips with no usable date land under "Undated".
  List<_RowItem> _groupByDay(List<BookingInfo> trips) {
    final sorted = [...trips];
    sorted.sort((a, b) {
      final ka = _sortKey(a);
      final kb = _sortKey(b);
      if (ka == null && kb == null) return 0;
      if (ka == null) return 1;
      if (kb == null) return -1;
      return kb.compareTo(ka);
    });

    final now = DateTime.now();

    // Group consecutive trips under their day header first, so each header can
    // carry the number of trips that fall under it (Today, Yesterday, …).
    final groups = <({String header, List<BookingInfo> trips})>[];
    for (final trip in sorted) {
      final key = _sortKey(trip);
      final header = key == null ? 'Undated' : _formatDayHeader(key, now);
      if (groups.isEmpty || groups.last.header != header) {
        groups.add((header: header, trips: <BookingInfo>[trip]));
      } else {
        groups.last.trips.add(trip);
      }
    }

    final items = <_RowItem>[];
    for (final g in groups) {
      items.add(_RowItem.header(g.header, g.trips.length));
      for (final trip in g.trips) {
        items.add(_RowItem.trip(trip));
      }
    }
    return items;
  }

  // Trips are filtered, sorted and grouped by their START date (falling back to
  // booking/end date only when start is missing).
  static DateTime? _sortKey(BookingInfo t) =>
      t.startDateTime ?? t.bookingDate ?? t.endDateTime;

  static const _weekdays = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
  ];
  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static String _formatDayHeader(DateTime d, DateTime now) {
    final day = DateTime(d.year, d.month, d.day);
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    final wd = _weekdays[d.weekday - 1];
    final mo = _months[d.month - 1];
    if (d.year == now.year) return '$wd, ${d.day} $mo';
    return '$wd, ${d.day} $mo ${d.year}';
  }

  /// Scrollable + refreshable message screen used for offline / error /
  /// empty states. Wrapping the column in a ListView keeps pull-to-refresh
  /// working when there's no data to scroll over.
  Widget _buildMessageState({
    required TripFilter filter,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    bool showRetry = true,
  }) {
    return RefreshIndicator(
      onRefresh: () => _loadListForFilter(filter),
      color: AppColors.brandPrimary,
      child: ListView(
        physics: kBouncyAlwaysScrollable,
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 110),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: AppColors.brandSoft,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 56, color: iconColor),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style:
                        TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                  if (showRetry) ...[
                    const SizedBox(height: 14),
                    ElevatedButton.icon(
                      onPressed: () => _loadListForFilter(filter),
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandPrimary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(TripFilter filter) => _buildMessageState(
        filter: filter,
        icon: filter.icon,
        iconColor: AppColors.brandPrimary,
        title: filter.emptyTitle,
        subtitle: filter.emptySubtitle,
        showRetry: false,
      );
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

class _RowItem {
  _RowItem.header(String label, int count)
      : headerLabel = label,
        headerCount = count,
        trip = null;
  _RowItem.trip(BookingInfo t)
      : headerLabel = null,
        headerCount = null,
        trip = t;

  final String? headerLabel;
  final int? headerCount;
  final BookingInfo? trip;

  bool get isHeader => headerLabel != null;
}
