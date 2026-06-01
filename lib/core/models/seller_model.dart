class Seller {
  final int? sellerId;
  final String? storeName;
  final int? userId;
  final String? description;
  final String? contactNumber;

  Seller({
    this.sellerId,
    this.storeName,
    this.userId,
    this.description,
    this.contactNumber,
  });

  factory Seller.fromJson(Map<String, dynamic> json) {
    return Seller(
      sellerId: json['sellerId'] as int?,
      storeName: json['storeName'] as String?,
      userId: json['userId'] as int?,
      description: json['description'] as String?,
      contactNumber: json['contactNumber'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sellerId': sellerId,
      'storeName': storeName,
      'userId': userId,
      'description': description,
      'contactNumber': contactNumber,
    };
  }
}

class SellerRequestDto {
  final String? storeName;
  final String? description;
  final String? contactNumber;

  SellerRequestDto({
    this.storeName,
    this.description,
    this.contactNumber,
  });

  Map<String, dynamic> toJson() {
    return {
      'storeName': storeName,
      'description': description,
      'contactNumber': contactNumber,
    };
  }
}

class SellerDashboard {
  final int? totalProducts;
  final int? totalOrders;
  final double? totalRevenue;
  final int? pendingOrders;
  final int? completedOrders;

  SellerDashboard({
    this.totalProducts,
    this.totalOrders,
    this.totalRevenue,
    this.pendingOrders,
    this.completedOrders,
  });

  factory SellerDashboard.fromJson(Map<String, dynamic> json) {
    return SellerDashboard(
      totalProducts: json['totalProducts'] as int?,
      totalOrders: json['totalOrders'] as int?,
      totalRevenue: (json['totalRevenue'] as num?)?.toDouble(),
      pendingOrders: json['pendingOrders'] as int?,
      completedOrders: json['completedOrders'] as int?,
    );
  }
}
