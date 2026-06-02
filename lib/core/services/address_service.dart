import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/address_model.dart';
import '../services/auth_service.dart';

class AddressService {
  /// Fetch all addresses for the authenticated user
  static Future<List<Address>> getAddresses() async {
    final headers = await AuthService.authHeaders;
    final response = await http.get(
      Uri.parse('${AuthService.baseUrl}/api/Addresses'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = AuthService.parseResponseList(response.body);
      return data
          .map((e) => Address.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception(
          'Failed to load addresses: ${response.statusCode} - ${response.body}');
    }
  }

  /// Add a new address
  static Future<void> addAddress(Address address) async {
    final headers = await AuthService.authHeaders;
    final response = await http.post(
      Uri.parse('${AuthService.baseUrl}/api/Addresses'),
      headers: headers,
      body: jsonEncode(address.toJson()),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      final data = jsonDecode(response.body);
      throw Exception(
          data['message'] ?? 'Failed to add address: ${response.statusCode}');
    }
  }

  /// Delete an address by id
  static Future<void> deleteAddress(dynamic addressId) async {
    final headers = await AuthService.authHeaders;
    final response = await http.delete(
      Uri.parse('${AuthService.baseUrl}/api/Addresses/$addressId'),
      headers: headers,
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(
          'Failed to delete address: ${response.statusCode}');
    }
  }

  /// Update an existing address
  static Future<void> updateAddress(int addressId, Address address) async {
    final headers = await AuthService.authHeaders;
    final response = await http.put(
      Uri.parse('${AuthService.baseUrl}/api/Addresses/$addressId'),
      headers: headers,
      body: jsonEncode(address.toJson()),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      final data = jsonDecode(response.body);
      throw Exception(
          data['message'] ?? 'Failed to update address: ${response.statusCode}');
    }
  }
}
