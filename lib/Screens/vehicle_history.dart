import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_agency_app/Screens/trip_card.dart';
import 'package:travel_agency_app/domain/models/booking_info.dart';
import 'package:travel_agency_app/domain/models/vehicles.dart';
import 'package:travel_agency_app/presentation/providers/viewmodel_provider.dart';

class VehicleTripHistory extends ConsumerStatefulWidget {
  final Vehicles vehicle;
//   final int vehicleId;
// final String vehicleInfo;

  const VehicleTripHistory({super.key, required this.vehicle});

  @override
  ConsumerState<VehicleTripHistory> createState() =>
      _VehicleTripHistoryState();
}

class _VehicleTripHistoryState
    extends ConsumerState<VehicleTripHistory>
    with TickerProviderStateMixin {

  late AnimationController _entryController;
  late Animation<double> _avatarScale;
  late Animation<Offset> _slideUp;
  late Animation<double> _fadeIn;

  static const Color _bg            = Color(0xFFF2F4F8);
  static const Color _surface       = Color(0xFFFFFFFF);
  static const Color _surfaceLight  = Color(0xFFF0F3FA);
  static const Color _accent        = Color(0xFF3D5AFE);
  static const Color _textPrimary   = Color(0xFF1A1D2E);
  static const Color _textSecondary = Color(0xFF7B82A0);
  static const Color _divider       = Color(0xFFE4E8F0);


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

    /// FETCH VEHICLE TRIPS
    Future.microtask(() {
      ref
          .read(addVehicleViewModelProvider.notifier)
          .getTripsByVehicle(widget.vehicle.vehicleId ?? 0);
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
        ref.watch(addVehicleViewModelProvider).fetchTripsByVehicleId;

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          _buildStaticHeader(state),
          Expanded(child: _buildTripList(state)),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────
  // HEADER
  // ────────────────────────────────────────────────────────────────

 Widget _buildStaticHeader(AsyncValue<List<BookingInfo>> tripState) {
  final topPad = MediaQuery.of(context).padding.top;

  return Container(
    padding: EdgeInsets.fromLTRB(20, topPad + 12, 20, 24),
    decoration: BoxDecoration(
      color: _surface,
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF6378FF).withOpacity(0.08),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // ── TOP ROW — Back + Label ──
        Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _divider, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 14,
                  color: _textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Text(
              "Vehicle's History",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _accent,
                letterSpacing: 2.2,
              ),
            ),
          ],
        ),

        const SizedBox(height: 22),

        // ── VEHICLE IDENTITY ROW ──
        SlideTransition(
          position: _slideUp,
          child: FadeTransition(
            opacity: _fadeIn,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [

                // Avatar
                ScaleTransition(
                  scale: _avatarScale,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Soft glow halo
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              const Color(0xFF6378FF).withOpacity(0.15),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF6378FF), Color(0xFF4A5BD4)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6378FF).withOpacity(0.30),
                              blurRadius: 16,
                              spreadRadius: -2,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.directions_car_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 14),

                // Name + plate
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.vehicle.name ?? 'Unknown Vehicle',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: _textPrimary,
                          letterSpacing: -0.5,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6378FF).withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFF6378FF).withOpacity(0.20),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.pin_outlined,
                                  size: 11,
                                  color: const Color(0xFF6378FF).withOpacity(0.7),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  widget.vehicle.number ?? '—',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF6378FF),
                                    letterSpacing: 1.6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Status chip — adapts color by status
                Builder(builder: (_) {
                  final isEngaged = (widget.vehicle.StatusId ?? 0) == 1;
                  final chipColor = isEngaged
                      ? const Color(0xFFBE9C02)
                      : const Color(0xFF22C55E);
                  final chipBg = isEngaged
                      ? const Color(0xFFFFFBEB)
                      : const Color(0xFFF0FDF4);
                  final chipBorder = isEngaged
                      ? const Color(0xFFBE9C02)
                      : const Color(0xFF22C55E);

                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 11, vertical: 7),
                    decoration: BoxDecoration(
                      color: chipBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: chipBorder.withOpacity(0.35),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: chipColor.withOpacity(0.10),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: chipColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          isEngaged ? "Engaged" : "Available",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: chipColor,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),

        // const SizedBox(height: 20),

        // ── Divider ──
        // Container(
        //   height: 1,
        //   decoration: BoxDecoration(
        //     gradient: LinearGradient(
        //       colors: [
        //         Colors.transparent,
        //         _divider,
        //         Colors.transparent,
        //       ],
        //     ),
        //   ),
        // ),

        const SizedBox(height: 16),

        _buildCompactStats(tripState),
      ],
    ),
  );
}

  // ────────────────────────────────────────────────────────────────
  // STATS
  // ────────────────────────────────────────────────────────────────

  Widget _buildCompactStats(
      AsyncValue<List<BookingInfo>> tripState) {
    return tripState.when(
      loading: () => const SizedBox(height: 52),
      error: (_, __) => const SizedBox.shrink(),
      data: (trips) {
        final total = trips.length;

        final paid = trips
            .where((t) =>
                (t.amountReceived ?? 0) >= (t.amountApprove ?? 0) &&
                (t.amountApprove ?? 0) > 0)
            .length;

        final totalValue = trips.fold<double>(
            0, (sum, t) => sum + (t.amountApprove ?? 0));

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
            const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800),
            ),
            Text(
              label,
              style: const TextStyle(
                  fontSize: 11,
                  color: _textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dividerLine() =>
      Container(width: 1, height: 30, color: _divider);

  // ────────────────────────────────────────────────────────────────
  // TRIP LIST
  // ────────────────────────────────────────────────────────────────

  Widget _buildTripList(
      AsyncValue<List<BookingInfo>> state) {
    return state.when(
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (e, _) => Center(child: Text('$e')),
      data: (trips) {
        if (trips.isEmpty) {
          return const Center(
            child: Text("No trips for this vehicle"),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 24),
          itemCount: trips.length,
          itemBuilder: (_, i) => TripCard(
            key: ValueKey(trips[i].tripId),
            bookinginfo: trips[i],
            ref: ref,
            status: trips[i].status?? 0,
          ),
        );
      },
    );
  }
}