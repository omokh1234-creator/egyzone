import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../core/services/admin_service.dart';

class AdminSellersTab extends StatefulWidget {
  const AdminSellersTab({super.key});

  @override
  State<AdminSellersTab> createState() => _AdminSellersTabState();
}

class _AdminSellersTabState extends State<AdminSellersTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _pendingSellers = [];
  List<dynamic> _allApplications = [];
  bool _isLoadingPending = true;
  bool _isLoadingAll = true;
  String _filterStatus = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchPending();
    _fetchAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchPending() async {
    setState(() => _isLoadingPending = true);
    final data = await AdminService.getPendingSellers();
    if (mounted) setState(() { _pendingSellers = data; _isLoadingPending = false; });
  }

  Future<void> _fetchAll() async {
    setState(() => _isLoadingAll = true);
    final data = await AdminService.getSellerApplications(status: _filterStatus.isEmpty ? null : _filterStatus);
    if (mounted) setState(() { _allApplications = data; _isLoadingAll = false; });
  }

  Future<void> _approve(dynamic seller) async {
    final id = (seller['sellerId'] ?? seller['id'] ?? seller['userId']) as int?;
    if (id == null) return;
    final ok = await AdminService.approveSeller(id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? 'Seller approved!' : 'Failed to approve seller'),
      backgroundColor: ok ? Colors.green : Colors.red,
    ));
    if (ok) { _fetchPending(); _fetchAll(); }
  }

  Future<void> _reject(dynamic seller) async {
    final id = (seller['sellerId'] ?? seller['id'] ?? seller['userId']) as int?;
    if (id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Seller'),
        content: Text('Reject ${seller['storeName'] ?? 'this seller'}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final ok = await AdminService.rejectSeller(id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? 'Seller rejected' : 'Failed to reject seller'),
      backgroundColor: ok ? Colors.orange : Colors.red,
    ));
    if (ok) { _fetchPending(); _fetchAll(); }
  }

  Color _statusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved': return Colors.green;
      case 'rejected': return Colors.red;
      case 'pending': return Colors.orange;
      default: return Colors.grey;
    }
  }

  Widget _buildSellerCard(dynamic seller, {bool showActions = true}) {
    final theme = Theme.of(context);
    final storeName = seller['storeName'] ?? 'Unknown Store';
    final status = seller['status'] ?? 'pending';
    final description = seller['description'] ?? '';
    final contact = seller['contactNumber'] ?? '';
    final appliedAt = seller['appliedAt'];

    return Card(
      margin: EdgeInsets.only(bottom: 1.5.h),
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
                Expanded(
                  child: Text(
                    storeName,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(status).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.toString().toUpperCase(),
                    style: TextStyle(color: _statusColor(status), fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
              ],
            ),
            if (description.isNotEmpty) ...[
              SizedBox(height: 0.8.h),
              Text(description, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.7))),
            ],
            if (contact.isNotEmpty) ...[
              SizedBox(height: 0.5.h),
              Row(
                children: [
                  Icon(Icons.phone_outlined, size: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                  const SizedBox(width: 4),
                  Text(contact, style: theme.textTheme.bodySmall),
                ],
              ),
            ],
            if (appliedAt != null) ...[
              SizedBox(height: 0.5.h),
              Text('Applied: ${_formatDate(appliedAt.toString())}',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
            ],
            if (showActions && (status.toString().toLowerCase() == 'pending')) ...[
              SizedBox(height: 1.5.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Reject'),
                      onPressed: () => _reject(seller),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Approve'),
                      onPressed: () => _approve(seller),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) { return raw; }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Pending (${_pendingSellers.length})'),
            const Tab(text: 'All Applications'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Pending Tab
              _isLoadingPending
                  ? const Center(child: CircularProgressIndicator())
                  : _pendingSellers.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle_outline, size: 64, color: Colors.green.withValues(alpha: 0.5)),
                              SizedBox(height: 2.h),
                              Text('No pending applications', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _fetchPending,
                          child: ListView(
                            padding: EdgeInsets.all(4.w),
                            children: _pendingSellers.map((s) => _buildSellerCard(s)).toList(),
                          ),
                        ),
              // All Applications Tab
              Column(
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                    child: DropdownButtonFormField<String>(
                      value: _filterStatus.isEmpty ? null : _filterStatus,
                      decoration: InputDecoration(
                        labelText: 'Filter by Status',
                        prefixIcon: const Icon(Icons.filter_list),
                        isDense: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      items: const [
                        DropdownMenuItem(value: '', child: Text('All')),
                        DropdownMenuItem(value: 'pending', child: Text('Pending')),
                        DropdownMenuItem(value: 'approved', child: Text('Approved')),
                        DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
                      ],
                      onChanged: (v) {
                        setState(() => _filterStatus = v ?? '');
                        _fetchAll();
                      },
                    ),
                  ),
                  Expanded(
                    child: _isLoadingAll
                        ? const Center(child: CircularProgressIndicator())
                        : _allApplications.isEmpty
                            ? Center(
                                child: Text('No applications found',
                                    style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
                              )
                            : RefreshIndicator(
                                onRefresh: _fetchAll,
                                child: ListView(
                                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                                  children: _allApplications.map((s) => _buildSellerCard(s, showActions: true)).toList(),
                                ),
                              ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
