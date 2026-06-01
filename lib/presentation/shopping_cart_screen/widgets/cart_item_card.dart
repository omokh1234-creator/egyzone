import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class CartItemCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onRemove;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onSaveForLater;

  const CartItemCard({
    super.key,
    required this.item,
    required this.onRemove,
    required this.onIncrement,
    required this.onDecrement,
    required this.onSaveForLater,
  });

  /// Price display like HomeScreen with ج.م on the left
  Widget _buildPrice(ThemeData theme) {
    final price = item['price'] as double;
    final value = price.toStringAsFixed(2);
    final parts = value.split('.');
    final integer = parts[0].replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );

    return Row(
      children: [
        Text(
          'ج.م ',
          style: theme.textTheme.titleMedium?.copyWith(
            fontSize: (theme.textTheme.titleMedium?.fontSize ?? 16) * 0.8,
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w400,
          ),
        ),
        Text(
          '$integer.${parts[1]}',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Safe image handling — resolves from flat imageUrl, nested product, or images list
    final productMap = item['product'] as Map<String, dynamic>?;
    
    String? imageUrl = item['imageUrl'] as String? ?? 
                      productMap?['imageUrl'] as String? ?? 
                      item['image'] as String? ?? 
                      productMap?['image'] as String?;
    
    if (imageUrl == null || imageUrl.isEmpty) {
      final imageList = (item['images'] ?? productMap?['images']) as List<dynamic>?;
      if (imageList != null && imageList.isNotEmpty) {
        final firstImage = imageList[0];
        if (firstImage is Map) {
          imageUrl = (firstImage['url'] ?? firstImage['imageUrl']) as String?;
        }
      }
    }

    return Dismissible(
      key: Key(item['id'].toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 4.w),
        decoration: BoxDecoration(
          color: theme.colorScheme.error,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'delete',
              color: theme.colorScheme.onError,
              size: 28,
            ),
            SizedBox(height: 0.5.h),
            Text(
              'Remove',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onError,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Remove Item', style: theme.textTheme.titleLarge),
              content: Text(
                'Are you sure you want to remove this item from your cart?',
                style: theme.textTheme.bodyMedium,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.error,
                  ),
                  child: const Text('Remove'),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (direction) => onRemove(),
      child: Card(
        margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
        child: InkWell(
          onLongPress: () => _showContextMenu(context, theme),
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
                    color: theme.colorScheme.surface,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: imageUrl != null
                        ? CustomImageWidget(
                            imageUrl: imageUrl,
                            width: 20.w,
                            height: 20.w,
                            fit: BoxFit.cover,
                            errorWidget: Container(
                              color: Colors.grey.shade200,
                              child: const Center(
                                child: Icon(
                                  Icons.image_not_supported,
                                  size: 40,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          )
                        : Container(
                            color: Colors.grey.shade200,
                            child: const Center(
                              child: Icon(
                                Icons.image_not_supported,
                                size: 40,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                  ),
                ),
                SizedBox(width: 3.w),
                // Product Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['name'] as String,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 0.5.h),
                      item['variant'] != null
                          ? Text(
                              item['variant'] as String,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            )
                          : const SizedBox.shrink(),
                      SizedBox(height: 1.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildPrice(theme),
                          _buildQuantityControls(theme),
                        ],
                      ),
                      item['inStock'] == false
                          ? Padding(
                              padding: EdgeInsets.only(top: 1.h),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 2.w,
                                  vertical: 0.5.h,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      theme.colorScheme.error.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Out of Stock',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.error,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuantityControls(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: item['quantity'] > 1 ? onDecrement : null,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              bottomLeft: Radius.circular(8),
            ),
            child: Container(
              padding: EdgeInsets.all(1.5.w),
              child: CustomIconWidget(
                iconName: 'remove',
                color: item['quantity'] > 1
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                size: 18,
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 3.w),
            child: Text(
              item['quantity'].toString(),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          InkWell(
            onTap: item['quantity'] < 10 ? onIncrement : null,
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(8),
              bottomRight: Radius.circular(8),
            ),
            child: Container(
              padding: EdgeInsets.all(1.5.w),
              child: CustomIconWidget(
                iconName: 'add',
                color: item['quantity'] < 10
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showContextMenu(BuildContext context, ThemeData theme) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.symmetric(vertical: 2.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: CustomIconWidget(
                iconName: 'bookmark_border',
                color: theme.colorScheme.onSurface,
                size: 24,
              ),
              title: Text('Save for Later', style: theme.textTheme.bodyLarge),
              onTap: () {
                Navigator.pop(context);
                onSaveForLater();
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'delete_outline',
                color: theme.colorScheme.error,
                size: 24,
              ),
              title: Text(
                'Remove from Cart',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                onRemove();
              },
            ),
          ],
        ),
      ),
    );
  }
}
