import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:thinky/shared_controls/theme/app_colors.dart';
import 'package:thinky/shared_controls/widgets/animated_widgets.dart';
import '../../domain/numbers_models.dart';
import '../controllers/numbers_controller.dart';
import '../controllers/numbers_state.dart';

/// Part 1: Counting objects and helping Pixy learn numbers
class NumbersCountingPage extends ConsumerStatefulWidget {
  const NumbersCountingPage({super.key});

  @override
  ConsumerState<NumbersCountingPage> createState() => _NumbersCountingPageState();
}

class _NumbersCountingPageState extends ConsumerState<NumbersCountingPage>
    with TickerProviderStateMixin {
  late AnimationController _pixyBounceController;
  late AnimationController _professorSlideController;
  late AnimationController _upgradeAnimController;
  late Animation<double> _pixyBounceAnim;
  late Animation<Offset> _professorSlideAnim;
  late Animation<double> _upgradeScaleAnim;

  static const Color _primaryColor = Color(0xFFFF9A5C);
  static const Color _primaryLight = Color(0xFFFFB347);
  static const Color _primaryDark = Color(0xFFE87B3A);
  static const Color _successColor = Color(0xFF4CAF50);
  static const Color _errorColor = Color(0xFFFF6B6B);

  @override
  void initState() {
    super.initState();
    _pixyBounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pixyBounceAnim = Tween<double>(begin: 0, end: -12).animate(
      CurvedAnimation(parent: _pixyBounceController, curve: Curves.easeInOut),
    );

    _professorSlideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _professorSlideAnim = Tween<Offset>(
      begin: const Offset(0, 1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _professorSlideController,
      curve: Curves.elasticOut,
    ));

    _upgradeAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _upgradeScaleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _upgradeAnimController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _pixyBounceController.dispose();
    _professorSlideController.dispose();
    _upgradeAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(numbersStateProvider);

    // Trigger professor animation
    if (state.phase == NumbersPhase.professorIntervention) {
      _professorSlideController.forward();
    } else {
      _professorSlideController.reverse();
    }

    // Trigger upgrade animation
    if (state.phase == NumbersPhase.modelUpgrade) {
      _upgradeAnimController.forward(from: 0.0);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F2),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(state),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        _buildObjectsArea(state),
                        const SizedBox(height: 16),
                        _buildPixySection(state),
                        const SizedBox(height: 16),
                        if (state.phase == NumbersPhase.counting) _buildNumberButtons(state),
                        if (state.phase == NumbersPhase.pixyGuessing) _buildResultSection(state),
                        if (state.phase == NumbersPhase.transitionToPart2) _buildTransitionCard(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Professor overlay
            if (state.phase == NumbersPhase.professorIntervention)
              _buildProfessorOverlay(state),
            // Model upgrade celebration
            if (state.phase == NumbersPhase.modelUpgrade)
              _buildUpgradeOverlay(state),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HEADER with progress
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildHeader(NumbersState state) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.arrow_back_ios_new_rounded,
                      color: _primaryDark, size: 18),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Partea 1: Numărăm obiecte',
                      style: GoogleFonts.alata(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF222222),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Nivelul: ${state.modelLevel.displayName} ${state.modelLevel.emoji}',
                      style: GoogleFonts.alata(
                        fontSize: 12,
                        color: _primaryDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: state.upgradeProgress.clamp(0.0, 1.0),
              backgroundColor: _primaryColor.withOpacity(0.12),
              valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${state.correctCount}/3 corecte → upgrade',
                style: GoogleFonts.alata(fontSize: 10, color: const Color(0xFF8A8A8F)),
              ),
              Row(
                children: List.generate(3, (i) {
                  final level = PixyModelLevel.values[i];
                  final isActive = state.modelLevel == level;
                  final isPast = state.modelLevel.index > level.index;
                  return Container(
                    margin: const EdgeInsets.only(left: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isActive
                          ? _primaryColor
                          : isPast
                              ? _successColor.withOpacity(0.15)
                              : Colors.grey.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      level.emoji,
                      style: const TextStyle(fontSize: 12),
                    ),
                  );
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // OBJECTS DISPLAY
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildObjectsArea(NumbersState state) {
    final round = state.round;
    if (round == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Câte obiecte vezi?',
            style: GoogleFonts.alata(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF222222),
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: List.generate(round.objects.length, (index) {
              return ScaleInWidget(
                delay: Duration(milliseconds: 100 * index),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _primaryColor.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _primaryColor.withOpacity(0.15),
                    ),
                  ),
                  child: Text(
                    round.objects[index].emoji,
                    style: const TextStyle(fontSize: 42),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PIXY SECTION
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildPixySection(NumbersState state) {
    final round = state.round;
    if (round == null) return const SizedBox.shrink();

    String pixyText;
    String pixyEmoji;

    if (state.phase == NumbersPhase.pixyGuessing && state.countingResult != null) {
      pixyText = state.countingResult!.pixyMessage;
      pixyEmoji = _emotionToEmoji(state.countingResult!.pixyEmotion);
    } else {
      pixyText = round.pixyMessage;
      pixyEmoji = '🤖';
    }

    return AnimatedBuilder(
      animation: _pixyBounceAnim,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _pixyBounceAnim.value),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_primaryColor.withOpacity(0.12), _primaryLight.withOpacity(0.08)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _primaryColor.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _primaryColor.withOpacity(0.15),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Text(pixyEmoji, style: const TextStyle(fontSize: 32)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.modelLevel.displayName,
                        style: GoogleFonts.alata(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _primaryDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        pixyText,
                        style: GoogleFonts.alata(
                          fontSize: 14,
                          color: const Color(0xFF444444),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // NUMBER BUTTONS (1-5)
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildNumberButtons(NumbersState state) {
    final controller = ref.read(numbersStateProvider.notifier);

    return Column(
      children: [
        Text(
          'Alege numărul corect:',
          style: GoogleFonts.alata(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF555555),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (i) {
            final number = i + 1;
            final isSelected = state.selectedAnswer == number;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: GestureDetector(
                onTap: () => controller.selectAnswer(number),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: isSelected ? _primaryColor : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? _primaryDark : _primaryColor.withOpacity(0.3),
                      width: isSelected ? 2.5 : 1.5,
                    ),
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(
                          color: _primaryColor.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$number',
                    style: GoogleFonts.alata(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : _primaryDark,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 20),
        // Submit OR Confirm Pixy's guess
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                label: 'CONFIRMĂ PIXY',
                icon: Icons.check_circle_rounded,
                color: _successColor,
                onTap: state.isSubmitting ? null : () => controller.submitCount(confirmed: true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                label: 'TRIMITE',
                icon: Icons.send_rounded,
                color: _primaryColor,
                enabled: state.selectedAnswer != null,
                onTap: state.selectedAnswer == null || state.isSubmitting
                    ? null
                    : () => controller.submitCount(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // RESULT SECTION (after submission)
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildResultSection(NumbersState state) {
    final result = state.countingResult;
    if (result == null) return const SizedBox.shrink();

    final controller = ref.read(numbersStateProvider.notifier);

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: result.isCorrect
                ? _successColor.withOpacity(0.08)
                : _errorColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: result.isCorrect
                  ? _successColor.withOpacity(0.3)
                  : _errorColor.withOpacity(0.3),
            ),
          ),
          child: Column(
            children: [
              Icon(
                result.isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: result.isCorrect ? _successColor : _errorColor,
                size: 40,
              ),
              const SizedBox(height: 12),
              Text(
                result.isCorrect ? 'Corect! 🎉' : 'Răspunsul corect era ${result.correctAnswer}',
                style: GoogleFonts.alata(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: result.isCorrect ? _successColor : _errorColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                result.pixyMessage,
                textAlign: TextAlign.center,
                style: GoogleFonts.alata(
                  fontSize: 13,
                  color: const Color(0xFF666666),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: _buildActionButton(
            label: 'URMĂTOAREA RUNDĂ',
            icon: Icons.arrow_forward_rounded,
            color: _primaryColor,
            onTap: () => controller.nextRound(),
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TRANSITION TO PART 2
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildTransitionCard() {
    final controller = ref.read(numbersStateProvider.notifier);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primaryColor.withOpacity(0.15), _primaryLight.withOpacity(0.1)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _primaryColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Text('🎨', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(
            'Bravo! Acum hai să învățăm\nsă desenăm cifrele!',
            textAlign: TextAlign.center,
            style: GoogleFonts.alata(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _primaryDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pixy va încerca să recunoască ce desenezi.',
            textAlign: TextAlign.center,
            style: GoogleFonts.alata(
              fontSize: 13,
              color: const Color(0xFF888888),
            ),
          ),
          const SizedBox(height: 24),
          _buildActionButton(
            label: 'MERGI LA DESENAT',
            icon: Icons.brush_rounded,
            color: _primaryColor,
            onTap: () => controller.switchToPart2(),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PROFESSOR OVERLAY
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildProfessorOverlay(NumbersState state) {
    final controller = ref.read(numbersStateProvider.notifier);
    final message = state.countingResult?.professorMessage ?? '';

    return Container(
      color: Colors.black.withOpacity(0.4),
      child: Center(
        child: SlideTransition(
          position: _professorSlideAnim,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 28),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5C6BC0).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Text('👨‍🏫', style: TextStyle(fontSize: 48)),
                ),
                const SizedBox(height: 20),
                Text(
                  'Profesorul spune:',
                  style: GoogleFonts.alata(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF5C6BC0),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.alata(
                    fontSize: 14,
                    height: 1.6,
                    color: const Color(0xFF444444),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => controller.dismissProfessor(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5C6BC0),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'AM ÎNȚELES!',
                      style: GoogleFonts.alata(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // MODEL UPGRADE OVERLAY
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildUpgradeOverlay(NumbersState state) {
    final controller = ref.read(numbersStateProvider.notifier);
    final newLevel = state.modelLevel;

    return Container(
      color: Colors.black.withOpacity(0.4),
      child: Center(
        child: ScaleTransition(
          scale: _upgradeScaleAnim,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 28),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: _primaryColor.withOpacity(0.3),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🎉', style: TextStyle(fontSize: 56)),
                const SizedBox(height: 16),
                Text(
                  'Pixy a avansat!',
                  style: GoogleFonts.alata(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: _primaryDark,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_primaryColor, _primaryLight],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${newLevel.emoji} ${newLevel.displayName}',
                    style: GoogleFonts.alata(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'AI-ul învață bine atunci când\noamenii sunt atenți și răbdători! 🌟',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.alata(
                    fontSize: 13,
                    height: 1.6,
                    color: const Color(0xFF666666),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => controller.dismissUpgrade(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'CONTINUĂ',
                      style: GoogleFonts.alata(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
    bool enabled = true,
  }) {
    final isEnabled = enabled && onTap != null;

    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isEnabled ? color : color.withOpacity(0.3),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            if (isEnabled)
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.alata(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _emotionToEmoji(String emotion) {
    switch (emotion) {
      case 'happy':
        return '😊';
      case 'sad':
        return '😢';
      case 'confused':
        return '😵';
      case 'thinking':
        return '🤔';
      default:
        return '🤖';
    }
  }
}
