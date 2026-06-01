import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../core/services/auth_service.dart';
import '../models/cart_model.dart';

class CartService {
  /// Fetch all cart items for the authenticated user
  static Future<List<CartItem>> getCartItems() async {
    final headers = await AuthService.authHeaders;
    final response = await http.get(
      Uri.parse('${AuthService.baseUrl}/api/CartItems'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = AuthService.parseResponseList(response.body);
      return data.map((item) => CartItem.fromJson(item as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to load cart items: ${response.statusCode} - ${response.body}');
    }
  }

  /// Add a product to the cart
  static Future<void> addToCart(dynamic productId, int quantity) async {
    final headers = await AuthService.authHeaders;
    final response = await http.post(
      Uri.parse('${AuthService.baseUrl}/api/CartItems'),
      headers: headers,
      body: jsonEncode({
        'productId': productId,
        'quantity': quantity,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to add to cart: ${response.statusCode} - ${response.body}');
    }
  }

  /// Remove a product from the cart
  static Future<void> removeFromCart(dynamic cartItemId) async {
    final headers = await AuthService.authHeaders;
    final response = await http.delete(
      Uri.parse('${AuthService.baseUrl}/api/CartItems/$cartItemId'),
      headers: headers,
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to remove from cart: ${response.statusCode} - ${response.body}');
    }
  }
}
