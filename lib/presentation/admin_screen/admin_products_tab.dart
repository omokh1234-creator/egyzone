import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../core/services/admin_service.dart';
import '../../widgets/custom_image_widget.dart';

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

          debugPrint('Product seller data: ${product['seller']}');
          debugPrint('Product full data: $product');

          return Card(
            margin: EdgeInsets.only(bottom: 1.5.h),
            child: ListTile(
              leading: SizedBox(
                width: 15.w,
                height: 15.w,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CustomImageWidget(
                    imageUrl: displayImageUrl,
                    fit: BoxFit.cover,
                    width: 15.w,
                    height: 15.w,
                    placeHolder: 'assets/images/no-image.jpg',
                  ),
                ),
              ),
              title: Text(name),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('EGP $price'),
                  Text('Seller: $seller'),
                  Text('$category / $subCategory'),
                  if (brand != 'Unknown') Text('Brand: $brand'),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () => _rejectProduct(id),
                  ),
                  IconButton(
                    icon: const Icon(Icons.check, color: Colors.green),
                    onPressed: () => _approveProduct(id),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
