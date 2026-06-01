import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _baseUrl = 'https://egzone.runasp.net';

  static String get baseUrl => _baseUrl;

  // Save token and userId after login
  static Future<void> saveAuthData(String token, String? userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    if (userId != null) {
      await prefs.setString(_userIdKey, userId);
    }
  }

  // Read token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Read userId
  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  // Delete data on logout
  static Future<void> clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
  }

  // Auth header for protected endpoints
  static Future<Map<String, String>> get authHeaders async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Public header (no token needed)
  static Map<String, String> get publicHeaders => {
        'Content-Type': 'application/json',
      };

  /// Safely extracts a List from the response body.
  ///
  /// Handles all response shapes used by this API:
  ///   • Plain array:          `[...]`                    → /api/Categories, /api/SubCategories
  ///   • Wrapped with "data":  `{"message":"..","data":[]}` → /api/Products
  ///   • Nested data map:      `{"data": {"items": [...]}}`
  static List<dynamic> parseResponseList(dynamic body) {
    if (body == null) return [];
    dynamic decoded;
    if (body is String) {
      if (body.trim().isEmpty) return [];
      try {
        decoded = jsonDecode(body);
      } catch (_) {
        return [];
      }
    } else {
      decoded = body;
    }

    // Case 1: Already a list (e.g. /api/Categories, /api/SubCategories)
    if (decoded is List) {
      return decoded;
    }

    // Case 2: Wrapped object (e.g. /api/Products → {"message":"..","data":[...]})
    if (decoded is Map) {
      final dataVal = decoded['data'];
      if (dataVal is List) return dataVal;

      // Case 3: data is itself a map containing a list
      if (dataVal is Map) {
        for (final v in dataVal.values) {
          if (v is List) return v;
        }
      }

      // Case 4: No "data" key — find any list value in the root map
      for (final v in decoded.values) {
        if (v is List) return v;
      }
    }

    return [];
  }

  /// Safely extracts a Map from the response body.
  ///
  /// Handles:
  ///   • Plain object:         `{...}`
  ///   • Wrapped with "data":  `{"data": {...}}`
  static Map<String, dynamic>? parseResponseMap(dynamic body) {
    if (body == null) return null;
    dynamic decoded;
    if (body is String) {
      if (body.trim().isEmpty) return null;
      try {
        decoded = jsonDecode(body);
      } catch (_) {
        return null;
      }
    } else {
      decoded = body;
    }

    if (decoded is Map) {
      if (decoded.containsKey('data') && decoded['data'] is Map) {
        return Map<String, dynamic>.from(decoded['data'] as Map);
      }
      return Map<String, dynamic>.from(decoded);
    }
    return null;
  }

  static Future<User> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/Auth/login'),
      headers: publicHeaders,
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      final String? token = data['token'] ?? data['accessToken'];
      String? userId;

      if (data is Map<String, dynamic>) {
        final user = data['user'] as Map<String, dynamic>?;
        userId = (data['userId'] ?? data['id'] ?? data['Id'] ??
                  user?['userId'] ?? user?['id'] ?? user?['Id'])?.toString();
      }

      if (token != null) {
        // If userId is missing, try fetching it from profile endpoint
        if (userId == null) {
          try {
            final profileResponse = await http.get(
              Uri.parse('$_baseUrl/api/UserProfile/profile'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
            );
            if (profileResponse.statusCode == 200) {
              final profileData = jsonDecode(profileResponse.body);
              userId = (profileData['userId'] ?? profileData['id'] ?? profileData['Id'])?.toString();
            }
          } catch (e) {
            debugPrint('Failed to fetch profile during login: $e');
          }
        }
        await saveAuthData(token, userId);
      }

      if (data is Map<String, dynamic>) {
        if (data.containsKey('user')) {
          return User.fromJson(data['user']);
        } else {
          return User.fromJson(data);
        }
      }
      return User(email: email, id: userId);
    } else {
      throw Exception('Failed to login: ${response.statusCode} - ${response.body}');
    }
  }

  static Future<void> register({
    required String fullName,
    required String email,
    required String password,
    required String phoneNumber,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/Auth/register'),
      headers: publicHeaders,
      body: jsonEncode({
        'fullName': fullName,
        'email': email,
        'password': password,
        'phoneNumber': phoneNumber,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to register: ${response.statusCode} - ${response.body}');
    }
  }

  // ─── Password Recovery ────────────────────────────────────────────────────────────────────────────────────────────────────────────

  static Future<void> forgotPassword(String email) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/Auth/forgot-password'),
      headers: publicHeaders,
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Failed to send reset link');
    }
  }

  static Future<void> resetPassword({
    required String email,
    required String token,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/Auth/reset-password'),
      headers: publicHeaders,
      body: jsonEncode({
        'email': email,
        'token': token,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      }),
    );

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Failed to reset password');
    }
  }
}
