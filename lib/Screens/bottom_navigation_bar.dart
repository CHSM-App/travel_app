import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_agency_app/Screens/customer_page.dart';
import 'package:travel_agency_app/Screens/dashbord.dart';
import 'package:travel_agency_app/Screens/setting.dart';
import 'package:travel_agency_app/Screens/trip_page.dart';
import 'package:travel_agency_app/Screens/vehicle_page.dart';
import 'package:travel_agency_app/core/theme/app_colors.dart';
import 'package:travel_agency_app/presentation/providers/viewmodel_provider.dart';

// ── Pill nav theme ──────────────────────────────────────────────────────────
class NavTheme {
  static const navAccent = AppColors.brandPrimary;
  static const navInactive = AppColors.textSecondary;
  // 10% alpha over brand primary — keep this in sync if brandPrimary changes.
  static const navActivePill = Color(0x1A4F46E5);
  static const navPillBg = Color(0x12FFFFFF);
  static const navPillBorder = Color(0x26000000);
  static const compactNavHeight = 48.0;
  static const regularNavHeight = 56.0;
}

class MainBottomNav extends ConsumerStatefulWidget {
  const MainBottomNav({super.key});

  @override
  ConsumerState<MainBottomNav> createState() => _MainBottomNavState();
}

class _MainBottomNavState extends ConsumerState<MainBottomNav>
    with TickerProviderStateMixin {
  int selectedIndex = 0;
  int vehicleTabIndex = 0;

  // Drag state for the sliding active-tab indicator.
  bool _isDragging = false;
  double? _dragX;
  int? _dragHoverIndex;

  // 380 ms elastic 1.0 → 1.18 bounce per tab.
  late final List<AnimationController> _iconControllers;
  late final List<Animation<double>> _iconScales;

  late final List<Widget> pages = [
    const TravelAdminDashboard(),
    const TripPage(),
    VehiclePage(
      onTabChanged: (index) {
        // Drives the FAB label between "Add Vehicle" / "Add Driver".
        setState(() {
          vehicleTabIndex = index;
        });
      },
    ),
    const CustomerListPage(),
    const ModernSettingsPage(),
  ];

  final List<_NavItem> _navItems = const [
    _NavItem(label: "Home",      icon: Icons.home_outlined,           activeIcon: Icons.home_rounded),
    _NavItem(label: "Trips",     icon: Icons.card_travel_outlined,    activeIcon: Icons.card_travel_rounded),
    _NavItem(label: "Fleets",  icon: Icons.directions_car_outlined, activeIcon: Icons.directions_car_rounded),
    _NavItem(label: "Customers", icon: Icons.people_outline,          activeIcon: Icons.people_rounded),
    _NavItem(label: "Settings",  icon: Icons.settings_outlined,       activeIcon: Icons.settings_rounded),
  ];

  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      final adminId = ref.read(loginViewModelProvider).adminId;
      if (adminId > 0) {
        ref.read(loginViewModelProvider.notifier).adminProfile(adminId);
      }
    });

    _iconControllers = List.generate(
      _navItems.length,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 380),
      ),
    );
    _iconScales = _iconControllers
        .map(
          (c) => Tween<double>(begin: 1.0, end: 1.18).animate(
            CurvedAnimation(parent: c, curve: Curves.elasticOut),
          ),
        )
        .toList();

    // Pre-bounce the initial tab so the active icon starts at its scaled size.
    _iconControllers[0].forward();
  }

  @override
  void dispose() {
    for (final c in _iconControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (selectedIndex == index) return;
    _iconControllers[selectedIndex].reverse();
    setState(() => selectedIndex = index);
    _iconControllers[index].forward(from: 0);
    HapticFeedback.selectionClick();
    // Keep the cross-tab provider in sync so deep links from elsewhere
    // (e.g. dashboard Action Needed rows) read a correct current value
    // and re-writing the same index doesn't loop back here.
    if (ref.read(bottomNavIndexProvider) != index) {
      ref.read(bottomNavIndexProvider.notifier).state = index;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen for external tab-switch requests (e.g. dashboard deep links).
    ref.listen<int>(bottomNavIndexProvider, (prev, next) {
      if (next != selectedIndex) _onItemTapped(next);
    });

    final loginState = ref.watch(loginViewModelProvider);
    String userName = "Admin";
    String agencyName = "";
    String initials = "A";
    String? profileImageUrl;

    final profileList = loginState.adminProfile.valueOrNull;
    if (profileList != null && profileList.isNotEmpty) {
      userName = profileList.first.name ?? "Admin";
      agencyName = profileList.first.agencyName?.trim() ?? "";
      if (userName.isNotEmpty) initials = userName[0].toUpperCase();

      final rawImageUrl = profileList.first.imageUrl?.trim();
      if (rawImageUrl != null &&
          rawImageUrl.isNotEmpty &&
          rawImageUrl.toLowerCase() != 'null') {
        profileImageUrl = rawImageUrl;
      }
    }

    // Light status bar icons against the dark indigo AppBar; white system
    // nav matches the pill's translucent background.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: PopScope(
        canPop: selectedIndex == 0,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          if (selectedIndex != 0) _onItemTapped(0);
        },
        child: Scaffold(
          extendBody: true,
          extendBodyBehindAppBar: true,
          backgroundColor: const Color(0xFFF0F4FF),

          // ── AppBar ─────────────────────────────────────────
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(68),
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: Color(0xff000c33),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.brandHeader.withOpacity(0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Hero(
                            tag: 'profile_avatar',
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.45),
                                    width: 1.5),
                              ),
                              child: profileImageUrl != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        profileImageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Center(
                                          child: Text(
                                            initials,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 18,
                                            ),
                                          ),
                                        ),
                                      ),
                                    )
                                  : Center(
                                      child: Text(
                                        initials,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  userName.isNotEmpty
                                      ? "Welcome back, $userName 👋"
                                      : "Welcome back 👋",
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    letterSpacing: 0.3,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  agencyName.isNotEmpty
                                      ? agencyName
                                      : userName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Body ───────────────────────────────────────────
          body: Stack(
            children: [
              // IndexedStack keeps each tab's state across switches.
              Positioned.fill(
                child: IndexedStack(
                  index: selectedIndex,
                  children: pages,
                ),
              ),

              // Each tab that supports adding an item now owns its own plain
              // circular "+" FAB (Trips, Fleet, Customers), so the bottom nav
              // no longer renders a shared add button here.

              // Floating glassmorphic pill nav with draggable indicator.
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _buildPillNav(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Floating pill nav ─────────────────────────────────────
  Widget _buildPillNav() {
    final isCompact = MediaQuery.of(context).size.width < 360;
    final navHeight =
        isCompact ? NavTheme.compactNavHeight : NavTheme.regularNavHeight;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        // Shadow lives on the outer container — ClipRRect below would crop any
        // shadow placed on the pill itself. Three layers: a wide indigo-tinted
        // ambient, a tighter neutral key for grounding, and a crisp hairline
        // that defines the bottom edge.
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: AppColors.brandPrimary.withOpacity(0.10),
                blurRadius: 32,
                spreadRadius: 0,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 16,
                spreadRadius: -2,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 2,
                spreadRadius: 0,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                height: navHeight,
                decoration: BoxDecoration(
                  // Tiny lift in the base tint — pure glass on a light page
                  // can read as flat; a hint of white gives the pill body.
                  color: Colors.white.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: NavTheme.navPillBorder,
                    width: 0.3,
                  ),
                ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final totalWidth = constraints.maxWidth;
                  final itemCount = _navItems.length;
                  final itemWidth = totalWidth / itemCount;
                  final pillWidth = itemWidth - 10;
                  final pillHeight = navHeight - 10;

                  final curCenter = (selectedIndex + 0.5) * itemWidth;
                  final minCenter = itemWidth / 2;
                  final maxCenter = totalWidth - itemWidth / 2;
                  final dragCenter = ((_dragX ?? curCenter)
                          .clamp(minCenter, maxCenter))
                      .toDouble();
                  final pillLeft = ((dragCenter - pillWidth / 2)
                          .clamp(0.0, totalWidth - pillWidth))
                      .toDouble();

                  return GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onHorizontalDragStart: (d) {
                      setState(() {
                        _isDragging = true;
                        _dragX = d.localPosition.dx
                            .clamp(minCenter, maxCenter)
                            .toDouble();
                        _dragHoverIndex = selectedIndex;
                      });
                    },
                    onHorizontalDragUpdate: (d) {
                      final clamped = d.localPosition.dx
                          .clamp(minCenter, maxCenter)
                          .toDouble();
                      final newHover = (clamped / itemWidth)
                          .floor()
                          .clamp(0, itemCount - 1);
                      if (newHover != _dragHoverIndex) {
                        HapticFeedback.selectionClick();
                      }
                      setState(() {
                        _dragX = clamped;
                        _dragHoverIndex = newHover;
                      });
                    },
                    onHorizontalDragEnd: (_) {
                      final raw = _dragX ?? curCenter;
                      final newIdx =
                          (raw / itemWidth).floor().clamp(0, itemCount - 1);
                      setState(() {
                        _isDragging = false;
                        _dragX = null;
                        _dragHoverIndex = null;
                      });
                      _onItemTapped(newIdx);
                    },
                    onHorizontalDragCancel: () {
                      setState(() {
                        _isDragging = false;
                        _dragX = null;
                        _dragHoverIndex = null;
                      });
                    },
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        AnimatedPositioned(
                          duration: _isDragging
                              ? Duration.zero
                              : const Duration(milliseconds: 220),
                          curve: Curves.easeInOut,
                          top: 5,
                          left: pillLeft,
                          width: pillWidth,
                          height: pillHeight,
                          child: Container(
                            decoration: BoxDecoration(
                              color: NavTheme.navActivePill,
                              borderRadius: BorderRadius.circular(22),
                            ),
                          ),
                        ),
                        Row(
                          children: List.generate(itemCount, (i) {
                            return Expanded(
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => _onItemTapped(i),
                                child: _buildTabCell(i, isCompact),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildTabCell(int i, bool isCompact) {
    final item = _navItems[i];
    final selected = i == selectedIndex;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
      child: AnimatedBuilder(
        animation: _iconScales[i],
        builder: (context, _) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Transform.scale(
                scale: _iconScales[i].value,
                child: Icon(
                  selected ? item.activeIcon : item.icon,
                  size: isCompact ? 18 : 20,
                  color: selected ? NavTheme.navAccent : NavTheme.navInactive,
                ),
              ),
              const SizedBox(height: 2),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: isCompact ? 10 : 11,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected ? NavTheme.navAccent : NavTheme.navInactive,
                  letterSpacing: 0.1,
                ),
                child: Text(
                  item.label,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Data Model ────────────────────────────────────────────
class _NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  const _NavItem(
      {required this.label, required this.icon, required this.activeIcon});
}
