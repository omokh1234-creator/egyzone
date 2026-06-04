import 'dart:convert';
import 'package:http/http.dart' as http;

import '../services/auth_service.dart';

class ReportService {
  /// Create a report for a product or review
  static Future<void> createReport({
    required String contentType,
    required int contentId,
    required String reason,
  }) async {
    final headers = await AuthService.authHeaders;
    final response = await http.post(
      Uri.parse('${AuthService.baseUrl}/api/Admin/reports'),
      headers: headers,
      body: jsonEncode({
        'contentType': contentType,
        'contentId': contentId,
        'reason': reason,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
          'Failed to create report: ${response.statusCode} - ${response.body}');
    }
  }
}
