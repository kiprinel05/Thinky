import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:thinky/shared_controls/theme/app_colors_extension.dart';

/// Base shimmer wrapper that applies the standard shimmer animation.
/// Wrap any placeholder layout in this widget.
class ShimmerBlock extends StatelessWidget {
  final Widget child;

  const ShimmerBlock({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Shimmer.fromColors(
      baseColor: colors.shimmer,
      highlightColor: colors.surface,
      child: child,
    );
  }
}

/// A single rectangular shimmer placeholder.
class ShimmerRect extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerRect({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// A circular shimmer placeholder.
class ShimmerCircle extends StatelessWidget {
  final double size;

  const ShimmerCircle({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
    );
  }
}
