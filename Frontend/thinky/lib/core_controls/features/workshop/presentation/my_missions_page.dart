import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:thinky/shared_controls/theme/app_colors.dart';
import 'package:thinky/shared_controls/theme/app_colors_extension.dart';
import 'package:thinky/shared_controls/theme/app_dimens.dart';
import 'package:thinky/shared_controls/widgets/animations/animated_widgets.dart';
import 'package:thinky/core_controls/models/workshop_models.dart';
import 'package:thinky/core_controls/services/workshop_service.dart';
import 'package:thinky/core/errors/error_logger.dart';
import 'package:thinky/core_controls/constants/app_texts.dart';

class MyMissionsPage extends StatefulWidget {
  const MyMissionsPage({super.key});

  @override
  State<MyMissionsPage> createState() => _MyMissionsPageState();
}

class _MyMissionsPageState extends State<MyMissionsPage> {
  List<WorkshopMission> _missions = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMyMissions();
  }

  Future<void> _loadMyMissions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await WorkshopService.getMyMissions();
      setState(() {
        _missions = result.missions;
        _isLoading = false;
      });
    } catch (e, stack) {
      ErrorLogger().logError(e, stackTrace: stack);
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
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
        title: Text(
          WorkshopTexts.myMissions,
          style: GoogleFonts.alata(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryPurple),
            )
          : _error != null
              ? _buildError()
              : _missions.isEmpty
                  ? _buildEmpty()
                  : _buildList(),
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
            WorkshopTexts.couldNotLoadYourMissions,
            style: GoogleFonts.alata(fontSize: 16, color: colors.textSecondary),
          ),
          const SizedBox(height: AppDimens.md),
          TextButton(
            onPressed: _loadMyMissions,
            child: Text(Common.tryAgain, style: GoogleFonts.alata(color: AppColors.primaryPurple)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    final colors = context.appColors;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.create_rounded, size: 48, color: colors.textHint),
          const SizedBox(height: AppDimens.md),
          Text(
            WorkshopTexts.noMissionsCreated,
            style: GoogleFonts.alata(fontSize: 16, color: colors.textSecondary),
          ),
          const SizedBox(height: AppDimens.md),
          ElevatedButton.icon(
            onPressed: () => context.push('/workshop/create'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryPurple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              ),
              elevation: 0,
            ),
            icon: const Icon(Icons.add_rounded, size: 20),
            label: Text(
              WorkshopTexts.createFirstMission,
              style: GoogleFonts.alata(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return RefreshIndicator(
      color: AppColors.primaryPurple,
      onRefresh: _loadMyMissions,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppDimens.lg),
        itemCount: _missions.length,
        itemBuilder: (context, index) {
          return FadeInWidget(
            delay: Duration(milliseconds: 50 * index),
            child: _buildMissionCard(_missions[index]),
          );
        },
      ),
    );
  }

  Widget _buildMissionCard(WorkshopMission mission) {
    final colors = context.appColors;
    return GestureDetector(
      onTap: () => context.push('/workshop/mission/${mission.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppDimens.md),
        padding: const EdgeInsets.all(AppDimens.md),
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(AppDimens.radiusLg),
          border: Border.all(color: colors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primaryPurple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              ),
              child: const Icon(
                Icons.quiz_rounded,
                color: AppColors.primaryPurple,
                size: 22,
              ),
            ),
            const SizedBox(width: AppDimens.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mission.title,
                    style: GoogleFonts.alata(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'v${mission.version}',
                        style: GoogleFonts.alata(fontSize: 12, color: colors.textMuted),
                      ),
                      const SizedBox(width: AppDimens.md),
                      Icon(Icons.download_rounded, size: 14, color: colors.textHint),
                      const SizedBox(width: 2),
                      Text(
                        '${mission.downloadCount}',
                        style: GoogleFonts.alata(fontSize: 12, color: colors.textMuted),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: colors.textHint,
            ),
          ],
        ),
      ),
    );
  }
}
