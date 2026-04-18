import 'package:flutter/material.dart';
import 'package:thinky/core_controls/features/missions/mission_animals/data/animals_models.dart';
import 'package:thinky/core_controls/features/missions/mission_animals/data/animals_repository.dart';
import 'package:thinky/shared_controls/theme/app_colors.dart';
import 'package:thinky/shared_controls/theme/app_colors_extension.dart';
import 'package:thinky/shared_controls/theme/app_dimens.dart';

/// Outcome overlay for each tile after submit.
enum AnimalsTileMark {
  none,
  correct,
  wrongPick,
  missed,
}

AnimalsTileMark tileMark({
  required String imageId,
  required Set<String> submittedSelection,
  required Set<String> correctIds,
  required bool showFeedback,
}) {
  if (!showFeedback) return AnimalsTileMark.none;
  final sel = submittedSelection.contains(imageId);
  final cor = correctIds.contains(imageId);
  if (cor && sel) return AnimalsTileMark.correct;
  if (cor && !sel) return AnimalsTileMark.missed;
  if (!cor && sel) return AnimalsTileMark.wrongPick;
  return AnimalsTileMark.none;
}

class AnimalsTeachingGrid extends StatelessWidget {
  const AnimalsTeachingGrid({
    super.key,
    required this.images,
    required this.selectedIds,
    required this.correctIds,
    required this.colors,
    required this.enabled,
    required this.showFeedback,
    required this.submittedSelection,
    required this.onToggle,
  });

  final List<AnimalImage> images;
  final Set<String> selectedIds;
  final Set<String> correctIds;
  final AppColorsExtension colors;
  final bool enabled;
  final bool showFeedback;
  final Set<String> submittedSelection;
  final void Function(String id) onToggle;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppDimens.sm,
        mainAxisSpacing: AppDimens.sm,
        childAspectRatio: 1,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) {
        final image = images[index];
        final selected = selectedIds.contains(image.id);
        final mark = tileMark(
          imageId: image.id,
          submittedSelection: submittedSelection,
          correctIds: correctIds,
          showFeedback: showFeedback,
        );
        return _TeachingTile(
          image: image,
          colors: colors,
          selected: selected,
          enabled: enabled,
          mark: mark,
          onTap: () => onToggle(image.id),
        );
      },
    );
  }
}

class _TeachingTile extends StatelessWidget {
  const _TeachingTile({
    required this.image,
    required this.colors,
    required this.selected,
    required this.enabled,
    required this.mark,
    required this.onTap,
  });

  final AnimalImage image;
  final AppColorsExtension colors;
  final bool selected;
  final bool enabled;
  final AnimalsTileMark mark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final url = AnimalsRepository.getImageUrl(image.url);
    Color border;
    double width = 2.5;
    List<BoxShadow>? shadows;

    switch (mark) {
      case AnimalsTileMark.correct:
        border = AppColors.success;
        shadows = [
          BoxShadow(color: AppColors.success.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4)),
        ];
        break;
      case AnimalsTileMark.wrongPick:
        border = AppColors.error;
        shadows = [
          BoxShadow(color: AppColors.error.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4)),
        ];
        break;
      case AnimalsTileMark.missed:
        border = AppColors.warning;
        width = 2;
        shadows = [
          BoxShadow(color: AppColors.warning.withValues(alpha: 0.25), blurRadius: 10, offset: const Offset(0, 4)),
        ];
        break;
      case AnimalsTileMark.none:
        border = selected ? AppColors.primaryPurple : Colors.transparent;
        width = selected ? 3 : 2;
        shadows = selected
            ? [
                BoxShadow(
                  color: AppColors.primaryPurple.withValues(alpha: 0.28),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ]
            : null;
    }

    final child = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimens.radiusLg),
            border: Border.all(color: border, width: width),
            boxShadow: shadows,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppDimens.radiusLg - 2),
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(color: colors.surface),
                Padding(
                  padding: const EdgeInsets.all(6),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _TileImage(url: url, colors: colors),
                  ),
                ),
                if (mark != AnimalsTileMark.none)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: _MarkBadge(mark: mark),
                  ),
                if (selected && mark == AnimalsTileMark.none)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primaryPurple, AppColors.primaryPurpleLight],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryPurple.withValues(alpha: 0.45),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.check_rounded, color: Colors.white, size: 16),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    return AnimatedScale(
      scale: selected && mark == AnimalsTileMark.none && enabled ? 1.02 : 1.0,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      child: child,
    );
  }
}

class _TileImage extends StatelessWidget {
  const _TileImage({required this.url, required this.colors});

  final String url;
  final AppColorsExtension colors;

  @override
  Widget build(BuildContext context) {
    if (url.startsWith('assets/')) {
      return Image.asset(url, fit: BoxFit.cover, width: double.infinity, height: double.infinity);
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              value: progress.expectedTotalBytes != null
                  ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                  : null,
              color: AppColors.primaryPurple,
            ),
          ),
        );
      },
      errorBuilder: (_, __, ___) => Center(
        child: Icon(Icons.pets_rounded, color: colors.textHint, size: 36),
      ),
    );
  }
}

class _MarkBadge extends StatelessWidget {
  const _MarkBadge({required this.mark});

  final AnimalsTileMark mark;

  @override
  Widget build(BuildContext context) {
    late IconData icon;
    late Color bg;
    switch (mark) {
      case AnimalsTileMark.correct:
        icon = Icons.check_circle_rounded;
        bg = AppColors.success;
        break;
      case AnimalsTileMark.wrongPick:
        icon = Icons.cancel_rounded;
        bg = AppColors.error;
        break;
      case AnimalsTileMark.missed:
        icon = Icons.help_outline_rounded;
        bg = AppColors.warning;
        break;
      case AnimalsTileMark.none:
        return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.95), shape: BoxShape.circle),
      child: Icon(icon, color: bg, size: 22),
    );
  }
}
