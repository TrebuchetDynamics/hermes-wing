import 'package:flutter/material.dart';

/// A pulsing list-shaped loading placeholder (ROADMAP 5.3).
///
/// Screen readers get [semanticLabel] instead of the decorative boxes, and
/// the pulse freezes when the platform asks for reduced motion.
class WingSkeletonList extends StatefulWidget {
  const WingSkeletonList({
    required this.semanticLabel,
    this.rows = 6,
    super.key,
  });

  final String semanticLabel;
  final int rows;

  @override
  State<WingSkeletonList> createState() => _WingSkeletonListState();
}

class _WingSkeletonListState extends State<WingSkeletonList>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    if (disableAnimations) {
      _pulse.stop();
      _pulse.value = 0.5;
    } else if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }

    return Semantics(
      key: const ValueKey('wing-skeleton-list'),
      label: widget.semanticLabel,
      child: ExcludeSemantics(
        child: FadeTransition(
          key: const ValueKey('wing-skeleton-pulse'),
          opacity: Tween(
            begin: 0.35,
            end: 0.75,
          ).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut)),
          child: ListView(
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (var i = 0; i < widget.rows; i++) WingSkeletonRow(index: i),
            ],
          ),
        ),
      ),
    );
  }
}

/// One placeholder row: an avatar circle plus two text bars whose widths
/// vary by [index] so the list reads as content, not stripes.
class WingSkeletonRow extends StatelessWidget {
  const WingSkeletonRow({required this.index, super.key});

  final int index;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    Widget bar(double widthFactor) => FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: widthFactor,
      child: Container(
        height: 12,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                bar([0.55, 0.7, 0.45][index % 3]),
                const SizedBox(height: 8),
                bar([0.85, 0.6, 0.75][index % 3]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
