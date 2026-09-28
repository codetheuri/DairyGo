import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../layout/breakpoints.dart';

/// Placeholders shaped like the content that is loading. They make a slow
/// load feel faster than a spinner and keep the layout from jumping when the
/// data arrives. They pulse gently, and stay still when the phone asks for
/// reduced motion.
class SkeletonPulse extends StatefulWidget {
  final Widget child;

  const SkeletonPulse({super.key, required this.child});

  @override
  State<SkeletonPulse> createState() => _SkeletonPulseState();
}

class _SkeletonPulseState extends State<SkeletonPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
    lowerBound: 0.45,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading',
      child: ExcludeSemantics(
        child: FadeTransition(opacity: _controller, child: widget.child),
      ),
    );
  }
}

/// One grey placeholder block.
class Bone extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;

  const Bone({super.key, this.width, this.height = 12, this.radius = 6});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.cardBorder,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// A list of placeholder rows (avatar, two lines, trailing figure), for any
/// list screen or picker.
class ListSkeleton extends StatelessWidget {
  final int rows;

  const ListSkeleton({super.key, this.rows = 8});

  @override
  Widget build(BuildContext context) {
    return SkeletonPulse(
      // Sizes to its rows, so it also works inside a column or sheet.
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: rows,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            children: [
              const Bone(width: 40, height: 40, radius: 20),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Varying widths look like real names.
                    FractionallySizedBox(
                      widthFactor: const [0.7, 0.5, 0.6][i % 3],
                      child: const Bone(height: 14),
                    ),
                    const SizedBox(height: 8),
                    const FractionallySizedBox(
                      widthFactor: 0.4,
                      child: Bone(height: 10),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              const Bone(width: 56, height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

/// A dashboard placeholder: a header card and a grid of figure cards.
class DashboardSkeleton extends StatelessWidget {
  final int cards;

  const DashboardSkeleton({super.key, this.cards = 4});

  @override
  Widget build(BuildContext context) {
    Widget card() => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FractionallySizedBox(widthFactor: 0.6, child: Bone()),
          SizedBox(height: 16),
          FractionallySizedBox(widthFactor: 0.8, child: Bone(height: 22)),
          SizedBox(height: 10),
          FractionallySizedBox(widthFactor: 0.5, child: Bone(height: 10)),
        ],
      ),
    );

    return SkeletonPulse(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Bone(height: 150, radius: 20),
            const SizedBox(height: 24),
            const FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: 0.5,
              child: Bone(height: 16),
            ),
            const SizedBox(height: 12),
            ResponsiveGrid(
              minItemWidth: 160,
              minColumns: 1,
              children: [for (var i = 0; i < cards; i++) card()],
            ),
          ],
        ),
      ),
    );
  }
}
