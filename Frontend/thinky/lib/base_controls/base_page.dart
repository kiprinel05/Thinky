import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thinky/shared_controls/theme/app_colors.dart';

/// BasePage - Abstract base class for all pages in the app
/// Provides common functionality like loading states, error handling, and scaffolding
abstract class BasePage extends ConsumerWidget {
  const BasePage({super.key});

  /// Page title for AppBar (optional)
  String? get title => null;

  /// Whether to show back button
  bool get showBackButton => true;

  /// Whether to show AppBar
  bool get showAppBar => true;

  /// Custom AppBar actions
  List<Widget>? get actions => null;

  /// Background color (defaults to white)
  Color get backgroundColor => AppColors.backgroundWhite;

  /// Build the page body content
  Widget buildBody(BuildContext context, WidgetRef ref);

  /// Build loading overlay (can be overridden)
  Widget buildLoading(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        color: AppColors.primaryPurple,
      ),
    );
  }

  /// Build error widget (can be overridden)
  Widget buildError(BuildContext context, String message, VoidCallback? onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error.withAlpha(179), // ~0.7 opacity
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Build empty state widget (can be overridden)
  Widget buildEmpty(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: AppColors.textMuted.withAlpha(128), // ~0.5 opacity
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: showAppBar ? _buildAppBar(context) : null,
      body: buildBody(context, ref),
    );
  }

  PreferredSizeWidget? _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: backgroundColor,
      elevation: 0,
      foregroundColor: AppColors.textPrimary,
      centerTitle: true,
      automaticallyImplyLeading: showBackButton,
      title: title != null
          ? Text(
              title!,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            )
          : null,
      actions: actions,
    );
  }
}

/// BasePageWithBackground - Page with background image support
abstract class BasePageWithBackground extends BasePage {
  const BasePageWithBackground({super.key});

  /// Background image asset path
  String? get backgroundImage => null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: showAppBar ? _buildAppBar(context) : null,
      body: Stack(
        children: [
          if (backgroundImage != null)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Image.asset(
                backgroundImage!,
                fit: BoxFit.cover,
              ),
            ),
          SafeArea(
            child: buildBody(context, ref),
          ),
        ],
      ),
    );
  }

  @override
  PreferredSizeWidget? _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      foregroundColor: AppColors.textPrimary,
      centerTitle: true,
      automaticallyImplyLeading: showBackButton,
      title: title != null
          ? Text(
              title!,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            )
          : null,
      actions: actions,
    );
  }
}
