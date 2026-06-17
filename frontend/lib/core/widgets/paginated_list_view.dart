import 'package:flutter/material.dart';
import 'package:travel_agency_app/core/theme/app_colors.dart';
import 'package:travel_agency_app/core/theme/app_scroll_behavior.dart';

/// A drop-in replacement for `ListView.builder` that renders a long list one
/// page at a time and reveals the next page as the user scrolls near the bottom
/// (client-side "infinite scroll").
///
/// The full [items] list still lives in memory — this only windows what gets
/// *built*, which keeps scrolling smooth when a list has hundreds of rows. It
/// also inherits the app's iOS bounce physics ([kBouncyAlwaysScrollable]).
///
/// Pass a [resetToken] (e.g. the current search query, or a tab id) that
/// changes whenever the underlying data is re-filtered — the window then snaps
/// back to the first page so fresh results aren't hidden below an old scroll
/// position. Wrap with pull-to-refresh by supplying [onRefresh].
class PaginatedListView<T> extends StatefulWidget {
  const PaginatedListView({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.pageSize = 20,
    this.padding,
    this.onRefresh,
    this.resetToken,
    this.controller,
    this.accentColor = AppColors.brandPrimary,
    this.itemLabel = 'items',
  });

  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;

  /// How many rows to reveal per page.
  final int pageSize;
  final EdgeInsetsGeometry? padding;

  /// When non-null the list is wrapped in a [RefreshIndicator].
  final Future<void> Function()? onRefresh;

  /// Changing this value resets the window to the first page (e.g. on search).
  final Object? resetToken;

  /// Optional external controller. If omitted, an internal one is used.
  final ScrollController? controller;

  final Color accentColor;

  /// Plural noun shown in the footer, e.g. "Showing 20 of 200 drivers".
  final String itemLabel;

  @override
  State<PaginatedListView<T>> createState() => _PaginatedListViewState<T>();
}

class _PaginatedListViewState<T> extends State<PaginatedListView<T>> {
  late final ScrollController _controller =
      widget.controller ?? ScrollController();
  bool _ownsController = false;
  late int _visible = widget.pageSize;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant PaginatedListView<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A new filter/tab/query → start from the first page again.
    if (oldWidget.resetToken != widget.resetToken) {
      _visible = widget.pageSize;
    }
    // Keep the window within the (possibly shrunken) list bounds.
    if (_visible > widget.items.length && widget.items.isNotEmpty) {
      _visible = ((widget.items.length / widget.pageSize).ceil())
          .clamp(1, 1 << 30) * widget.pageSize;
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_controller.hasClients) return;
    final pos = _controller.position;
    if (pos.pixels >= pos.maxScrollExtent - 300) _revealMore();
  }

  void _revealMore() {
    if (_visible >= widget.items.length) return;
    setState(() {
      _visible = (_visible + widget.pageSize).clamp(0, widget.items.length);
    });
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.items.length;
    final visible = _visible.clamp(0, total);
    final hasMore = visible < total;

    final list = ListView.builder(
      controller: _controller,
      physics: kBouncyAlwaysScrollable,
      padding: widget.padding,
      // One extra slot for the load-more footer.
      itemCount: visible + (hasMore ? 1 : 0),
      itemBuilder: (context, i) {
        if (i >= visible) return _loadMore(visible, total);
        return widget.itemBuilder(context, widget.items[i], i);
      },
    );

    if (widget.onRefresh == null) return list;
    return RefreshIndicator(
      onRefresh: widget.onRefresh!,
      color: widget.accentColor,
      child: list,
    );
  }

  Widget _loadMore(int shown, int total) {
    return GestureDetector(
      onTap: _revealMore,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                valueColor: AlwaysStoppedAnimation(widget.accentColor),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Showing $shown of $total ${widget.itemLabel}',
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF7B82A0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
