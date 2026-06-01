import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class CouponService {
  /// Validates a coupon code and returns its details (including discountAmount)
  static Future<Map<String, dynamic>> validateCoupon(String code) async {
    final headers = await AuthService.authHeaders;
    final response = await http.get(
      Uri.parse('${AuthService.baseUrl}/api/Coupons/validate/$code'),
      headers: headers,
    );

    debugPrint('CouponService: Raw Validation Response: ${response.body}');

    if (response.statusCode == 200) {
      return AuthService.parseResponseMap(response.body) ?? {};
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Invalid or expired coupon code');
    }
  }

  /// Fetches all active coupons (Admin usually, but good to have)
  static Future<List<dynamic>> fetchCoupons() async {
    final headers = await AuthService.authHeaders;
    final response = await http.get(
      Uri.parse('${AuthService.baseUrl}/api/Coupons'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return AuthService.parseResponseList(response.body);
    } else {
      throw Exception('Failed to fetch coupons: ${response.statusCode}');
    }
  }
}
