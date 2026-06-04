import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../core/services/admin_service.dart';
import '../../../core/services/product_service.dart';

class AdminReportsTab extends StatefulWidget {
  const AdminReportsTab({super.key});

  @override
  State<AdminReportsTab> createState() => _AdminReportsTabState();
}

class _AdminReportsTabState extends State<AdminReportsTab> {
  bool _isLoading = true;
  List<dynamic> _reports = [];
  String _selectedStatus = ''; // '' = all, 'open', 'resolved', 'dismissed'
  final Map<int, dynamic> _products = {};

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  Future<void> _fetchReports() async {
    setState(() => _isLoading = true);
    try {
      final apiStatus = _getApiStatusValue(_selectedStatus);
      final reports = await AdminService.getReports(status: apiStatus);
      if (mounted) {
        setState(() {
          _reports = reports;
          _isLoading = false;
        });
        // Fetch product details for product reports
        _fetchProductDetails();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load reports: $e')),
        );
      }
    }
  }

  Future<void> _fetchProductDetails() async {
    for (final report in _reports) {
      if (report['contentType'] == 'Product' && report['contentId'] != null) {
        final contentId = report['contentId'];
        if (!_products.containsKey(contentId)) {
          try {
            final product = await ProductService.fetchProductDetail(contentId);
            if (mounted && product != null) {
              setState(() {
                _products[contentId] = product.toMap();
              });
            }
          } catch (e) {
            // Ignore errors fetching product details
          }
        }
      }
    }
  }

  Future<void> _resolveReport(int id) async {
    try {
      final success = await AdminService.resolveReport(id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report resolved')),
        );
        _fetchReports();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to resolve: $e')),
        );
      }
    }
  }

  Future<void> _dismissReport(int id) async {
    try {
      final success = await AdminService.dismissReport(id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report dismissed')),
        );
        _fetchReports();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to dismiss: $e')),
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
      try {
        final success = await AdminService.deleteProduct(productId);
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product deleted')),
          );
          _fetchReports();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete product: $e')),
          );
        }
      }
    }
  }

  Future<void> _rejectProduct(int productId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Product'),
        content: const Text('Are you sure you want to reject this product?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reject', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final success = await AdminService.rejectProduct(productId);
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product rejected')),
          );
          _fetchReports();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to reject product: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
          child: Row(
            children: [
              _buildFilterChip('All', ''),
              SizedBox(width: 2.w),
              _buildFilterChip('Open', 'open'),
              SizedBox(width: 2.w),
              _buildFilterChip('Resolved', 'resolved'),
              SizedBox(width: 2.w),
              _buildFilterChip('Dismissed', 'dismissed'),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _reports.isEmpty
                  ? Center(
                      child: Text('No reports found.',
                          style: theme.textTheme.bodyLarge))
                  : RefreshIndicator(
                      onRefresh: _fetchReports,
                      child: ListView.builder(
                        itemCount: _reports.length,
                        itemBuilder: (context, index) {
                          final report = _reports[index];
                          final id = report['reportId'] ?? report['id'] ?? 0;
                          final type = report['contentType'] ?? 'Unknown';
                          final reason =
                              report['reason'] ?? 'No reason provided';
                          final status =
                              (report['status'] ?? 'open').toString();
                          final contentId = report['contentId'];
                          final isOpen = status.toLowerCase() == 'open';

                          Color statusColor = Colors.orange;
                          if (status.toLowerCase() == 'resolved')
                            statusColor = Colors.green;
                          if (status.toLowerCase() == 'dismissed')
                            statusColor = Colors.grey;

                          return Card(
                            margin: EdgeInsets.symmetric(
                                horizontal: 4.w, vertical: 1.h),
                            child: Column(
                              children: [
                                ExpansionTile(
                                  leading: Icon(Icons.report_problem,
                                      color: statusColor),
                                  title: Text('Report: $type',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  subtitle: Text(
                                      'Status: ${status.toUpperCase()}',
                                      style: TextStyle(
                                          color: statusColor,
                                          fontWeight: FontWeight.bold)),
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.all(4.w),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text('Reason:',
                                              style:
                                                  theme.textTheme.titleSmall),
                                          Text(reason),
                                          SizedBox(height: 2.h),
                                          if (type == 'Product' &&
                                              contentId != null &&
                                              _products.containsKey(contentId))
                                            _buildProductCard(
                                                _products[contentId],
                                                contentId),
                                          if (type == 'Review')
                                            Text('Review ID: $contentId',
                                                style:
                                                    theme.textTheme.bodySmall),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 4.w, vertical: 1.h),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton(
                                        onPressed: () => _dismissReport(id),
                                        child: const Text('Dismiss'),
                                      ),
                                      SizedBox(width: 2.w),
                                      ElevatedButton(
                                        onPressed: () => _resolveReport(id),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                        ),
                                        child: const Text('Resolve'),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildProductCard(dynamic product, int productId) {
    final theme = Theme.of(context);
    final name = product['name'] ?? 'Unknown Product';
    final price = product['price']?.toString() ?? '0.0';
    final imageUrl = product['imageUrl'] ?? '';

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          if (imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageUrl,
                width: 15.w,
                height: 15.w,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 15.w,
                  height: 15.w,
                  color: theme.colorScheme.surface,
                  child: Icon(Icons.image_not_supported,
                      color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
            )
          else
            Container(
              width: 15.w,
              height: 15.w,
              color: theme.colorScheme.surface,
              child:
                  Icon(Icons.image, color: theme.colorScheme.onSurfaceVariant),
            ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 0.5.h),
                Text(
                  'ج.م $price',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    return FilterChip(
      label: Text(label),
      selected: _selectedStatus == value,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedStatus = value;
          });
          _fetchReports();
        }
      },
    );
  }

  String _getApiStatusValue(String filterValue) {
    // Map UI filter values to API status values
    switch (filterValue.toLowerCase()) {
      case 'open':
        return 'Open'; // Try capitalized
      case 'resolved':
        return 'Resolved';
      case 'dismissed':
        return 'Dismissed';
      default:
        return '';
    }
  }
}
