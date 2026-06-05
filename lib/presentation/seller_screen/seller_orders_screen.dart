import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../core/models/order_model.dart';
import '../../core/services/order_service.dart';

class SellerOrdersScreen extends StatefulWidget {
  const SellerOrdersScreen({super.key});

  @override
  State<SellerOrdersScreen> createState() => _SellerOrdersScreenState();
}

class _SellerOrdersScreenState extends State<SellerOrdersScreen> {
  List<Order> _orders = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final orders = await OrderService.getSellerOrders();
      if (mounted) setState(() { _orders = orders; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString().replaceAll('Exception: ', ''); _isLoading = false; });
    }
  }

  Future<void> _updateStatus(Order order, String newStatus) async {
    try {
      await OrderService.updateOrderStatus(order.orderId ?? 0, newStatus);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order #${order.orderId} status updated to $newStatus'),
          backgroundColor: Colors.green,
        ),
      );
      _fetchOrders();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showStatusDialog(Order order) {
    final statuses = ['Processing', 'Shipped', 'Delivered', 'Cancelled'];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Update Order #${order.orderId}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: statuses.map((s) => ListTile(
            title: Text(s),
            leading: Radio<String>(
              value: s,
              groupValue: order.status,
              onChanged: (v) {
                Navigator.pop(ctx);
                if (v != null) _updateStatus(order, v);
              },
            ),
          )).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'delivered': return Colors.green;
      case 'shipped': return Colors.blue;
      case 'cancelled': return Colors.red;
      case 'processing': return Colors.orange;
      default: return Colors.grey;
    }
  }

  IconData _statusIcon(String? status) {
    switch (status?.toLowerCase()) {
      case 'delivered': return Icons.check_circle_rounded;
      case 'shipped': return Icons.local_shipping_rounded;
      case 'cancelled': return Icons.cancel_rounded;
      case 'processing': return Icons.pending_rounded;
      default: return Icons.receipt_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('My Orders'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchOrders,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
                      SizedBox(height: 2.h),
                      Text(_error!, textAlign: TextAlign.center),
                      SizedBox(height: 2.h),
                      ElevatedButton(onPressed: _fetchOrders, child: const Text('Retry')),
                    ],
                  ),
                )
              : _orders.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long_outlined, size: 64, color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
                          SizedBox(height: 2.h),
                          Text('No orders yet', style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchOrders,
                      child: ListView.builder(
                        padding: EdgeInsets.all(4.w),
                        itemCount: _orders.length,
                        itemBuilder: (ctx, i) {
                          final order = _orders[i];
                          final statusColor = _statusColor(order.status);
                          return Card(
                            margin: EdgeInsets.only(bottom: 2.h),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 2,
                            child: Padding(
                              padding: EdgeInsets.all(4.w),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Order #${order.orderId ?? '—'}',
                                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: statusColor.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(_statusIcon(order.status), color: statusColor, size: 14),
                                            const SizedBox(width: 4),
                                            Text(
                                              order.status ?? 'Unknown',
                                              style: TextStyle(color: statusColor, fontWeight: FontWeight.w600, fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (order.createdAt != null) ...[
                                    SizedBox(height: 1.h),
                                    Text(
                                      _formatDate(order.createdAt!),
                                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                                    ),
                                  ],
                                  SizedBox(height: 1.5.h),
                                  Row(
                                    children: [
                                      Icon(Icons.payments_outlined, size: 16, color: theme.colorScheme.primary),
                                      const SizedBox(width: 6),
                                      Text(
                                        'EGP ${order.totalAmount?.toStringAsFixed(2) ?? '0.00'}',
                                        style: theme.textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (order.paymentMethod != null) ...[
                                    SizedBox(height: 0.5.h),
                                    Text(
                                      'Payment: ${order.paymentMethod}',
                                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                                    ),
                                  ],
                                  SizedBox(height: 1.5.h),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      OutlinedButton.icon(
                                        icon: const Icon(Icons.edit_note_rounded, size: 16),
                                        label: const Text('Update Status'),
                                        onPressed: () => _showStatusDialog(order),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: theme.colorScheme.primary,
                                          side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.5)),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return dateStr;
    }
  }
}
