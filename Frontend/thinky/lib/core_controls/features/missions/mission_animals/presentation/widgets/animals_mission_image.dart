import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:thinky/core_controls/constants/app_texts.dart';
import 'package:thinky/shared_controls/theme/app_colors.dart';
import 'package:thinky/shared_controls/theme/app_colors_extension.dart';

/// Displays a mission animal image with cleaner styling and more breathing room.
class AnimalsMissionImage extends StatelessWidget {
  const AnimalsMissionImage({
    super.key,
    required this.imageUrl,
    required this.colors,
    this.maxHeight = 240,
    this.borderRadius = 20,
  });

  final String imageUrl;
  final AppColorsExtension colors;
  final double maxHeight;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        var height = width * 0.74;

        if (height > maxHeight) height = maxHeight;
        if (height < 140) height = 140;

        return SizedBox(
          width: width,
          height: height,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(borderRadius),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(borderRadius - 6),
                  child: ColoredBox(
                    color: colors.surface,
                    child: _ImageBody(
                      url: imageUrl,
                      colors: colors,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ImageBody extends StatelessWidget {
  const _ImageBody({
    required this.url,
    required this.colors,
  });

  final String url;
  final AppColorsExtension colors;

  @override
  Widget build(BuildContext context) {
    if (url.startsWith('assets/')) {
      return Image.asset(
        url,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }

    return Image.network(
      url,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;

        final expected = loadingProgress.expectedTotalBytes;
        final loaded = loadingProgress.cumulativeBytesLoaded;

        return Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              value: expected != null ? loaded / expected : null,
              color: AppColors.primaryPurple,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.image_not_supported_rounded,
                size: 44,
                color: colors.textHint,
              ),
              const SizedBox(height: 8),
              Text(
                Animals.imageLoadError,
                textAlign: TextAlign.center,
                style: GoogleFonts.alata(
                  fontSize: 13,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}