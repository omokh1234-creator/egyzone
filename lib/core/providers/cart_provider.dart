import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';
import '../services/coupon_service.dart';

class CartProvider extends ChangeNotifier {
  static const String _cartKey = 'user_cart_items';
  List<Map<String, dynamic>> _items = [];
  bool _isLoaded = false;
  Map<String, dynamic>? _appliedCoupon;

  CartProvider() {
    _loadFromPrefs();
  }

  List<Map<String, dynamic>> get items => _items;
  Map<String, dynamic>? get appliedCoupon => _appliedCoupon;

  int get totalItems => _items.fold(0, (sum, item) {
        final quantity = item['quantity'] is int ? item['quantity'] as int : 0;
        return sum + quantity;
      });

  double get subtotal => _items.fold(0.0, (sum, item) {
        final price =
            item['price'] is num ? (item['price'] as num).toDouble() : 0.0;
        final quantity = item['quantity'] is int ? item['quantity'] as int : 0;
        return sum + (price * quantity);
      });

  double get discount {
    if (_appliedCoupon == null) return 0.0;
    
    // Handle potential array response like [{...}]
    final Map<String, dynamic> rawData = (_appliedCoupon is List && (_appliedCoupon as List).isNotEmpty)
        ? (_appliedCoupon as List).first as Map<String, dynamic>
        : (_appliedCoupon is Map ? _appliedCoupon as Map<String, dynamic> : {});

    // Handle potential wrapper like { "data": { ... } }
    final data = rawData['data'] is Map 
        ? rawData['data'] as Map<String, dynamic>
        : rawData;

    if (data.isEmpty) return 0.0;

    // Handle both camelCase and PascalCase and common shortened names
    final isPercentage = data['isPercentage'] ?? 
                       data['IsPercentage'] ?? 
                       data['percentage'] ?? 
                       true;
    
    final discountVal = (data['discount'] ?? 
                        data['Discount'] ??
                        data['discountPercent'] ?? 
                        data['DiscountPercent'] ?? 
                        data['percent'] ?? 
                        data['Percent'] ??
                        data['discountAmount'] ?? 
                        data['DiscountAmount'] ?? 
                        data['amount'] ?? 
                        data['Amount'] ??
                        data['value'] ?? 
                        data['Value'] ??
                        0) as num;
    
    final currentSubtotal = subtotal;
    debugPrint('CartProvider: Discount Calculation -> Subtotal: $currentSubtotal, Value: $discountVal, IsPercent: $isPercentage');
    debugPrint('CartProvider: Items in cart: ${_items.length}');
    for (var item in _items) {
      debugPrint('CartProvider: Item: ${item['name']}, Price: ${item['price']}, Qty: ${item['quantity']}');
    }

    if (isPercentage) {
      return currentSubtotal * (discountVal / 100);
    } else {
      return discountVal.toDouble();
    }
  }

  double get total => subtotal - discount;

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? cartData = prefs.getString(_cartKey);
      if (cartData != null && cartData.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(cartData);
        _items = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (e) {
      debugPrint('CartProvider: Error loading cart: $e');
    } finally {
      _isLoaded = true;
      notifyListeners();
      refreshFromServer();
    }
  }

