import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../core/app_export.dart';
import '../../../core/services/auth_service.dart';

class OrderListCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final VoidCallback onTap;
  final VoidCallback onCancel;
  final VoidCallback onReview;

  const OrderListCard({
    super.key,
    required this.order,
    required this.onTap,
    required this.onCancel,
    required this.onReview,
  });

  /// Price display like CartItemCard with ج.م on the left
  Widget _buildPrice(ThemeData theme, double price) {
    final value = price.toStringAsFixed(2);
    final parts = value.split('.');
    final integer = parts[0].replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );
    // Only show decimal part if it's not .00
    final priceText = parts[1] == '00' ? integer : '$integer.${parts[1]}';
    return Row(
      children: [
        Text(
          'ج.م  ',
          style: theme.textTheme.titleMedium?.copyWith(
            fontSize: (theme.textTheme.titleMedium?.fontSize ?? 16) * 0.8,
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w400,
          ),
        ),
        Text(
          priceText,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status, ThemeData theme) {
    switch (status.toLowerCase()) {
      case 'pending':
      case 'processing':
        return Colors.orange;
      case 'shipped':
      case 'out for delivery':
        return theme.colorScheme.secondary; // This is accentBlue in dark theme
      case 'delivered':
      case 'completed':
      case 'success':
      case 'paid':
        return theme.colorScheme.primary; // Use the theme's specific green
      case 'cancelled':
      case 'failed':
        return theme.colorScheme.error;
      default:
        return theme.colorScheme.primary;
    }
  }

  String _normalizeUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url.replaceFirst('http://egzone.runasp.net', 'https://egzone.runasp.net');
    }
    final clean = url.startsWith('/') ? url : '/$url';
    return '${AuthService.baseUrl}$clean';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // API uses 'items' as seen in the debug response
    final rawItems = order['items'] ?? order['OrderItems'] ?? order['orderItems'] ?? [];
    final List<dynamic> orderItems = rawItems is List ? rawItems : [];

    String imageUrl = '';
    String productName = 'Order #${order['orderId'] ?? order['OrderId'] ?? ''}';
    int extraItems = 0;

    if (orderItems.isNotEmpty) {
      final first = orderItems.first;
      if (first is Map<String, dynamic>) {
        // 1. Try direct fields from the order item
        final name = first['productName'] ?? first['ProductName'];
        final img = first['imageUrl'] ?? first['ImageUrl'];

        if (name != null) productName = name.toString();
        if (img != null && img.toString().isNotEmpty) {
          imageUrl = _normalizeUrl(img.toString());
        }

        // 2. If imageUrl is still empty, check enriched 'product' object
        if (imageUrl.isEmpty) {
          final productMap = (first['product'] ?? first['Product']) as Map<String, dynamic>?;
          if (productMap != null) {
            // Check 'imageUrl' or 'images' list (as seen in product_debug.json)
            final pImg = productMap['imageUrl'] ?? productMap['ImageUrl'];
            if (pImg != null && pImg.toString().isNotEmpty) {
              imageUrl = _normalizeUrl(pImg.toString());
            } else {
              final images = productMap['images'] ?? productMap['productImages'] ?? productMap['ProductImages'];
              if (images is List && images.isNotEmpty) {
                final firstImg = images.first;
                if (firstImg is Map) {
                  final url = (firstImg['url'] ?? firstImg['imageUrl'] ?? firstImg['ImageUrl']) as String?;
                  if (url != null && url.isNotEmpty) imageUrl = _normalizeUrl(url);
                } else if (firstImg is String && firstImg.isNotEmpty) {
                  imageUrl = _normalizeUrl(firstImg);
                }
              }
            }
            
            // Fallback product name if not in item
            if (name == null) {
              final pName = productMap['name'] ?? productMap['Name'];
              if (pName != null) productName = pName.toString();
            }
          }
        }
      }
      extraItems = orderItems.length - 1;
    }

    if (extraItems > 0) productName += ' (+$extraItems items)';

    final totalAmount = ((order['totalAmount'] ?? order['TotalAmount']) as num?)?.toDouble() ?? 0.0;
    final status = ((order['status'] ?? order['Status']) ?? 'Pending').toString();
    final isCancelable = ['pending', 'processing', 'placed'].contains(status.toLowerCase());
    final isReviewable = ['completed', 'delivered', 'paid', 'success'].contains(status.toLowerCase());
    final statusColor = _getStatusColor(status, theme);

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(3.w),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              Container(
                width: 20.w,
                height: 20.w,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: theme.colorScheme.surfaceContainerHighest,
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.1),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: imageUrl.isNotEmpty
                      ? CustomImageWidget(
                          imageUrl: imageUrl,
                          width: 20.w,
                          height: 20.w,
                          fit: BoxFit.cover,
                          errorWidget: _placeholderIcon(),
                        )
                      : _placeholderIcon(),
                ),
              ),
              SizedBox(width: 3.w),
              // Order Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      productName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 0.5.h),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            status,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          (order['createdAt'] ?? order['CreatedAt'])?.toString().split('T')[0] ?? '',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 1.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildPrice(theme, totalAmount),
                        if (isCancelable)
                          InkWell(
                            onTap: onCancel,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                              decoration: BoxDecoration(
                                border: Border.all(color: theme.colorScheme.error),
                                borderRadius: BorderRadius.circular(8),
                                color: theme.colorScheme.error.withValues(alpha: 0.1),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.cancel_outlined, size: 16, color: theme.colorScheme.error),
                                  SizedBox(width: 1.w),
                                  Text(
                                    'Cancel',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.error,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else if (isReviewable)
                          InkWell(
                            onTap: onReview,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.star_outline, size: 16, color: theme.colorScheme.onPrimary),
                                  SizedBox(width: 1.w),
                                  Text(
                                    'Rate',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.onPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholderIcon() {
    return Container(
      color: Colors.grey.shade200,
      child: const Center(
        child: Icon(Icons.shopping_bag_outlined, size: 32, color: Colors.grey),
      ),
    );
  }
}
