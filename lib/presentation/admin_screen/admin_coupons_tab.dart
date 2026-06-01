import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';
import '../../../core/services/admin_service.dart';

class AdminCouponsTab extends StatefulWidget {
  const AdminCouponsTab({super.key});

  @override
  State<AdminCouponsTab> createState() => _AdminCouponsTabState();
}

class _AdminCouponsTabState extends State<AdminCouponsTab> {
  bool _isLoading = true;
  List<dynamic> _coupons = [];

  @override
  void initState() {
    super.initState();
    _fetchCoupons();
  }

  Future<void> _fetchCoupons() async {
    setState(() => _isLoading = true);
    try {
      final coupons = await AdminService.getCoupons();
      if (mounted) {
        setState(() {
          _coupons = coupons;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load coupons: $e')),
        );
      }
    }
  }

  Future<void> _deleteCoupon(int couponId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Coupon', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to delete this coupon?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await AdminService.deleteCoupon(couponId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Coupon deleted successfully' : 'Failed to delete coupon'),
            backgroundColor: success ? Colors.green : Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        if (success) {
          _fetchCoupons();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
            ),
            SizedBox(height: 2.h),
            Text(
              'Loading coupons...',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    if (_coupons.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withValues(alpha: 0.1),
                    theme.colorScheme.secondary.withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.confirmation_number_outlined,
                size: 64,
                color: theme.colorScheme.primary,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              'No coupons yet',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Create your first discount code to boost sales',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            SizedBox(height: 2.h),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/admin/create-coupon').then((_) => _fetchCoupons()),
                icon: const Icon(Icons.add),
                label: const Text('Create Coupon'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchCoupons,
      color: theme.colorScheme.primary,
      child: ListView.builder(
        padding: EdgeInsets.all(4.w),
        itemCount: _coupons.length,
        itemBuilder: (context, index) {
          final coupon = _coupons[index];
          final id = coupon['couponId'] ?? coupon['id'] ?? 0;
          final code = coupon['code'] ?? 'UNKNOWN';
          final discount = coupon['discountPercent']?.toString() ?? '0';
          final maxUsage = coupon['maxUsage']?.toString() ?? '0';
          final currentUsage = coupon['currentUsage']?.toString() ?? '0';
          final expiryDate = coupon['expiryDate'];
          final isActive = coupon['isActive'] ?? true;

          DateTime? expiryDateTime;
          if (expiryDate != null) {
            try {
              expiryDateTime = DateTime.parse(expiryDate);
            } catch (e) {
              expiryDateTime = null;
            }
          }

          final isExpired = expiryDateTime != null && expiryDateTime.isBefore(DateTime.now());
          final usagePercentage = maxUsage != '0' ? (int.parse(currentUsage) / int.parse(maxUsage)) : 0.0;

          return Container(
            margin: EdgeInsets.only(bottom: 2.h),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isExpired
                    ? [Colors.grey.shade100, Colors.grey.shade50]
                    : [
                        theme.colorScheme.primary.withValues(alpha: 0.05),
                        theme.colorScheme.secondary.withValues(alpha: 0.05),
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isExpired
                    ? Colors.grey.shade300
                    : theme.colorScheme.primary.withValues(alpha: 0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isExpired
                      ? Colors.grey.withValues(alpha: 0.1)
                      : theme.colorScheme.primary.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  Positioned(
                    top: -50,
                    right: -50,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: (isExpired ? Colors.grey : theme.colorScheme.primary).withValues(alpha: 0.05),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(4.w),
                    child: Row(
                      children: [
                        Container(
                          width: 18.w,
                          height: 18.w,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isExpired
                                  ? [Colors.grey.shade400, Colors.grey.shade600]
                                  : [theme.colorScheme.primary, theme.colorScheme.secondary],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: (isExpired ? Colors.grey : theme.colorScheme.primary).withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  discount,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                ),
                                Text(
                                  '%',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      code,
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
                                    decoration: BoxDecoration(
                                      color: isExpired
                                          ? Colors.grey.shade200
                                          : (isActive ? Colors.green.shade100 : Colors.orange.shade100),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isExpired
                                            ? Colors.grey.shade400
                                            : (isActive ? Colors.green : Colors.orange),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      isExpired ? 'Expired' : (isActive ? 'Active' : 'Inactive'),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: isExpired
                                            ? Colors.grey.shade700
                                            : (isActive ? Colors.green.shade700 : Colors.orange.shade700),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 1.h),
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 14,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  SizedBox(width: 0.5.w),
                                  Text(
                                    expiryDateTime != null
                                        ? 'Expires: ${DateFormat('MMM dd, yyyy').format(expiryDateTime)}'
                                        : 'No expiry',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 1.h),
                              Row(
                                children: [
                                  Icon(
                                    Icons.bar_chart,
                                    size: 14,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  SizedBox(width: 0.5.w),
                                  Text(
                                    'Usage: $currentUsage/$maxUsage',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  SizedBox(width: 2.w),
                                  Expanded(
                                    child: Container(
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                      child: FractionallySizedBox(
                                        widthFactor: usagePercentage.clamp(0.0, 1.0),
                                        alignment: Alignment.centerLeft,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
                                            ),
                                            borderRadius: BorderRadius.circular(2),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 2.w),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: Icon(Icons.delete_outline, color: Colors.red.shade700, size: 20),
                            onPressed: () => _deleteCoupon(id),
                            tooltip: 'Delete',
                          ),
                        ),
                      ],
                    ),
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
