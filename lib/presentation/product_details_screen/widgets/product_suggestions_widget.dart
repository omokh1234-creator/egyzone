import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:provider/provider.dart';

import '../../../core/app_export.dart';
import '../../../core/services/product_service.dart';
import '../../../core/models/product_model.dart';
import '../../../core/providers/cart_provider.dart';

class ProductSuggestionsWidget extends StatefulWidget {
  final int? subCategoryId;
  final dynamic currentProductId;

  const ProductSuggestionsWidget({
    super.key,
    required this.subCategoryId,
    required this.currentProductId,
  });

  @override
  State<ProductSuggestionsWidget> createState() =>
      _ProductSuggestionsWidgetState();
}

class _ProductSuggestionsWidgetState extends State<ProductSuggestionsWidget> {
  bool _isLoading = true;
  List<Product> _suggestions = [];

  @override
  void initState() {
    super.initState();
    _fetchSuggestions();
  }

  Future<void> _fetchSuggestions() async {
    try {
      final products = await ProductService.fetchProducts(
        subCategoryId: widget.subCategoryId,
      );
      if (mounted) {
        setState(() {
          // Filter out unapproved products and the current product
          _suggestions = products
              .where(
                  (p) => p.isApproved && p.productId != widget.currentProductId)
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Padding(
        padding: EdgeInsets.all(4.w),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_suggestions.isEmpty) {
      return const SizedBox.shrink(); // Hide if no suggestions
    }

    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
          child: Text(
            'You might also like',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 35.h,
          child: ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            scrollDirection: Axis.horizontal,
            itemCount: _suggestions.length,
            separatorBuilder: (context, index) => SizedBox(width: 4.w),
            itemBuilder: (context, index) {
              final product = _suggestions[index];
              return _SuggestionCard(
                product: product.toMap(),
                onTap: () {
                  // Navigate to the product details screen, replacing current
                  // or pushing a new one based on preference.
                  // We'll push a new one so the user can go back.
                  Navigator.pushNamed(
                    context,
                    '/product-detail-screen',
                    arguments: product.toMap(),
                  );
                },
                onAddToCart: () {
                  context.read<CartProvider>().addItem(product.toMap());
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${product.name} added to cart'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback onTap;
  final VoidCallback onAddToCart;

  const _SuggestionCard({
    required this.product,
    required this.onTap,
    required this.onAddToCart,
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

  String _resolveImageUrl() {
    final direct = product['imageUrl'] as String?;
    if (direct != null && direct.isNotEmpty) return direct;

    final images = product['images'];
    if (images is List && images.isNotEmpty) {
      final first = images.first;
      if (first is Map) {
        final url = (first['url'] ?? first['imageUrl']) as String?;
        if (url != null && url.isNotEmpty) return url;
      }
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final imageUrl = _resolveImageUrl();
    final rating = product['rating'] ?? 0.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 45.w,
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
            SizedBox(
              height: 20.h,
              width: double.infinity,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(11),
                ),
                child: CustomImageWidget(
                  imageUrl: imageUrl.isNotEmpty ? imageUrl : null,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 20.h,
                  placeHolder: 'assets/images/no-image.jpg',
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(3.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product['name'] as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                    SizedBox(height: .5.h),
                    Row(
                      children: [
                        CustomIconWidget(
                          iconName: 'star',
                          color: Colors.amber,
                          size: 16,
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
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              'ج.م ',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontSize: 10,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              _formatPrice(
                                  (product['price'] as num).toDouble()),
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
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
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
