class OrderItem {
  final dynamic orderItemId;
  final dynamic orderId;
  final dynamic productId;
  final int quantity;
  final double price;
  final Map<String, dynamic>? product;

  OrderItem({
    this.orderItemId,
    this.orderId,
    this.productId,
    this.quantity = 1,
    this.price = 0.0,
    this.product,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      orderItemId: json['orderItemId'],
      orderId: json['orderId'],
      productId: json['productId'],
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      product: json['product'] as Map<String, dynamic>?,
    );
  }
}

class Order {
  final dynamic orderId;
  final dynamic customerId;
  final double totalAmount;
  final String status;
  final String? createdAt;
  final dynamic couponId;
  final String? paymentMethod;
  final List<OrderItem> orderItems;
  final Map<String, dynamic>? coupon;

  Order({
    this.orderId,
    this.customerId,
    this.totalAmount = 0.0,
    this.status = 'Pending',
    this.createdAt,
    this.couponId,
    this.paymentMethod,
    this.orderItems = const [],
    this.coupon,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      orderId: json['orderId'],
      customerId: json['customerId'],
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'Pending',
      createdAt: json['createdAt'] as String?,
      couponId: json['couponId'],
      paymentMethod: json['paymentMethod'] as String?,
      orderItems: (json['orderItems'] as List<dynamic>? ?? [])
          .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      coupon: json['coupon'] as Map<String, dynamic>?,
    );
  }
}

class PlaceOrderDto {
  final String paymentMethod;
  final String? couponCode;
  final int? addressId;

  PlaceOrderDto({
    required this.paymentMethod,
    this.couponCode,
    this.addressId,
  });

  Map<String, dynamic> toJson() => {
        'paymentMethod': paymentMethod,
        if (couponCode != null && couponCode!.isNotEmpty)
          'couponCode': couponCode,
        if (addressId != null) 'addressId': addressId,
      };
}
