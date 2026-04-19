import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:thinky/core_controls/constants/app_texts.dart';
import 'package:thinky/core_controls/services/context_collector.dart';
import 'package:thinky/core_controls/services/language_service.dart';
import 'package:thinky/core_controls/services/mascot_service.dart';

enum MascotMessageStatus { ok, sending, failed }

@immutable
class MascotMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final MascotMessageStatus status;

  const MascotMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.status = MascotMessageStatus.ok,
  });

  MascotMessage copyWith({
    String? text,
    MascotMessageStatus? status,
  }) {
    return MascotMessage(
      id: id,
      text: text ?? this.text,
      isUser: isUser,
      timestamp: timestamp,
      status: status ?? this.status,
    );
  }
}

@immutable
class MascotChatState {
  final String sessionId;
  final List<MascotMessage> messages;
  final bool isTyping;
  final String? lastFailedUserText;

  const MascotChatState({
    required this.sessionId,
    required this.messages,
    this.isTyping = false,
    this.lastFailedUserText,
  });

  MascotChatState copyWith({
    String? sessionId,
    List<MascotMessage>? messages,
    bool? isTyping,
    Object? lastFailedUserText = _kSentinel,
  }) {
    return MascotChatState(
      sessionId: sessionId ?? this.sessionId,
      messages: messages ?? this.messages,
      isTyping: isTyping ?? this.isTyping,
      lastFailedUserText: identical(lastFailedUserText, _kSentinel)
          ? this.lastFailedUserText
          : lastFailedUserText as String?,
    );
  }

  bool get hasUserMessages => messages.any((m) => m.isUser);
}

const Object _kSentinel = Object();

/// Persistent Pixy-chat state across navigations and language changes.
final mascotChatControllerProvider =
    StateNotifierProvider<MascotChatController, MascotChatState>((ref) {
  return MascotChatController(ref);
});

class MascotChatController extends StateNotifier<MascotChatState> {
  MascotChatController(this._ref)
      : super(MascotChatState(
          sessionId: _newSessionId(),
          messages: [_greetingMessage()],
        ));

  final Ref _ref;

  String _languageCode() =>
      _ref.read(languageProvider).languageCode.toLowerCase();

  Future<void> sendText(String rawText, GoRouter router) async {
    final text = rawText.trim();
    if (text.isEmpty || state.isTyping) return;

    final userMsg = MascotMessage(
      id: 'u-${DateTime.now().microsecondsSinceEpoch}',
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );
    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isTyping: true,
      lastFailedUserText: null,
    );

    final appContext = await ContextCollector.collect(router);
    final result = await MascotService.sendMessage(
      message: text,
      context: appContext,
      language: _languageCode(),
      sessionId: state.sessionId,
    );

    if (!mounted) return;

    if (result.isSuccess) {
      final pixyMsg = MascotMessage(
        id: 'p-${DateTime.now().microsecondsSinceEpoch}',
        text: result.reply!,
        isUser: false,
        timestamp: DateTime.now(),
      );
      state = state.copyWith(
        messages: [...state.messages, pixyMsg],
        isTyping: false,
      );
    } else {
      final errorMsg = MascotMessage(
        id: 'e-${DateTime.now().microsecondsSinceEpoch}',
        text: _localizeError(result.error),
        isUser: false,
        timestamp: DateTime.now(),
        status: MascotMessageStatus.failed,
      );
      state = state.copyWith(
        messages: [...state.messages, errorMsg],
        isTyping: false,
        lastFailedUserText: text,
      );
    }
  }

  /// Re-send the last user message that failed.
  Future<void> retryLast(GoRouter router) async {
    final failed = state.lastFailedUserText;
    if (failed == null) return;
    // Drop the trailing failure bubble before retrying.
    final messages = [...state.messages];
    if (messages.isNotEmpty &&
        messages.last.status == MascotMessageStatus.failed) {
      messages.removeLast();
    }
    state = state.copyWith(
      messages: messages,
      lastFailedUserText: null,
    );
    await sendText(failed, router);
  }

  /// Wipe the conversation: rotate the session id, ask the server to forget
  /// any history under the old id, and show a fresh greeting.
  Future<void> clearChat() async {
    final oldSession = state.sessionId;
    state = MascotChatState(
      sessionId: _newSessionId(),
      messages: [_greetingMessage()],
    );
    await MascotService.resetSession(oldSession);
  }

  static String _newSessionId() {
    return 'pixy-${DateTime.now().microsecondsSinceEpoch}';
  }

  static MascotMessage _greetingMessage() {
    return MascotMessage(
      id: 'greeting',
      text: MascotTexts.greeting,
      isUser: false,
      timestamp: DateTime.now(),
    );
  }

  static String _localizeError(MascotErrorKind? kind) {
    switch (kind) {
      case MascotErrorKind.empty:
        return MascotTexts.errorEmptyReply;
      case MascotErrorKind.network:
        return MascotTexts.errorConnection;
      case MascotErrorKind.server:
      case MascotErrorKind.unknown:
      case null:
        return MascotTexts.errorGeneric;
    }
  }
}
