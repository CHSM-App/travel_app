import 'dart:async';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_agency_app/Screens/add_tripbooking.dart';
import 'package:travel_agency_app/Screens/trip_card.dart';
import 'package:travel_agency_app/core/network/error_messages.dart';
import 'package:travel_agency_app/core/theme/app_colors.dart';
import 'package:travel_agency_app/core/widgets/skeleton.dart';
import 'package:travel_agency_app/core/network/network_state_notifier.dart';
import 'package:travel_agency_app/domain/models/booking_info.dart';
import 'package:travel_agency_app/domain/viewModel/trippage_viewmodel.dart';
import 'package:travel_agency_app/presentation/providers/viewmodel_provider.dart';

/// Single source of truth for trip filters. `key` is the wire value used by
/// the cross-screen [tripPageInitialFilterProvider] deep-link signal.
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

  // The list to render. For [TripFilter.completed] the caller must additionally
  // pick a sub-tab — see [CompletedSubTab.listFrom]. We default to the unpaid
  // bucket here so this stays usable as a fallback if the sub-tab is missing.
  AsyncValue<List<BookingInfo>> listFrom(TripPageState state) {
    switch (this) {
      case TripFilter.all:
        return state.allList;
      case TripFilter.active:
        return state.activeList;
      case TripFilter.upcoming:
        return state.upcomingList;
      case TripFilter.completed:
        return state.unpaidList;
      case TripFilter.cancelled:
        return state.cancelledList;
    }
  }
}

/// Sub-tab shown only when [TripFilter.completed] is selected. Splits the
/// completed bucket into the two views the operator actually cares about.
enum CompletedSubTab {
  unpaid('Unpaid', Icons.payment_rounded),
  paid('Paid', Icons.history_rounded);

  const CompletedSubTab(this.label, this.icon);

  final String label;
  final IconData icon;

  AsyncValue<List<BookingInfo>> listFrom(TripPageState state) {
    switch (this) {
      case CompletedSubTab.unpaid:
        return state.unpaidList;
      case CompletedSubTab.paid:
        return state.historyList;
    }
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

  TripFilter _selectedFilter = TripFilter.active;
  // Active only when [_selectedFilter] is [TripFilter.completed]. Default to
  // "Unpaid" because that's the actionable view operators usually want first.
  CompletedSubTab _completedSubTab = CompletedSubTab.unpaid;
  DateRange _selectedRange = DateRange.all;
  DateTimeRange? _customRange;
  String _searchQuery = '';

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();

    // If someone (e.g. the dashboard's Action Needed card) requested a specific
    // filter before this page was mounted, honour it. ref.listen below catches
    // requests that arrive after mount; this branch is needed because listen
    // doesn't fire on the value already present at subscription time.
    final resolved = _resolveDeepLink(ref.read(tripPageInitialFilterProvider));
    if (resolved != null) {
      _selectedFilter = resolved.filter;
      if (resolved.subTab != null) _completedSubTab = resolved.subTab!;
      // A companion date signal pins the list to a single day (e.g. tomorrow's
      // pickups from the dashboard's "Upcoming Trips" row).
      final initialDate = ref.read(tripPageInitialDateProvider);
      if (initialDate != null) {
        _selectedRange = DateRange.custom;
        _customRange = _singleDayRange(initialDate);
      }
      ref.read(tripPageInitialFilterProvider.notifier).state = null;
      ref.read(tripPageInitialDateProvider.notifier).state = null;
    }

    Future.microtask(() => _loadListForFilter(_selectedFilter));
  }

  /// Translates a [tripPageInitialFilterProvider] key into a filter + optional
  /// sub-tab. Keeps the old `'paid'` / `'unpaid'` deep-links working — they now
  /// open Completed with the matching sub-tab pre-selected.
  ({TripFilter filter, CompletedSubTab? subTab})? _resolveDeepLink(
      String? key) {
    if (key == 'unpaid') {
      return (filter: TripFilter.completed, subTab: CompletedSubTab.unpaid);
    }
    if (key == 'paid') {
      return (filter: TripFilter.completed, subTab: CompletedSubTab.paid);
    }
    final f = TripFilter.fromKey(key);
    if (f == null) return null;
    return (filter: f, subTab: null);
  }

  /// A day-only [DateTimeRange] covering exactly [day] (start == end), used to
  /// pin the date filter to a single calendar day.
  DateTimeRange _singleDayRange(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    return DateTimeRange(start: d, end: d);
  }

