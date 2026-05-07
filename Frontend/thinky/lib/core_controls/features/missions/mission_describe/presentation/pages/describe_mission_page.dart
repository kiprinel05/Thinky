import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/describe_models.dart';
import '../../data/describe_repository.dart';
import '../controllers/describe_controller.dart';

/// Main page for the Describe Mission
/// "Press record and describe what you see."
class DescribeMissionPage extends ConsumerStatefulWidget {
  const DescribeMissionPage({super.key});

  @override
  ConsumerState<DescribeMissionPage> createState() =>
      _DescribeMissionPageState();
}

class _DescribeMissionPageState extends ConsumerState<DescribeMissionPage>
    with TickerProviderStateMixin {
  // Animations
  late AnimationController _pulseController;
  late AnimationController _feedbackController;
  late AnimationController _encouragementController;

  late Animation<double> _pulseScale;
  late Animation<double> _feedbackSlide;
  late Animation<double> _encouragementOpacity;

  // Recording timer
  Timer? _recordingTimer;
  int _recordingSeconds = 0;

  // Input mode toggle
  bool _isTextMode = false;
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Pulsing ring animation for recording state
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseScale = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _feedbackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _feedbackSlide = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
          parent: _feedbackController, curve: Curves.easeOutBack),
    );

    _encouragementController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _encouragementOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _encouragementController, curve: Curves.easeOut),
    );

    // Start mission
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(describeControllerProvider.notifier).startMission();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _feedbackController.dispose();
    _encouragementController.dispose();
    _recordingTimer?.cancel();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(describeControllerProvider);

    // Animation triggers
    ref.listen<DescribeMissionState>(describeControllerProvider, (prev, next) {
      if (next.phase == DescribeMissionPhase.feedback) {
        _feedbackController.forward(from: 0.0);
        if (next.encouragement != null) {
          _encouragementController.forward(from: 0.0);
        }
      }
      if (next.phase == DescribeMissionPhase.recording) {
        _startRecordingTimer();
      } else {
        _stopRecordingTimer();
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(state),
            if (state.phase != DescribeMissionPhase.loading &&
                state.phase != DescribeMissionPhase.missionComplete &&
                state.phase != DescribeMissionPhase.error)
              _buildProgressBar(state),
            Expanded(child: _buildContent(state)),
          ],
        ),
      ),
    );
  }

  void _startRecordingTimer() {
    _recordingSeconds = 0;
    _recordingTimer?.cancel();
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() => _recordingSeconds = t.tick);
    });
  }

  void _stopRecordingTimer() {
    _recordingTimer?.cancel();
    _recordingTimer = null;
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  // ═══════════════════════════════════════════════════════════════════
  // APP BAR
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildAppBar(DescribeMissionState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(true),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F3F7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back,
                  color: Color(0xFF222222), size: 20),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Describe It',
                  style: GoogleFonts.alata(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF222222),
                  ),
                ),
                Text(
                  'Describe what you see in the image',
                  style: GoogleFonts.alata(
                    fontSize: 12,
                    color: const Color(0xFF8A8A8F),
                  ),
                ),
              ],
            ),
          ),
          // Round indicator
          if (state.roundData != null)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFF7043).withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${state.currentRound}/${state.totalRounds}',
                style: GoogleFonts.alata(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFFF7043),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // PROGRESS BAR
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildProgressBar(DescribeMissionState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: LinearProgressIndicator(
          value: state.progress,
          minHeight: 6,
          backgroundColor: const Color(0xFFE8E8ED),
          valueColor:
              const AlwaysStoppedAnimation<Color>(Color(0xFFFF7043)),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // CONTENT ROUTER
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildContent(DescribeMissionState state) {
    switch (state.phase) {
      case DescribeMissionPhase.loading:
        return _buildLoading();
      case DescribeMissionPhase.viewing:
        return _buildViewingPhase(state);
      case DescribeMissionPhase.recording:
        return _buildRecordingPhase(state);
      case DescribeMissionPhase.processing:
        return _buildProcessing();
      case DescribeMissionPhase.feedback:
        return _buildFeedbackPhase(state);
      case DescribeMissionPhase.missionComplete:
        return _buildMissionComplete(state);
      case DescribeMissionPhase.error:
        return _buildError(state);
    }
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Color(0xFFFF7043)),
          const SizedBox(height: 16),
          Text('Loading image...',
              style: GoogleFonts.alata(
                  fontSize: 16, color: const Color(0xFF8A8A8F))),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // VIEWING PHASE — Image + Record button
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildViewingPhase(DescribeMissionState state) {
    final imageUrl =
        DescribeRepository.getImageUrl(state.roundData!.image.imageUrl);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Image card
          _buildImageCard(imageUrl),
          const SizedBox(height: 20),

          // Hint text
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Text('💡', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    state.roundData!.image.hint,
                    style: GoogleFonts.alata(
                      fontSize: 13,
                      color: const Color(0xFF666666),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Voice/Text toggle
          _buildInputModeToggle(),
          const SizedBox(height: 20),

          // Record button or text input based on mode
          if (_isTextMode)
            _buildTextInputSection()
          else
            _buildRecordButton(
              icon: Icons.mic,
              label: 'Tap to Record',
              color: const Color(0xFFFF7043),
              onTap: () {
                ref.read(describeControllerProvider.notifier).startRecording();
              },
            ),
        ],
      ),
    );
  }

  Widget _buildInputModeToggle() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFF2F3F7),
        borderRadius: BorderRadius.circular(22),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isTextMode = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                decoration: BoxDecoration(
                  color: !_isTextMode ? const Color(0xFFFF7043) : Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.mic,
                        size: 18,
                        color: !_isTextMode ? Colors.white : const Color(0xFF8A8A8F),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Voice',
                        style: GoogleFonts.alata(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: !_isTextMode ? Colors.white : const Color(0xFF8A8A8F),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isTextMode = true),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                decoration: BoxDecoration(
                  color: _isTextMode ? const Color(0xFFFF7043) : Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.keyboard,
                        size: 18,
                        color: _isTextMode ? Colors.white : const Color(0xFF8A8A8F),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Text',
                        style: GoogleFonts.alata(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _isTextMode ? Colors.white : const Color(0xFF8A8A8F),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextInputSection() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8F8FA),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE8E8ED)),
          ),
          child: TextField(
            controller: _textController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Describe what you see in the image...',
              hintStyle: GoogleFonts.alata(
                fontSize: 14,
                color: const Color(0xFFBBBBC5),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
            style: GoogleFonts.alata(
              fontSize: 14,
              color: const Color(0xFF222222),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              if (_textController.text.trim().isNotEmpty) {
                ref
                    .read(describeControllerProvider.notifier)
                    .submitText(_textController.text);
                _textController.clear();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF7043),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Submit Description',
                  style: GoogleFonts.alata(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageCard(String imageUrl) {
    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8E8ED), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: const Color(0xFFF2F3F7),
            child: const Center(
              child: Icon(Icons.image, size: 60, color: Color(0xFFBBBBBB)),
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // RECORDING PHASE — Pulsing mic + timer (UI Enhancement: "Listening…" animation)
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildRecordingPhase(DescribeMissionState state) {
    final imageUrl =
        DescribeRepository.getImageUrl(state.roundData!.image.imageUrl);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Image (smaller during recording)
          SizedBox(
            height: 150,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.network(imageUrl, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox()),
            ),
          ),
          const SizedBox(height: 20),

          // ✨ "Listening…" animation — pulsing concentric rings
          SizedBox(
            width: 200,
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer pulsing ring
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, _) {
                    return Transform.scale(
                      scale: _pulseScale.value,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFFF7043)
                              .withAlpha((40 * (1.3 - _pulseScale.value)).toInt()),
                        ),
                      ),
                    );
                  },
                ),
                // Middle ring
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, _) {
                    final delay =
                        (_pulseScale.value - 1.0) * 0.7 + 1.0;
                    return Transform.scale(
                      scale: delay,
                      child: Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              const Color(0xFFFF7043).withAlpha(30),
                        ),
                      ),
                    );
                  },
                ),
                // Stop button
                GestureDetector(
                  onTap: () {
                    ref
                        .read(describeControllerProvider.notifier)
                        .stopRecording();
                  },
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFF7043),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF7043).withAlpha(100),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.stop,
                        color: Colors.white, size: 36),
                  ),
                ),
              ],
            ),
          ),

          // Timer + label
          Text(
            _formatDuration(_recordingSeconds),
            style: GoogleFonts.alata(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFFF7043),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Listening… Tap stop when done',
            style: GoogleFonts.alata(
              fontSize: 14,
              color: const Color(0xFF8A8A8F),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(
                  color: color.withAlpha(80),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: GoogleFonts.alata(
              fontSize: 14,
              color: const Color(0xFF666666),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // PROCESSING
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildProcessing() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Color(0xFFFF7043)),
          const SizedBox(height: 16),
          Text(
            'Processing your voice...',
            style: GoogleFonts.alata(
                fontSize: 16, color: const Color(0xFF8A8A8F)),
          ),
          const SizedBox(height: 4),
          Text(
            'Pixy is listening carefully 🎧',
            style: GoogleFonts.alata(
                fontSize: 13, color: const Color(0xFFAAAAAA)),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // FEEDBACK PHASE — Transcription + keyword results
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildFeedbackPhase(DescribeMissionState state) {
    final result = state.lastResult;
    if (result == null) return _buildLoading();

    final isGood = result.matchScore >= 0.5;
    final accentColor =
        isGood ? const Color(0xFF66BB6A) : const Color(0xFFFF8A65);

    return AnimatedBuilder(
      animation: _feedbackController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _feedbackSlide.value),
          child: Opacity(
            opacity: _feedbackController.value,
            child: child,
          ),
        );
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Score indicator
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: accentColor.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${(result.matchScore * 100).toInt()}%',
                  style: GoogleFonts.alata(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Message
            Text(
              result.message,
              style: GoogleFonts.alata(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF222222),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Transcription card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE8E8ED)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'You said:',
                    style: GoogleFonts.alata(
                        fontSize: 12, color: const Color(0xFF8A8A8F)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '"${result.transcription}"',
                    style: GoogleFonts.alata(
                      fontSize: 15,
                      fontStyle: FontStyle.italic,
                      color: const Color(0xFF333333),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Matched keywords
            if (result.matchedKeywords.isNotEmpty)
              _buildKeywordChips(
                  'Matched ✅', result.matchedKeywords, const Color(0xFF66BB6A)),
            if (result.missingKeywords.isNotEmpty)
              _buildKeywordChips(
                  'Missing', result.missingKeywords, const Color(0xFFFF8A65)),

            const SizedBox(height: 14),

            // Mascot encouragement
            if (state.encouragement != null)
              AnimatedBuilder(
                animation: _encouragementController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _encouragementOpacity.value,
                    child: Transform.translate(
                      offset: Offset(
                          0, 8 * (1 - _encouragementOpacity.value)),
                      child: child,
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF7043).withAlpha(20),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                        color: const Color(0xFFFF7043).withAlpha(50)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🤖',
                          style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          state.encouragement!,
                          style: GoogleFonts.alata(
                              fontSize: 13,
                              color: const Color(0xFF666666)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Next / Retry button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  ref
                      .read(describeControllerProvider.notifier)
                      .nextRound();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                ),
                child: Text(
                  state.currentRound >= state.totalRounds
                      ? 'See Results 🏆'
                      : 'Next Image →',
                  style: GoogleFonts.alata(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeywordChips(
      String title, List<String> keywords, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.alata(
                fontSize: 12, color: const Color(0xFF8A8A8F)),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: keywords
                .map((kw) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withAlpha(25),
                        borderRadius: BorderRadius.circular(10),
                        border:
                            Border.all(color: color.withAlpha(60)),
                      ),
                      child: Text(
                        kw,
                        style: GoogleFonts.alata(
                            fontSize: 12, color: color),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // MISSION COMPLETE
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildMissionComplete(DescribeMissionState state) {
    final score = state.totalRounds > 0
        ? (state.correctRounds / state.totalRounds * 100).toInt()
        : 0;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF66BB6A).withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('🏆', style: TextStyle(fontSize: 50)),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Mission Complete!',
              style: GoogleFonts.alata(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF222222),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatBox(
                    'Score', '$score%',
                    score >= 70
                        ? const Color(0xFF66BB6A)
                        : const Color(0xFFFF8A65)),
                _buildStatBox('Rounds', '${state.correctRounds}/${state.totalRounds}',
                    const Color(0xFFFF7043)),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              score >= 80
                  ? 'Amazing descriptions! 🌟'
                  : score >= 50
                      ? 'Good effort! Keep practicing! 💪'
                      : 'Try describing more details next time! 📚',
              style: GoogleFonts.alata(
                fontSize: 15,
                color: const Color(0xFF8A8A8F),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF7043),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                ),
                child: Text(
                  'Back to Missions',
                  style: GoogleFonts.alata(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.alata(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.alata(
                fontSize: 12, color: const Color(0xFF8A8A8F)),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // ERROR
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildError(DescribeMissionState state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                size: 60, color: Color(0xFFFF5252)),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: GoogleFonts.alata(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF222222),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              state.errorMessage ?? 'Unknown error',
              style: GoogleFonts.alata(
                  fontSize: 14, color: const Color(0xFF8A8A8F)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                ref
                    .read(describeControllerProvider.notifier)
                    .startMission();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF7043),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                'Try Again',
                style: GoogleFonts.alata(
                    fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
