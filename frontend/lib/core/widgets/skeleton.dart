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
