import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/category_model.dart';
import 'auth_service.dart';

class CategoryService {
  static Future<List<ProductCategory>> getAllCategories() async {
    final response = await http.get(
      Uri.parse('${AuthService.baseUrl}/api/Categories'),
      headers: AuthService.publicHeaders,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = AuthService.parseResponseList(response.body);
      return data
          .map((item) => ProductCategory.fromJson(item as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Failed to load categories: ${response.statusCode}');
    }
  }

  static Future<ProductCategory> getCategoryById(int id) async {
    final response = await http.get(
      Uri.parse('${AuthService.baseUrl}/api/Categories/$id'),
      headers: AuthService.publicHeaders,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return ProductCategory.fromJson(data);
    } else {
      throw Exception('Failed to load category: ${response.statusCode}');
    }
  }

  static Future<ProductCategory> createCategory(String name) async {
    final headers = await AuthService.authHeaders;
    
    final response = await http.post(
      Uri.parse('${AuthService.baseUrl}/api/Categories'),
      headers: headers,
      body: jsonEncode({'name': name}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return ProductCategory.fromJson(data);
    } else {
      throw Exception('Failed to create category: ${response.statusCode}');
    }
  }

  static Future<ProductCategory> updateCategory(int id, String name) async {
    final headers = await AuthService.authHeaders;
    
    final response = await http.put(
      Uri.parse('${AuthService.baseUrl}/api/Categories/$id'),
      headers: headers,
      body: jsonEncode({'name': name}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return ProductCategory.fromJson(data);
    } else {
      throw Exception('Failed to update category: ${response.statusCode}');
    }
  }

  static Future<void> deleteCategory(int id) async {
    final headers = await AuthService.authHeaders;
    
    final response = await http.delete(
      Uri.parse('${AuthService.baseUrl}/api/Categories/$id'),
      headers: headers,
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete category: ${response.statusCode}');
    }
  }
}
