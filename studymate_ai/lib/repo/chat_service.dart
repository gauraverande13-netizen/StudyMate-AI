import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:studymate_ai/constant/api_constants.dart';

class ChatService {
  static const String baseUrl = ApiConstants.baseUrl;

  static Future<Map<String, dynamic>> sendMessage({
    required String message,
    int? sessionId,
    int? userId,
  }) async {
    final url = Uri.parse('$baseUrl/chat/message');

    try {
      final Map<String, dynamic> payload = {
        'session_id': sessionId,
        'message': message,
      };
      if (userId != null) {
        payload['user_id'] = userId;
      }

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'reply': data['content'] ?? 'No response',
          'session_id': data['session_id'],
        };
      } else {
        return {
          'success': false,
          'reply': 'Server Error: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'reply': 'Connection error: $e'};
    }
  }
}
