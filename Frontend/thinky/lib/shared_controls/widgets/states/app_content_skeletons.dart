import 'package:flutter/material.dart';
import 'package:thinky/shared_controls/theme/app_colors_extension.dart';
import 'package:thinky/shared_controls/theme/app_dimens.dart';

/// Shared loading placeholders (shimmer-colored blocks) used across missions menu,
/// leaderboard, profile, workshop, and quiz for visual consistency.
class AppContentSkeletons {
  AppContentSkeletons._();

  static Widget _block(AppColorsExtension colors, {required double height, double? width}) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: colors.shimmer,
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
      ),
    );
  }

  /// Two-column masonry-style blocks (missions catalog).
  static Widget missionsCatalogGrid(BuildContext context) {
    final colors = context.appColors;
    Widget skel(double h) => _block(colors, height: h);
    return SizedBox(
      height: 420,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              children: [
                skel(200),
                const SizedBox(height: 16),
                skel(180),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              children: [
                skel(220),
                const SizedBox(height: 16),
                skel(160),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Stats card + list rows (leaderboard).
  static Widget leaderboardList(BuildContext context) {
    final colors = context.appColors;
    Widget row() => Padding(
          padding: const EdgeInsets.only(bottom: AppDimens.sm),
          child: _block(colors, height: 64),
        );
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppDimens.lg,
        AppDimens.md,
        AppDimens.lg,
        AppDimens.xxl,
      ),
      children: [
        _block(colors, height: 140),
        const SizedBox(height: AppDimens.lg),
        row(),
        row(),
        row(),
        row(),
        row(),
      ],
    );
  }

  /// Profile header + settings placeholders.
  static Widget profilePage(BuildContext context) {
    final colors = context.appColors;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppDimens.lg,
        AppDimens.sm,
        AppDimens.lg,
        AppDimens.xxl,
      ),
      children: [
        _block(colors, height: 160),
        const SizedBox(height: AppDimens.xl),
        _block(colors, height: 52),
        const SizedBox(height: AppDimens.sm),
        _block(colors, height: 52),
        const SizedBox(height: AppDimens.sm),
        _block(colors, height: 52),
        const SizedBox(height: AppDimens.xl),
        _block(colors, height: 48),
      ],
    );
  }

  /// Workshop mission rows.
  static Widget workshopMissionList(BuildContext context) {
    final colors = context.appColors;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppDimens.lg,
        AppDimens.sm,
        AppDimens.lg,
        100,
      ),
      children: List.generate(
        6,
        (i) => Padding(
          padding: const EdgeInsets.only(bottom: AppDimens.md),
          child: _block(colors, height: 88),
        ),
      ),
    );
  }

  /// Quiz initial / reload loading (replaces spinner-only state).
  static Widget quizPageBody(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _block(colors, height: 12),
          const SizedBox(height: 24),
          _block(colors, height: 140),
          const SizedBox(height: 24),
          _block(colors, height: 180),
          const Spacer(),
        ],
      ),
    );
  }

  /// Shown over quiz while answers are submitting.
  static Widget quizSubmittingOverlay(BuildContext context) {
    final colors = context.appColors;
    final progressColor = Theme.of(context).colorScheme.primary;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: progressColor,
              ),
            ),
            const SizedBox(height: 20),
            _block(colors, height: 14, width: 200),
            const SizedBox(height: 8),
            _block(colors, height: 14, width: 160),
          ],
        ),
      ),
    );
  }
}
