import 'package:flutter/material.dart';
import 'shimmer_block.dart';

/// Skeleton that mirrors a generic list of cards (workshop browse, leaderboard rows).
class ListTileSkeleton extends StatelessWidget {
  final int itemCount;

  const ListTileSkeleton({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    return ShimmerBlock(
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        itemCount: itemCount,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, __) => const _ListItemPlaceholder(),
      ),
    );
  }
}

class _ListItemPlaceholder extends StatelessWidget {
  const _ListItemPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          ShimmerCircle(size: 44),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerRect(height: 14, width: 140),
                SizedBox(height: 8),
                ShimmerRect(height: 10, width: 90),
              ],
            ),
          ),
          ShimmerRect(height: 20, width: 36, borderRadius: 6),
        ],
      ),
    );
  }
}
