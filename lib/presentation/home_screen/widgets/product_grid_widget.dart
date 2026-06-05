import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../core/providers/saved_items_provider.dart';
import 'package:provider/provider.dart';

class ProductGridWidget extends StatelessWidget {
  const ProductGridWidget({
    super.key,
    required this.products,
    required this.onProductTap,
    required this.onAddToCart,
  });

  final List<Map<String, dynamic>> products;
  final ValueChanged<Map<String, dynamic>> onProductTap;
  final ValueChanged<Map<String, dynamic>> onAddToCart;

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = 100.w > 600 ? 3 : 2;

    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: 1.w),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: 0.59,
          crossAxisSpacing: 1.5.w,
          mainAxisSpacing: 0.6.h,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return _ProductCard(
              product: products[index],
              onTap: () => onProductTap(products[index]),
              onAddToCart: () => onAddToCart(products[index]),
            );
          },
          childCount: products.length,
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.onTap,
    required this.onAddToCart,
  });

  final Map<String, dynamic> product;
  final VoidCallback onTap;
  final VoidCallback onAddToCart;

  static String _formatPrice(double price) {
    final value = price.toStringAsFixed(2);
    final parts = value.split('.');
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
    final imageUrl = product['imageUrl'] as String? ?? '';
    final rating = (product['rating'] as num? ?? 0.0).toDouble();

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
                  right: 8,
                  child: Consumer<SavedItemsProvider>(
                    builder: (context, provider, _) {
                      final isSaved = provider.isSaved(product['productId'] ?? product['id']);
                      return GestureDetector(
                        onTap: () => provider.toggleItem(product),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface.withValues(alpha: 0.8),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            isSaved ? Icons.favorite : Icons.favorite_border,
                            color: isSaved ? Colors.red : theme.colorScheme.onSurfaceVariant,
                            size: 20,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            // Product Details
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 2.5.w, vertical: 1.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Name
                    Text(
                      product['name'] as String? ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),

                    SizedBox(height: .3.h),

                    // Rating
                    Row(
                      children: [
                        CustomIconWidget(
                          iconName: 'star',
                          color: Colors.amber,
                          size: 18,
                        ),
                        SizedBox(width: 1.w),
                        Text(
                          rating.toString(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 3.h),

                    // Price + Add to Cart
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              'ج.م ',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontSize:
                                    (theme.textTheme.titleMedium?.fontSize ??
                                            16) *
                                        0.6,
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            Text(
                              _formatPrice((product['price'] as num? ?? 0.0).toDouble()),
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w100,
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: onAddToCart,
                          child: Container(
                            padding: EdgeInsets.all(1.5.w),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: CustomIconWidget(
                              iconName: 'shopping_bag',
                              color: theme.colorScheme.onPrimary,
                              size: 19,
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
    );
  }
}
