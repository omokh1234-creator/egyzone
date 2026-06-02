import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class ChatService {
  static Future<String> sendMessage(String message) async {
    final url = '${AuthService.baseUrl}/api/Chatbot/ask';
    
    debugPrint('ChatService: Sending message to $url');
    debugPrint('ChatService: Message: $message');
    
    // Explicitly set headers with Content-Type
    final headers = {
      'Content-Type': 'application/json; charset=UTF-8',
    };
    debugPrint('ChatService: Headers: $headers');
    
    // Create request body as JSON object
    final body = jsonEncode({'message': message});
    debugPrint('ChatService: Request body: $body');
    
    var response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: body,
    );

    debugPrint('ChatService: Response status: ${response.statusCode}');
    debugPrint('ChatService: Response body: ${response.body}');

    // If public headers fail, try with auth headers
    if (response.statusCode != 200) {
      debugPrint('ChatService: Public headers failed, trying with auth headers');
      final authHeaders = await AuthService.authHeaders;
      debugPrint('ChatService: Auth headers: $authHeaders');
      
      response = await http.post(
        Uri.parse(url),
        headers: authHeaders,
        body: body,
      );

      debugPrint('ChatService: Response status with auth: ${response.statusCode}');
      debugPrint('ChatService: Response body with auth: ${response.body}');
    }

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['reply'] as String? ?? data['response'] as String? ?? data['message'] as String? ?? 'No response';
    } else {
      throw Exception('Failed to send message: ${response.statusCode} - ${response.body}');
    }
  }
}
