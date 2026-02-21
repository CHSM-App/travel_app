import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_agency_app/Screens/trip_card.dart';
import 'package:travel_agency_app/domain/models/booking_info.dart';
import 'package:travel_agency_app/domain/models/vehicles.dart';
import 'package:travel_agency_app/presentation/providers/viewmodel_provider.dart';

class VehicleTripHistory extends ConsumerStatefulWidget {
  // final BookingInfo vehicle;
  final int vehicleId;
final String vehicleName;

  const VehicleTripHistory({super.key, required this.vehicleId, required this.vehicleName, required Vehicles vehicle});

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
          .getTripsByVehicle(widget.vehicleId);
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
    final vehicle = widget.vehicleName;
    final topPad = MediaQuery.of(context).padding.top;

    return Container(
      padding: EdgeInsets.fromLTRB(20, topPad + 12, 20, 20),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius:
            const BorderRadius.vertical(bottom: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: _accent.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // BACK
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: _surfaceLight,
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: _divider),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 15,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                "Vehicle Trip History",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _textSecondary,
                  letterSpacing: 1.4,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // VEHICLE NAME
          SlideTransition(
            position: _slideUp,
            child: FadeTransition(
              opacity: _fadeIn,
              child: Row(
                children: [
                  ScaleTransition(
                    scale: _avatarScale,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6378FF), _accent],
                        ),
                      ),
                      child: const Icon(
                        Icons.directions_car_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehicle ?? 'Vehicle',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: _textPrimary,
                        ),
                      ),
                     

                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 18),

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
            tripType: '',
          ),
        );
      },
    );
  }
}