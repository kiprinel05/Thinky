import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:thinky/core_controls/constants/app_texts.dart';
import 'package:thinky/core_controls/features/mascot/presentation/controllers/mascot_chat_controller.dart';
import 'package:thinky/core_controls/features/mascot/presentation/widgets/pixy_avatar.dart';
import 'package:thinky/core_controls/services/language_service.dart';
import 'package:thinky/shared_controls/theme/app_colors.dart';
import 'package:thinky/shared_controls/theme/app_colors_extension.dart';
import 'package:thinky/shared_controls/theme/app_dimens.dart';

class MascotChatPage extends ConsumerStatefulWidget {
  const MascotChatPage({super.key});

  @override
  ConsumerState<MascotChatPage> createState() => _MascotChatPageState();
}

class _MascotChatPageState extends ConsumerState<MascotChatPage>
    with TickerProviderStateMixin {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  late final AnimationController _typingController;
  late final AnimationController _pulseController;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _typingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _inputController.addListener(() {
      final hasText = _inputController.text.trim().isNotEmpty;
      if (hasText != _hasText) {
        setState(() => _hasText = hasText);
      }
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _typingController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _send([String? overrideText]) async {
    final text = (overrideText ?? _inputController.text).trim();
    if (text.isEmpty) return;
    _inputController.clear();
    await ref
        .read(mascotChatControllerProvider.notifier)
        .sendText(text, GoRouter.of(context));
    _scrollToBottom();
  }

  Future<void> _confirmAndClear() async {
    final colors = context.appColors;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          MascotTexts.clearChatConfirmTitle,
          style: GoogleFonts.alata(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        content: Text(
          MascotTexts.clearChatConfirmBody,
          style: GoogleFonts.alata(
            fontSize: 14,
            height: 1.45,
            color: colors.textSecondary,
          ),
        ),
        actionsPadding:
            const EdgeInsets.fromLTRB(AppDimens.md, 0, AppDimens.md, AppDimens.md),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              MascotTexts.clearChatCancel,
              style: GoogleFonts.alata(
                fontWeight: FontWeight.w600,
                color: colors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryPurple,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.lg,
                vertical: 12,
              ),
            ),
            child: Text(
              MascotTexts.clearChatConfirmAction,
              style: GoogleFonts.alata(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(mascotChatControllerProvider.notifier).clearChat();
      _inputController.clear();
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(textRefreshProvider);
    final state = ref.watch(mascotChatControllerProvider);
    final colors = context.appColors;

    // Auto-scroll on new messages / typing indicator changes.
    ref.listen<MascotChatState>(mascotChatControllerProvider, (prev, next) {
      if (prev?.messages.length != next.messages.length || prev?.isTyping != next.isTyping) {
        _scrollToBottom();
      }
    });

    final showSuggestions = !state.hasUserMessages && !state.isTyping;

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          _Header(
            onClear: state.hasUserMessages ? _confirmAndClear : null,
            pulse: _pulseController,
          ),
          Expanded(
            child: Stack(
              children: [
                ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.fromLTRB(
                    AppDimens.lg,
                    AppDimens.lg,
                    AppDimens.lg,
                    AppDimens.sm,
                  ),
                  itemCount: state.messages.length +
                      (state.isTyping ? 1 : 0) +
                      (showSuggestions ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index < state.messages.length) {
                      final msg = state.messages[index];
                      return _MessageBubble(
                        message: msg,
                        onRetry: msg.status == MascotMessageStatus.failed
                            ? () => ref
                                .read(mascotChatControllerProvider.notifier)
                                .retryLast(GoRouter.of(context))
                            : null,
                      );
                    }
                    final afterMessages = index - state.messages.length;
                    if (state.isTyping && afterMessages == 0) {
                      return _TypingIndicator(controller: _typingController);
                    }
                    // Suggestion strip (only shown when chat is "fresh").
                    return _SuggestionStrip(
                      onPick: (text) => _send(text),
                    );
                  },
                ),
              ],
            ),
          ),
          _InputBar(
            controller: _inputController,
            focusNode: _focusNode,
            canSend: _hasText && !state.isTyping,
            onSend: _send,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HEADER
// ─────────────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final VoidCallback? onClear;
  final AnimationController pulse;

  const _Header({required this.onClear, required this.pulse});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppDimens.sm,
        MediaQuery.of(context).padding.top + AppDimens.sm,
        AppDimens.sm,
        AppDimens.md,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          bottom: BorderSide(color: colors.border, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryPurple.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _IconBack(),
          const Spacer(),
          // Avatar + identity (centered).
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const PixyAvatar(size: 44, withGlow: true),
              const SizedBox(width: AppDimens.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    MascotTexts.title,
                    style: GoogleFonts.alata(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedBuilder(
                        animation: pulse,
                        builder: (context, _) {
                          return Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(
                                alpha: 0.55 + 0.45 * pulse.value,
                              ),
                              shape: BoxShape.circle,
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 6),
                      Text(
                        MascotTexts.online,
                        style: GoogleFonts.alata(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          _HeaderIconButton(
            icon: Icons.refresh_rounded,
            tooltip: MascotTexts.clearChat,
            onPressed: onClear,
          ),
        ],
      ),
    );
  }
}

class _IconBack extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return IconButton(
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.border, width: 1),
        ),
        child: Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 16,
          color: colors.textPrimary,
        ),
      ),
      onPressed: () => context.pop(),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final enabled = onPressed != null;
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: enabled
              ? AppColors.primaryPurple.withValues(alpha: 0.1)
              : colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: enabled
                ? AppColors.primaryPurple.withValues(alpha: 0.25)
                : colors.border,
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled
              ? AppColors.primaryPurple
              : colors.textHint,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MESSAGE BUBBLES
// ─────────────────────────────────────────────────────────────────────────────

class _MessageBubble extends StatefulWidget {
  final MascotMessage message;
  final VoidCallback? onRetry;

  const _MessageBubble({required this.message, required this.onRetry});

  @override
  State<_MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<_MessageBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entry;

  @override
  void initState() {
    super.initState();
    _entry = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    )..forward();
  }

  @override
  void dispose() {
    _entry.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final msg = widget.message;
    final isUser = msg.isUser;
    final isFailed = msg.status == MascotMessageStatus.failed;

    final bubble = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.lg,
        vertical: AppDimens.md,
      ),
      decoration: BoxDecoration(
        gradient: isUser
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryPurple,
                  AppColors.primaryPurpleDark,
                ],
              )
            : null,
        color: isUser
            ? null
            : (isFailed
                ? AppColors.errorLight
                : colors.surface),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(20),
          topRight: const Radius.circular(20),
          bottomLeft: Radius.circular(isUser ? 20 : 6),
          bottomRight: Radius.circular(isUser ? 6 : 20),
        ),
        border: isUser
            ? null
            : Border.all(
                color: isFailed
                    ? AppColors.error.withValues(alpha: 0.4)
                    : colors.border,
                width: 1,
              ),
        boxShadow: [
          BoxShadow(
            color: isUser
                ? AppColors.primaryPurple.withValues(alpha: 0.22)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            msg.text,
            style: GoogleFonts.alata(
              fontSize: 15,
              height: 1.45,
              color: isUser
                  ? Colors.white
                  : (isFailed
                      ? AppColors.errorDark
                      : colors.textPrimary),
              fontWeight: isUser ? FontWeight.w500 : FontWeight.w400,
            ),
          ),
          if (isFailed && widget.onRetry != null) ...[
            const SizedBox(height: AppDimens.sm),
            InkWell(
              onTap: widget.onRetry,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.refresh_rounded,
                      size: 16,
                      color: AppColors.errorDark,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      MascotTexts.retry,
                      style: GoogleFonts.alata(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.errorDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );

    final row = Row(
      mainAxisAlignment:
          isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!isUser) const PixyAvatar(size: 28),
        if (!isUser) const SizedBox(width: AppDimens.sm),
        Flexible(child: bubble),
      ],
    );

    return Padding(
      padding: EdgeInsets.only(
        bottom: AppDimens.md,
        left: isUser ? 60 : 0,
        right: isUser ? 0 : 60,
      ),
      child: FadeTransition(
        opacity: CurvedAnimation(parent: _entry, curve: Curves.easeOut),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: Offset(isUser ? 0.06 : -0.06, 0.04),
            end: Offset.zero,
          ).animate(
              CurvedAnimation(parent: _entry, curve: Curves.easeOutCubic)),
          child: row,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TYPING INDICATOR
// ─────────────────────────────────────────────────────────────────────────────

class _TypingIndicator extends StatelessWidget {
  final AnimationController controller;
  const _TypingIndicator({required this.controller});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.md, right: 60),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const PixyAvatar(size: 28),
          const SizedBox(width: AppDimens.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.lg,
              vertical: AppDimens.md,
            ),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: const Radius.circular(6),
                bottomRight: const Radius.circular(20),
              ),
              border: Border.all(color: colors.border, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: AnimatedBuilder(
              animation: controller,
              builder: (context, _) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) {
                    final t =
                        ((controller.value * 3 - i).clamp(0.0, 1.0)).toDouble();
                    final scale = 0.8 +
                        0.4 * (1 - (t - 0.5).abs() * 2).clamp(0.0, 1.0);
                    final opacity = 0.35 +
                        0.65 * (1 - (t - 0.5).abs() * 2).clamp(0.0, 1.0);
                    return Padding(
                      padding: EdgeInsets.only(right: i < 2 ? 6 : 0),
                      child: Opacity(
                        opacity: opacity,
                        child: Transform.scale(
                          scale: scale,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primaryPurple,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SUGGESTION CHIPS (shown only when no user message has been sent yet)
// ─────────────────────────────────────────────────────────────────────────────

class _SuggestionStrip extends StatelessWidget {
  final ValueChanged<String> onPick;
  const _SuggestionStrip({required this.onPick});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final items = <(IconData, String)>[
      (Icons.rocket_launch_rounded, MascotTexts.suggest1),
      (Icons.lightbulb_outline_rounded, MascotTexts.suggest2),
      (Icons.build_rounded, MascotTexts.suggest3),
    ];
    return Padding(
      padding: const EdgeInsets.only(left: 36, right: 0, bottom: AppDimens.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppDimens.xs),
            child: Text(
              '✨',
              style: TextStyle(fontSize: 14, color: colors.textHint),
            ),
          ),
          ...items.map((it) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _SuggestionChip(
                  icon: it.$1,
                  label: it.$2,
                  onTap: () => onPick(it.$2),
                ),
              )),
        ],
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SuggestionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.md,
            vertical: 9,
          ),
          decoration: BoxDecoration(
            color: AppColors.primaryPurple.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: AppColors.primaryPurple.withValues(alpha: 0.28),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: AppColors.primaryPurple,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: GoogleFonts.alata(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryPurple,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.arrow_forward_rounded,
                size: 14,
                color: AppColors.primaryPurple.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// INPUT BAR
// ─────────────────────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool canSend;
  final Future<void> Function([String?]) onSend;

  const _InputBar({
    required this.controller,
    required this.focusNode,
    required this.canSend,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppDimens.lg,
        AppDimens.md,
        AppDimens.lg,
        MediaQuery.of(context).padding.bottom + 80,
      ),
      decoration: BoxDecoration(
        color: colors.background,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: colors.inputFill,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: colors.border, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                onSubmitted: (_) => canSend ? onSend() : null,
                textInputAction: TextInputAction.send,
                maxLines: 4,
                minLines: 1,
                style: GoogleFonts.alata(
                  fontSize: 15,
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: MascotTexts.inputHint,
                  hintStyle: GoogleFonts.alata(
                    fontSize: 15,
                    color: colors.textHint,
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.lg,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppDimens.sm),
          _SendButton(
            enabled: canSend,
            onTap: () => onSend(),
          ),
        ],
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onTap;

  const _SendButton({required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: MascotTexts.sendTooltip,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          gradient: enabled
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primaryPurple,
                    AppColors.primaryPurpleDark,
                  ],
                )
              : null,
          color: enabled ? null : AppColors.borderGrey,
          borderRadius: BorderRadius.circular(16),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: AppColors.primaryPurple.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : const [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(16),
            child: Icon(
              Icons.arrow_upward_rounded,
              color: enabled ? Colors.white : Colors.white.withValues(alpha: 0.7),
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}
