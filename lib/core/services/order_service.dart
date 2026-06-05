import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/order_model.dart';
import '../services/auth_service.dart';

class OrderService {
  /// Place a new order
  /// Uses PlaceOrderDto: { paymentMethod, couponCode }
  static Future<Order> placeOrder({
    required String paymentMethod,
    String? couponCode,
    int? addressId,
  }) async {
    final headers = await AuthService.authHeaders;
    final body = PlaceOrderDto(
      paymentMethod: paymentMethod,
      couponCode: couponCode,
      addressId: addressId,
    ).toJson();

    final response = await http.post(
      Uri.parse('${AuthService.baseUrl}/api/Orders/place-order'),
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = AuthService.parseResponseMap(response.body);
      // API may return the order object or just a success message
      if (data != null && data.containsKey('orderId')) {
        return Order.fromJson(data);
      }
      return Order(status: 'Placed');
    } else {
      final data = jsonDecode(response.body);
      throw Exception(
          data['message'] ?? 'Failed to place order: ${response.statusCode}');
    }
  }

  /// Fetch all orders for the authenticated user
  static Future<List<Order>> getMyOrders() async {
    final headers = await AuthService.authHeaders;
    final response = await http.get(
      Uri.parse('${AuthService.baseUrl}/api/Orders/my-orders'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = AuthService.parseResponseList(response.body);
      return data
          .map((e) => Order.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception(
          'Failed to load orders: ${response.statusCode} - ${response.body}');
    }
  }

  /// Cancel an order
  static Future<void> cancelOrder(int orderId) async {
    final headers = await AuthService.authHeaders;
    final response = await http.post(
      Uri.parse('${AuthService.baseUrl}/api/Orders/$orderId/cancel'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      String errorMessage = 'Failed to cancel order: ${response.statusCode}';
      try {
        final data = jsonDecode(response.body);
        if (data['message'] != null) {
          errorMessage = data['message'];
        }
      } catch (_) {}
      throw Exception(errorMessage);
    }
  }

  /// Fetch all orders for the seller's products
  static Future<List<Order>> getSellerOrders() async {
    final headers = await AuthService.authHeaders;
    final response = await http.get(
      Uri.parse('${AuthService.baseUrl}/api/Orders/seller-orders'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = AuthService.parseResponseList(response.body);
      return data
          .map((e) => Order.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Failed to load seller orders: ${response.statusCode}');
    }
  }

  /// Update order status (seller action: e.g. Shipped, Delivered)
  static Future<void> updateOrderStatus(int orderId, String status) async {
    final headers = await AuthService.authHeaders;
    final response = await http.put(
      Uri.parse('${AuthService.baseUrl}/api/Orders/$orderId/status'),
      headers: headers,
      body: jsonEncode({'status': status}),
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      String errorMessage = 'Failed to update order status: ${response.statusCode}';
      try {
        final data = jsonDecode(response.body);
        if (data['message'] != null) errorMessage = data['message'];
      } catch (_) {}
      throw Exception(errorMessage);
    }
  }
}
