import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:thinky/shared_controls/theme/app_colors.dart';
import 'package:thinky/shared_controls/theme/app_colors_extension.dart';
import 'package:thinky/shared_controls/theme/app_dimens.dart';
import 'package:thinky/shared_controls/widgets/animations/animated_widgets.dart';
import 'package:thinky/core_controls/models/workshop_models.dart';
import 'package:thinky/core_controls/services/workshop_service.dart';
import 'package:thinky/core_controls/storage/workshop_storage.dart';
import 'package:thinky/core/errors/error_logger.dart';
import 'package:thinky/core_controls/network/user_facing_error_mapper.dart';
import 'package:thinky/shared_controls/widgets/error_handler_ui.dart';
import 'package:thinky/core_controls/constants/app_texts.dart';

class WorkshopDetailPage extends StatefulWidget {
  final int missionId;

  const WorkshopDetailPage({super.key, required this.missionId});

  @override
  State<WorkshopDetailPage> createState() => _WorkshopDetailPageState();
}

class _WorkshopDetailPageState extends State<WorkshopDetailPage> {
  WorkshopMissionDetail? _mission;
  bool _isLoading = true;
  bool _isDownloading = false;
  bool _isDownloaded = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMission();
  }

  Future<void> _loadMission() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final detail = await WorkshopService.getMissionDetail(widget.missionId);
      final downloaded = await WorkshopStorage.isDownloaded(widget.missionId);
      setState(() {
        _mission = detail;
        _isDownloaded = downloaded;
        _isLoading = false;
      });
    } catch (e, stack) {
      ErrorLogger().logError(e, stackTrace: stack);
      setState(() {
        _error = UserFacingErrorMapper.map(e);
        _isLoading = false;
      });
    }
  }

  Future<void> _downloadMission() async {
    if (_mission == null) return;
    setState(() => _isDownloading = true);

    try {
      final detail = await WorkshopService.downloadMission(widget.missionId);
      await WorkshopStorage.saveDownloadedMission(detail);
      setState(() {
        _mission = detail;
        _isDownloaded = true;
        _isDownloading = false;
      });

      if (mounted) {
        ErrorHandlerUI.showSuccess(context, WorkshopTexts.downloadSuccess);
      }
    } catch (e, stack) {
      ErrorLogger().logError(e, stackTrace: stack);
      setState(() => _isDownloading = false);
      if (mounted) {
        ErrorHandlerUI.showError(
          context,
          '${WorkshopTexts.downloadFailed} ${UserFacingErrorMapper.map(e)}',
        );
      }
    }
  }

  void _playMission() {
    if (_mission == null) return;
    context.push('/workshop-play/${_mission!.id}');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: colors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryPurple),
            )
          : _error != null
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildError() {
    final colors = context.appColors;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, size: 48, color: colors.textHint),
          const SizedBox(height: AppDimens.md),
          Text(
            WorkshopTexts.couldNotLoadMission,
            style: GoogleFonts.alata(fontSize: 16, color: colors.textSecondary),
          ),
          const SizedBox(height: AppDimens.md),
          TextButton(
            onPressed: _loadMission,
            child: Text(Common.tryAgain, style: GoogleFonts.alata(color: AppColors.primaryPurple)),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final colors = context.appColors;
    final mission = _mission!;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppDimens.lg, 0, AppDimens.lg, AppDimens.xxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FadeInWidget(
            child: Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primaryPurple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimens.radiusXl),
                ),
                child: const Icon(
                  Icons.quiz_rounded,
                  color: AppColors.primaryPurple,
                  size: 40,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppDimens.lg),

          FadeInWidget(
            delay: const Duration(milliseconds: 100),
            child: Text(
              mission.title,
              style: GoogleFonts.alata(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 6),

          FadeInWidget(
            delay: const Duration(milliseconds: 150),
            child: Row(
              children: [
                Icon(Icons.person_outline_rounded, size: 16, color: colors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  mission.authorName,
                  style: GoogleFonts.alata(fontSize: 13, color: colors.textSecondary),
                ),
                const SizedBox(width: AppDimens.md),
                Icon(Icons.download_rounded, size: 16, color: colors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  '${mission.downloadCount}',
                  style: GoogleFonts.alata(fontSize: 13, color: colors.textSecondary),
                ),
                const SizedBox(width: AppDimens.md),
                Icon(Icons.quiz_rounded, size: 16, color: colors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  '${mission.questions.length} ${WorkshopTexts.questionsCount}',
                  style: GoogleFonts.alata(fontSize: 13, color: colors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimens.md),

          if (mission.tags.isNotEmpty)
            FadeInWidget(
              delay: const Duration(milliseconds: 200),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: mission.tags.map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryPurple.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppDimens.radiusCircle),
                    ),
                    child: Text(
                      tag,
                      style: GoogleFonts.alata(
                        fontSize: 12,
                        color: AppColors.primaryPurple,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          const SizedBox(height: AppDimens.lg),

          if (mission.description != null && mission.description!.isNotEmpty)
            FadeInWidget(
              delay: const Duration(milliseconds: 250),
              child: Text(
                mission.description!,
                style: GoogleFonts.alata(
                  fontSize: 14,
                  color: colors.iconColor,
                  height: 1.5,
                ),
              ),
            ),
          const SizedBox(height: AppDimens.lg),

          FadeInWidget(
            delay: const Duration(milliseconds: 300),
            child: Container(
              padding: const EdgeInsets.all(AppDimens.md),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 18, color: colors.textMuted),
                  const SizedBox(width: AppDimens.sm),
                  Text(
                    'Version ${mission.version} • ${mission.missionType.toUpperCase()}',
                    style: GoogleFonts.alata(fontSize: 12, color: colors.textMuted),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppDimens.xl),

          FadeInWidget(
            delay: const Duration(milliseconds: 350),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isDownloading
                    ? null
                    : _isDownloaded
                        ? _playMission
                        : _downloadMission,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isDownloaded
                      ? AppColors.success
                      : AppColors.primaryPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                  ),
                  elevation: 0,
                ),
                icon: _isDownloading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        _isDownloaded
                            ? Icons.play_arrow_rounded
                            : Icons.download_rounded,
                        size: 22,
                      ),
                label: Text(
                  _isDownloading
                      ? WorkshopTexts.downloading
                      : _isDownloaded
                          ? WorkshopTexts.playQuiz
                          : WorkshopTexts.downloadMissionButton,
                  style: GoogleFonts.alata(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