  Future<void> refreshFromServer() async {
    try {
      final headers = await AuthService.authHeaders;
      if (!headers.containsKey('Authorization')) return;

      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/api/CartItems'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final dynamic rawItems;
        if (data is List) {
          rawItems = data;
        } else if (data is Map) {
          final env = data['data'];
          if (env is List) {
            rawItems = env;
          } else if (env is Map) {
            rawItems = env['cartItems'] ?? env['CartItems'] ?? [];
          } else {
            rawItems = data['cartItems'] ?? data['CartItems'] ?? [];
          }
        } else {
          rawItems = [];
        }

        if (rawItems is List) {
          final List<Map<String, dynamic>> serverItemsList = [];
          for (final item in rawItems) {
            if (item is! Map<String, dynamic>) continue;

            final productMap = item['product'] as Map<String, dynamic>?;
            final id = item['productId'] ?? productMap?['id'] ?? productMap?['productId'] ?? item['ProductId'];
            if (id == null) continue;

            final imageList = (item['images'] ?? productMap?['images']) as List<dynamic>?;
            String resolvedUrl = item['imageUrl'] as String? ?? 
                               productMap?['imageUrl'] as String? ?? 
                               productMap?['ImageUrl'] as String? ?? 
                               item['image'] as String? ?? 
                               productMap?['image'] as String? ?? 
                               '';
                               
            if (resolvedUrl.isEmpty && imageList != null && imageList.isNotEmpty) {
              final firstImage = imageList[0];
              if (firstImage is Map) {
                resolvedUrl = (firstImage['url'] ?? firstImage['imageUrl'] ?? '') as String;
              } else if (firstImage is String) {
                resolvedUrl = firstImage;
              }
            }

            serverItemsList.add({
              'id': id,
              'productId': id,
              'cartItemId': item['cartItemId'],
              'name': item['productName'] ?? productMap?['name'] ?? productMap?['Name'] ?? 'Product',
              'price': (item['price'] as num?)?.toDouble() ?? (productMap?['price'] as num?)?.toDouble() ?? 0.0,
              'imageUrl': resolvedUrl,
              'images': imageList,
              'quantity': (item['quantity'] as num?)?.toInt() ?? 1,
              'stock': (item['stock'] as num?)?.toInt() ?? (productMap?['stock'] as num?)?.toInt() ?? 1,
              'inStock': true,
            });
          }

          // Merge server items with local items
          for (final serverItem in serverItemsList) {
            final localIndex = _items.indexWhere((local) => local['id'].toString() == serverItem['id'].toString());
            if (localIndex >= 0) {
              final localItem = _items[localIndex];
              final serverUrl = serverItem['imageUrl'] as String? ?? '';
              _items[localIndex] = {
                ...localItem,
                ...serverItem,
                'imageUrl': serverUrl.isNotEmpty ? serverUrl : (localItem['imageUrl'] ?? ''),
                'images': (serverItem['images'] as List?)?.isNotEmpty == true ? serverItem['images'] : localItem['images'],
              };
            } else {
              _items.add(serverItem);
            }
          }

          _items.removeWhere((local) {
            if (local['cartItemId'] == null) return false;
            return !serverItemsList.any((s) => s['id'].toString() == local['id'].toString());
          });

          _saveToPrefs();
          notifyListeners();
          debugPrint('CartProvider: Sync completed. Total items: ${_items.length}');
        }
      }
    } catch (e) {
      debugPrint('CartProvider: Sync error: $e');
    }
  }

  Future<void> _saveToPrefs() async {
    if (!_isLoaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final savableItems = _items.map((item) {
        return {
          'id': item['id'],
          'productId': item['productId'],
          'name': item['name'],
          'price': item['price'],
          'imageUrl': item['imageUrl'],
          'images': item['images'],
          'quantity': item['quantity'],
          'category': item['category'],
          'subcategory': item['subcategory'],
          'stock': item['stock'],
          'inStock': item['inStock'],
          'cartItemId': item['cartItemId'],
        };
      }).toList();
      await prefs.setString(_cartKey, jsonEncode(savableItems));
    } catch (e) {
      debugPrint('CartProvider: Error saving cart: $e');
    }
  }





  /// Resolves the correct id — API returns productId, local uses id
  dynamic _resolveId(Map<String, dynamic> product) {
    return product['id'] ?? product['productId'];
  }

  void addItem(Map<String, dynamic> product, {int quantity = 1, bool overwriteQuantity = false}) {
    final id = _resolveId(product);
    if (id == null) return;

    // Resolve image URL for local add
    final productMap = product['product'] as Map<String, dynamic>?;
    final imageList = (product['images'] ?? productMap?['images'] ?? product['Images']) as List<dynamic>?;
    String resolvedUrl = (product['imageUrl'] ?? product['ImageUrl'] ?? productMap?['imageUrl'] ?? product['image'] ?? productMap?['image'] ?? '') as String;
    
    if (resolvedUrl.isEmpty && imageList != null && imageList.isNotEmpty) {
      final firstImage = imageList[0];
      if (firstImage is Map) {
        resolvedUrl = (firstImage['url'] ?? firstImage['imageUrl'] ?? '') as String;
      } else if (firstImage is String) {
        resolvedUrl = firstImage;
      }
    }

    final normalized = Map<String, dynamic>.from(product);
    normalized['id'] = id;
    normalized['imageUrl'] = resolvedUrl;
    normalized['images'] = imageList;
    
    final index = _items.indexWhere(
      (item) => item['id'].toString() == id.toString(),
    );
    
    if (index >= 0) {
      if (overwriteQuantity) {
        _items[index]['quantity'] = quantity;
      } else {
        _items[index]['quantity'] = (_items[index]['quantity'] as int) + quantity;
      }
      _syncUpdateQuantityToApi(id, _items[index]['quantity']);
    } else {
      normalized['quantity'] = quantity;
      _items.add(normalized);
      _syncAddItemToApi(id, quantity);
    }
    
    debugPrint('CartProvider: Item added. Total items: ${_items.length}');
    _saveToPrefs();
    notifyListeners();
  }

  void removeItem(dynamic id) {
    // Find the item to get its cartItemId before removing it
    final item = _items.firstWhere(
      (item) => item['id'].toString() == id.toString(),
      orElse: () => {},
    );
    final idToRemove = item['cartItemId'] ?? id;

    _items.removeWhere((item) => item['id'].toString() == id.toString());
    _syncRemoveItemFromApi(idToRemove);
    _saveToPrefs();
    notifyListeners();
  }

  void increment(dynamic id) {
    final index = _items.indexWhere(
      (item) => item['id'].toString() == id.toString(),
    );
    if (index >= 0) {
      _items[index]['quantity'] = (_items[index]['quantity'] as int) + 1;
      _syncUpdateQuantityToApi(id, _items[index]['quantity']);
      _saveToPrefs();
      notifyListeners();
    }
  }

  void decrement(dynamic id) {
    final index = _items.indexWhere(
      (item) => item['id'].toString() == id.toString(),
    );
    if (index >= 0 && (_items[index]['quantity'] as int) > 1) {
      _items[index]['quantity'] = (_items[index]['quantity'] as int) - 1;
      _syncUpdateQuantityToApi(id, _items[index]['quantity']);
      _saveToPrefs();
      notifyListeners();
    }
  }

  void clearCart() {
    // Capture the correct IDs for deletion (prefer cartItemId if available)
    final idsToRemove = _items.map((item) => item['cartItemId'] ?? item['id']).toList();
    
    _items.clear();
    _appliedCoupon = null;
    _saveToPrefs();
    notifyListeners();

    // Sync clear to API using the correct IDs
    for (final id in idsToRemove) {
      _syncRemoveItemFromApi(id);
    }
  }

  Future<void> applyCoupon(String code) async {
    try {
      final couponData = await CouponService.validateCoupon(code);
      debugPrint('CartProvider: Applied Coupon API Response: $couponData');
      debugPrint('CartProvider: Coupon Data Type: ${couponData.runtimeType}');
      debugPrint('CartProvider: Coupon Keys: ${couponData.keys.toList()}');
      _appliedCoupon = couponData;
      notifyListeners();
    } catch (e) {
      debugPrint('CartProvider: Coupon validation error: $e');
      _appliedCoupon = null;
      notifyListeners();
      rethrow;
    }
  }

  void removeCoupon() {
    _appliedCoupon = null;
    notifyListeners();
  }

  // ─── API Syncing ──────────────────────────────────────────────────────────

  Future<void> _syncAddItemToApi(dynamic productId, int quantity) async {
    try {
      final headers = await AuthService.authHeaders;
      if (!headers.containsKey('Authorization')) {
        debugPrint('CartProvider: Skipping API sync (not logged in)');
        return;
      }

      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/api/CartItems'),
        headers: headers,
        body: jsonEncode({
          'productId': productId is String ? int.tryParse(productId) : productId,
          'quantity': quantity
        }),
      );
      
      debugPrint('CartProvider: API Add Status: ${response.statusCode}');
      if (response.statusCode != 200 && response.statusCode != 201) {
        debugPrint('CartProvider: API Add Error Body: ${response.body}');
      }
    } catch (e) {
      debugPrint('CartProvider: API Sync Add Error: $e');
    }
  }

  Future<void> _syncRemoveItemFromApi(dynamic productId) async {
    try {
      final headers = await AuthService.authHeaders;
      if (!headers.containsKey('Authorization')) return;

      final response = await http.delete(
        Uri.parse('${AuthService.baseUrl}/api/CartItems/$productId'),
        headers: headers,
      );
      
      debugPrint('CartProvider: API Remove Status: ${response.statusCode}');
    } catch (e) {
      debugPrint('CartProvider: API Sync Remove Error: $e');
    }
  }

  Future<void> _syncUpdateQuantityToApi(dynamic productId, int quantity) async {
    // To prevent the "snowball" effect where the server increments the total,
    // we only sync when adding NEW items or we use a more specific update logic.
    // If the server POST increments, we should only send the delta.
    // For now, we will skip syncing the 'total' on every increment to be safe,
    // as the local state is the source of truth during the session.
    debugPrint('CartProvider: Skipping redundant quantity sync for $productId to prevent snowball effect');
  }
}
