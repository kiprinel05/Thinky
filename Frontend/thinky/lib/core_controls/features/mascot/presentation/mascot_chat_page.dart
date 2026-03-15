import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:thinky/shared_controls/theme/app_colors.dart';
import 'package:thinky/shared_controls/theme/app_dimens.dart';
import 'package:thinky/core_controls/services/mascot_service.dart';
import 'package:thinky/core_controls/services/context_collector.dart';

class MascotChatPage extends StatefulWidget {
  const MascotChatPage({super.key});

  @override
  State<MascotChatPage> createState() => _MascotChatPageState();
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  _ChatMessage({required this.text, required this.isUser})
      : timestamp = DateTime.now();
}

class _MascotChatPageState extends State<MascotChatPage>
    with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _isTyping = false;
  late AnimationController _dotController;

  @override
  void initState() {
    super.initState();
    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _messages.add(_ChatMessage(
      text: 'Salut! Eu sunt Pixy 🤖\nCum te pot ajuta cu aplicația?',
      isUser: false,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _dotController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _isTyping = true;
    });
    _controller.clear();
    _scrollToBottom();

    final router = GoRouter.of(context);
    final appContext = await ContextCollector.collect(router);
    final reply = await MascotService.sendMessage(text, appContext);

    if (mounted) {
      setState(() {
        _isTyping = false;
        _messages.add(_ChatMessage(text: reply, isUser: false));
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Container(
              color: AppColors.backgroundWhite,
              child: ListView.builder(
                controller: _scrollController,
                padding: EdgeInsets.fromLTRB(
                  AppDimens.lg,
                  AppDimens.md,
                  AppDimens.lg,
                  AppDimens.sm,
                ),
                itemCount: _messages.length + (_isTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length && _isTyping) {
                    return _buildTypingIndicator();
                  }
                  return _buildMessageBubble(_messages[index], index);
                },
              ),
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppDimens.sm,
        MediaQuery.of(context).padding.top + AppDimens.sm,
        AppDimens.sm,
        AppDimens.lg,
      ),
      decoration: BoxDecoration(
        color: AppColors.backgroundGrey,
        border: Border(
          bottom: BorderSide(color: AppColors.borderLight, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryPurple.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.backgroundGrey,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderLight, width: 1),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: AppColors.textPrimary,
              ),
            ),
            onPressed: () => context.pop(),
          ),
          const SizedBox(width: AppDimens.sm),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primaryPurple,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryPurple.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('🤖', style: TextStyle(fontSize: 22)),
                  ),
                ),
                const SizedBox(width: AppDimens.md),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Pixy',
                      style: GoogleFonts.alata(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Asistent AI',
                      style: GoogleFonts.alata(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 56),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(_ChatMessage message, int index) {
    final isUser = message.isUser;
    final isWelcome = index == 0 && !isUser;

    return Padding(
      padding: EdgeInsets.only(
        bottom: AppDimens.md,
        left: isUser ? 56 : 0,
        right: isUser ? 0 : 56,
      ),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) _buildPixyAvatar(),
          if (!isUser) const SizedBox(width: AppDimens.sm),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.lg,
                vertical: AppDimens.md,
              ),
              decoration: BoxDecoration(
                color: isUser
                    ? AppColors.primaryPurple
                    : AppColors.backgroundWhite,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                border: isUser
                    ? null
                    : Border.all(
                        color: AppColors.borderLight,
                        width: 1,
                      ),
                boxShadow: [
                  BoxShadow(
                    color: isUser
                        ? AppColors.primaryPurple.withValues(alpha: 0.2)
                        : Colors.black.withValues(alpha: 0.04),
                    blurRadius: isUser ? 8 : 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: isWelcome
                  ? _buildWelcomeContent(message.text)
                  : Text(
                      message.text,
                      style: GoogleFonts.alata(
                        fontSize: 15,
                        height: 1.5,
                        color: isUser
                            ? Colors.white
                            : AppColors.textPrimary,
                        fontWeight: isUser
                            ? FontWeight.w500
                            : FontWeight.w400,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeContent(String text) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          style: GoogleFonts.alata(
            fontSize: 15,
            height: 1.5,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppDimens.sm),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _buildSuggestionChip('Ce misiuni am?'),
            _buildSuggestionChip('Cum funcționează Pixy?'),
            _buildSuggestionChip('Explică-mi Workshop'),
          ],
        ),
      ],
    );
  }

  Widget _buildSuggestionChip(String label) {
    return GestureDetector(
      onTap: () {
        _controller.text = label;
        _sendMessage();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.md,
          vertical: AppDimens.xs + 2,
        ),
        decoration: BoxDecoration(
          color: AppColors.primaryPurple.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: AppColors.primaryPurple.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.alata(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryPurple,
          ),
        ),
      ),
    );
  }

  Widget _buildPixyAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.primaryPurple.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.primaryPurple.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: const Center(
        child: Text('🤖', style: TextStyle(fontSize: 16)),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildPixyAvatar(),
          const SizedBox(width: AppDimens.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.lg,
              vertical: AppDimens.md,
            ),
            decoration: BoxDecoration(
              color: AppColors.backgroundWhite,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: const Radius.circular(4),
                bottomRight: const Radius.circular(18),
              ),
              border: Border.all(color: AppColors.borderLight, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: AnimatedBuilder(
              animation: _dotController,
              builder: (context, _) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) {
                    final offset =
                        ((_dotController.value * 3 - i).clamp(0.0, 1.0));
                    final opacity = (0.4 +
                            0.6 *
                                (1 -
                                    (offset - 0.5).abs() * 2).clamp(0.0, 1.0))
                        .toDouble();
                    return Padding(
                      padding: EdgeInsets.only(right: i < 2 ? 6 : 0),
                      child: Opacity(
                        opacity: opacity,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.primaryPurple,
                            shape: BoxShape.circle,
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

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppDimens.lg,
        AppDimens.md,
        AppDimens.lg,
        MediaQuery.of(context).padding.bottom + 80,
      ),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
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
                color: AppColors.backgroundGrey,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.borderLight, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _controller,
                onSubmitted: (_) => _sendMessage(),
                maxLines: 4,
                minLines: 1,
                style: GoogleFonts.alata(
                  fontSize: 15,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'Scrie un mesaj...',
                  hintStyle: GoogleFonts.alata(
                    fontSize: 15,
                    color: AppColors.textHint,
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
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _sendMessage,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primaryPurple,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryPurple.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_upward_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
