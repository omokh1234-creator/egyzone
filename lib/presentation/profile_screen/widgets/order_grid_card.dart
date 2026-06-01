import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../core/app_export.dart';
import '../../../core/models/product_model.dart';
import '../../../widgets/custom_image_widget.dart';

class OrderGridCard extends StatelessWidget {
  const OrderGridCard({
    super.key,
    required this.order,
    required this.onTap,
    required this.onCancel,
    required this.onReview,
  });

  final Map<String, dynamic> order;
  final VoidCallback onTap;
  final VoidCallback onCancel;
  final VoidCallback onReview;

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
    
    // Extract first product details for the cover image and name
    final orderItems = order['orderItems'] as List? ?? [];
    String imageUrl = '';
    String productName = 'Order #${order['orderId']}';
    
    if (orderItems.isNotEmpty) {
      final firstItem = orderItems.first;
      final productMap = firstItem['product'] as Map<String, dynamic>?;
      if (productMap != null) {
        imageUrl = Product.fromJson(productMap).imageUrl;
        productName = productMap['name'] ?? productName;
        if (orderItems.length > 1) {
          productName += ' (+${orderItems.length - 1})';
        }
      }
    }

    final totalAmount = (order['totalAmount'] as num?)?.toDouble() ?? 0.0;
    final status = (order['status'] ?? 'Pending').toString();
    final isCancelable = ['pending', 'processing', 'placed'].contains(status.toLowerCase());
    final isReviewable = ['completed', 'delivered', 'paid', 'success'].contains(status.toLowerCase());

    return GestureDetector(
      onTap: onTap,
      child: Container(
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
                      placeHolder: 'assets/images/no-image.jpg',
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status, theme).withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status,
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
                    // Product / Order Name
                    Text(
                      productName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),

                    SizedBox(height: .5.h),

                    // Order Date
                    Text(
                      order['createdAt']?.toString().split('T')[0] ?? '',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),

                    const Spacer(),

                    // Price + Action Button
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
                              _formatPrice(totalAmount),
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w100,
                              ),
                            ),
                          ],
                        ),
                        if (isCancelable)
                          GestureDetector(
                            onTap: onCancel,
                            child: Container(
                              padding: EdgeInsets.all(1.7.w),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.error.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: theme.colorScheme.error),
                              ),
                              child: Icon(
                                Icons.cancel_outlined,
                                color: theme.colorScheme.error,
                                size: 19,
                              ),
                            ),
                          )
                        else if (isReviewable)
                          GestureDetector(
                            onTap: onReview,
                            child: Container(
                              padding: EdgeInsets.all(1.7.w),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.star_outline,
                                color: theme.colorScheme.onPrimary,
                                size: 19,
                              ),
                            ),
                          )
                        else
                          const SizedBox(width: 24), // Placeholder for spacing
                      ],
                    ),

                    SizedBox(height: 0.6.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status, ThemeData theme) {
    switch (status.toLowerCase()) {
      case 'pending':
      case 'processing':
        return Colors.orange;
      case 'shipped':
      case 'out for delivery':
        return Colors.blue;
      case 'delivered':
      case 'completed':
      case 'success':
        return Colors.green;
      case 'cancelled':
      case 'failed':
        return theme.colorScheme.error;
      default:
        return theme.colorScheme.primary;
    }
  }
}
