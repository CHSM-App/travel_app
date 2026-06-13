import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:travel_agency_app/Screens/trip_card.dart';
import 'package:travel_agency_app/core/storage/constant.dart';
import 'package:travel_agency_app/core/theme/app_colors.dart';
import 'package:travel_agency_app/core/utils/driver_report_export.dart';
import 'package:travel_agency_app/core/widgets/error_view.dart';
import 'package:travel_agency_app/core/widgets/skeleton.dart';
import 'package:travel_agency_app/core/widgets/trip_filter.dart';
import 'package:travel_agency_app/domain/models/booking_info.dart';
import 'package:travel_agency_app/domain/models/drivers.dart';
import 'package:travel_agency_app/presentation/providers/viewmodel_provider.dart';

/// Client-side status filter for the driver's trip list. All of a driver's
/// trips are fetched once, so filtering happens in memory — keyed on
/// [BookingInfo.status]: 1 = Active, 2 = Unpaid, 3 = Upcoming, 4 = Complete,
/// 5 = Cancelled.
enum _DriverTripFilter {
  all('All', Icons.list_alt_rounded),
  active('Active', Icons.directions_car_rounded),
  upcoming('Upcoming', Icons.schedule_rounded),
  completed('Completed', Icons.task_alt_rounded),
  cancelled('Cancelled', Icons.cancel_rounded);

  const _DriverTripFilter(this.label, this.icon);

  final String label;
  final IconData icon;

  bool matches(BookingInfo t) {
    switch (this) {
      case _DriverTripFilter.all:
        return true;
      case _DriverTripFilter.active:
        return t.status == 1;
      case _DriverTripFilter.upcoming:
        return t.status == 3;
      case _DriverTripFilter.completed:
        // Completed covers both unpaid (2) and fully paid/complete (4).
        return t.status == 2 || t.status == 4;
      case _DriverTripFilter.cancelled:
        return t.status == 5;
    }
  }
}

class DriverHistoryPage extends ConsumerStatefulWidget {
  final Drivers driver;

  const DriverHistoryPage({super.key, required this.driver});

  @override
  ConsumerState<DriverHistoryPage> createState() =>
      _DriverHistoryPageState();
}