  /// Applies a deep-link's companion date signal: pin to a single day when
  /// [day] is set, otherwise reset the range back to "All". Always wrapped in
  /// setState since it runs after the page is mounted.
  void _applyDeepLinkDate(DateTime? day) {
    setState(() {
      if (day == null) {
        _selectedRange = DateRange.all;
        _customRange = null;
      } else {
        _selectedRange = DateRange.custom;
        _customRange = _singleDayRange(day);
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
        // Both sub-tabs feed off these lists; pull them in parallel so toggling
        // between Unpaid/Paid never shows a stale skeleton.
        await Future.wait([
          notifier.unpaidList(agencyId),
          notifier.historyList(agencyId),
        ]);
        break;
      case TripFilter.cancelled:
        await notifier.cancelledList(agencyId);
        break;
    }
  }

  void _applyFilter(TripFilter filter, {CompletedSubTab? subTab}) {
    final filterChanged = filter != _selectedFilter;
    final subTabChanged =
        subTab != null && subTab != _completedSubTab;
    if (!filterChanged && !subTabChanged) return;
    setState(() {
      _selectedFilter = filter;
      if (subTab != null) _completedSubTab = subTab;
    });
    if (filterChanged) _loadListForFilter(filter);
  }

  void _applyCompletedSubTab(CompletedSubTab subTab) {
    if (subTab == _completedSubTab) return;
    setState(() => _completedSubTab = subTab);
  }

  /// Commits the filter selections made in the bottom sheet back to the page,
  /// reloading the list only when the status filter actually changed.
  void _applyFromSheet(
    TripFilter filter,
    CompletedSubTab subTab,
    DateRange range,
    DateTimeRange? customRange,
  ) {
    final filterChanged = filter != _selectedFilter;
    setState(() {
      _selectedFilter = filter;
      _completedSubTab = subTab;
      _selectedRange = range;
      _customRange = customRange;
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
      _applyFilter(resolved.filter, subTab: resolved.subTab);
      // Apply (or clear) the companion date filter so the deep-linked list lands
      // in a predictable state — pinned to a single day, or back to "All".
      _applyDeepLinkDate(ref.read(tripPageInitialDateProvider));
      ref.read(tripPageInitialFilterProvider.notifier).state = null;
      ref.read(tripPageInitialDateProvider.notifier).state = null;
    });

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
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
                  child: _buildTripList(
                    _selectedFilter == TripFilter.completed
                        ? _completedSubTab.listFrom(state)
                        : _selectedFilter.listFrom(state),
                  ),
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
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
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
          if (_selectedFilter == TripFilter.completed) ...[
            const SizedBox(height: 8),
            _buildCompletedSubTabs(),
          ],
        ],
      ),
    );
  }

  /// Single filter entry point. Shows the brand colour + a count badge when any
  /// non-default filter is active, and opens the full filter sheet on tap.
  Widget _buildFilterButton() {
    final activeCount = (_selectedFilter != TripFilter.active ? 1 : 0) +
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
                Icons.tune_rounded,
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

  /// Bottom sheet holding every filter — status, completed view, and date range
  /// — with a live preview, Reset, and Apply. Selections are staged locally and
  /// only committed when Apply is tapped.
  void _openFilterSheet() {
    TripFilter tempFilter = _selectedFilter;
    CompletedSubTab tempSub = _completedSubTab;
    DateRange tempRange = _selectedRange;
    DateTimeRange? tempCustom = _customRange;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
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
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.brandPrimary
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
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
                        size: 14,
                        color: selected ? Colors.white : Colors.grey.shade700,
                      ),
                      const SizedBox(width: 5),
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

            Widget sectionTitle(String t) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      t,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.grey.shade500,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                );

            return Container(
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
                  const SizedBox(height: 10),
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
                          tempFilter = TripFilter.active;
                          tempSub = CompletedSubTab.unpaid;
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
                  const SizedBox(height: 8),

                  // ── Status ──────────────────────────────────────────────
                  sectionTitle('STATUS'),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: [
                      for (final f in TripFilter.values)
                        choiceChip(
                          label: f.label,
                          icon: f.icon,
                          selected: tempFilter == f,
                          onTap: () => setSheetState(() => tempFilter = f),
                        ),
                    ],
                  ),

                  // ── Completed view (contextual) ─────────────────────────
                  if (tempFilter == TripFilter.completed) ...[
                    const SizedBox(height: 12),
                    sectionTitle('COMPLETED VIEW'),
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: [
                        for (final s in CompletedSubTab.values)
                          choiceChip(
                            label: s.label,
                            icon: s.icon,
                            selected: tempSub == s,
                            onTap: () => setSheetState(() => tempSub = s),
                          ),
                      ],
                    ),
                  ],

                  // ── Date range ──────────────────────────────────────────
                  const SizedBox(height: 12),
                  sectionTitle('DATE RANGE'),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: [
                      for (final r in DateRange.values)
                        choiceChip(
                          label: (r == DateRange.custom && tempCustom != null)
                              ? '${_shortDate(tempCustom!.start)} – ${_shortDate(tempCustom!.end)}'
                              : r.label,
                          icon: r.icon,
                          selected: tempRange == r,
                          onTap: () async {
                            if (r == DateRange.custom) {
                              final picked =
                                  await _showRangePicker(ctx, tempCustom);
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

                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _applyFromSheet(
                            tempFilter, tempSub, tempRange, tempCustom);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
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

  Widget _buildCompletedSubTabs() {
    return Container(
      height: 38,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Row(
        children: [
          for (final tab in CompletedSubTab.values)
            Expanded(
              child: _buildSubTabPill(
                tab: tab,
                selected: tab == _completedSubTab,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSubTabPill({
    required CompletedSubTab tab,
    required bool selected,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _applyCompletedSubTab(tab),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: selected ? AppColors.brandPrimary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.brandPrimary.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : const [],
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                tab.icon,
                size: 15,
                color: selected ? Colors.white : Colors.grey.shade700,
              ),
              const SizedBox(width: 6),
              Text(
                tab.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: selected ? Colors.white : Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocus,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          isDense: true,
          hintText: 'Search trips...',
          hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: Colors.grey.shade600,
            size: 20,
          ),
          // Listen to the controller directly so toggling the clear button
          // doesn't rebuild the whole page on every keystroke.
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: _searchController,
            builder: (_, value, __) {
              if (value.text.isEmpty) return const SizedBox.shrink();
              return IconButton(
                icon: Icon(
                  Icons.clear_rounded,
                  color: Colors.grey.shade600,
                  size: 18,
                ),
                onPressed: () {
                  _searchController.clear();
                  _onSearchChanged('');
                },
              );
            },
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
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
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 110),
          children: const [
            SkeletonListItem(),
            SkeletonListItem(),
            SkeletonListItem(),
            SkeletonListItem(),
            SkeletonListItem(),
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
            iconColor: Colors.grey.shade500,
            title: 'You appear to be offline',
            subtitle:
                'Check your connection and pull to refresh, or tap retry.',
          );
        }

        return _buildMessageState(
          filter: filter,
          icon: Icons.error_outline_rounded,
          iconColor: Colors.red.shade300,
          title: 'Error loading trips',
          subtitle: friendlyErrorMessage(e),
        );
      },
      data: (trips) {
        final filtered = _filterAndSearch(trips, filter);
        if (filtered.isEmpty) return _buildEmptyState(filter);

        final items = _groupByDay(filtered);

        return RefreshIndicator(
          onRefresh: () => _loadListForFilter(filter),
          color: AppColors.brandPrimary,
          child: ListView.builder(
            // Extra bottom padding so the last card scrolls clear of the
            // floating pill nav (nav height ~64 + margin + safety).
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 110),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final item = items[i];
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
          ),
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

  List<BookingInfo> _filterAndSearch(
    List<BookingInfo> trips,
    TripFilter filter,
  ) {
    // Same defensive payment-status check as before, now keyed on the sub-tab:
    // the unpaid view only shows trips that are actually unpaid/partially paid.
    final isUnpaidTab = filter == TripFilter.completed &&
        _completedSubTab == CompletedSubTab.unpaid;
    final query = _searchQuery;
    final hasQuery = query.isNotEmpty;
    final range = _selectedRange;
    final now = DateTime.now();

    return trips.where((trip) {
      if (isUnpaidTab) {
        final status = trip.payment_status?.toLowerCase() ?? '';
        if (status != 'unpaid' && status != 'partially paid') return false;
      }
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
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 80, 24, 110),
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 56, color: iconColor),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
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
        ],
      ),
    );
  }

  Widget _buildEmptyState(TripFilter filter) => _buildMessageState(
        filter: filter,
        icon: filter.icon,
        iconColor: Colors.indigo.shade300,
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
