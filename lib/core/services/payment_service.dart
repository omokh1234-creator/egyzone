import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/payment_model.dart';
import '../services/auth_service.dart';

class PaymentService {
  /// Process a payment for an order
  /// Uses PaymentRequestDto: { orderId, methodId, cardNumber? }
  static Future<void> processPayment(PaymentRequestDto dto) async {
    final headers = await AuthService.authHeaders;
    final response = await http.post(
      Uri.parse('${AuthService.baseUrl}/api/Payments/process-payment'),
      headers: headers,
      body: jsonEncode(dto.toJson()),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      final data = jsonDecode(response.body);
      throw Exception(
          data['message'] ?? 'Failed to process payment: ${response.statusCode}');
    }
  }

  /// Fetch all payments for the authenticated user
  static Future<List<Payment>> getMyPayments() async {
    final headers = await AuthService.authHeaders;
    final response = await http.get(
      Uri.parse('${AuthService.baseUrl}/api/Payments/my-payments'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = AuthService.parseResponseList(response.body);
      return data
          .map((e) => Payment.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception(
          'Failed to load payments: ${response.statusCode} - ${response.body}');
    }
  }
}
