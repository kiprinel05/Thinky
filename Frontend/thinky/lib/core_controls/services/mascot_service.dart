import 'dart:convert';

import 'package:thinky/core/errors/error_logger.dart';
import 'package:thinky/core_controls/services/api_client.dart';

/// Categorised error for the mascot chat. The UI layer turns this into a
/// localized message via [MascotTexts.errorXxx].
enum MascotErrorKind {
  empty, // server returned 200 but no usable reply
  network, // connection / timeout / DNS / TLS
  server, // 4xx / 5xx response
  unknown,
}

class MascotChatResult {
  final String? reply;
  final MascotErrorKind? error;

  const MascotChatResult.success(this.reply) : error = null;
  const MascotChatResult.failure(this.error) : reply = null;

  bool get isSuccess => reply != null;
}

class MascotService {
  /// Sends a single message to Pixy.
  ///
  /// * [language] — current app locale, sent as `Accept-Language` so the
  ///   backend system prompt + fallback strings localize correctly.
  /// * [sessionId] — stable per-conversation id; the backend uses it to keep
  ///   a small rolling history so multi-turn chats stay coherent.
  static Future<MascotChatResult> sendMessage({
    required String message,
    required Map<String, dynamic> context,
    required String language,
    required String sessionId,
  }) async {
    try {
      final response = await ApiClient.post(
        '/ai/mascot/chat',
        {
          'message': message,
          'context': context,
          'session_id': sessionId,
        },
        extraHeaders: {'Accept-Language': language},
        timeout: const Duration(seconds: 25),
      );

      if (response.statusCode != 200) {
        ErrorLogger().logDebug(
          'Mascot chat HTTP ${response.statusCode}: ${response.body}',
        );
        return const MascotChatResult.failure(MascotErrorKind.server);
      }

      final data = jsonDecode(response.body);
      final reply = (data is Map && data['reply'] is String)
          ? (data['reply'] as String).trim()
          : '';
      if (reply.isEmpty) {
        return const MascotChatResult.failure(MascotErrorKind.empty);
      }
      return MascotChatResult.success(reply);
    } on TimeoutException {
      return const MascotChatResult.failure(MascotErrorKind.network);
    } catch (e, stack) {
      ErrorLogger().logError(e, stackTrace: stack);
      return const MascotChatResult.failure(MascotErrorKind.network);
    }
  }

  /// Asks the backend to forget the rolling history for [sessionId]. Best
  /// effort — failures are logged but do not surface to the UI.
  static Future<void> resetSession(String sessionId) async {
    try {
      await ApiClient.post(
        '/ai/mascot/reset?session_id=${Uri.encodeQueryComponent(sessionId)}',
        const {},
        timeout: const Duration(seconds: 5),
      );
    } catch (e, stack) {
      ErrorLogger().logDebug('Mascot reset failed: $e');
      ErrorLogger().logError(e, stackTrace: stack);
    }
  }
}
