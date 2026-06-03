import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class BrandService {
  /// Fetch all brands
  static Future<List<Map<String, dynamic>>> getBrands() async {
    try {
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/api/Brands'),
        headers: AuthService.publicHeaders,
      );
      print('BrandService.getBrands response: ${response.statusCode} ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = AuthService.parseResponseList(response.body);
        print('BrandService.getBrands parsed data: $data');
        return data
            .map((item) => item as Map<String, dynamic>)
            .toList();
      }
    } catch (e) {
      print('BrandService.getBrands error: $e');
    }
    return [];
  }

  /// Get brand by ID
  static Future<Map<String, dynamic>?> getBrandById(int brandId) async {
    try {
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/api/Brands/$brandId'),
        headers: AuthService.publicHeaders,
      );

      if (response.statusCode == 200) {
        final data = AuthService.parseResponseMap(response.body);
        return data;
      }
    } catch (_) {}
    return null;
  }

  /// Create a new brand
  static Future<Map<String, dynamic>?> createBrand(String name) async {
    try {
      final url = Uri.parse('${AuthService.baseUrl}/api/Brands/CreateBrand');
      final headers = await AuthService.authHeaders;
      
      // MultipartRequest doesn't use 'Content-Type': 'application/json'
      headers.remove('Content-Type');

      final request = http.MultipartRequest('POST', url)
        ..headers.addAll(headers)
        ..fields['Name'] = name;

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = AuthService.parseResponseMap(response.body);
        return data;
      }
    } catch (_) {}
    return null;
  }
}
