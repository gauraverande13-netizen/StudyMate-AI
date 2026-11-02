import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

class SummaryService {
  static const String baseUrl = 'http://127.0.0.1:8000/api/v1';

  // 1. Fetch user-specific uploaded documents
  static Future<List<dynamic>> getUserDocuments({required int userId}) async {
    final url = Uri.parse('$baseUrl/docs/?user_id=$userId');

    try {
      final response = await http
          .get(url, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return List<dynamic>.from(data);
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  // 2. Upload document with user_id and generate AI summary
  static Future<dynamic> uploadAndSummarize(
    PlatformFile file, {
    required int userId,
  }) async {
    final url = Uri.parse('$baseUrl/docs/upload');

    try {
      var request = http.MultipartRequest('POST', url);
      request.fields['user_id'] = userId.toString();

      if (file.bytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            file.bytes!,
            filename: file.name,
          ),
        );
      } else if (file.path != null) {
        request.files.add(
          await http.MultipartFile.fromPath('file', file.path!),
        );
      } else {
        return {'success': false, 'message': 'File could not be read.'};
      }

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 120),
      );
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final docId = data['id'] ?? data['doc_id'];
        return {
          'success': true,
          'doc_id': docId,
          'filename': data['filename'] ?? file.name,
          'summary': data['summary'] ?? 'Summary not found.',
          'key_points': data['key_points'] ?? '',
          'full_text': data['full_text'] ?? '',
          'file_url': data['file_url'] ?? (docId != null ? '$baseUrl/docs/$docId/file' : ''),
        };
      } else {
        return {
          'success': false,
          'message': 'Upload failed (${response.statusCode}): ${response.body}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  // Helper to get download/view URL for document
  static String getFileUrl(dynamic docId) {
    return '$baseUrl/docs/$docId/file';
  }

  // Fetch full document details including extracted text
  static Future<Map<String, dynamic>?> getDocumentContent(dynamic docId) async {
    final url = Uri.parse('$baseUrl/docs/$docId/content');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }
}
