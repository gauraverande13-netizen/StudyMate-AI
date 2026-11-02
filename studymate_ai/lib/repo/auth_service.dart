import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:studymate_ai/repo/user_session.dart';

class AuthService {
  static const String baseUrl = 'http://127.0.0.1:8000/api/v1';

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/auth/login');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'email': email, 'password': password}),
      );
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final int userId = data['user_id'] is int ? data['user_id'] : int.parse(data['user_id'].toString());
        final String fullName = data['full_name'] ?? email.split('@').first;
        final String token = data['access_token'] ?? '';

        await UserSession.saveUserSession(
          userId: userId,
          userName: fullName,
          email: email,
          token: token,
        );

        return {'success': true, 'data': data, 'user_id': userId, 'user_name': fullName};
      } else {
        return {
          'success': false,
          'message': data['detail'] ?? 'Login failed. Please check credentials.',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Server connection error: $e'};
    }
  }

  static Future<Map<String, dynamic>> registerUser({
    required String email,
    required String password,
    String? fullName,
  }) async {
    final url = Uri.parse('$baseUrl/auth/signup');
    final String fallbackName = fullName ?? email.split('@').first;
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'full_name': fallbackName,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final int userId = data['id'] is int ? data['id'] : int.parse(data['id'].toString());
        final String savedName = data['full_name'] ?? fallbackName;

        await UserSession.saveUserSession(
          userId: userId,
          userName: savedName,
          email: email,
        );

        return {'success': true, 'data': data, 'user_id': userId, 'user_name': savedName};
      } else {
        return {
          'success': false,
          'message': data['detail'] ?? 'Registration failed',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Server error: $e'};
    }
  }
}
