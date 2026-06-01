class WishlistItem {
  final int? wishlistItemId;
  final int? productId;
  final int? userId;
  final DateTime? addedAt;

  WishlistItem({
    this.wishlistItemId,
    this.productId,
    this.userId,
    this.addedAt,
  });

  factory WishlistItem.fromJson(Map<String, dynamic> json) {
    return WishlistItem(
      wishlistItemId: json['wishlistItemId'] as int?,
      productId: json['productId'] as int?,
      userId: json['userId'] as int?,
      addedAt: json['addedAt'] != null 
          ? DateTime.parse(json['addedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'wishlistItemId': wishlistItemId,
      'productId': productId,
      'userId': userId,
      'addedAt': addedAt?.toIso8601String(),
    };
  }
}
