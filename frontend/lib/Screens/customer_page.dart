import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:vego/Screens/add_customer.dart';
import 'package:vego/Screens/customer_hist.dart';
import 'package:vego/core/theme/app_colors.dart';
import 'package:vego/core/theme/app_scroll_behavior.dart';
import 'package:vego/core/widgets/error_view.dart';
import 'package:vego/core/widgets/paginated_list_view.dart';
import 'package:vego/core/widgets/skeleton.dart';
import 'package:vego/domain/models/customers.dart';
import 'package:vego/presentation/providers/viewmodel_provider.dart';

// ─── Design Tokens ────────────────────────────────────────────────────────────
class _C {
  static const bg = Color(0xFFF0F4FF);
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

  // Opens the Add Customer form, then refreshes the list so the new customer
  // shows without a manual pull-to-refresh.
  Future<void> _openAddCustomer() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddCustomerPage()),
    );
    if (result != null && mounted) _refresh();
  }

  // Full rupee amount with Indian grouping, e.g. ₹27,100 / ₹2,71,000.
  String _fullMoney(double v) =>
      '₹${NumberFormat.decimalPattern('en_IN').format(v)}';

  // Two-letter monogram for the avatar.
  String _initials(String? name) {
    if (name == null || name.trim().isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : parts[0][0].toUpperCase();
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
    final hasDues = (customer.pendingAmount ?? 0) > 0;
    final hasPhone = customer.phone != null && customer.phone!.isNotEmpty;
    final hasAddr = customer.address != null && customer.address!.isNotEmpty;

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
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.circular(16),
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
          borderRadius: BorderRadius.circular(16),
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
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 9, 6, 9),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Top: avatar + name/status + Due badge + menu ─────
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Avatar monogram
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: _C.indigoLight,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _C.indigo.withValues(alpha: 0.18),
                              width: 1.5,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _initials(customer.name),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: _C.indigo,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Name
                        Expanded(
                          child: Text(
                            customer.name ?? 'Unknown',
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              color: _C.slate900,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Due / Paid pill
                        _statusBadge(hasDues),
                        const SizedBox(width: 2),
                        _cardMenu(customer),
                      ],
                    ),

                    const SizedBox(height: 9),
                    Container(height: 1, color: _C.slate100),
                    const SizedBox(height: 9),

                    // ── Bottom: contact (left) + outstanding (right) ─────
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              if (hasPhone) ...[
                                const Icon(Icons.phone_rounded,
                                    size: 14, color: _C.slate500),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    customer.phone!,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: _C.slate700,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                              if (hasPhone && hasAddr)
                                const SizedBox(width: 16),
                              if (hasAddr) ...[
                                const Icon(Icons.location_on_rounded,
                                    size: 14, color: _C.slate500),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    customer.address!,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: _C.slate700,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Outstanding amount
                        Text(
                          hasDues
                              ? _fullMoney(customer.pendingAmount!)
                              : 'No dues',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: hasDues ? _C.error : _C.success,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Due / Paid pill shown at the top-right of the card.
  Widget _statusBadge(bool hasDues) {
    final color = hasDues ? _C.error : _C.success;
    final bg = hasDues ? _C.errorLight : _C.success.withValues(alpha: 0.12);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasDues
                ? Icons.error_outline_rounded
                : Icons.check_circle_outline_rounded,
            size: 13,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            hasDues ? 'Due' : 'Paid',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ── Three-dot Menu ───────────────────────────────────────────────────────────
  Widget _cardMenu(Customer customer) {
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      icon: const Icon(Icons.more_vert_rounded, color: _C.slate500, size: 20),
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
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  

                  // const SizedBox(height: 12),

                  // Search bar
                  Row(
                    children: [
                      Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          height: 44,
                          decoration: BoxDecoration(
                            color: _C.slate50,
                            borderRadius: BorderRadius.circular(12),
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
                            textCapitalization: TextCapitalization.words,
                            onChanged: (v) =>
                                setState(() => _query = v.toLowerCase().trim()),
                            textAlignVertical: TextAlignVertical.center,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                              color: _C.slate900,
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              hintText: 'Search name, phone or address…',
                              hintStyle: const TextStyle(
                                color: _C.slate500,
                                fontWeight: FontWeight.w400,
                                fontSize: 13.5,
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
                                        margin: const EdgeInsets.all(11),
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
                                horizontal: 12, vertical: 0,
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  
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
                    physics: kBouncyAlwaysScrollable,
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 110),
                    children: const [
                      CustomerCardSkeleton(),
                      CustomerCardSkeleton(),
                      CustomerCardSkeleton(),
                      CustomerCardSkeleton(),
                      CustomerCardSkeleton(),
                      CustomerCardSkeleton(),
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
                  return PaginatedListView<Customer>(
                    items: filtered,
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
                    onRefresh: () async => _refresh(),
                    resetToken: _query,
                    itemLabel: 'customers',
                    itemBuilder: (_, item, i) => _card(item, i),
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

