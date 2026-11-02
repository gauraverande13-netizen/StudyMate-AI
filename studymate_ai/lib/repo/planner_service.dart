import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:studymate_ai/constant/api_constants.dart';

class PlannerService {
  static const String baseUrl = '${ApiConstants.baseUrl}/planner';

  // Date-wise tasks get karna
  static Future<List<Map<String, dynamic>>> fetchTasksByDate({
    required int userId,
    required DateTime date,
  }) async {
    final formattedDate =
        "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

    final url = Uri.parse(
      '$baseUrl/?user_id=$userId&selected_date=$formattedDate',
    );

    try {
      final response = await http
          .get(url, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is List) {
          return decoded
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint("Error fetching tasks for $formattedDate: $e");
      return [];
    }
  }

  // Task create karna
  static Future<bool> createTask({
    required int userId,
    required DateTime date,
    required String title,
    String? description,
    String? timeSlot,
  }) async {
    final formattedDate =
        "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

    final url = Uri.parse('$baseUrl/');

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'user_id': userId,
              'task_date': formattedDate,
              'title': title,
              'description': description ?? '',
              'time_slot': timeSlot ?? '',
            }),
          )
          .timeout(const Duration(seconds: 6));
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint("Error creating task: $e");
      return false;
    }
  }

  // Task Complete/Incomplete toggle karna
  static Future<bool> toggleTaskComplete(int taskId, bool isCompleted) async {
    final url = Uri.parse('$baseUrl/$taskId');

    try {
      final response = await http
          .put(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'is_completed': isCompleted}),
          )
          .timeout(const Duration(seconds: 6));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Error updating task: $e");
      return false;
    }
  }

  // Task delete karna
  static Future<bool> deleteTask(int taskId) async {
    final url = Uri.parse('$baseUrl/$taskId');

    try {
      final response = await http
          .delete(url)
          .timeout(const Duration(seconds: 6));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Error deleting task: $e");
      return false;
    }
  }

  static Future<dynamic> fetchTodaySummary({required int userId}) async {
    final now = DateTime.now();
    final activeDate =
        "${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    final url = Uri.parse(
      '$baseUrl/summary/today?user_id=$userId&today_date=$activeDate',
    );

    try {
      final response = await http
          .get(url, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {};
    } catch (e) {
      debugPrint("Error fetching today goals summary: $e");
      return {};
    }
  }
}
