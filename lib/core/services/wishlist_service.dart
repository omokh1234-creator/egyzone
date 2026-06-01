import 'package:http/http.dart' as http;
import '../models/wishlist_model.dart';
import 'auth_service.dart';

class WishlistService {
  static Future<List<WishlistItem>> getWishlist() async {
    final headers = await AuthService.authHeaders;
    
    final response = await http.get(
      Uri.parse('${AuthService.baseUrl}/api/Wishlist'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = AuthService.parseResponseList(response.body);
      return data
          .map((item) => WishlistItem.fromJson(item as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Failed to load wishlist: ${response.statusCode}');
    }
  }

  static Future<void> addToWishlist(int productId) async {
    final headers = await AuthService.authHeaders;
    
    final response = await http.post(
      Uri.parse('${AuthService.baseUrl}/api/Wishlist/$productId'),
      headers: headers,
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to add to wishlist: ${response.statusCode}');
    }
  }

  static Future<void> removeFromWishlist(int wishlistItemId) async {
    final headers = await AuthService.authHeaders;
    
    final response = await http.delete(
      Uri.parse('${AuthService.baseUrl}/api/Wishlist/$wishlistItemId'),
      headers: headers,
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to remove from wishlist: ${response.statusCode}');
    }
  }

  static Future<void> clearWishlist() async {
    final headers = await AuthService.authHeaders;
    
    final response = await http.delete(
      Uri.parse('${AuthService.baseUrl}/api/Wishlist/clear'),
      headers: headers,
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to clear wishlist: ${response.statusCode}');
    }
  }
}
