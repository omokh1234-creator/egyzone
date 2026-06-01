class Coupon {
  final int? couponId;
  final String? code;
  final int? discountPercent;
  final String? expiryDate;
  final int? maxUsage;
  final int? usedCount;
  final double? discountAmount;
  final bool? isPercentage;

  Coupon({
    this.couponId,
    this.code,
    this.discountPercent,
    this.expiryDate,
    this.maxUsage,
    this.usedCount,
    this.discountAmount,
    this.isPercentage,
  });

  factory Coupon.fromJson(Map<String, dynamic> json) {
    return Coupon(
      couponId: json['couponId'] as int?,
      code: json['code'] as String?,
      discountPercent: json['discountPercent'] as int?,
      expiryDate: json['expiryDate'] as String?,
      maxUsage: json['maxUsage'] as int?,
      usedCount: json['usedCount'] as int?,
      discountAmount: (json['discountAmount'] as num?)?.toDouble(),
      isPercentage: json['isPercentage'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'couponId': couponId,
      'code': code,
      'discountPercent': discountPercent,
      'expiryDate': expiryDate,
      'maxUsage': maxUsage,
      'usedCount': usedCount,
      'discountAmount': discountAmount,
      'isPercentage': isPercentage,
    };
  }
}

class CreateCouponDto {
  final String? code;
  final int? discountPercent;
  final String? expiryDate;
  final int? maxUsage;
  final bool? isPercentage;

  CreateCouponDto({
    this.code,
    this.discountPercent,
    this.expiryDate,
    this.maxUsage,
    this.isPercentage,
  });

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'discountPercent': discountPercent,
      'expiryDate': expiryDate,
      'maxUsage': maxUsage,
      'isPercentage': isPercentage,
    };
  }
}
