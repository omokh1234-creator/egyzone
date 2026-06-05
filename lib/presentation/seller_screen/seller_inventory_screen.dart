import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../../core/models/product_model.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/cart_provider.dart';
import '../../core/services/product_service.dart';
import '../../core/services/seller_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../widgets/custom_image_widget.dart';

class SellerInventoryScreen extends StatefulWidget {
  const SellerInventoryScreen({super.key});

  @override
  State<SellerInventoryScreen> createState() => _SellerInventoryScreenState();
}

class _SellerInventoryScreenState extends State<SellerInventoryScreen> {
  List<Product> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    setState(() => _isLoading = true);
    try {
      final products = await ProductService.fetchSellerProducts();
      
      // Fetch full product details in parallel for images
      final futures = products.map((product) async {
        final detail = await ProductService.fetchProductDetail(product.productId);
        return detail ?? product;
      });
      
      final productsWithDetails = await Future.wait(futures);
      
      if (mounted) {
        setState(() {
          _products = productsWithDetails;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading products: $e')),
        );
      }
    }
  }

  Future<void> _deleteProduct(int productId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: const Text('Are you sure you want to delete this product?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await SellerService.deleteProduct(productId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Product deleted successfully' : 'Failed to delete product'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
        if (success) {
          _fetchProducts();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final role = context.watch<AuthProvider>().displayRole;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: CustomAppBar(
          title: 'My Inventory',
          style: CustomAppBarStyle.standard,
          showBackButton: false,
          showSearchButton: false,
          showCartButton: false,
        ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _products.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 80,
                        color: colorScheme.primary.withValues(alpha: 0.3),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'No Products Yet',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10.w),
                        child: Text(
                          'Start adding your products to the EGYZONE marketplace and reach thousands of customers.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      SizedBox(height: 4.h),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(context, '/seller/add-product').then((value) {
                            if (value == true) {
                              _fetchProducts();
                            }
                          });
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add New Product'),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 1.5.h),
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchProducts,
                  child: ListView.builder(
                    padding: EdgeInsets.all(2.w),
                    itemCount: _products.length,
                    itemBuilder: (context, index) {
                      final product = _products[index];
                      return Card(
                        margin: EdgeInsets.only(bottom: 2.h),
                        child: ListTile(
                          leading: SizedBox(
                            width: 15.w,
                            height: 15.w,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CustomImageWidget(
                                imageUrl: product.imageUrls.isNotEmpty ? product.imageUrls.first : product.imageUrl,
                                fit: BoxFit.cover,
                                width: 15.w,
                                height: 15.w,
                                placeHolder: 'assets/images/no-image.jpg',
                              ),
                            ),
                          ),
                          title: Text(product.name),
                          subtitle: Text('EGP ${product.price.toStringAsFixed(2).replaceAll('.00', '')}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/seller/edit-product',
                                    arguments: product.toMap(),
                                  ).then((value) {
                                    if (value == true) {
                                      _fetchProducts();
                                    }
                                  });
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteProduct(product.productId),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: _products.isNotEmpty
          ? FloatingActionButton(
              onPressed: () {
                Navigator.pushNamed(context, '/seller/add-product').then((value) {
                  if (value == true) {
                    _fetchProducts();
                  }
                });
              },
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: CustomBottomBar(
        currentRoute: '/seller/inventory',
        role: role,
        cartItemCount: context.watch<CartProvider>().totalItems,
      ),
      ),
    );
  }
}
