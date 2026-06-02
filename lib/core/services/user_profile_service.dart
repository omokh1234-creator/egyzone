import 'dart:convert';
import 'package:http/http.dart' as http;

import 'auth_service.dart';

class UserProfileService {
  /// Fetch user profile
  static Future<Map<String, dynamic>?> getProfile() async {
    try {
      final headers = await AuthService.authHeaders;
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/api/UserProfile/profile'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = AuthService.parseResponseMap(response.body);
        return data;
      }
    } catch (_) {}
    return null;
  }

  /// Update user profile
  static Future<bool> updateProfile({
    required String fullName,
    String? phoneNumber,
  }) async {
    try {
      final headers = await AuthService.authHeaders;
      final response = await http.put(
        Uri.parse('${AuthService.baseUrl}/api/UserProfile/update'),
        headers: headers,
        body: jsonEncode({
          'fullName': fullName,
          if (phoneNumber != null) 'phoneNumber': phoneNumber,
        }),
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (_) {}
    return false;
  }

  /// Change password
  static Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final headers = await AuthService.authHeaders;
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/api/UserProfile/change-password'),
        headers: headers,
        body: jsonEncode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (_) {}
    return false;
  }
}
