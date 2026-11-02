import 'dart:convert';

import 'package:http/http.dart';
import 'package:http/http.dart' as http;
import 'package:studymate_ai/models/recent_work_model.dart';

class StudyService {
  static const String baseUrl = 'http://127.0.0.1:8000';

  static Future<List<RecentWork>> fetchRecentWork() async {
    final url = Uri.parse('$baseUrl/api/v1/study/recent-works');

    try {
      final Response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (Response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(Response.body);
        return data.map((item) => RecentWork.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load recent works (${Response.statusCode})');
      }
    } catch (e) {
      throw Exception('Server connect zala nahi: $e');
    }
  }
}
