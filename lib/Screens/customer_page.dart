import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_agency_app/Screens/add_customer.dart';
import 'package:travel_agency_app/Screens/customer_hist.dart';
import 'package:travel_agency_app/Screens/customer_report.dart';
import 'package:travel_agency_app/core/theme/app_colors.dart';
import 'package:travel_agency_app/core/widgets/error_view.dart';
import 'package:travel_agency_app/core/widgets/skeleton.dart';
import 'package:travel_agency_app/domain/models/customers.dart';
import 'package:travel_agency_app/presentation/providers/viewmodel_provider.dart';

// ─── Design Tokens ────────────────────────────────────────────────────────────
class _C {
  static const bg = Color(0xFFF4F6FB);
  static const surface = Color(0xFFFFFFFF);
  static const slate900 = Color(0xFF0F172A);
  static const slate700 = Color(0xFF334155);
  static const slate500 = Color(0xFF64748B);
  static const slate300 = Color(0xFFCBD5E1);
  static const slate100 = Color(0xFFF1F5F9);
  static const slate50 = Color(0xFFF8FAFC);

  static const indigo = AppColors.brandPrimary;
  static const indigoLight = AppColors.brandSoft;

  static const amber = Color(0xFFF59E0B);
  static const amberLight = Color(0xFFFFFBEB);
  static const error = Color(0xFFEF4444);
  static const errorLight = Color(0xFFFEF2F2);
  static const success = Color(0xFF10B981);

}

// ─────────────────────────────────────────────────────────────────────────────

class CustomerListPage extends ConsumerStatefulWidget {
  const CustomerListPage({super.key});

  @override
  ConsumerState<CustomerListPage> createState() => _CustomerListPageState();
}

