import 'dart:convert';
import 'package:thinky/core_controls/services/api_client.dart';
import 'package:thinky/core/errors/error_logger.dart';

class MascotService {
  static Future<String> sendMessage(
    String message,
    Map<String, dynamic> context,
  ) async {
    try {
      final response = await ApiClient.post('/ai/mascot/chat', {
        'message': message,
        'context': context,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['reply'] ?? 'Hmm, nu am primit un răspuns. 🤖';
      } else {
        return 'Oops! Am o problemă de conexiune. Încearcă din nou! 🤖';
      }
    } catch (e, stack) {
      ErrorLogger().logError(e, stackTrace: stack);
      return 'Nu mă pot conecta la server acum. Încearcă mai târziu! 🤖';
    }
  }
}
