import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Holds the currently logged-in user's profile in memory.
/// Call [loadProfile] after login to populate it.
class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null;

  String get displayName =>
      _currentUser?.fullName?.isNotEmpty == true
          ? _currentUser!.fullName!
          : 'Guest';

  String get displayEmail => _currentUser?.email ?? '';
  String get displayRole => (_currentUser?.role ?? 'customer').toLowerCase();

  bool get isAdmin => displayRole == 'admin';
  bool get isSeller => displayRole == 'seller';
  bool get isCustomer => displayRole == 'customer' || !isLoggedIn;

  /// Fetch user profile from the API and cache in memory
  Future<void> loadProfile() async {
    final token = await AuthService.getToken();
    if (token == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/api/UserProfile/profile'),
        headers: await AuthService.authHeaders,
      );

      if (response.statusCode == 200) {
        final data = AuthService.parseResponseMap(response.body);
        if (data != null) {
          _currentUser = User.fromJson(data);
        } else {
          _error = 'Failed to parse profile data';
        }
      } else {
        _error = 'Failed to load profile (${response.statusCode})';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update user profile and refresh
  Future<void> updateProfile({
    required String fullName,
    required String phoneNumber,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('${AuthService.baseUrl}/api/UserProfile/update'),
        headers: await AuthService.authHeaders,
        body: jsonEncode({
          'fullName': fullName,
          'phoneNumber': phoneNumber,
        }),
      );

      if (response.statusCode == 200) {
        await loadProfile();
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Failed to update profile');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Clear user on logout
  void logout() {
    _currentUser = null;
    _error = null;
    notifyListeners();
  }
}
