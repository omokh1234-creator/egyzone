import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Product Info Widget
/// Displays product name, price, rating, and stock status
class ProductInfoWidget extends StatelessWidget {
  final String name;
  final double price;
  final double originalPrice;
  final double rating;
  final int reviewCount;
  final bool inStock;
  final int stock;
  final String? sellerName;
  final String? brandName;

  const ProductInfoWidget({
    super.key,
    required this.name,
    required this.price,
    required this.originalPrice,
    required this.rating,
    required this.reviewCount,
    required this.inStock,
    required this.stock,
    this.sellerName,
    this.brandName,
  });

  String _formatPrice(double value) {
    final val = value.toStringAsFixed(2);
    final parts = val.split('.');
    final integer = parts[0].replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );
    // Only show decimal part if it's not .00
    if (parts[1] == '00') {
      return integer;
    }
    return '$integer.${parts[1]}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasDiscount = originalPrice > price;
    final discountPercentage = hasDiscount
        ? ((originalPrice - price) / originalPrice * 100).round()
        : 0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Name
          Text(
            name,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),

          if (brandName != null && brandName!.isNotEmpty) ...[
            SizedBox(height: 0.5.h),
            Text(
              brandName!,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],

          if (sellerName != null && sellerName!.isNotEmpty) ...[
            SizedBox(height: 1.h),
            Row(
              children: [
                CustomIconWidget(
                  iconName: 'storefront',
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                SizedBox(width: 2.w),
                Text(
                  'Sold by: ',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  sellerName!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],

          SizedBox(height: 1.5.h),

          // Rating and Reviews
          Row(
            children: [
              Row(
                children: List.generate(5, (index) {
                  final starValue = index + 1;
                  final isFullStar = rating >= starValue;
                  final isHalfStar =
                      rating >= starValue - 0.5 && rating < starValue;

                  return CustomIconWidget(
                    iconName: isFullStar
                        ? 'star'
                        : isHalfStar
                            ? 'star_half'
                            : 'star_border',
                    color: isFullStar || isHalfStar
                        ? const Color(0xFFFFA726)
                        : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                    size: 20,
                  );
                }),
              ),
              SizedBox(width: 2.w),
              Text(
                rating.toStringAsFixed(1),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              SizedBox(width: 2.w),
              Text(
                '($reviewCount reviews)',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),

          SizedBox(height: 2.h),

          // Price Section (HomeScreen style)
          Row(
            children: [
              Text(
                'ج.م ',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: (theme.textTheme.titleMedium?.fontSize ?? 20) * 1,
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w400,
                ),
              ),
              Text(
                _formatPrice(price),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 25,
                ),
              ),
              if (hasDiscount) ...[
                SizedBox(width: 2.w),
                Text(
                  _formatPrice(originalPrice),
                  style: theme.textTheme.titleMedium?.copyWith(
                    decoration: TextDecoration.lineThrough,
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                SizedBox(width: 2.w),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '-$discountPercentage%',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              ],
            ],
          ),

          SizedBox(height: 2.h),

          // Stock Status
          Row(
            children: [
              Container(
                width: 2.w,
                height: 2.w,
                decoration: BoxDecoration(
                  color: inStock
                      ? theme.colorScheme.primary
                      : theme.colorScheme.error,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 2.w),
              Text(
                inStock ? 'In Stock ($stock available)' : 'Out of Stock',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: inStock
                      ? theme.colorScheme.primary
                      : theme.colorScheme.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
