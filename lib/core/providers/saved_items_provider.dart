import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';

class SavedItemsProvider extends ChangeNotifier {
  static const String _savedKey = 'user_saved_items';
  List<Map<String, dynamic>> _items = [];
  bool _isLoaded = false;

  SavedItemsProvider() {
    _loadFromPrefs();
  }

  List<Map<String, dynamic>> get items => _items;

  bool isSaved(dynamic id) {
    return _items.any((item) => item['id'].toString() == id.toString());
  }

  void toggleItem(Map<String, dynamic> product) {
    final id = product['id'] ?? product['productId'];
    final index = _items.indexWhere(
      (item) => item['id'].toString() == id.toString(),
    );

    if (index >= 0) {
      _items.removeAt(index);
      _syncRemoveItemFromApi(id);
    } else {
      String imageUrl = '';
      if (product['imageUrl'] != null &&
          (product['imageUrl'] as String).isNotEmpty) {
        imageUrl = product['imageUrl'] as String;
      } else if (product['images'] != null &&
          (product['images'] as List).isNotEmpty) {
        imageUrl = (product['images'] as List).first['url'] as String? ?? '';
      }

      _items.add({
        'id': id,
        'name': product['name'],
        'price': '${product["price"]}',
        'image': imageUrl,
        'semanticLabel': product['name'],
      });
      _syncAddItemToApi(id);
    }
    _saveToPrefs();
    notifyListeners();
  }

  void removeItem(dynamic id) {
    _items.removeWhere((item) => item['id'].toString() == id.toString());
    _saveToPrefs();
    notifyListeners();
  }

  // ─── Persistence ──────────────────────────────────────────────────────────

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? data = prefs.getString(_savedKey);
      if (data != null) {
        final List<dynamic> decoded = jsonDecode(data);
        _items = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (e) {
      debugPrint('SavedItemsProvider: Load error: $e');
    } finally {
      _isLoaded = true;
      notifyListeners();
      // Initial sync check
      final headers = await AuthService.authHeaders;
      if (headers.containsKey('Authorization')) {
        syncWithServer();
      }
    }
  }

  Future<void> _saveToPrefs() async {
    if (!_isLoaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_savedKey, jsonEncode(_items));
    } catch (e) {
      debugPrint('SavedItemsProvider: Save error: $e');
    }
  }

  // ─── Cloud Sync ───────────────────────────────────────────────────────────

  /// Bidirectional sync: Pulls from server AND pushes unique local items to server
  Future<void> syncWithServer() async {
    try {
      final headers = await AuthService.authHeaders;
      if (!headers.containsKey('Authorization')) return;

      // 1. Fetch current server wishlist
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/api/Wishlist'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = AuthService.parseResponseList(response.body);
        if (data.isNotEmpty) {
          final List<dynamic> serverProductIds = data.map((item) {
            final productMap = item['product'] as Map<String, dynamic>?;
            return item['productId'] ?? productMap?['productId'] ?? productMap?['id'];
          }).toList();

          // 2. Push local items that aren't on the server yet
          for (final localItem in _items) {
            final localId = localItem['id'];
            if (!serverProductIds.contains(localId)) {
              await _syncAddItemToApi(localId);
            }
          }

          // 3. Add server items that aren't in local list
          bool changed = false;
          for (final serverItem in data) {
            final productMap = serverItem['product'] as Map<String, dynamic>?;
            if (productMap == null) continue;

            final id = serverItem['productId'] ?? productMap['productId'] ?? productMap['id'];
            // Store the wishlist item ID if available so we can delete it later
            final wishlistItemId = serverItem['id'];

            if (!isSaved(id)) {
              _items.add({
                'id': id,
                'wishlistItemId': wishlistItemId,
                'name': productMap['name'] ?? 'Product',
                'price': '${productMap["price"] ?? 0}',
                'image': productMap['imageUrl'] ?? '',
                'semanticLabel': productMap['name'],
              });
              changed = true;
            } else {
              // Update existing local item with wishlistItemId if missing
              final index = _items.indexWhere((item) => item['id'].toString() == id.toString());
              if (index >= 0 && _items[index]['wishlistItemId'] == null) {
                _items[index]['wishlistItemId'] = wishlistItemId;
                changed = true;
              }
            }
          }

          if (changed) {
            _saveToPrefs();
            notifyListeners();
          }
        }
      }
    } catch (_) {}
  }

  Future<void> refreshFromServer() => syncWithServer();

  Future<void> _syncAddItemToApi(dynamic productId) async {
    try {
      final headers = await AuthService.authHeaders;
      if (!headers.containsKey('Authorization')) return;

      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/api/Wishlist/$productId'),
        headers: headers,
      );
      
      // We could try to fetch the new wishlistItemId here, but it's easier to just sync again later.
      if (response.statusCode == 200) {
        // Optionally trigger a sync to get the new wishlistItemId
        // syncWithServer();
      }
    } catch (_) {}
  }

  Future<void> _syncRemoveItemFromApi(dynamic productId) async {
    try {
      final headers = await AuthService.authHeaders;
      if (!headers.containsKey('Authorization')) return;

      // Find the wishlistItemId locally before deleting
      final index = _items.indexWhere((item) => item['id'].toString() == productId.toString());
      final wishlistItemId = index >= 0 ? _items[index]['wishlistItemId'] : null;

      if (wishlistItemId != null) {
        await http.delete(
          Uri.parse('${AuthService.baseUrl}/api/Wishlist/$wishlistItemId'),
          headers: headers,
        );
      } else {
        // Fallback: If we don't know the wishlistItemId, we can't easily delete it without fetching first, 
        // but maybe the API still supports deleting by productId? (Swagger doesn't show it, so we skip).
      }
    } catch (_) {}
  }
}
