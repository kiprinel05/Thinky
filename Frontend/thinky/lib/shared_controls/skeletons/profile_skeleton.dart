import 'package:flutter/material.dart';
import 'shimmer_block.dart';

/// Skeleton that mirrors the profile page layout while data loads.
class ProfileSkeleton extends StatelessWidget {
  const ProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerBlock(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 24),
            const ShimmerCircle(size: 80),
            const SizedBox(height: 16),
            const ShimmerRect(height: 18, width: 140),
            const SizedBox(height: 8),
            const ShimmerRect(height: 12, width: 80),
            const SizedBox(height: 32),
            _buildSettingRow(),
            const SizedBox(height: 16),
            _buildSettingRow(),
            const SizedBox(height: 16),
            _buildSettingRow(),
            const SizedBox(height: 16),
            _buildSettingRow(),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingRow() {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }
}
