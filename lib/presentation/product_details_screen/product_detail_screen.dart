import 'package:egyzone/presentation/product_details_screen/widgets/product_image_carousel_widget.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/product_description_widget.dart';
import './widgets/product_info_widget.dart';
import './widgets/product_specifications_widget.dart';
import './widgets/product_suggestions_widget.dart';
import './widgets/product_reviews_widget.dart';
import './widgets/quantity_selector_widget.dart';
import '../../core/providers/cart_provider.dart';
import '../../core/providers/saved_items_provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/product_service.dart';

class ProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic> productData;

  const ProductDetailScreen({super.key, required this.productData});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  int _quantity = 1;
  bool _isAddingToCart = false;
  int? _dynamicReviewCount;
  double? _dynamicRating;
  String? _dynamicSellerName;
  String? _dynamicBrandName;

  Map<String, dynamic> get _productData => widget.productData;

  /// Resolves product id — handles both 'id' and 'productId' from API
  dynamic get _productId => _productData['id'] ?? _productData['productId'];

  /// Builds images list from productImages array or falls back to imageUrl
  List<Map<String, dynamic>> get _images {
    // Prefer the 'images' list which should already contain normalized URLs from the Product model
    if (_productData['images'] != null &&
        (_productData['images'] as List).isNotEmpty) {
      return (_productData['images'] as List)
          .map((img) => img as Map<String, dynamic>)
          .toList();
    }

    // Fallback to productImages array (new API schema)
    if (_productData['productImages'] != null &&
        (_productData['productImages'] as List).isNotEmpty) {
      return (_productData['productImages'] as List)
          .map((img) => {
                'url': img['imageUrl'] ?? img['url'] ?? '',
                'semanticLabel': _productData['name'] ?? '',
              })
          .toList();
    }

    // Fallback to single imageUrl
    return [
      {
        'url': _productData['imageUrl'] as String? ?? '',
        'semanticLabel': _productData['name'] ?? '',
      }
    ];
  }

  /// Maps specifications from API schema.
  /// API returns [{label, value}], Swagger schema uses [{name, value}].
  List<Map<String, dynamic>> get _specifications {
    final specs = _productData['specifications'];
    if (specs == null) return [];
    return (specs as List)
        .map((s) => {
              // API uses 'label'; Swagger schema uses 'name' — handle both
              'name': s['label'] as String? ?? s['name'] as String? ?? '',
              'value': s['value'] as String? ?? '',
            })
        .where((s) => (s['name'] as String).isNotEmpty) // skip blank entries
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _dynamicSellerName = _productData['sellerName'] as String?;
    _dynamicBrandName = _productData['brandName'] as String?;
    if (_dynamicSellerName == null ||
        _dynamicSellerName!.isEmpty ||
        _dynamicBrandName == null ||
        _dynamicBrandName!.isEmpty) {
      _fetchFullDetails();
    }
  }

  Future<void> _fetchFullDetails() async {
    if (_productId == null) return;
    try {
      final detail = await ProductService.fetchProductDetail(_productId);
      if (mounted && detail != null) {
        setState(() {
          if (detail.sellerName != null && detail.sellerName!.isNotEmpty) {
            _dynamicSellerName = detail.sellerName;
          }
          if (detail.brandName != null && detail.brandName!.isNotEmpty) {
            _dynamicBrandName = detail.brandName;
          }
        });
      }
    } catch (_) {
      // Ignore errors silently
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _incrementQuantity() => setState(() => _quantity++);
  void _decrementQuantity() {
    if (_quantity > 1) setState(() => _quantity--);
  }

  Future<void> _addToCart() async {
    setState(() => _isAddingToCart = true);

    try {
      if (_productId != null) {
        final response = await http.post(
          Uri.parse('${AuthService.baseUrl}/api/CartItems'),
          headers: await AuthService.authHeaders,
          body: jsonEncode({
            'productId': _productId,
            'quantity': _quantity,
          }),
        );

        if (response.statusCode != 200 && response.statusCode != 201) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Could not sync with server, added locally'),
              ),
            );
          }
        }
      }
    } catch (_) {
      // Network error — still add locally
    }

    // Always update local cart for immediate UI
    if (mounted) {
      context.read<CartProvider>().addItem(_productData, quantity: _quantity);
      setState(() => _isAddingToCart = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$_quantity × ${_productData["name"]} added to cart'),
          duration: const Duration(seconds: 2),
          action: SnackBarAction(
            label: 'View Cart',
            onPressed: () =>
                Navigator.pushNamed(context, '/shopping-cart-screen'),
          ),
        ),
      );
    }
  }

  void _shareProduct() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share functionality would open here'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSaved =
        context.select<SavedItemsProvider, bool>((p) => p.isSaved(_productId));

    // Stock check from API schema
    final int stock = _productData['stock'] as int? ?? 0;
    final bool inStock = _productData['inStock'] as bool? ?? stock > 0;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pop(context);
      },
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: CustomAppBar(
          title: 'Product Details',
          style: CustomAppBarStyle.standard,
          showBackButton: true,
          onBackButtonPressed: () {
            Navigator.pop(context);
          },
          showSearchButton: false,
          showCartButton: true,
          cartItemCount: context.select<CartProvider, int>((p) => p.totalItems),
          actions: [
            IconButton(
              icon: CustomIconWidget(
                iconName: 'share',
                color: theme.colorScheme.onSurface,
                size: 24,
              ),
              onPressed: _shareProduct,
              tooltip: 'Share',
            ),
          ],
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ProductImageCarouselWidget(
                    images: _images,
                    productId: _productId.toString(),
                  ),
                  ProductInfoWidget(
                    name: _productData['name'] as String? ?? '',
                    price: (_productData['price'] as num? ?? 0).toDouble(),
                    originalPrice:
                        (_productData['originalPrice'] as num?)?.toDouble() ??
                            (_productData['price'] as num? ?? 0).toDouble(),
                    rating: _dynamicRating ??
                        (_productData['rating'] as num? ?? 0.0).toDouble(),
                    reviewCount: _dynamicReviewCount ??
                        (_productData['reviewCount'] as int? ?? 0),
                    inStock: inStock,
                    sellerName: _dynamicSellerName,
                    brandName: _dynamicBrandName,
                  ),
                  ProductDescriptionWidget(
                    description: _productData['description'] as String? ??
                        'No description available',
                  ),
                  ProductSpecificationsWidget(
                    specifications: _specifications,
                  ),
                  ProductReviewsWidget(
                    productId: _productId as int,
                    rating: (_productData['rating'] as num? ?? 0.0).toDouble(),
                    reviewCount: _productData['reviewCount'] as int? ?? 0,
                    onReviewsUpdated: (count, avg) {
                      setState(() {
                        _dynamicReviewCount = count;
                        _dynamicRating = avg;
                      });
                    },
                  ),
                  ProductSuggestionsWidget(
                    subCategoryId: _productData['subCategoryId'] as int?,
                    currentProductId: _productId,
                  ),
                  SizedBox(height: 20.h),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                    child: Row(
                      children: [
                        Container(
                          width: 12.w,
                          height: 6.h,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: theme.colorScheme.outline,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: CustomIconWidget(
                              iconName:
                                  isSaved ? 'favorite' : 'favorite_border',
                              color: isSaved
                                  ? theme.colorScheme.error
                                  : theme.colorScheme.onSurfaceVariant,
                              size: 24,
                            ),
                            onPressed: () => context
                                .read<SavedItemsProvider>()
                                .toggleItem(_productData),
                            tooltip: 'Save Item',
                          ),
                        ),
                        SizedBox(width: 2.w),
                        QuantitySelectorWidget(
                          quantity: _quantity,
                          onIncrement: _incrementQuantity,
                          onDecrement: _decrementQuantity,
                        ),
                        SizedBox(width: 2.w),
                        Expanded(
                          child: SizedBox(
                            height: 6.h,
                            child: ElevatedButton(
                              onPressed: (!inStock || _isAddingToCart)
                                  ? null
                                  : _addToCart,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: theme.colorScheme.onPrimary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isAddingToCart
                                  ? SizedBox(
                                      width: 5.w,
                                      height: 5.w,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          theme.colorScheme.onPrimary,
                                        ),
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        CustomIconWidget(
                                          iconName: 'shopping_bag',
                                          color: theme.colorScheme.onPrimary,
                                          size: 20,
                                        ),
                                        SizedBox(width: 2.w),
                                        Text(
                                          inStock
                                              ? 'Add to Cart'
                                              : 'Out of Stock',
                                          style: theme.textTheme.labelLarge
                                              ?.copyWith(
                                            color: theme.colorScheme.onPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: CustomBottomBar(
          currentRoute: '/product-detail-screen',
          cartItemCount: context.select<CartProvider, int>((p) => p.totalItems),
        ),
      ),
    );
  }
}
