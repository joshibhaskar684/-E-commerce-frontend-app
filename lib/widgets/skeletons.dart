import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Grey shimmering placeholder (the website uses "skeleton" cards too).
class ShimmerBox extends StatelessWidget {
  const ShimmerBox({super.key, this.width, this.height, this.radius = 0});

  final double? width;
  final double? height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Shimmer.fromColors(
      baseColor: scheme.surfaceContainerHigh,
      highlightColor: scheme.surfaceContainerLow,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(color: scheme.surfaceContainerHigh, borderRadius: BorderRadius.circular(radius)),
      ),
    );
  }
}

class ProductCardSkeleton extends StatelessWidget {
  const ProductCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          AspectRatio(aspectRatio: 1, child: ShimmerBox()),
          Padding(
            padding: EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(width: 60, height: 10, radius: 4),
                SizedBox(height: 8),
                ShimmerBox(height: 12, radius: 4),
                SizedBox(height: 6),
                ShimmerBox(width: 90, height: 12, radius: 4),
                SizedBox(height: 12),
                ShimmerBox(width: 70, height: 16, radius: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ListTileSkeleton extends StatelessWidget {
  const ListTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          ShimmerBox(width: 84, height: 84, radius: 12),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(height: 14, radius: 4),
                SizedBox(height: 8),
                ShimmerBox(width: 120, height: 12, radius: 4),
                SizedBox(height: 14),
                ShimmerBox(width: 80, height: 18, radius: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
