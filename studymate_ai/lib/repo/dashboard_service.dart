import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:studymate_ai/constant/api_constants.dart';

class DashboardService {
  static const String baseUrl = ApiConstants.serverUrl;

  static Future<Map<String, dynamic>> getDashboardSummary({int? userId}) async {
    final query = userId != null ? '?user_id=$userId' : '';
    final url = Uri.parse('$baseUrl/api/v1/dashboard/summary$query');

    try {
      final response = await http
          .get(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {
          'success': false,
          'message': 'Failed to load dashboard data (${response.statusCode})',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }
}
