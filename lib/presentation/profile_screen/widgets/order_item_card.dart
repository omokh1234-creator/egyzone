import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../core/app_export.dart';
import '../../../core/models/product_model.dart';

class OrderItemCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onReview;

  const OrderItemCard({
    super.key,
    required this.item,
    required this.onReview,
  });

  String _formatPrice(double price) {
    final value = price.toStringAsFixed(2);
    final parts = value.split('.');
    final integer = parts[0].replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );
    return '$integer.${parts[1]}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final productMap = item['product'] as Map<String, dynamic>?;
    final productName = productMap?['name'] ?? 'Unknown Product';
    final price = (item['price'] as num?)?.toDouble() ?? 0.0;
    final quantity = (item['quantity'] as num?)?.toInt() ?? 1;
    final rating = (productMap?['rating'] ?? 0.0).toString();
    
    // Use the robust Product.fromJson to get the image URL
    final imageUrl = Product.fromJson(productMap ?? {}).imageUrl;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Image Section
          Stack(
            children: [
              SizedBox(
                height: 21.h,
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(14),
                  ),
                  child: CustomImageWidget(
                    imageUrl: imageUrl.isNotEmpty ? imageUrl : null,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 21.h,
                  ),
                ),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Qty: $quantity',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Details Section
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 2.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    productName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall,
                  ),

                  SizedBox(height: .5.h),

                  // Rating
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 18),
                      SizedBox(width: 1.w),
                      Text(
                        rating,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // Price + Review Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            'ج.م ',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontSize: (theme.textTheme.titleMedium?.fontSize ?? 16) * 0.6,
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          Text(
                            _formatPrice(price),
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w100,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: onReview,
                        child: Container(
                          padding: EdgeInsets.all(1.7.w),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.rate_review_outlined,
                            color: theme.colorScheme.onPrimary,
                            size: 19,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 0.6.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
