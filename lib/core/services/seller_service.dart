import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'auth_service.dart';

class SellerService {
  /// Create a new product with multiple images
  /// Uses multipart/form-data as per Swagger definition
  static Future<bool> createProduct({
    required String name,
    required double price,
    required String description,
    required int categoryId,
    required int subCategoryId,
    required List<String> imagePaths,
    String? categoryName,
    String? subCategoryName,
    int? brandId,
    List<String> specifications = const [],
  }) async {
    final url = Uri.parse('${AuthService.baseUrl}/api/Products');
    final headers = await AuthService.authHeaders;
    
    // MultipartRequest doesn't use 'Content-Type': 'application/json'
    headers.remove('Content-Type');

    final request = http.MultipartRequest('POST', url)
      ..headers.addAll(headers)
      ..fields['Name'] = name
      ..fields['Price'] = price.toString()
      ..fields['Description'] = description
      ..fields['CategoryId'] = categoryId.toString()
      ..fields['SubCategoryId'] = subCategoryId.toString()
      ..fields['IsApproved'] = 'false';

    if (brandId != null) request.fields['BrandId'] = brandId.toString();

    if (categoryName != null) request.fields['CategoryName'] = categoryName;
    if (subCategoryName != null) request.fields['SubCategoryName'] = subCategoryName;

    // Add specifications as individual fields if the API expects them that way,
    // or as a list if supported. Swagger says "items: { type: string }".
    for (var i = 0; i < specifications.length; i++) {
      request.fields['Specifications[$i]'] = specifications[i];
    }

    // Add image files
    for (final path in imagePaths) {
      final file = await http.MultipartFile.fromPath(
        'ImageFiles', // Matches Swagger field name
        path,
        contentType: MediaType('image', 'jpeg'), // Default to jpeg
      );
      request.files.add(file);
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    } else {
      final data = jsonDecode(response.body);
      debugPrint('Product creation error: ${response.statusCode} - ${response.body}');
      throw Exception(data['message'] ?? data['error'] ?? 'Failed to create product: ${response.statusCode}');
    }
  }

  /// Update an existing product
  /// Uses JSON PUT with UpdateProductDto schema
  static Future<bool> updateProduct(int productId, Map<String, dynamic> data) async {
    final url = Uri.parse('${AuthService.baseUrl}/api/Products/$productId');
    final headers = await AuthService.authHeaders;

    // Build request body matching UpdateProductDto schema
    final requestBody = {
      'name': data['name'],
      'price': data['price'],
      'subCategoryId': data['subCategoryId'],
      'imageUrl': data['imageUrl'],
    };

    final response = await http.put(
      url,
      headers: headers,
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 200 || response.statusCode == 204) {
      return true;
    } else {
      final responseData = jsonDecode(response.body);
      debugPrint('Product update error: ${response.statusCode} - ${response.body}');
      throw Exception(responseData['message'] ?? responseData['error'] ?? 'Failed to update product: ${response.statusCode}');
    }
  }

  /// Delete a product
  static Future<bool> deleteProduct(int productId) async {
    final response = await http.delete(
      Uri.parse('${AuthService.baseUrl}/api/Products/$productId'),
      headers: await AuthService.authHeaders,
    );

    return response.statusCode == 200 || response.statusCode == 204;
  }

  /// Get seller profile
  static Future<Map<String, dynamic>?> getSellerProfile() async {
    try {
      final headers = await AuthService.authHeaders;
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/api/Sellers/my-profile'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = AuthService.parseResponseMap(response.body);
        return data;
      }
    } catch (_) {}
    return null;
  }

  /// Register as seller
  static Future<bool> registerAsSeller({
    required String storeName,
    String? description,
    String? contactNumber,
  }) async {
    try {
      final headers = await AuthService.authHeaders;
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/api/Sellers/register-as-seller'),
        headers: headers,
        body: jsonEncode({
          'storeName': storeName,
          if (description != null) 'description': description,
          if (contactNumber != null) 'contactNumber': contactNumber,
        }),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {}
    return false;
  }

  /// Get seller dashboard statistics
  static Future<Map<String, dynamic>?> getSellerDashboard() async {
    try {
      final headers = await AuthService.authHeaders;
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/api/Sellers/dashboard'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = AuthService.parseResponseMap(response.body);
        return data;
      }
    } catch (_) {}
    return null;
  }
}
