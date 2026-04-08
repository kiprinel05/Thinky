import 'package:flutter/material.dart';
import 'shimmer_block.dart';

/// Skeleton that mirrors the missions menu two-column masonry grid.
class MissionCardsSkeleton extends StatelessWidget {
  const MissionCardsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    const horizontalPadding = 24.0;
    const spacing = 16.0;
    final cardWidth = (screenWidth - horizontalPadding * 2 - spacing) / 2;

    final cards = <_CardSpec>[
      _CardSpec(height: 200),
      _CardSpec(height: 220),
      _CardSpec(height: 220),
      _CardSpec(height: 200),
      _CardSpec(height: 200),
      _CardSpec(height: 220),
    ];

    final List<double> colHeights = [0, 0];
    final List<_Positioned> positioned = [];

    for (final card in cards) {
      final col = colHeights[0] <= colHeights[1] ? 0 : 1;
      final x = col == 0 ? 0.0 : cardWidth + spacing;
      final y = colHeights[col];
      positioned.add(_Positioned(x: x, y: y, width: cardWidth, height: card.height));
      colHeights[col] = y + card.height + spacing;
    }

    final totalHeight = colHeights[0] > colHeights[1] ? colHeights[0] : colHeights[1];

    return ShimmerBlock(
      child: SizedBox(
        height: totalHeight,
        child: Stack(
          children: positioned.map((p) {
            return Positioned(
              left: p.x,
              top: p.y,
              width: p.width,
              height: p.height,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ShimmerCircle(size: 40),
                    const SizedBox(height: 12),
                    ShimmerRect(height: 14, width: p.width * 0.7),
                    const SizedBox(height: 8),
                    ShimmerRect(height: 10, width: p.width * 0.5),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _CardSpec {
  final double height;
  _CardSpec({required this.height});
}

class _Positioned {
  final double x, y, width, height;
  _Positioned({required this.x, required this.y, required this.width, required this.height});
}