class _DriverHistoryPageState
    extends ConsumerState<DriverHistoryPage>
    with TickerProviderStateMixin {

  late AnimationController _entryController;
  late Animation<double> _avatarScale;
  late Animation<Offset> _slideUp;
  late Animation<double> _fadeIn;

  _DriverTripFilter _filter = _DriverTripFilter.all;

  // Date-range + free-text search applied on top of the status filter,
  // mirroring TripPage. Search is a toggled icon → field with a debounced query.
  static const Duration _searchDebounce = Duration(milliseconds: 250);
  TripDateRange _range = TripDateRange.all;
  DateTimeRange? _customRange;
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  Timer? _debounceTimer;
  bool _searchVisible = false;
  String _query = '';

  // True while a PDF/Excel file is being generated for this driver.
  bool _exporting = false;

  static const Color _bg = Color(0xFFF0F4FF);
  static const Color _surface = Color(0xFFFFFFFF);
  static const Color _surfaceLight = Color(0xFFF0F3FA);
  static const Color _accent = AppColors.brandPrimary;
  static const Color _accentSoft = AppColors.brandSoft;
  static const Color _textPrimary = Color(0xFF1A1D2E);
  static const Color _textSecondary = Color(0xFF7B82A0);
  static const Color _divider = Color(0xFFE4E8F0);
  static const Color _success = Color(0xFF2DB976);
  static const Color _warning = Color(0xFFE67E22);

  static final NumberFormat _money = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

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

    /// FETCH DRIVER TRIPS
    Future.microtask(() {
      ref
          .read(addDriverViewModelProvider.notifier)
          .fetchDriverHistory(widget.driver.driverId ?? 0);
    });
  }

  @override
  void dispose() {
    _entryController.dispose();
    _debounceTimer?.cancel();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_searchDebounce, () {
      if (!mounted) return;
      final normalized = value.trim().toLowerCase();
      if (normalized == _query) return;
      setState(() => _query = normalized);
    });
  }

  void _toggleSearch() {
    setState(() {
      _searchVisible = !_searchVisible;
      if (!_searchVisible) {
        _debounceTimer?.cancel();
        _searchCtrl.clear();
        _query = '';
        _searchFocus.unfocus();
      }
    });
    if (_searchVisible) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _searchFocus.requestFocus();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state =
        ref.watch(addDriverViewModelProvider).fetchTripsByDriverId;

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: _bg,
      // Identity bar (name / phone / address) stays pinned at the top; the
      // report card + licence scroll away, and the filter row sits at the top
      // of the list body (non-scrollable) so trips get maximum visibility.
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverPersistentHeader(
            pinned: true,
            delegate: _StickyHeaderDelegate(
              height: topPad + 64,
              child: _buildIdentityBar(topPad),
            ),
          ),
          // Filter chip row pinned directly under the identity bar so the
          // status / date / search controls stay at the top while scrolling.
          SliverPersistentHeader(
            pinned: true,
            delegate: _StickyHeaderDelegate(
              height: 64,
              child: _buildFilterRow(),
            ),
          ),
          SliverToBoxAdapter(child: _buildReportSection(state)),
        ],
        body: _buildTripList(state),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // HEADER
  // ─────────────────────────────────────────────────────────────

  // ── STICKY IDENTITY BAR ────────────────────────────────────────────
  // Pinned at the top of the scroll view: back action plus the driver's
  // name, phone and address — always visible while scrolling.
  Widget _buildIdentityBar(double topPad) {
    final driver = widget.driver;
    final hasAddress =
        driver.address != null && driver.address!.trim().isNotEmpty;

    return Container(
      padding: EdgeInsets.fromLTRB(12, topPad + 8, 12, 8),
      decoration: BoxDecoration(
        color: _surface,
        border: const Border(bottom: BorderSide(color: _divider)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _iconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            label: 'Back',
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(width: 10),
          ScaleTransition(scale: _avatarScale, child: _smallAvatar()),
          const SizedBox(width: 10),
          Expanded(
            child: SlideTransition(
              position: _slideUp,
              child: FadeTransition(
                opacity: _fadeIn,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      driver.name ?? 'Unknown Driver',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: _textPrimary,
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.phone_rounded,
                            size: 11, color: _textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          driver.phone ?? '--',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _textSecondary,
                          ),
                        ),
                        if (hasAddress) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.location_on_rounded,
                              size: 11, color: _textSecondary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              driver.address!.trim(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: _textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Export this driver's report (PDF / Excel) for the active range.
          _exporting
              ? Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: _surfaceLight,
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: _divider, width: 1.2),
                  ),
                  padding: const EdgeInsets.all(10),
                  child: const CircularProgressIndicator(
                    strokeWidth: 2.2,
                    valueColor: AlwaysStoppedAnimation(_accent),
                  ),
                )
              : _iconButton(
                  icon: Icons.ios_share_rounded,
                  label: 'Export report',
                  iconColor: _accent,
                  bgColor: _accentSoft,
                  onTap: _exportReport,
                ),
        ],
      ),
    );
  }

  Widget _smallAvatar() => Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.brandPrimary,
          boxShadow: [
            BoxShadow(
              color: _accent.withValues(alpha: 0.30),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.person_rounded, color: Colors.white, size: 20),
      );

  Widget _iconButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? iconColor,
    Color? bgColor,
  }) =>
      Semantics(
        button: true,
        label: label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(11),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: bgColor ?? _surfaceLight,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: _divider, width: 1.2),
              ),
              child: Icon(icon, color: iconColor ?? _textPrimary, size: 16),
            ),
          ),
        ),
      );

  // Scrollable section beneath the pinned identity bar — report card +
  // licence details. Scrolls away as the trip list scrolls.
  Widget _buildReportSection(AsyncValue<List<BookingInfo>> tripState) {
    return FadeTransition(
      opacity: _fadeIn,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildReportCard(tripState),
            _buildLicenceCard(),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // LICENCE DETAILS
  // ─────────────────────────────────────────────────────────────

  // Compact licence no + expiry, shown inline beneath the phone / address
  // rows in the driver info block.
  Widget _buildLicenceRow() {
    final no = widget.driver.licenceNo;
    final expiry = widget.driver.licenceExpiry;
    final hasNo = no != null && no.trim().isNotEmpty;
    if (!hasNo && expiry == null) return const SizedBox.shrink();

    final now = DateTime.now();
    final expired = expiry != null &&
        DateTime(expiry.year, expiry.month, expiry.day)
            .isBefore(DateTime(now.year, now.month, now.day));
    final expiryColor =
        expired ? const Color(0xFFE53935) : _textSecondary;

    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        children: [
          const Icon(Icons.badge_rounded, size: 12, color: _textSecondary),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              hasNo ? no.trim() : '—',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: _textSecondary,
                letterSpacing: 0.3,
              ),
            ),
          ),
          if (expiry != null) ...[
            const SizedBox(width: 10),
            Icon(
              expired
                  ? Icons.event_busy_rounded
                  : Icons.event_available_rounded,
              size: 12,
              color: expiryColor,
            ),
            const SizedBox(width: 4),
            Text(
              _formatDate(expiry),
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: expiryColor,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Licence document viewer button — only rendered when a document exists.
  Widget _buildLicence() {
    final docUrl = _normalizeDocUrl(widget.driver.photo);
    final hasDoc = docUrl != null && docUrl.isNotEmpty;
    if (!hasDoc) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => _openDocument(docUrl),
          icon: Icon(
            _isPdfUrl(docUrl)
                ? Icons.picture_as_pdf_rounded
                : Icons.visibility_rounded,
            size: 16,
          ),
          label: const Text('View Licence Document'),
          style: OutlinedButton.styleFrom(
            foregroundColor: _accent,
            side: const BorderSide(color: _accent),
            padding: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  // ── Licence document helpers (mirrors add_driver.dart) ───────────────

  bool _isPdfUrl(String? url) {
    if (url == null || url.trim().isEmpty) return false;
    final parsed = Uri.tryParse(url.trim());
    final path = (parsed?.path ?? url).toLowerCase();
    return path.endsWith('.pdf');
  }

  // Turns whatever the API stored (a bare filename, a Windows path, a
  // ./uploads path, or an already-absolute URL) into a fully-qualified URL.
  String? _normalizeDocUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.trim().isEmpty) return null;

    var cleaned = rawUrl.trim().replaceAll('\\', '/');

    if (cleaned.startsWith('http://') || cleaned.startsWith('https://')) {
      return cleaned;
    }

    final isFileNameOnly = !cleaned.contains('/') &&
        RegExp(
          r'\.(jpg|jpeg|png|webp|heic|pdf)$',
          caseSensitive: false,
        ).hasMatch(cleaned);

    final uploadIdx = cleaned.toLowerCase().indexOf('upload/');
    if (uploadIdx != -1) {
      cleaned = cleaned.substring(uploadIdx);
    } else {
      final uploadsIdx = cleaned.toLowerCase().indexOf('uploads/');
      if (uploadsIdx != -1) cleaned = cleaned.substring(uploadsIdx);
    }

    if (cleaned.startsWith('./')) cleaned = cleaned.substring(2);

    final base =
        baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;

    if (isFileNameOnly) return '$base/upload/DriverDocuments/$cleaned';
    if (cleaned.startsWith('/')) return '$base$cleaned';
    return '$base/$cleaned';
  }

  Future<void> _openDocument(String url) async {
    // PDFs open in an external viewer/browser; images open fullscreen in-app.
    if (_isPdfUrl(url)) {
      final uri = Uri.tryParse(url);
      if (uri == null) {
        _showSnack('Invalid document URL');
        return;
      }
      final launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        final retry = await launchUrl(uri, mode: LaunchMode.platformDefault);
        if (!retry) _showSnack('Could not open document');
      }
      return;
    }

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _FullscreenImagePage(networkUrl: url)),
    );
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade600),
    );
  }

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String _formatDate(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

  // ─────────────────────────────────────────────────────────────
  // STATS
  // ─────────────────────────────────────────────────────────────

  // ── REPORT CARD ────────────────────────────────────────────────────
  // Account summary: revenue *received* (not approved) as the hero figure,
  // with approved total, plus trips / paid / pending breakdown tiles.
  Widget _buildReportCard(AsyncValue<List<BookingInfo>> tripState) {
    return tripState.when(
      loading: () => Container(
        height: 132,
        decoration: BoxDecoration(
          color: _surfaceLight,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _divider),
        ),
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _accent,
              backgroundColor: _accent.withValues(alpha: 0.1),
            ),
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (allTrips) {
        // The summary reflects the active date range + search, so the figures
        // change as the date filter changes.
        final now = DateTime.now();
        final trips = allTrips
            .where((t) =>
                _range.matches(tripSortKey(t), now, customRange: _customRange) &&
                tripMatchesQuery(t, _query))
            .toList();

        final total = trips.length;
        final paidCount = trips
            .where((t) =>
                (t.amountReceived ?? 0) >= (t.amountApprove ?? 0) &&
                (t.amountApprove ?? 0) > 0)
            .length;
        final approved =
            trips.fold<double>(0, (sum, t) => sum + (t.amountApprove ?? 0));
        final received =
            trips.fold<double>(0, (sum, t) => sum + (t.amountReceived ?? 0));
        double pending = 0;
        for (final t in trips) {
          final due = (t.amountApprove ?? 0) - (t.amountReceived ?? 0);
          if (due > 0) pending += due;
        }

        return Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _divider, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: _accent.withValues(alpha: 0.07),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              // ── Hero: revenue received ──────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                decoration: const BoxDecoration(
                  color: AppColors.brandHeader,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.trending_up_rounded,
                                size: 13,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'Revenue Received',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withValues(alpha: 0.85),
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _money.format(received),
                              style: const TextStyle(
                                fontSize: 23,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.5,
                                height: 1,
                              ),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'of ${_money.format(approved)} approved',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.78),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Breakdown tiles ─────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                child: Row(
                  children: [
                    _reportTile(
                      Icons.route_rounded,
                      'Trips',
                      '$total',
                      _accent,
                    ),
                    _tileDivider(),
                    _reportTile(
                      Icons.check_circle_outline_rounded,
                      'Paid',
                      '$paidCount',
                      _success,
                    ),
                    _tileDivider(),
                    _reportTile(
                      Icons.pending_actions_rounded,
                      'Pending',
                      _money.format(pending),
                      pending > 0 ? _warning : _textSecondary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _reportTile(IconData icon, String label, String value, Color color) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(height: 7),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: _textPrimary,
                  height: 1.1,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10.5,
                color: _textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tileDivider() {
    return Container(width: 1, height: 40, color: _divider);
  }

  // Licence details card (number / expiry + document button), shown below the
  // report card. Hidden entirely when the driver has no licence info or doc.
  Widget _buildLicenceCard() {
    final no = widget.driver.licenceNo;
    final expiry = widget.driver.licenceExpiry;
    final docUrl = _normalizeDocUrl(widget.driver.photo);
    final hasInfo = (no != null && no.trim().isNotEmpty) || expiry != null;
    final hasDoc = docUrl != null && docUrl.isNotEmpty;
    if (!hasInfo && !hasDoc) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _accentSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.badge_rounded, size: 13, color: _accent),
              ),
              const SizedBox(width: 8),
              const Text(
                'LICENCE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: _textSecondary,
                ),
              ),
            ],
          ),
          if (hasInfo) _buildLicenceRow(),
          if (hasDoc) _buildLicence(),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // TRIP LIST
  // ─────────────────────────────────────────────────────────────

  Future<void> _refreshTrips() async {
    await ref
        .read(addDriverViewModelProvider.notifier)
        .fetchDriverHistory(widget.driver.driverId ?? 0);
  }

  // ─────────────────────────────────────────────────────────────
  // EXPORT (single driver)
  // ─────────────────────────────────────────────────────────────

  /// Human-readable label for the active date window, mirroring the figures
  /// the report card shows.
  String _rangeLabel(DateTime now) {
    final fmt = DateFormat('dd MMM yyyy');
    final today = DateTime(now.year, now.month, now.day);
    switch (_range) {
      case TripDateRange.all:
        return 'All time';
      case TripDateRange.today:
        return fmt.format(today);
      case TripDateRange.week:
        return '${fmt.format(today.subtract(const Duration(days: 6)))} - '
            '${fmt.format(today)}';
      case TripDateRange.month:
        return '${fmt.format(today.subtract(const Duration(days: 29)))} - '
            '${fmt.format(today)}';
      case TripDateRange.custom:
        final c = _customRange;
        if (c == null) return 'All time';
        return '${fmt.format(c.start)} - ${fmt.format(c.end)}';
    }
  }

  /// Builds a single-driver [DriverReportSnapshot] from the loaded trips,
  /// filtered to the active date range + search, then runs the shared export.
  Future<void> _exportReport() async {
    if (_exporting) return;
    final trips = ref
            .read(addDriverViewModelProvider)
            .fetchTripsByDriverId
            .asData
            ?.value ??
        const <BookingInfo>[];
    final now = DateTime.now();
    final periodTrips = trips
        .where((t) =>
            _range.matches(tripSortKey(t), now, customRange: _customRange) &&
            tripMatchesQuery(t, _query))
        .toList()
      ..sort((a, b) => (tripSortKey(b) ?? DateTime(0))
          .compareTo(tripSortKey(a) ?? DateTime(0)));

    final stat = DriverReportStat(driver: widget.driver, trips: periodTrips);
    final snap = DriverReportSnapshot(
      title: '${widget.driver.name ?? 'Driver'} Report',
      periodLabel: _range.label,
      dateRangeLabel: _rangeLabel(now),
      stats: [stat],
      totalReceived: stat.received,
      totalApproved: stat.approved,
      totalDriverPay: stat.driverPay,
      activeDrivers: stat.hasActivity ? 1 : 0,
      totalDrivers: 1,
      tripCount: stat.tripCount,
    );

    setState(() => _exporting = true);
    await runDriverReportExport(context, snap);
    if (mounted) setState(() => _exporting = false);
  }

  Widget _buildTripList(
      AsyncValue<List<BookingInfo>> state) {
    return state.when(
      loading: () => RefreshIndicator(
        onRefresh: _refreshTrips,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
          children: const [
            TripCardSkeleton(),
            TripCardSkeleton(),
            TripCardSkeleton(),
            TripCardSkeleton(),
          ],
        ),
      ),
      error: (e, _) => NetworkErrorView(error: e, onRetry: _refreshTrips),
      data: (trips) {
        if (trips.isEmpty) {
          return const Center(
              child: Text("No trips for this driver"));
        }

        // Date-range + search narrow the list first; the status chips (and
        // their counts) then operate on what remains.
        final now = DateTime.now();
        final base = trips
            .where((t) =>
                _range.matches(tripSortKey(t), now, customRange: _customRange) &&
                tripMatchesQuery(t, _query))
            .toList();
        final filtered = base.where((t) => _filter.matches(t)).toList();

        if (filtered.isEmpty) return _filteredEmptyState();

        return RefreshIndicator(
          onRefresh: _refreshTrips,
          color: _accent,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: filtered.length,
            itemBuilder: (_, i) => TripCard(
              key: ValueKey(filtered[i].tripId),
              bookinginfo: filtered[i],
              status: filtered[i].status ?? 0,
            ),
          ),
        );
      },
    );
  }

  // ── FILTER ROW ─────────────────────────────────────────────────────
  // Non-scrollable row at the top of the list: status dropdown + date filter
  // + search icon, which toggles to a back button + search field. Mirrors
  // TripPage / CustomerHist.
  Widget _buildFilterRow() {
    return Container(
      decoration: const BoxDecoration(
        color: _surface,
        border: Border(bottom: BorderSide(color: _divider)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        transitionBuilder: (child, anim) =>
            FadeTransition(opacity: anim, child: child),
        child: _searchVisible ? _buildSearchRow() : _buildPrimaryRow(),
      ),
    );
  }

  Widget _buildPrimaryRow() {
    return Row(
      key: const ValueKey('primary'),
      children: [
        _buildStatusDropdown(),
        const Spacer(),
        TripDateFilterButton(
          range: _range,
          customRange: _customRange,
          onChanged: (r, c) => setState(() {
            _range = r;
            _customRange = c;
          }),
        ),
        const SizedBox(width: 2),
        IconButton(
          icon: const Icon(Icons.search_rounded,
              color: _textSecondary, size: 22),
          tooltip: 'Search',
          onPressed: _toggleSearch,
        ),
      ],
    );
  }

  Widget _buildSearchRow() {
    return Row(
      key: const ValueKey('search'),
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _textSecondary),
          onPressed: _toggleSearch,
        ),
        Expanded(
          child: TripSearchField(
            controller: _searchCtrl,
            focusNode: _searchFocus,
            onChanged: _onSearchChanged,
          ),
        ),
      ],
    );
  }

  // Status filter as a dropdown, styled like TripPage's status dropdown.
  Widget _buildStatusDropdown() {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.brandPrimary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<_DriverTripFilter>(
          value: _filter,
          isDense: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.white,
            size: 20,
          ),
          dropdownColor: AppColors.brandPrimary,
          borderRadius: BorderRadius.circular(10),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          selectedItemBuilder: (context) => [
            for (final f in _DriverTripFilter.values)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.tune_rounded, size: 15, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    'Status: ${f.label}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
          ],
          items: [
            for (final f in _DriverTripFilter.values)
              DropdownMenuItem(
                value: f,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(f.icon, size: 16, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(f.label),
                  ],
                ),
              ),
          ],
          onChanged: (value) {
            if (value != null) setState(() => _filter = value);
          },
        ),
      ),
    );
  }

  // Shown when the driver has trips but none match the active filter.
  Widget _filteredEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_filter.icon, size: 52, color: _accent.withValues(alpha: 0.5)),
            const SizedBox(height: 14),
            Text(
              'No ${_filter.label.toLowerCase()} trips',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Try a different filter.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: _textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// FULLSCREEN IMAGE VIEWER
// ─────────────────────────────────────────────────────────────
class _FullscreenImagePage extends StatelessWidget {
  final String networkUrl;

  const _FullscreenImagePage({required this.networkUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4,
          child: Image.network(
            networkUrl,
            fit: BoxFit.contain,
            headers: const {'Cache-Control': 'no-cache'},
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return const CircularProgressIndicator(color: Colors.white);
            },
            errorBuilder: (_, __, ___) => const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.broken_image_rounded,
                    color: Colors.white54, size: 48),
                SizedBox(height: 12),
                Text(
                  'Could not load document',
                  style: TextStyle(color: Colors.white54),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Fixed-height pinned sliver header used to keep the driver identity bar
/// stuck to the top while the report card and trip list scroll.
class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  _StickyHeaderDelegate({required this.height, required this.child});

  final double height;
  final Widget child;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) =>
      SizedBox.expand(child: child);

  @override
  bool shouldRebuild(covariant _StickyHeaderDelegate oldDelegate) =>
      oldDelegate.height != height || oldDelegate.child != child;
}
