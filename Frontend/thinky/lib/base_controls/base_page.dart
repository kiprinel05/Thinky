import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thinky/shared_controls/theme/app_colors.dart';
import 'package:thinky/shared_controls/theme/app_colors_extension.dart';

/// BasePage - Abstract base class for all pages in the app
/// Provides common functionality like loading states, error handling, and scaffolding
abstract class BasePage extends ConsumerWidget {
  const BasePage({super.key});

  String? get title => null;
  bool get showBackButton => true;
  bool get showAppBar => true;
  List<Widget>? get actions => null;

  /// Override to provide a fixed background color; defaults to null which uses
  /// the semantic theme color `appColors.background`.
  Color? get backgroundColor => null;

  Widget buildBody(BuildContext context, WidgetRef ref);

  /// Override to provide a custom AppBar. Return null to use the default.
  Widget? buildAppBar(BuildContext context) => null;

  Widget buildLoading(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primaryPurple),
    );
  }

  Widget buildError(BuildContext context, String message, VoidCallback? onRetry) {
    final colors = context.appColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error.withAlpha(179),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.textSecondary, fontSize: 14),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ],
        ),
      ),
    );
  }

  Widget buildEmpty(BuildContext context, String message) {
    final colors = context.appColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: colors.textMuted.withAlpha(128),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bg = backgroundColor ?? context.appColors.background;
    return Scaffold(
      backgroundColor: bg,
      appBar: showAppBar ? _buildDefaultAppBar(context, bg) : null,
      body: buildBody(context, ref),
    );
  }

  PreferredSizeWidget? _buildDefaultAppBar(BuildContext context, Color bg) {
    final colors = context.appColors;
    return AppBar(
      backgroundColor: bg,
      elevation: 0,
      foregroundColor: colors.textPrimary,
      centerTitle: true,
      automaticallyImplyLeading: showBackButton,
      title: title != null
          ? Text(title!, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700))
          : null,
      actions: actions,
    );
  }
}

/// BasePageWithBackground - Page with background image support
abstract class BasePageWithBackground extends BasePage {
  const BasePageWithBackground({super.key});

  String? get backgroundImage => null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bg = backgroundColor ?? context.appColors.background;
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: bg,
      appBar: showAppBar ? _buildBgAppBar(context, colors) : null,
      body: Stack(
        children: [
          if (backgroundImage != null)
            Positioned(
              top: 0, left: 0, right: 0,
              child: Image.asset(backgroundImage!, fit: BoxFit.cover),
            ),
          SafeArea(child: buildBody(context, ref)),
        ],
      ),
    );
  }

  PreferredSizeWidget? _buildBgAppBar(BuildContext context, AppColorsExtension colors) {
    return AppBar(
      backgroundColor: AppColors.transparent,
      elevation: 0,
      foregroundColor: colors.textPrimary,
      centerTitle: true,
      automaticallyImplyLeading: showBackButton,
      title: title != null
          ? Text(title!, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700))
          : null,
      actions: actions,
    );
  }
}
