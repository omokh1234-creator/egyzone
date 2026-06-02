import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../core/services/admin_service.dart';

class AdminProductsTab extends StatefulWidget {
  const AdminProductsTab({super.key});

  @override
  State<AdminProductsTab> createState() => _AdminProductsTabState();
}

class _AdminProductsTabState extends State<AdminProductsTab> {
  bool _isLoading = true;
  List<dynamic> _products = [];

  @override
  void initState() {
    super.initState();
    _fetchPendingProducts();
  }

  Future<void> _fetchPendingProducts() async {
    setState(() => _isLoading = true);
    try {
      final products = await AdminService.getPendingProducts();
      if (mounted) {
        setState(() {
          _products = products;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load pending products: $e')),
        );
      }
    }
  }

  Future<void> _approveProduct(int id) async {
    try {
      final success = await AdminService.approveProduct(id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product approved successfully!'), backgroundColor: Colors.green),
        );
        _fetchPendingProducts();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to approve product: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _rejectProduct(int id) async {
    try {
      final success = await AdminService.rejectProduct(id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product rejected.'), backgroundColor: Colors.orange),
        );
        _fetchPendingProducts();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to reject product: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: theme.colorScheme.primary),
            SizedBox(height: 2.h),
            Text(
              'All caught up!',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 1.h),
            Text(
              'No pending products to review.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchPendingProducts,
      child: ListView.builder(
        padding: EdgeInsets.all(4.w),
        itemCount: _products.length,
        itemBuilder: (context, index) {
          final product = _products[index];
          final id = product['productId'] ?? product['id'] ?? 0;
          final name = product['name'] ?? 'Unknown Product';
          final price = product['price']?.toString() ?? '0.00';
          final imageUrl = product['imageUrl'];
          final imageUrls = product['imageUrls'] as List<dynamic>?;
          final seller = product['seller']?['storeName'] ?? product['seller']?['user']?['fullName'] ?? 'Unknown Seller';
          final category = product['categoryName'] ?? product['category']?['name'] ?? 'Unknown';
          final subCategory = product['subCategoryName'] ?? product['subCategory']?['name'] ?? 'Unknown';
          final brand = product['brand']?['name'] ?? product['brandName'] ?? 'Unknown';

          final displayImageUrl = (imageUrl != null && imageUrl.isNotEmpty) 
              ? imageUrl 
              : (imageUrls != null && imageUrls.isNotEmpty ? imageUrls[0] : null);

          return Card(
            margin: EdgeInsets.only(bottom: 2.h),
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (displayImageUrl != null && displayImageUrl.isNotEmpty)
                  Image.network(
                    displayImageUrl,
                    height: 15.h,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 15.h,
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: const Center(child: Icon(Icons.broken_image, size: 32)),
                    ),
                  )
                else
                  Container(
                    height: 15.h,
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: Center(
                      child: Icon(Icons.image_not_supported, size: 32, color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ),
                Padding(
                  padding: EdgeInsets.all(3.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        'Seller: $seller',
                        style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
                      ),
                      SizedBox(height: 0.5.h),
                      Row(
                        children: [
                          Text(
                            'Category: $category',
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                          SizedBox(width: 2.w),
                          Text(
                            'Sub: $subCategory',
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        'Brand: $brand',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                      SizedBox(height: 1.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$price ج.م',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 1.5.h),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _rejectProduct(id),
                              icon: const Icon(Icons.close, size: 18),
                              label: const Text('Reject'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: theme.colorScheme.error,
                                side: BorderSide(color: theme.colorScheme.error),
                                padding: EdgeInsets.symmetric(vertical: 1.h),
                              ),
                            ),
                          ),
                          SizedBox(width: 2.w),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _approveProduct(id),
                              icon: const Icon(Icons.check, size: 18),
                              label: const Text('Approve'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 1.h),
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
          );
        },
      ),
    );
  }
}
