import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class SummaryService {
  static const String baseUrl = 'https://studymate-backend-zrrm.onrender.com/api/v1';

  // 1. Fetch user-specific uploaded documents
  static Future<List<dynamic>> getUserDocuments({required int userId}) async {
    final url = Uri.parse('$baseUrl/docs/?user_id=$userId');

    try {
      final response = await http
          .get(url, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
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
      } else if (!kIsWeb && file.path != null) {
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
        final decoded = jsonDecode(response.body);
        return {
          'success': true,
          'summary': decoded['summary'],
          'key_points': decoded['key_points'],
          'full_text': decoded['full_text'],
          'filename': decoded['filename'],
          'doc_id': decoded['id'],
          'file_url': decoded['file_url'],
        };
      } else {
        try {
          final errorData = jsonDecode(response.body);
          return {
            'success': false,
            'message': errorData['detail'] ?? 'Document processing failed.',
          };
        } catch (_) {
          return {
            'success': false,
            'message': 'Failed with status code: ${response.statusCode}',
          };
        }
      }
    } catch (e) {
      return {'success': false, 'message': 'Upload error: $e'};
    }
  }

  // 3. Delete Document
  static Future<bool> deleteDocument(dynamic docId) async {
    final url = Uri.parse('$baseUrl/docs/$docId');
    try {
      final response = await http.delete(url);
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      return false;
    }
  }

  // 4. File URL generator
  static String getFileUrl(dynamic docId) {
    return '$baseUrl/docs/$docId/file';
  }
}
