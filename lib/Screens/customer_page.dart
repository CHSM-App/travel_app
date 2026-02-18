import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_agency_app/Screens/add_customer.dart';
import 'package:travel_agency_app/Screens/customer_hist.dart';
import 'package:travel_agency_app/domain/models/customers.dart';
import 'package:travel_agency_app/presentation/providers/viewmodel_provider.dart';

// ─── Design Tokens ────────────────────────────────────────────────────────────
class _C {
  static const bg = Color(0xFFF5F4F1);
  static const surface = Color(0xFFFFFFFF);
  static const slate900 = Color(0xFF1C1917);
  static const slate700 = Color(0xFF44403C);
  static const slate500 = Color(0xFF78716C);
  static const slate300 = Color(0xFFD6D3D1);
  static const slate100 = Color(0xFFF5F4F1);
  static const violet = Color(0xFF7C3AED);
  static const violetLight = Color(0xFFEDE9FE);
  static const violetDark = Color(0xFF5B21B6);
  static const amber = Color(0xFFE8A020);
  static const amberLight = Color(0xFFFFF3D6);
  static const error = Color(0xFFDC2626);
  static const errorLight = Color(0xFFFEE2E2);
  static const success = Color(0xFF059669);
}

// Avatar palette — cycles for visual variety
const _avatarPairs = [
  [Color(0xFFEDE9FE), Color.fromARGB(255, 63, 81, 181)], // violet
];

// ─────────────────────────────────────────────────────────────────────────────

class CustomerListPage extends ConsumerStatefulWidget {
  const CustomerListPage({super.key});

  @override
  ConsumerState<CustomerListPage> createState() => _CustomerListPageState();
}

