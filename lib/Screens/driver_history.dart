import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:travel_agency_app/Screens/trip_card.dart';
import 'package:travel_agency_app/core/storage/constant.dart';
import 'package:travel_agency_app/core/theme/app_colors.dart';
import 'package:travel_agency_app/core/widgets/error_view.dart';
import 'package:travel_agency_app/core/widgets/skeleton.dart';
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

  static const Color _bg = Color(0xFFF2F4F8);
  static const Color _surface = Color(0xFFFFFFFF);
  static const Color _surfaceLight = Color(0xFFF0F3FA);
  static const Color _accent = AppColors.brandPrimary;
  static const Color _textPrimary = Color(0xFF1A1D2E);
  static const Color _textSecondary = Color(0xFF7B82A0);
  static const Color _divider = Color(0xFFE4E8F0);

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state =
        ref.watch(addDriverViewModelProvider).fetchTripsByDriverId;

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          _buildHeader(state),
          Expanded(child: _buildTripList(state)),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // HEADER
  // ─────────────────────────────────────────────────────────────

  Widget _buildHeader(AsyncValue<List<BookingInfo>> tripState) {
    final topPad = MediaQuery.of(context).padding.top;

    return Container(
      padding: EdgeInsets.fromLTRB(16, topPad + 8, 16, 14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius:
            const BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// Back + Label
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: _surfaceLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _divider),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 13,
                  ),
                ),
              ),
              // const SizedBox(width: 14),
              // const Text(
              //   "Driver's History",
              //   style: TextStyle(
              //     fontSize: 11,
              //     fontWeight: FontWeight.w700,
              //     color: _accent,
              //     letterSpacing: 2.2,
              //   ),
              // ),
            ],
          ),

          const SizedBox(height: 12),

          /// Driver Info
          SlideTransition(
            position: _slideUp,
            child: FadeTransition(
              opacity: _fadeIn,
              child: Row(
                children: [

                  /// Avatar
                  ScaleTransition(
                    scale: _avatarScale,
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: const LinearGradient(
                          colors: [AppColors.brandPrimaryLight, AppColors.brandPrimaryDark],
                        ),
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  /// Name + Phone
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.driver.name ?? 'Unknown Driver',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(
                              Icons.phone_rounded,
                              size: 12,
                              color: _textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.driver.phone ?? '',
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: _textSecondary,
                              ),
                            ),
                          ],
                        ),
                        if (widget.driver.address != null &&
                            widget.driver.address!.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.location_on_rounded,
                                size: 12,
                                color: _textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  widget.driver.address!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: _textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        _buildLicenceRow(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          _buildLicence(),

          const SizedBox(height: 12),

          _buildStats(tripState),
        ],
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

Widget _buildStats(AsyncValue<List<BookingInfo>> tripState) {
  return tripState.when(
    loading: () => const SizedBox(height: 44),
    error: (_, __) => const SizedBox.shrink(),
    data: (trips) {

      final total = trips.length;

      final paid = trips.where((t) =>
          (t.amountReceived ?? 0) >= (t.amountApprove ?? 0) &&
          (t.amountApprove ?? 0) > 0
      ).length;

      final totalValue = trips.fold<double>(
        0,
        (sum, t) => sum + (t.amountApprove ?? 0),
      );

      return Container(
        decoration: BoxDecoration(
          color: _surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _divider),
        ),
        child: Row(
          children: [
            _stat("$total", "Trips"),
            _dividerLine(),
            _stat("$paid", "Paid"),
            _dividerLine(),
            _stat("₹${totalValue.toStringAsFixed(0)}", "Total"),
          ],
        ),
      );
    },
  );
}

  Widget _stat(String value, String label) {
    return Expanded(
      child: Padding(
        padding:
            const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800)),
            Text(label,
                style: const TextStyle(
                    fontSize: 10.5,
                    color: _textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _dividerLine() =>
      Container(width: 1, height: 24, color: _divider);

  // ─────────────────────────────────────────────────────────────
  // TRIP LIST
  // ─────────────────────────────────────────────────────────────

  Future<void> _refreshTrips() async {
    await ref
        .read(addDriverViewModelProvider.notifier)
        .fetchDriverHistory(widget.driver.driverId ?? 0);
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
            SkeletonListItem(),
            SkeletonListItem(),
            SkeletonListItem(),
            SkeletonListItem(),
          ],
        ),
      ),
      error: (e, _) => NetworkErrorView(error: e),
      data: (trips) {
        if (trips.isEmpty) {
          return const Center(
              child: Text("No trips for this driver"));
        }

        final filtered =
            trips.where((t) => _filter.matches(t)).toList();

        return RefreshIndicator(
          onRefresh: _refreshTrips,
          child: Column(
            children: [
              _buildFilterChips(trips),
              Expanded(
                child: filtered.isEmpty
                    ? _filteredEmptyState()
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 24),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) => TripCard(
                          key: ValueKey(filtered[i].tripId),
                          bookinginfo: filtered[i],
                          status: filtered[i].status ?? 0,
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Status filter chips ───────────────────────────────────────
  Widget _buildFilterChips(List<BookingInfo> trips) {
    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        itemCount: _DriverTripFilter.values.length,
        itemBuilder: (context, index) {
          final filter = _DriverTripFilter.values[index];
          final isSelected = filter == _filter;
          final count = filter == _DriverTripFilter.all
              ? trips.length
              : trips.where(filter.matches).length;

          return GestureDetector(
            onTap: () {
              if (filter != _filter) setState(() => _filter = filter);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isSelected ? _accent : _surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? _accent : _divider,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: _accent.withValues(alpha: 0.30),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : [],
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    filter.icon,
                    size: 14,
                    color: isSelected ? Colors.white : _textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${filter.label} ($count)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : _textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
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
