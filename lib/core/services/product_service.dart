import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'auth_service.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';

class ProductService {
  // ─── Categories ────────────────────────────────────────────────────────────

  /// Fetches all categories with nested subcategories.
  ///
  /// Uses /api/Categories which returns a plain JSON array:
  ///   [{id, name, subCategories:[{id, name}]}, ...]
  ///
  /// Falls back to /api/SubCategories (flat list, no parent info) if needed.
  static Future<List<ProductCategory>> fetchCategories() async {
    // Primary: /api/Categories — full nested hierarchy in one request
    try {
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/api/Categories'),
        headers: AuthService.publicHeaders,
      );

      if (response.statusCode == 200) {
        // This endpoint returns a plain JSON array (no wrapper object)
        final List<dynamic> data = AuthService.parseResponseList(response.body);
        if (data.isNotEmpty) {
          return data
              .map((e) => ProductCategory.fromJson(e as Map<String, dynamic>))
              .where((cat) => cat.name.isNotEmpty)
              .toList();
        }
      }
    } catch (_) {}

    // Fallback: /api/SubCategories — flat list, group manually
    // Note: this endpoint returns [{id, name}] without parent category info,
    // so all subcategories will be grouped under a single "General" category.
    try {
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/api/SubCategories'),
        headers: AuthService.publicHeaders,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = AuthService.parseResponseList(response.body);
        if (data.isNotEmpty) {
          // Without parent category info, put everything under "General"
          final subs = data.map((sub) {
            final subId = (sub['subCategoryId'] as num?)?.toInt() ??
                (sub['id'] as num?)?.toInt() ?? 0;
            final subName = sub['name'] as String? ?? '';
            return ProductSubCategory(
              subCategoryId: subId,
              name: subName,
              categoryId: 1,
            );
          }).toList();

          return [
            ProductCategory(
              categoryId: 1,
              name: 'All Categories',
              subCategories: subs,
            )
          ];
        }
      }
    } catch (_) {}

    // Last resort default
    return [
      ProductCategory(
        categoryId: 1,
        name: 'General',
        subCategories: [
          ProductSubCategory(subCategoryId: 1, name: 'All', categoryId: 1),
        ],
      )
    ];
  }

  // ─── Products ──────────────────────────────────────────────────────────────

  /// Fetches products with optional filters.
  ///
  /// API: GET /api/Products?page=1&pageSize=10&subCategoryId=&search=&minPrice=&maxPrice=&isApproved=
  /// Response: {"message": "...", "data": [...products]}
  static Future<List<Product>> fetchProducts({
    int? subCategoryId,
    String? search,
    double? minPrice,
    double? maxPrice,
    bool? isApproved,
    int? brandId,
    int page = 1,
    int pageSize = 50,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'pageSize': pageSize.toString(),
    };
    if (subCategoryId != null) {
      queryParams['subCategoryId'] = subCategoryId.toString();
    }
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }
    if (minPrice != null) {
      queryParams['minPrice'] = minPrice.toString();
    }
    if (maxPrice != null) {
      queryParams['maxPrice'] = maxPrice.toString();
    }
    if (isApproved != null) {
      queryParams['isApproved'] = isApproved.toString();
    }
    if (brandId != null) {
      queryParams['brandId'] = brandId.toString();
    }

    final uri = Uri.parse('${AuthService.baseUrl}/api/Products')
        .replace(queryParameters: queryParams);

    final response = await http.get(uri, headers: AuthService.publicHeaders);

    if (response.statusCode != 200) {
      throw Exception('Failed to load products (${response.statusCode})');
    }

    // Response: {"message": "...", "data": [...]} OR plain [...] 
    final List<dynamic> data = AuthService.parseResponseList(response.body);
    return data
        .map((item) => Product.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Fetches a single product's details.
  ///
  /// The detail endpoint returns the full product including:
  /// brand{brandId, name}, seller{sellerId, storeName}, 
  /// subCategory{subCategoryId, name, category{categoryId, name}},
  /// productImages[{imageId, imageUrl, isMain}], specifications, productVariants
  static Future<Product?> fetchProductDetail(int id) async {
    try {
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/api/Products/$id'),
        headers: AuthService.publicHeaders,
      );
      if (response.statusCode == 200) {
        final data = AuthService.parseResponseMap(response.body);
        if (data != null) {
          return Product.fromJson(data);
        }
      }
    } catch (_) {}
    return null;
  }

  /// Fetches products for a specific seller (requires auth).
  static Future<List<Product>> fetchSellerProducts() async {
    try {
      final headers = await AuthService.authHeaders;
      if (!headers.containsKey('Authorization')) return [];

      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/api/Products/my-products'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = AuthService.parseResponseList(response.body);
        return data
            .map((item) => Product.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  /// Fetches reviews for a specific product.
  ///
  /// API: GET /api/ProductReviews/product/{productId}
  static Future<List<Map<String, dynamic>>> fetchProductReviews(int productId) async {
    try {
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/api/ProductReviews/product/$productId'),
        headers: AuthService.publicHeaders,
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = AuthService.parseResponseList(response.body);
        return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } catch (_) {}
    return [];
  }

  /// Posts a new product review (requires auth).
  ///
  /// API: POST /api/ProductReviews
  /// Body: {productId: int, rating: int (1-5), comment: string?}
  static Future<bool> postReview({
    required int productId,
    required int rating,
    String? comment,
  }) async {
    try {
      final headers = await AuthService.authHeaders;
      if (!headers.containsKey('Authorization')) return false;

      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/api/ProductReviews'),
        headers: headers,
        body: jsonEncode({
          'productId': productId,
          'rating': rating,
          if (comment != null && comment.isNotEmpty) 'comment': comment,
        }),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {}
    return false;
  }

  /// Upload a product image
  ///
  /// API: POST /api/Products/upload-image
  /// Body: multipart/form-data with image file
  static Future<String?> uploadProductImage(String imagePath) async {
    try {
      final headers = await AuthService.authHeaders;
      headers.remove('Content-Type');

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${AuthService.baseUrl}/api/Products/upload-image'),
      )
        ..headers.addAll(headers);

      final file = await http.MultipartFile.fromPath(
        'image',
        imagePath,
        contentType: MediaType('image', 'jpeg'),
      );
      request.files.add(file);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = AuthService.parseResponseMap(response.body);
        return data?['imageUrl'] as String?;
      }
    } catch (_) {}
    return null;
  }
}
