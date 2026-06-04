import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class AdminService {
  static String get _base => '${AuthService.baseUrl}/api/Admin';

  // ─── Dashboard ───────────────────────────────────────────────────────────
  /// GET /api/Admin/dashboard
  static Future<Map<String, dynamic>> getDashboard() async {
    final response = await http.get(
      Uri.parse('$_base/dashboard'),
      headers: await AuthService.authHeaders,
    );
    debugPrint('AdminService getDashboard: ${response.statusCode} ${response.body}');
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
      // If wrapped in a data key
      if (decoded is Map && decoded['data'] is Map) {
        return Map<String, dynamic>.from(decoded['data'] as Map);
      }
      return {};
    }
    return {};
  }

  // ─── Users ───────────────────────────────────────────────────────────────
  /// GET /api/Admin/users
  static Future<List<dynamic>> getUsers() async {
    final response = await http.get(
      Uri.parse('$_base/users'),
      headers: await AuthService.authHeaders,
    );
    debugPrint('AdminService getUsers: ${response.statusCode}');
    if (response.statusCode == 200) {
      return AuthService.parseResponseList(response.body);
    }
    return [];
  }

  /// PUT /api/Admin/users/{id}/ban
  static Future<bool> banUser(int id) async {
    final response = await http.put(
      Uri.parse('$_base/users/$id/ban'),
      headers: await AuthService.authHeaders,
    );
    debugPrint('AdminService banUser $id: ${response.statusCode}');
    return response.statusCode == 200 || response.statusCode == 204;
  }

  /// PUT /api/Admin/users/{id}/role  body: { "newRole": "admin"|"seller"|"customer" }
  static Future<bool> updateUserRole(int id, String newRole) async {
    final response = await http.put(
      Uri.parse('$_base/users/$id/role'),
      headers: await AuthService.authHeaders,
      body: jsonEncode({'newRole': newRole}),
    );
    debugPrint('AdminService updateUserRole $id -> $newRole: ${response.statusCode}');
    return response.statusCode == 200 || response.statusCode == 204;
  }

  // ─── Products ────────────────────────────────────────────────────────────
  /// GET /api/Admin/products/pending
  static Future<List<dynamic>> getPendingProducts() async {
    final response = await http.get(
      Uri.parse('$_base/products/pending'),
      headers: await AuthService.authHeaders,
    );
    if (response.statusCode == 200) {
      return AuthService.parseResponseList(response.body);
    }
    return [];
  }

  /// PUT /api/Admin/products/{id}/approve
  static Future<bool> approveProduct(int id) async {
    final response = await http.put(
      Uri.parse('$_base/products/$id/approve'),
      headers: await AuthService.authHeaders,
    );
    debugPrint('AdminService approveProduct $id: ${response.statusCode}');
    return response.statusCode == 200 || response.statusCode == 204;
  }

  /// PUT /api/Admin/products/{id}/reject
  static Future<bool> rejectProduct(int id) async {
    final response = await http.put(
      Uri.parse('$_base/products/$id/reject'),
      headers: await AuthService.authHeaders,
    );
    debugPrint('AdminService rejectProduct $id: ${response.statusCode}');
    return response.statusCode == 200 || response.statusCode == 204;
  }

  /// DELETE /api/Products/{id}
  static Future<bool> deleteProduct(int id) async {
    final response = await http.delete(
      Uri.parse('${AuthService.baseUrl}/api/Products/$id'),
      headers: await AuthService.authHeaders,
    );
    debugPrint('AdminService deleteProduct $id: ${response.statusCode}');
    return response.statusCode == 200 || response.statusCode == 204;
  }

  // ─── Reports ─────────────────────────────────────────────────────────────
  /// GET /api/Admin/reports?status=open|resolved|dismissed
  static Future<List<dynamic>> getReports({String? status}) async {
    final uri = Uri.parse('$_base/reports').replace(
      queryParameters: status != null && status.isNotEmpty
          ? {'status': status}
          : null,
    );
    final response = await http.get(
      uri,
      headers: await AuthService.authHeaders,
    );
    debugPrint('AdminService getReports(status=$status): ${response.statusCode}');
    if (response.statusCode == 200) {
      return AuthService.parseResponseList(response.body);
    }
    return [];
  }

  /// PUT /api/Admin/reports/{id}/resolve
  static Future<bool> resolveReport(int id) async {
    final response = await http.put(
      Uri.parse('$_base/reports/$id/resolve'),
      headers: await AuthService.authHeaders,
    );
    debugPrint('AdminService resolveReport $id: ${response.statusCode}');
    return response.statusCode == 200 || response.statusCode == 204;
  }

  /// PUT /api/Admin/reports/{id}/dismiss
  static Future<bool> dismissReport(int id) async {
    final response = await http.put(
      Uri.parse('$_base/reports/$id/dismiss'),
      headers: await AuthService.authHeaders,
    );
    debugPrint('AdminService dismissReport $id: ${response.statusCode}');
    return response.statusCode == 200 || response.statusCode == 204;
  }

  // ─── Coupons (existing) ──────────────────────────────────────────────────
  /// GET /api/Coupons
  static Future<List<dynamic>> getCoupons() async {
    final response = await http.get(
      Uri.parse('${AuthService.baseUrl}/api/Coupons'),
      headers: await AuthService.authHeaders,
    );
    debugPrint('AdminService getCoupons: ${response.statusCode}');
    if (response.statusCode == 200) {
      return AuthService.parseResponseList(response.body);
    }
    return [];
  }

  /// POST /api/Coupons
  static Future<bool> createCoupon({
    required String code,
    required int discountPercent,
    required DateTime expiryDate,
    required int maxUsage,
  }) async {
    final body = jsonEncode({
      'code': code,
      'discountPercent': discountPercent,
      'expiryDate': expiryDate.toIso8601String(),
      'maxUsage': maxUsage,
    });
    debugPrint('AdminService createCoupon: $body');

    final response = await http.post(
      Uri.parse('${AuthService.baseUrl}/api/Coupons'),
      headers: await AuthService.authHeaders,
      body: body,
    );
    debugPrint('AdminService createCoupon: ${response.statusCode} ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Failed to create coupon: ${response.statusCode}');
    }
  }

  /// DELETE /api/Coupons/{id}
  static Future<bool> deleteCoupon(int couponId) async {
    final response = await http.delete(
      Uri.parse('${AuthService.baseUrl}/api/Coupons/$couponId'),
      headers: await AuthService.authHeaders,
    );
    return response.statusCode == 200 || response.statusCode == 204;
  }

  /// PUT /api/Coupons/{id}
  static Future<bool> updateCoupon(int couponId, {
    String? code,
    int? discountPercent,
    DateTime? expiryDate,
    int? maxUsage,
    bool? isPercentage,
  }) async {
    final body = jsonEncode({
      if (code != null) 'code': code,
      if (discountPercent != null) 'discountPercent': discountPercent,
      if (expiryDate != null) 'expiryDate': expiryDate.toIso8601String(),
      if (maxUsage != null) 'maxUsage': maxUsage,
      if (isPercentage != null) 'isPercentage': isPercentage,
    });

    final response = await http.put(
      Uri.parse('${AuthService.baseUrl}/api/Coupons/$couponId'),
      headers: await AuthService.authHeaders,
      body: body,
    );
    return response.statusCode == 200 || response.statusCode == 204;
  }
}
