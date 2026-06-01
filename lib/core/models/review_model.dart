class ProductReview {
  final int? reviewId;
  final int productId;
  final int? userId;
  final int rating;
  final String? comment;
  final DateTime? createdAt;
  final String? userName; // Helper for UI
  final String? userEmail; // Helper for UI

  ProductReview({
    this.reviewId,
    required this.productId,
    this.userId,
    required this.rating,
    this.comment,
    this.createdAt,
    this.userName,
    this.userEmail,
  });

  factory ProductReview.fromJson(Map<String, dynamic> json) {
    // Helper to find field by any name/case
    dynamic find(Map<String, dynamic>? map, List<String> keys) {
      if (map == null) return null;
      for (var key in keys) {
        if (map.containsKey(key)) return map[key];
        // Try lowercase version
        final lowerKey = key.toLowerCase();
        final match = map.keys.firstWhere(
            (k) => k.toLowerCase() == lowerKey,
            orElse: () => '');
        if (match.isNotEmpty) return map[match];
      }
      return null;
    }

    final user = json['user'] as Map<String, dynamic>?;

    // Robust ID parsing
    int? parseId(dynamic val) {
      if (val == null) return null;
      if (val is int) return val;
      return int.tryParse(val.toString());
    }

    return ProductReview(
      reviewId: parseId(find(json, ['reviewId', 'id', 'ReviewId'])),
      productId: parseId(find(json, ['productId', 'ProductId'])) ?? 0,
      userId: parseId(find(json, ['userId', 'UserId'])) ??
          parseId(find(user, ['userId', 'id', 'UserId'])),
      rating: parseId(find(json, ['rating', 'Rating'])) ?? 5,
      comment: find(json, ['comment', 'Comment', 'content']) as String?,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      userName: find(user, ['fullName', 'name', 'userName', 'username']) ??
          find(json, ['userName', 'username', 'fullName', 'name']),
      userEmail: find(user, ['email', 'Email']) as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'rating': rating,
      'comment': comment,
      // userId is typically handled by the backend token
    };
  }
}
