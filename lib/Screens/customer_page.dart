import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_agency_app/Screens/add_customer.dart';
import 'package:travel_agency_app/Screens/customer_hist.dart';
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

  static const indigo = Color(0xFF4F6FE8);
  static const indigoLight = Color(0xFFEEF2FF);

  static const amber = Color(0xFFF59E0B);
  static const amberLight = Color(0xFFFFFBEB);
  static const error = Color(0xFFEF4444);
  static const errorLight = Color(0xFFFEF2F2);
  static const success = Color(0xFF10B981);

}

// Avatar color cycles
const _avatarPalette = [
  [Color(0xFFEEF2FF), Color(0xFF4F6FE8)],

];

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
    final pair = _avatarPalette[index % _avatarPalette.length];
    final bgCol = pair[0];
    final fgCol = pair[1];

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
          border: Border.all(color: _C.slate300.withOpacity(0.45), width: 1),
          boxShadow: [
            BoxShadow(
              color: _C.indigo.withOpacity(0.06),
              blurRadius: 18,
              offset: const Offset(0, 5),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
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
              highlightColor: _C.indigoLight.withOpacity(0.5),
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
                              color: fgCol.withOpacity(0.2),
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
                              Row(
                                children: [
                                  if (customer.phone != null &&
                                      customer.phone!.isNotEmpty) ...[
                                    _InfoChip(
                                      icon: Icons.phone_rounded,
                                      label: customer.phone!,
                                      iconColor: _C.indigo,
                                      bgColor: _C.indigoLight,
                                    ),
                                    const SizedBox(width: 6),
                                  ],
                                  if (customer.address != null &&
                                      customer.address!.isNotEmpty)
                                    Flexible(
                                      child: _InfoChip(
                                        icon: Icons.location_on_rounded,
                                        label: customer.address!,
                                        iconColor: _C.slate500,
                                        bgColor: _C.slate100,
                                        maxWidth: double.infinity,
                                        ellipsis: true,
                                      ),
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
          border: Border.all(color: _C.slate300.withOpacity(0.5)),
        ),
        child: const Icon(Icons.more_vert_rounded, color: _C.slate500, size: 17),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 12,
      shadowColor: Colors.black.withOpacity(0.15),
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
        _menuItem('view', Icons.history_rounded, 'View History',
            _C.indigoLight, _C.indigo),
        const PopupMenuDivider(height: 0),
        _menuItem('edit', Icons.edit_rounded, 'Edit',
            _C.amberLight, _C.amber),
        const PopupMenuDivider(height: 0),
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
        child: Column(
          children: [

            // ── Header ──────────────────────────────────────────────────────
            Container(
              color: _C.surface,
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Title row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        
                            const SizedBox(height: 2),
                            // Live count badge
                            // state.CustomerList.maybeWhen(
                              // data: (list) {
                              //   final filtered = _applyFilter(list);
                              //   // return Text(
                              //   //   _query.isNotEmpty
                              //   //       ? '${filtered.length} of ${list.length} customers'
                              //   //       : '${list.length} customers total',
                              //   //   style: const TextStyle(
                              //   //     fontSize: 12,
                              //   //     color: _C.slate500,
                              //   //     fontWeight: FontWeight.w500,
                              //   //   ),
                              //   // );
                              // },
                              // orElse: () => const SizedBox.shrink(),
                            // ),
                          ],
                        ),
                      ),

                   
                
                    ],
                  ),

                  // const SizedBox(height: 12),

                  // Search bar
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: _C.slate50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _searchFocused
                            ? _C.indigo
                            : _C.slate300.withOpacity(0.7),
                        width: _searchFocused ? 1.5 : 1,
                      ),
                      boxShadow: _searchFocused
                          ? [BoxShadow(
                              color: _C.indigo.withOpacity(0.12),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            )]
                          : [],
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      focusNode: _searchFocus,
                      onChanged: (v) =>
                          setState(() => _query = v.toLowerCase()),
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
                                    color: _C.slate300.withOpacity(0.5),
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

                  const SizedBox(height: 14),
                ],
              ),
            ),

            // ── List ────────────────────────────────────────────────────────
            Expanded(
              child: state.CustomerList.when(
                loading: () => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 42,
                        height: 42,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          strokeCap: StrokeCap.round,
                          color: _C.indigo,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Loading customers…',
                        style: TextStyle(
                          color: _C.slate500, fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: const BoxDecoration(
                            color: _C.errorLight, shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.wifi_off_rounded,
                              size: 36, color: _C.error),
                        ),
                        const SizedBox(height: 20),
                        const Text('Something went wrong',
                          style: TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w800,
                            color: _C.slate900,
                          )),
                        const SizedBox(height: 8),
                        Text(e.toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13, color: _C.slate500,
                          )),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: _refresh,
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text('Retry'),
                          style: FilledButton.styleFrom(
                            backgroundColor: _C.indigo,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

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