class _CustomerListPageState extends ConsumerState<CustomerListPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  String _query = '';
  bool _searchFocused = false;

  @override
  void initState() {
    super.initState();
    _searchFocus.addListener(() {
      setState(() => _searchFocused = _searchFocus.hasFocus);
    });
    Future.microtask(() async {
      await ref.read(loginViewModelProvider.notifier).loadFromStorage();
      final agencyId = ref.read(loginViewModelProvider).agencyId ?? '';
      if (agencyId.trim().isNotEmpty) {
        ref.read(customerViewModelProvider.notifier).fetchCustomerslist(agencyId);
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _refresh() {
    final agencyId = ref.read(loginViewModelProvider).agencyId ?? '';
    if (agencyId.trim().isEmpty) return;
    ref.read(customerViewModelProvider.notifier).fetchCustomerslist(agencyId);
  }

  /// Gradient "Report" pill shown beside the search bar — mirrors the button in
  /// vehicle_page.dart. Opens the customer-wise report screen. Sized to match
  /// the search bar's height so the row stays aligned.
  Widget _reportButton() {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CustomerReportPage()),
      ),
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: _C.amber,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: _C.amber.withValues(alpha: 0.45),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.insights_rounded, color: Colors.white, size: 18),
            SizedBox(width: 6),
            Text(
              'Report',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Opens the Add Customer form, then refreshes the list so the new customer
  // shows without a manual pull-to-refresh.
  Future<void> _openAddCustomer() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddCustomerPage()),
    );
    if (result != null && mounted) _refresh();
  }

  // Compact rupee label: ₹1.2L / ₹45.0K / ₹850. Keeps long balances from
  // blowing out the card width.
  String _money(double v) {
    if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '₹${(v / 1000).toStringAsFixed(1)}K';
    return '₹${v.toStringAsFixed(0)}';
  }

  String _initials(String? name) {
    if (name == null || name.trim().isEmpty) return '?';
    final parts = name.trim().split(' ');
    return parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : name[0].toUpperCase();
  }

  List<Customer> _applyFilter(List<Customer> list) {
    if (_query.isEmpty) return list;
    return list.where((c) {
      final name = c.name?.toLowerCase() ?? '';
      final phone = c.phone?.toLowerCase() ?? '';
      final address = c.address?.toLowerCase() ?? '';
      return name.contains(_query) ||
          phone.contains(_query) ||
          address.contains(_query);
    }).toList();
  }

  // ── Customer Card ────────────────────────────────────────────────────────────
  Widget _card(Customer customer, int index) {
    const bgCol = _C.indigoLight;
    const fgCol = _C.indigo;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 250 + index * 45),
      curve: Curves.easeOutCubic,
      builder: (ctx, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(0, 16 * (1 - v)),
          child: child,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _C.slate300.withValues(alpha: 0.45), width: 1),
          boxShadow: [
            BoxShadow(
              color: _C.indigo.withValues(alpha: 0.06),
              blurRadius: 18,
              offset: const Offset(0, 5),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              splashColor: _C.indigoLight,
              highlightColor: _C.indigoLight.withValues(alpha: 0.5),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => CustomerHist(customer: customer)),
              ),
              child: Stack(
                children: [
                  // Left color accent bar
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 4,
                      decoration: BoxDecoration(
                        color: fgCol,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(18),
                          bottomLeft: Radius.circular(18),
                        ),
                      ),
                    ),
                  ),

                  // Main content
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 50, 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [

                        // Avatar
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: bgCol,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: fgCol.withValues(alpha: 0.2),
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              _initials(customer.name),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: fgCol,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 13),

                        // Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                customer.name ?? 'Unknown',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: _C.slate900,
                                  letterSpacing: -0.3,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 5),
                              // Chips flow left-to-right and wrap onto the next
                              // line when they don't fit, so the pending badge
                              // sits beside the address but never overflows on
                              // narrow screens / long addresses.
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  if (customer.phone != null &&
                                      customer.phone!.isNotEmpty)
                                    _InfoChip(
                                      icon: Icons.phone_rounded,
                                      label: customer.phone!,
                                      iconColor: _C.indigo,
                                      bgColor: _C.indigoLight,
                                    ),
                                  if (customer.address != null &&
                                      customer.address!.isNotEmpty)
                                    _InfoChip(
                                      icon: Icons.location_on_rounded,
                                      label: customer.address!,
                                      iconColor: _C.slate500,
                                      bgColor: _C.slate100,
                                      maxWidth: 200,
                                      ellipsis: true,
                                    ),
                                  // Outstanding balance — only when the customer
                                  // owes money.
                                  if ((customer.pendingAmount ?? 0) > 0)
                                    _InfoChip(
                                      icon: Icons.account_balance_wallet_rounded,
                                      label:
                                          'Pending ${_money(customer.pendingAmount!)}',
                                      iconColor: _C.error,
                                      bgColor: _C.errorLight,
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Three-dot menu
                  Positioned(top: 8, right: 6, child: _cardMenu(customer)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Three-dot Menu ───────────────────────────────────────────────────────────
  Widget _cardMenu(Customer customer) {
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      icon: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: _C.slate100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _C.slate300.withValues(alpha: 0.5)),
        ),
        child: const Icon(Icons.more_vert_rounded, color: _C.slate500, size: 17),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 12,
      shadowColor: Colors.black.withValues(alpha: 0.15),
      color: _C.surface,
      onSelected: (val) {
        switch (val) {
          case 'view':
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => CustomerHist(customer: customer)));
            break;
          case 'edit':
            _editCustomer(customer);
            break;
          case 'delete':
            _deleteCustomer(customer);
            break;
        }
      },
      itemBuilder: (ctx) => [
        // _menuItem('view', Icons.history_rounded, 'View History',
        //     _C.indigoLight, _C.indigo),
        // const PopupMenuDivider(height: 0),
        _menuItem('edit', Icons.edit_rounded, 'Edit',
            _C.amberLight, _C.amber),
        // const PopupMenuDivider(height: 0),
        _menuItem('delete', Icons.delete_rounded, 'Delete',
            _C.errorLight, _C.error, textColor: _C.error),
      ],
    );
  }

  PopupMenuItem<String> _menuItem(
    String value, IconData icon, String label,
    Color iconBg, Color iconColor, {Color textColor = _C.slate700}) {
    return PopupMenuItem(
      value: value,
      height: 48,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 15, color: iconColor),
          ),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w600, color: textColor,
          )),
        ],
      ),
    );
  }

  // ── Actions ──────────────────────────────────────────────────────────────────
  void _editCustomer(Customer customer) async {
    final result = await Navigator.push(context,
        MaterialPageRoute(builder: (_) => AddCustomerPage(isEdit: true, customer: customer)));
    if (result != null && mounted) _refresh();
  }

  void _deleteCustomer(Customer customer) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        backgroundColor: _C.surface,

        
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: const BoxDecoration(
                  color: _C.errorLight, shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_remove_rounded,
                    color: _C.error, size: 30),
              ),
              const SizedBox(height: 16),
              const Text('Delete Customer', style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w800, color: _C.slate900,
              )),
              const SizedBox(height: 8),
              Text(
                'Are you sure you want to delete "${customer.name}"?\nThis action cannot be undone.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: _C.slate500, height: 1.6),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        side: const BorderSide(color: _C.slate300),
                      ),
                      child: const Text('Cancel', style: TextStyle(
                          fontWeight: FontWeight.w600, color: _C.slate700)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        final result = await ref
                            .read(customerViewModelProvider.notifier)
                            .deleteCustomer(customer.customerId ?? 0);

                        if (!mounted) return;

                        if (result['success'] == true) {
                          _refresh();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    result['message']?.toString() ??
                                        'Customer deleted',
                                  ),
                                ],
                              ),
                              backgroundColor: _C.success,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              margin: const EdgeInsets.all(16),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                result['message']?.toString() ??
                                    ref.read(customerViewModelProvider).error ??
                                    'Delete failed',
                              ),
                              backgroundColor: _C.error,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              margin: const EdgeInsets.all(16),
                            ),
                          );
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: _C.error,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Delete',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Empty State ──────────────────────────────────────────────────────────────
  Widget _emptyState({required bool hasData}) => Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: const BoxDecoration(
              color: _C.indigoLight, shape: BoxShape.circle,
            ),
            child: const Icon(Icons.people_rounded, size: 44, color: _C.indigo),
          ),
          const SizedBox(height: 22),
          Text(
            !hasData ? 'No customers yet' : 'No results found',
            style: const TextStyle(
              fontSize: 19, fontWeight: FontWeight.w800,
              color: _C.slate900, letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            !hasData
                ? 'Tap the button below to add\nyour first customer'
                : 'Try searching by name,\nphone or address',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: _C.slate500, height: 1.6),
          ),
        ],
      ),
    ),
  );

  // ── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(customerViewModelProvider);

    return Scaffold(
      backgroundColor: _C.bg,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
          children: [

            // ── Header ──────────────────────────────────────────────────────
            Container(
              color: _C.surface,
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  

                  const SizedBox(height: 12),

                  // Search bar + roster Report button
                  Row(
                    children: [
                      Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: _C.slate50,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _searchFocused
                                  ? _C.indigo
                                  : _C.slate300.withValues(alpha: 0.7),
                              width: _searchFocused ? 1.5 : 1,
                            ),
                            boxShadow: _searchFocused
                                ? [BoxShadow(
                                    color: _C.indigo.withValues(alpha: 0.12),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  )]
                                : [],
                          ),
                          child: TextField(
                            controller: _searchCtrl,
                            focusNode: _searchFocus,
                            onChanged: (v) =>
                                setState(() => _query = v.toLowerCase().trim()),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: _C.slate900,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Search name, phone or address…',
                              hintStyle: const TextStyle(
                                color: _C.slate500,
                                fontWeight: FontWeight.w400,
                                fontSize: 14,
                              ),
                              prefixIcon: Icon(
                                Icons.search_rounded,
                                color: _searchFocused ? _C.indigo : _C.slate500,
                                size: 20,
                              ),
                              suffixIcon: _query.isNotEmpty
                                  ? GestureDetector(
                                      onTap: () {
                                        _searchCtrl.clear();
                                        setState(() => _query = '');
                                      },
                                      child: Container(
                                        margin: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: _C.slate300
                                              .withValues(alpha: 0.5),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.close_rounded,
                                            color: _C.slate700, size: 14),
                                      ),
                                    )
                                  : null,
                              filled: false,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14,
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _reportButton(),
                    ],
                  ),

                  const SizedBox(height: 14),
                ],
              ),
            ),

            // ── List ────────────────────────────────────────────────────────
            Expanded(
              child: state.customerList.when(
                loading: () => RefreshIndicator(
                  onRefresh: () async => _refresh(),
                  color: _C.indigo,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(0, 8, 0, 110),
                    children: const [
                      SkeletonListItem(hasTrailingLine: false),
                      SkeletonListItem(hasTrailingLine: false),
                      SkeletonListItem(hasTrailingLine: false),
                      SkeletonListItem(hasTrailingLine: false),
                      SkeletonListItem(hasTrailingLine: false),
                      SkeletonListItem(hasTrailingLine: false),
                    ],
                  ),
                ),

                error: (e, _) =>
                    NetworkErrorView(error: e, onRetry: () async => _refresh()),

                data: (customers) {
                  final filtered = _applyFilter(customers);
                  if (filtered.isEmpty) {
                    return _emptyState(hasData: customers.isNotEmpty);
                  }
                  return RefreshIndicator(
                    color: _C.indigo,
                    onRefresh: () async => _refresh(),
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) => _card(filtered[i], i),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
            // Plain circular "+" FAB — adds a customer. Lifted to clear the
            // floating pill nav.
            Positioned(
              right: 20,
              bottom: 90,
              child: FloatingActionButton(
                heroTag: 'customerAddFab',
                onPressed: _openAddCustomer,
                backgroundColor: _C.indigo,
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

      // ── FAB ─────────────────────────────────────────────────────────────────
      // floatingActionButton: FloatingActionButton.extended(
      //   onPressed: () async {
      //     final result = await Navigator.push(context,
      //         MaterialPageRoute(builder: (_) => const AddCustomerPage()));
      //     if (result != null && mounted) _refresh();
      //   },
      //   backgroundColor: _C.indigo,
      //   elevation: 0,
      //   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      //   icon: const Icon(Icons.person_add_rounded, color: Colors.white, size: 20),
      //   label: const Text(
      //     'Add Customer',
      //     style: TextStyle(
      //       color: Colors.white, fontWeight: FontWeight.w700,
      //       fontSize: 14, letterSpacing: 0.2,
      //     ),
      //   ),
      // ),
    );
  }
}

// ─── Info Chip Widget ─────────────────────────────────────────────────────────
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final Color bgColor;
  final double maxWidth;
  final bool ellipsis;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.bgColor,
    this.maxWidth = 120,
    this.ellipsis = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      constraints: BoxConstraints(maxWidth: maxWidth),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: iconColor),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: iconColor,
              ),
              overflow: ellipsis ? TextOverflow.ellipsis : null,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}
