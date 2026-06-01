import 'product_model.dart';
import 'user_model.dart';

class Cart {
  final dynamic cartId;
  final dynamic customerId;
  final List<CartItem> cartItems;
  final User? customer;

  Cart({
    this.cartId,
    this.customerId,
    this.cartItems = const [],
    this.customer,
  });

  factory Cart.fromJson(Map<String, dynamic> json) {
    return Cart(
      cartId: json['cartId'],
      customerId: json['customerId'],
      cartItems: json['cartItems'] != null
          ? (json['cartItems'] as List).map((i) => CartItem.fromJson(i)).toList()
          : [],
      customer: json['customer'] != null ? User.fromJson(json['customer']) : null,
    );
  }

  double get totalPrice {
    double total = 0;
    for (var item in cartItems) {
      if (item.product != null) {
        total += item.product!.price * item.quantity;
      }
    }
    return total;
  }
}

class CartItem {
  final dynamic cartItemId;
  final dynamic cartId;
  final dynamic productId;
  final int quantity;
  final Product? product;

  CartItem({
    this.cartItemId,
    this.cartId,
    this.productId,
    this.quantity = 1,
    this.product,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      cartItemId: json['cartItemId'],
      cartId: json['cartId'],
      productId: json['productId'],
      quantity: json['quantity'] ?? 1,
      product: json['product'] != null ? Product.fromJson(json['product']) : null,
    );
  }
}

class CartItemRequestDto {
  final dynamic productId;
  final int quantity;

  CartItemRequestDto({
    required this.productId,
    required this.quantity,
  });

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'quantity': quantity,
    };
  }
}