class _CustomerListPageState extends ConsumerState<CustomerListPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  // ── Lifecycle ────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(customerViewModelProvider.notifier).fetchCustomerslist(),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────
  void _refresh() =>
      ref.read(customerViewModelProvider.notifier).fetchCustomerslist();

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
    final pair = _avatarPairs[index % _avatarPairs.length];
    final bgCol = pair[0];
    final fgCol = pair[1];

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 280 + index * 50),
      curve: Curves.easeOutCubic,
      builder: (ctx, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(0, 18 * (1 - v)),
          child: child,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _C.slate300.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: _C.slate900.withOpacity(0.05),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            splashColor: _C.violetLight,
            highlightColor: _C.violetLight.withOpacity(0.4),

            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => CustomerHist(customer: customer)),
            ),
            child: Stack(
              children: [
                // Main Content
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 48, 16),
                  // 🔥 important: right padding 48 to avoid overlap with menu
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: bgCol,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: fgCol.withOpacity(0.25),
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            _initials(customer.name),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: fgCol,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 14),

                      // Info Section
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              customer.name ?? 'Unknown',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: _C.slate900,
                              ),
                            ),
                            const SizedBox(height: 6),

                            if (customer.phone != null &&
                                customer.phone!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.phone_rounded,
                                      size: 13,
                                      color: _C.slate500,
                                    ),

                                    const SizedBox(width: 5),
                                    Text(
                                      customer.phone!,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: _C.slate500,
                                      ),
                                    ),

                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.location_on_rounded,
                                      size: 13,
                                      color: _C.slate500,
                                    ),
                                    Text(
                                      customer.address!,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: _C.slate500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            // if (customer.address != null &&
                            //     customer.address!.isNotEmpty)
                            //   Row(
                            //     children: [
                            //       const Icon(Icons.location_on_rounded,
                            //           size: 13, color: _C.slate500),
                            //       const SizedBox(width: 5),
                            //       Expanded(
                            //         child: Text(
                            //           customer.address!,
                            //           style: const TextStyle(
                            //             fontSize: 13,
                            //             color: _C.slate500,
                            //             fontWeight: FontWeight.w500,
                            //           ),
                            //           overflow: TextOverflow.ellipsis,
                            //         ),
                            //       ),
                            //     ],
                            //   ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // 🔥 Top Right Menu
                Positioned(top: 8, right: 8, child: _cardMenu(customer)),
              ],
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
        ),
        child: const Icon(
          Icons.more_vert_rounded,
          color: _C.slate500,
          size: 18,
        ),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 8,
      color: _C.surface,
      onSelected: (val) {
        switch (val) {
          case 'view':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CustomerHist(customer: customer),
              ),
            );
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
        _menuItem(
          'view',
          Icons.history_rounded,
          'View History',
          _C.violetLight,
          _C.violet,
        ),
        const PopupMenuDivider(height: 0),
        _menuItem('edit', Icons.edit_rounded, 'Edit', _C.amberLight, _C.amber),
        const PopupMenuDivider(height: 0),
        _menuItem(
          'delete',
          Icons.delete_rounded,
          'Delete',
          _C.errorLight,
          _C.error,
          textColor: _C.error,
        ),
      ],
    );
  }

  PopupMenuItem<String> _menuItem(
    String value,
    IconData icon,
    String label,
    Color iconBg,
    Color iconColor, {
    Color textColor = _C.slate700,
  }) {
    return PopupMenuItem(
      value: value,
      height: 46,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 15, color: iconColor),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  // ── Actions ──────────────────────────────────────────────────────────────────
  void _editCustomer(Customer customer) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddCustomerPage(isEdit: true, customer: customer),
      ),
    );
    if (result != null && mounted) _refresh();
  }

  void _deleteCustomer(Customer customer) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: _C.errorLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_remove_rounded,
                  color: _C.error,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Delete Customer',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _C.slate900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Are you sure you want to delete "${customer.name}"?\nThis cannot be undone.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: _C.slate500,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: const BorderSide(color: _C.slate300),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _C.slate700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        // TODO: call delete API
                        // ref.read(customerViewModelProvider.notifier)
                        //    .deleteCustomer(customer.customerId!);
                        _refresh();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Row(
                                children: [
                                  Icon(
                                    Icons.check_circle_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  SizedBox(width: 10),
                                  Text('Customer deleted'),
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
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: _C.error,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Delete',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
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
            width: 100,
            height: 100,
            decoration: const BoxDecoration(
              color: _C.violetLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.people_rounded,
              size: 48,
              color: _C.violetDark,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            !hasData ? 'No customers yet' : 'No results found',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _C.slate900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            !hasData
                ? 'Tap the button below to add\nyour first customer'
                : 'Try searching by name,\nphone or address',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: _C.slate500,
              height: 1.6,
            ),
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
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Container(
              color: _C.surface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (v) =>
                          setState(() => _query = v.toLowerCase()),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: _C.slate900,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search by name, phone or address...',
                        hintStyle: const TextStyle(
                          color: _C.slate500,
                          fontWeight: FontWeight.w400,
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: _C.slate500,
                          size: 20,
                        ),
                        suffixIcon: _query.isNotEmpty
                            ? GestureDetector(
                                onTap: () {
                                  _searchCtrl.clear();
                                  setState(() => _query = '');
                                },
                                child: const Icon(
                                  Icons.close_rounded,
                                  color: _C.slate500,
                                  size: 18,
                                ),
                              )
                            : null,
                        filled: true,
                        fillColor: _C.slate100,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: _C.slate300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: _C.violet,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ),

                  Container(height: 1, color: _C.slate300.withOpacity(0.4)),
                ],
              ),
            ),

            // ── List ────────────────────────────────────────────────────────
            Expanded(
              child: state.CustomerList.when(
                // Loading
                loading: () => const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 44,
                        height: 44,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          strokeCap: StrokeCap.round,
                          color: _C.violet,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Loading customers...',
                        style: TextStyle(
                          color: _C.slate500,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Error
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: const BoxDecoration(
                            color: _C.errorLight,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.wifi_off_rounded,
                            size: 40,
                            color: _C.error,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Something went wrong',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: _C.slate900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          e.toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            color: _C.slate500,
                          ),
                        ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: _refresh,
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text('Retry'),
                          style: FilledButton.styleFrom(
                            backgroundColor: _C.violet,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Data
                data: (customers) {
                  final filtered = _applyFilter(customers);

                  if (filtered.isEmpty) {
                    return _emptyState(hasData: customers.isNotEmpty);
                  }

                  return RefreshIndicator(
                    color: _C.violet,
                    onRefresh: () async => _refresh(),
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) => _card(filtered[i], i),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),

      // ── FAB ─────────────────────────────────────────────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddCustomerPage()),
          );
          if (result != null && mounted) _refresh();
        },
        backgroundColor: Color.fromARGB(255, 63, 81, 181),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        icon: const Icon(
          Icons.person_add_rounded,
          color: Colors.white,
          size: 20,
        ),
        label: const Text(
          'Add Customer',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 15,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}
