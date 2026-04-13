import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:thinky/core_controls/constants/app_texts.dart';
import 'package:thinky/core_controls/services/language_service.dart';
import 'package:thinky/shared_controls/theme/app_colors.dart';
import 'package:thinky/shared_controls/theme/app_colors_extension.dart';
import '../../data/grouping_models.dart';
import '../../data/grouping_repository.dart';
import '../controllers/grouping_controller.dart';
import 'grouping_learning_view.dart';

/// Main page for the Grouping Mission
/// "Group images: fruits, vegetables, toys"
class GroupingMissionPage extends ConsumerStatefulWidget {
  const GroupingMissionPage({super.key});

  @override
  ConsumerState<GroupingMissionPage> createState() => _GroupingMissionPageState();
}

class _GroupingMissionPageState extends ConsumerState<GroupingMissionPage>
    with TickerProviderStateMixin {
  late AnimationController _motivationalController;
  late Animation<double> _motivationalOpacity;

  // Category colors matching app theme
  static const Map<String, Color> _categoryColors = {
    'fruits': Color(0xFFFF8A65),     // Warm orange
    'vegetables': Color(0xFF66BB6A), // Fresh green
    'toys': Color(0xFF8E97FD),       // App purple/blue
  };

  static const Map<String, IconData> _categoryIcons = {
    'fruits': Icons.apple,
    'vegetables': Icons.eco,
    'toys': Icons.toys,
  };

  @override
  void initState() {
    super.initState();
    _motivationalController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _motivationalOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _motivationalController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
        reverseCurve: const Interval(0.7, 1.0, curve: Curves.easeOut),
      ),
    );

    // Start mission
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(groupingControllerProvider.notifier).startMission();
    });
  }

  @override
  void dispose() {
    _motivationalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(textRefreshProvider);
    final colors = context.appColors;
    final state = ref.watch(groupingControllerProvider);

    // Listen for motivational text changes
    ref.listen<GroupingMissionState>(groupingControllerProvider, (previous, next) {
      if (next.motivationalText != null && next.motivationalText != previous?.motivationalText) {
        _motivationalController.forward(from: 0.0).then((_) {
          Future.delayed(const Duration(milliseconds: 800), () {
            if (mounted) _motivationalController.reverse();
          });
        });
      }
    });

    if (state.showLearning) {
      return Scaffold(
        body: GroupingLearningView(
          onDone: () => ref.read(groupingControllerProvider.notifier).closeLearning(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(state, colors),
            if (state.phase == GroupingMissionPhase.playing ||
                state.phase == GroupingMissionPhase.submitting)
              _buildProgressIndicator(state, colors),
            Expanded(child: _buildContent(state, colors)),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(GroupingMissionState state, AppColorsExtension colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(true),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colors.inputFill,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.border),
              ),
              child: Icon(Icons.arrow_back, color: colors.textPrimary, size: 20),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  GroupingSorting.title,
                  style: GoogleFonts.alata(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                if (state.phase == GroupingMissionPhase.playing)
                  Text(
                    GroupingSorting.roundOf(state.currentRound, state.totalRounds),
                    style: GoogleFonts.alata(
                      fontSize: 13,
                      color: colors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          // Motivational microcopy bubble
          if (state.motivationalText != null)
            AnimatedBuilder(
              animation: _motivationalController,
              builder: (context, child) {
                return Opacity(
                  opacity: _motivationalOpacity.value,
                  child: Transform.translate(
                    offset: Offset(0, -8 * (1 - _motivationalOpacity.value)),
                    child: child,
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF8E97FD),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  state.motivationalText!,
                  style: GoogleFonts.alata(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(GroupingMissionState state, AppColorsExtension colors) {
    final progress = state.items.isEmpty
        ? 0.0
        : state.assignments.length / state.items.length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: colors.inputFill,
              valueColor: AlwaysStoppedAnimation<Color>(
                progress == 1.0 ? const Color(0xFF66BB6A) : AppColors.primaryPurple,
              ),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                GroupingSorting.sortedProgress(
                  state.assignments.length,
                  state.items.length,
                ),
                style: GoogleFonts.alata(fontSize: 11, color: colors.textSecondary),
              ),
              if (state.startTime != null)
                _TimerWidget(startTime: state.startTime!, colors: colors),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildContent(GroupingMissionState state, AppColorsExtension colors) {
    switch (state.phase) {
      case GroupingMissionPhase.loading:
      case GroupingMissionPhase.submitting:
        return _buildLoading(colors);
      case GroupingMissionPhase.playing:
        return _buildPlayingPhase(state, colors);
      case GroupingMissionPhase.results:
        return _buildResults(state, colors);
      case GroupingMissionPhase.missionComplete:
        return _buildMissionComplete(colors);
      case GroupingMissionPhase.error:
        return _buildError(state, colors);
      default:
        return _buildLoading(colors);
    }
  }

  Widget _buildLoading(AppColorsExtension colors) {
    Widget skel(double h, [double? w]) => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: colors.shimmer,
            borderRadius: BorderRadius.circular(16),
          ),
        );
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: skel(140)),
                const SizedBox(width: 12),
                Expanded(child: skel(140)),
                const SizedBox(width: 12),
                Expanded(child: skel(140)),
              ],
            ),
            const SizedBox(height: 20),
            skel(12, double.infinity),
            const SizedBox(height: 8),
            skel(12, 200),
            const SizedBox(height: 24),
            const CircularProgressIndicator(color: AppColors.primaryPurple),
            const SizedBox(height: 16),
            Text(
              GroupingSorting.loadingItems,
              style: GoogleFonts.alata(fontSize: 16, color: colors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PLAYING PHASE — Drag & Drop Interface
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildPlayingPhase(GroupingMissionState state, AppColorsExtension colors) {
    return Column(
      children: [
        // Instruction text
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
          child: Text(
            GroupingSorting.instruction,
            style: GoogleFonts.alata(
              fontSize: 14,
              color: colors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 8),

        // Category drop zones (smaller tables)
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: state.categories.map((category) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _buildCategoryDropZone(state, category, colors),
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Divider
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              color: colors.divider,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Image tray (unassigned items) - more space
        Expanded(
          flex: 3,
          child: _buildImageTray(state, colors),
        ),

        // Submit button
        if (state.allAssigned)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: _buildSubmitButton(),
          ),
      ],
    );
  }

  Widget _buildCategoryDropZone(
    GroupingMissionState state,
    String category,
    AppColorsExtension colors,
  ) {
    final color = _categoryColors[category] ?? AppColors.primaryPurple;
    final icon = _categoryIcons[category] ?? Icons.category;
    final itemsInCat = state.itemsInCategory(category);
    final controller = ref.read(groupingControllerProvider.notifier);

    return DragTarget<GroupingItem>(
      onWillAcceptWithDetails: (details) => true,
      onAcceptWithDetails: (details) {
        controller.assignItem(details.data.id, category);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isHovering ? color.withValues(alpha: 0.15) : colors.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isHovering ? color : colors.border,
              width: isHovering ? 2.5 : 1.5,
            ),
            boxShadow: isHovering
                ? [BoxShadow(color: color.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 4))]
                : [],
          ),
          child: Column(
            children: [
              // Category header (more compact)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    topRight: Radius.circular(14),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(icon, color: color, size: 18),
                    const SizedBox(height: 1),
                    Text(
                      category[0].toUpperCase() + category.substring(1),
                      style: GoogleFonts.alata(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),

              // Dropped items
              Expanded(
                child: itemsInCat.isEmpty
                    ? Center(
                        child: Text(
                          GroupingSorting.dropHere,
                          style: GoogleFonts.alata(
                            fontSize: 11,
                            color: colors.textHint,
                          ),
                        ),
                      )
                    : _buildScrollableDropList(itemsInCat, color, colors),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildScrollableDropList(
    List<GroupingItem> itemsInCat,
    Color color,
    AppColorsExtension colors,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final needsScroll = itemsInCat.length > 2;
        return Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(4),
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                children: itemsInCat.map((item) {
                  return _buildDroppedItemChip(item, color, colors);
                }).toList(),
              ),
            ),
            // Scroll indicator (fade at bottom when scrollable)
            if (needsScroll)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: IgnorePointer(
                  child: Container(
                    height: 24,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          color.withOpacity(0.15),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildDroppedItemChip(
    GroupingItem item,
    Color categoryColor,
    AppColorsExtension colors,
  ) {
    final controller = ref.read(groupingControllerProvider.notifier);

    return GestureDetector(
      onTap: () => controller.removeItem(item.id),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: categoryColor.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: _GroupingImage(
                item: item,
                width: 28,
                height: 28,
                categoryColor: categoryColor,
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                item.name,
                style: GoogleFonts.alata(fontSize: 10, color: colors.textPrimary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.close, size: 12, color: colors.textHint),
          ],
        ),
      ),
    );
  }

  Widget _buildImageTray(GroupingMissionState state, AppColorsExtension colors) {
    final unassigned = state.unassignedItems;

    if (unassigned.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline, size: 40, color: Color(0xFF66BB6A)),
            const SizedBox(height: 8),
            Text(
              GroupingSorting.allSorted,
              style: GoogleFonts.alata(fontSize: 16, color: const Color(0xFF66BB6A)),
            ),
            const SizedBox(height: 4),
            Text(
              GroupingSorting.tapSubmitHint,
              style: GoogleFonts.alata(fontSize: 12, color: colors.textSecondary),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 4),
            child: Text(
              GroupingSorting.itemsToSort,
              style: GoogleFonts.alata(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                GridView.builder(
                  padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.9,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: unassigned.length,
                  itemBuilder: (context, index) {
                    return _buildDraggableItem(unassigned[index]);
                  },
                ),
                // Scroll hint - fade at bottom when more items
                if (unassigned.length > 6)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: IgnorePointer(
                      child: Container(
                        height: 32,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              colors.background.withValues(alpha: 0.94),
                            ],
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.keyboard_arrow_down,
                            color: AppColors.primaryPurple.withValues(alpha: 0.6),
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDraggableItem(GroupingItem item) {
    return Draggable<GroupingItem>(
      data: item,
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            color: context.appColors.cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primaryPurple, width: 2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _GroupingImage(
              item: item,
              width: 90,
              height: 90,
              categoryColor: AppColors.primaryPurple,
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _buildItemCard(item, showLabel: false),
      ),
      child: _buildItemCard(item, showLabel: false),
    );
  }

  /// Item card in tray - no label (label shown only when dropped in table)
  Widget _buildItemCard(GroupingItem item, {required bool showLabel}) {
    final colors = context.appColors;
    return Container(
      decoration: BoxDecoration(
        color: colors.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _GroupingImage(
          item: item,
          width: double.infinity,
          height: double.infinity,
          categoryColor: colors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: () {
          ref.read(groupingControllerProvider.notifier).submitGrouping();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryPurple,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
        ),
        child: Text(
          GroupingSorting.submitWithCheck,
          style: GoogleFonts.alata(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RESULTS PHASE
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildResults(GroupingMissionState state, AppColorsExtension colors) {
    final result = state.lastResult;
    if (result == null) return _buildLoading(colors);

    final isAllCorrect = result.isCorrect;
    final accentColor = isAllCorrect ? const Color(0xFF66BB6A) : const Color(0xFFFF8A65);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Big emoji / icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                isAllCorrect ? '🎉' : '🤔',
                style: const TextStyle(fontSize: 40),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Message
          Text(
            result.message,
            style: GoogleFonts.alata(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatBox(GroupingSorting.statAccuracy, '${(result.accuracy * 100).toInt()}%', accentColor, colors),
              _buildStatBox(GroupingSorting.statTime, '${result.timeSpent.toStringAsFixed(1)}s', AppColors.primaryPurple, colors),
              _buildStatBox(GroupingSorting.statCorrect, '${result.correctCount}/${result.totalCount}', const Color(0xFF66BB6A), colors),
            ],
          ),
          const SizedBox(height: 24),

          // Per-item results
          ...result.details.map((detail) => _buildItemResultRow(detail, colors)),
          const SizedBox(height: 24),

          // Continue button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                ref.read(groupingControllerProvider.notifier).continueAfterResults();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
              ),
              child: Text(
                isAllCorrect ? GroupingSorting.continueExcited : GroupingSorting.tryAgainStrong,
                style: GoogleFonts.alata(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(
    String label,
    String value,
    Color color,
    AppColorsExtension colors,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.alata(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.alata(fontSize: 11, color: colors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildItemResultRow(GroupingItemResult detail, AppColorsExtension colors) {
    final isCorrect = detail.isCorrect;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isCorrect
              ? const Color(0xFF66BB6A).withOpacity(0.06)
              : const Color(0xFFFF5252).withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCorrect
                ? const Color(0xFF66BB6A).withOpacity(0.2)
                : const Color(0xFFFF5252).withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(
              isCorrect ? Icons.check_circle : Icons.cancel,
              color: isCorrect ? const Color(0xFF66BB6A) : const Color(0xFFFF5252),
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                detail.itemName,
                style: GoogleFonts.alata(fontSize: 14, color: colors.textPrimary),
              ),
            ),
            if (!isCorrect)
              Text(
                detail.correctCategory,
                style: GoogleFonts.alata(
                  fontSize: 12,
                  color: colors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MISSION COMPLETE
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildMissionComplete(AppColorsExtension colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF66BB6A).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('🏆', style: TextStyle(fontSize: 50)),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              GroupingSorting.missionComplete,
              style: GoogleFonts.alata(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              GroupingSorting.masteredMessage,
              style: GoogleFonts.alata(
                fontSize: 16,
                color: colors.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => ref.read(groupingControllerProvider.notifier).openLearning(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                ),
                child: Text(
                  GroupingSorting.lessonButton,
                  style: GoogleFonts.alata(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                GroupingSorting.backToMissions,
                style: GoogleFonts.alata(
                  fontSize: 14,
                  color: colors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ERROR
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildError(GroupingMissionState state, AppColorsExtension colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Color(0xFFFF5252)),
            const SizedBox(height: 16),
            Text(
              GroupingSorting.errorTitle,
              style: GoogleFonts.alata(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              state.errorMessage ?? GroupingSorting.unknownError,
              style: GoogleFonts.alata(fontSize: 14, color: colors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                ref.read(groupingControllerProvider.notifier).startMission();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                GroupingSorting.tryAgain,
                style: GoogleFonts.alata(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// GROUPING IMAGE — loads from local assets (reliable) or network fallback
// ═══════════════════════════════════════════════════════════════════════════

class _GroupingImage extends StatelessWidget {
  final GroupingItem item;
  final double width;
  final double height;
  final Color categoryColor;

  const _GroupingImage({
    required this.item,
    required this.width,
    required this.height,
    required this.categoryColor,
  });

  @override
  Widget build(BuildContext context) {
    final assetPath = GroupingRepository.getAssetPath(item.url);
    final networkUrl = GroupingRepository.getImageUrl(item.url);

    // Prefer local assets (work offline, no CORS)
    if (assetPath != null) {
      return SizedBox(
        width: width,
        height: height,
        child: Image.asset(
          assetPath,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildNetworkFallback(networkUrl),
        ),
      );
    }
    return _buildNetworkFallback(networkUrl);
  }

  Widget _buildNetworkFallback(String url) {
    return SizedBox(
      width: width,
      height: height,
      child: Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: width,
          height: height,
          color: categoryColor.withOpacity(0.2),
          child: Icon(Icons.image, size: width * 0.3, color: categoryColor),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// TIMER WIDGET — live elapsed time display
// ═══════════════════════════════════════════════════════════════════════════

class _TimerWidget extends StatefulWidget {
  final DateTime startTime;
  final AppColorsExtension colors;
  const _TimerWidget({required this.startTime, required this.colors});

  @override
  State<_TimerWidget> createState() => _TimerWidgetState();
}

class _TimerWidgetState extends State<_TimerWidget> {
  late final Stream<int> _timerStream;

  @override
  void initState() {
    super.initState();
    _timerStream = Stream.periodic(
      const Duration(seconds: 1),
      (count) => DateTime.now().difference(widget.startTime).inSeconds,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: _timerStream,
      builder: (context, snapshot) {
        final seconds = snapshot.data ?? 0;
        final min = seconds ~/ 60;
        final sec = seconds % 60;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.timer_outlined, size: 14, color: widget.colors.textSecondary),
            const SizedBox(width: 3),
            Text(
              '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}',
              style: GoogleFonts.alata(fontSize: 11, color: widget.colors.textSecondary),
            ),
          ],
        );
      },
    );
  }
}
