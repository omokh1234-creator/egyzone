import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/review_model.dart';
import './auth_service.dart';

class ReviewService {
  static const String _endpoint = '/api/ProductReviews';

  /// Fetches all reviews for a specific product
  static Future<List<ProductReview>> getProductReviews(int productId) async {
    final response = await http.get(
      Uri.parse('${AuthService.baseUrl}$_endpoint/product/$productId'),
      headers: AuthService.publicHeaders,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = AuthService.parseResponseList(response.body);
      debugPrint('Fetched reviews for product $productId: ${response.body}');
      return data.map((item) => ProductReview.fromJson(item as Map<String, dynamic>)).toList();
    } else if (response.statusCode == 404) {
      return []; // No reviews yet
    } else {
      throw Exception('Failed to load reviews (${response.statusCode})');
    }
  }

  /// Submits a new review and returns detailed response info
  static Future<Map<String, dynamic>> submitReviewWithResponse(ProductReview review) async {
    try {
      final url = Uri.parse('${AuthService.baseUrl}$_endpoint');
      final headers = await AuthService.authHeaders;
      final body = jsonEncode(review.toJson());

      debugPrint('Submitting review to $url');
      debugPrint('Headers: $headers');
      debugPrint('Body: $body');

      final response = await http.post(
        url,
        headers: headers,
        body: body,
      );

      debugPrint('Response Status: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'message': 'Success'};
      } else {
        String errorMessage = 'Error ${response.statusCode}';
        try {
          final data = jsonDecode(response.body);
          errorMessage = data['message'] ?? data['title'] ?? errorMessage;
        } catch (_) {
          if (response.body.isNotEmpty) errorMessage = response.body;
        }
        return {'success': false, 'message': errorMessage};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Submits a new review for a product (Legacy support)
  static Future<bool> submitReview(ProductReview review) async {
    final result = await submitReviewWithResponse(review);
    return result['success'] == true;
  }

  /// Deletes a review by its ID
  static Future<bool> deleteReview(int reviewId) async {
    try {
      final url = Uri.parse('${AuthService.baseUrl}$_endpoint/$reviewId');
      final headers = await AuthService.authHeaders;

      debugPrint('Deleting review at $url');

      final response = await http.delete(
        url,
        headers: headers,
      );

      debugPrint('Delete Response Status: ${response.statusCode}');
      
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('Delete Review Error: $e');
      return false;
    }
  }

  /// Updates an existing review
  static Future<bool> updateReview(int reviewId, int rating, String comment) async {
    try {
      final url = Uri.parse('${AuthService.baseUrl}$_endpoint/$reviewId');
      final headers = await AuthService.authHeaders;
      final body = jsonEncode({
        'rating': rating,
        'comment': comment,
      });

      debugPrint('Updating review at $url');

      final response = await http.put(
        url,
        headers: headers,
        body: body,
      );

      debugPrint('Update Response Status: ${response.statusCode}');
      
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('Update Review Error: $e');
      return false;
    }
  }
}
