import 'package:flutter/material.dart';

/// A muted, gently-animated placeholder block used while data is loading.
/// Drop-in replacement for `'...'` text or spinner placeholders — show one
/// (or a stack of them) where real content will appear.
class SkeletonBox extends StatefulWidget {
  final double? width;
  final double height;
  final BorderRadius? borderRadius;

  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = Curves.easeInOut.transform(_ctrl.value);
        final color = Color.lerp(
          const Color(0xFFE5E9F5),
          const Color(0xFFF1F3FA),
          t,
        )!;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: color,
            borderRadius:
                widget.borderRadius ?? BorderRadius.circular(6),
          ),
        );
      },
    );
  }
}

/// A card-shaped skeleton designed to mimic the shape of list items
/// (customer / driver / vehicle / trip cards). Use inside `ListView` while
/// the real list is loading so the page doesn't pop in jarringly.
class SkeletonListItem extends StatelessWidget {
  final bool hasTrailingLine;
  final double? width;

  const SkeletonListItem({
    super.key,
    this.hasTrailingLine = true,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonBox(width: 42, height: 42),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonBox(width: 140, height: 14),
                const SizedBox(height: 8),
                const SkeletonBox(width: 90, height: 11),
                if (hasTrailingLine) ...[
                  const SizedBox(height: 10),
                  const SkeletonBox(width: double.infinity, height: 1),
                  const SizedBox(height: 10),
                  Row(
                    children: const [
                      SkeletonBox(width: 60, height: 18),
                      SizedBox(width: 8),
                      SkeletonBox(width: 60, height: 18),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Shared hairline-border colour used by the card skeletons below so they
/// line up with the real cards' `Border.all`.
const Color _kSkeletonBorder = Color(0xFFE4E8F0);

/// Skeleton that mirrors `TripCard` (trips, customer/driver/vehicle history):
/// a header row (vehicle name + route, status pill on the right), a divider,
/// then a footer row (customer + date on the left, total amount on the right).
/// No leading avatar — the real card's avatar is currently disabled.
class TripCardSkeleton extends StatelessWidget {
  const TripCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kSkeletonBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: vehicle name + route  ·  status pill
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SkeletonBox(width: 130, height: 14),
                    SizedBox(height: 7),
                    SkeletonBox(width: 175, height: 11),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SkeletonBox(
                width: 60,
                height: 22,
                borderRadius: BorderRadius.circular(20),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const SkeletonBox(width: double.infinity, height: 1),
          const SizedBox(height: 10),
          // Footer: customer + date  ·  total
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SkeletonBox(width: 100, height: 12),
                    SizedBox(height: 6),
                    SkeletonBox(width: 130, height: 10),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SkeletonBox(width: 26, height: 8),
                  SizedBox(height: 5),
                  SkeletonBox(width: 52, height: 14),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Skeleton that mirrors the customer card: avatar monogram + name with a
/// status pill on top, a divider, then a contact line with a trailing amount.
class CustomerCardSkeleton extends StatelessWidget {
  const CustomerCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kSkeletonBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              SkeletonBox(
                width: 38,
                height: 38,
                borderRadius: BorderRadius.circular(19),
              ),
              const SizedBox(width: 10),
              const SkeletonBox(width: 150, height: 15),
              const Spacer(),
              SkeletonBox(
                width: 50,
                height: 22,
                borderRadius: BorderRadius.circular(20),
              ),
            ],
          ),
          const SizedBox(height: 9),
          const SkeletonBox(width: double.infinity, height: 1),
          const SizedBox(height: 9),
          const Row(
            children: [
              SkeletonBox(width: 160, height: 13),
              Spacer(),
              SkeletonBox(width: 54, height: 14),
            ],
          ),
        ],
      ),
    );
  }
}

/// A flexible single-row card skeleton for the simpler list cards — vehicles,
/// drivers, ledger rows, service records and deleted items. Tunable so each
/// page can match its real card's margin / padding / leading box / trailing
/// chip rather than all sharing one fixed shape.
class SimpleCardSkeleton extends StatelessWidget {
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  /// Side of the leading square/circle box. Null → no leading box.
  final double? leadingSize;
  final double leadingRadius;

  final double titleWidth;

  /// Width of the second line. Null → single-line title only.
  final double? subtitleWidth;

  /// Trailing chip (menu / badge / amount). Null → none.
  final double? trailingWidth;
  final double trailingHeight;
  final double trailingRadius;

  const SimpleCardSkeleton({
    super.key,
    this.margin = const EdgeInsets.only(bottom: 8),
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    this.borderRadius = 16,
    this.leadingSize,
    this.leadingRadius = 11,
    this.titleWidth = 130,
    this.subtitleWidth = 90,
    this.trailingWidth,
    this.trailingHeight = 22,
    this.trailingRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: _kSkeletonBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (leadingSize != null) ...[
            SkeletonBox(
              width: leadingSize,
              height: leadingSize!,
              borderRadius: BorderRadius.circular(leadingRadius),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SkeletonBox(width: titleWidth, height: 13),
                if (subtitleWidth != null) ...[
                  const SizedBox(height: 7),
                  SkeletonBox(width: subtitleWidth, height: 11),
                ],
              ],
            ),
          ),
          if (trailingWidth != null) ...[
            const SizedBox(width: 8),
            SkeletonBox(
              width: trailingWidth,
              height: trailingHeight,
              borderRadius: BorderRadius.circular(trailingRadius),
            ),
          ],
        ],
      ),
    );
  }
}

/// Builds N `SkeletonListItem`s wrapped in a non-scrollable column. Use
/// inside a `RefreshIndicator` + scroll view as the loading state.
class SkeletonList extends StatelessWidget {
  final int itemCount;
  final bool hasTrailingLine;

  const SkeletonList({
    super.key,
    this.itemCount = 5,
    this.hasTrailingLine = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        itemCount,
        (_) => SkeletonListItem(hasTrailingLine: hasTrailingLine),
      ),
    );
  }
}
