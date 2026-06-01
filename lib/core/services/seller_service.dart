import 'dart:convert';
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
    String? brandName,
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
      ..fields['SubCategoryId'] = subCategoryId.toString();

    if (categoryName != null) request.fields['CategoryName'] = categoryName;
    if (subCategoryName != null) request.fields['SubCategoryName'] = subCategoryName;
    if (brandName != null) request.fields['BrandName'] = brandName;

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
      throw Exception(data['message'] ?? 'Failed to create product: ${response.statusCode}');
    }
  }

  /// Update an existing product
  /// Sets isApproved to false so admin must verify before publishing
  static Future<bool> updateProduct(int productId, Map<String, dynamic> data) async {
    // Set isApproved to false to require admin verification
    data['IsApproved'] = false;
    
    final response = await http.put(
      Uri.parse('${AuthService.baseUrl}/api/Products/$productId'),
      headers: await AuthService.authHeaders,
      body: jsonEncode(data),
    );

    return response.statusCode == 200 || response.statusCode == 204;
  }

  /// Delete a product
  static Future<bool> deleteProduct(int productId) async {
    final response = await http.delete(
      Uri.parse('${AuthService.baseUrl}/api/Products/$productId'),
      headers: await AuthService.authHeaders,
    );

    return response.statusCode == 200 || response.statusCode == 204;
  }
}
