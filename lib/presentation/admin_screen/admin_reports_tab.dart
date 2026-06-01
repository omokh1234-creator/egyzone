import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../core/services/admin_service.dart';

class AdminReportsTab extends StatefulWidget {
  const AdminReportsTab({super.key});

  @override
  State<AdminReportsTab> createState() => _AdminReportsTabState();
}

class _AdminReportsTabState extends State<AdminReportsTab> {
  bool _isLoading = true;
  List<dynamic> _reports = [];
  String _selectedStatus = ''; // '' = all, 'open', 'resolved', 'dismissed'

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  Future<void> _fetchReports() async {
    setState(() => _isLoading = true);
    try {
      final reports = await AdminService.getReports(status: _selectedStatus);
      if (mounted) {
        setState(() {
          _reports = reports;
          _isLoading = false;
        });
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
                  ? Center(child: Text('No reports found.', style: theme.textTheme.bodyLarge))
                  : RefreshIndicator(
                      onRefresh: _fetchReports,
                      child: ListView.builder(
                        itemCount: _reports.length,
                        itemBuilder: (context, index) {
                          final report = _reports[index];
                          final id = report['reportId'] ?? report['id'] ?? 0;
                          final type = report['contentType'] ?? 'Unknown';
                          final reason = report['reason'] ?? 'No reason provided';
                          final status = (report['status'] ?? 'open').toString().toLowerCase();

                          Color statusColor = Colors.orange;
                          if (status == 'resolved') statusColor = Colors.green;
                          if (status == 'dismissed') statusColor = Colors.grey;

                          return Card(
                            margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                            child: ExpansionTile(
                              leading: Icon(Icons.report_problem, color: statusColor),
                              title: Text('Report: $type', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('Status: ${status.toUpperCase()}', style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
                              children: [
                                Padding(
                                  padding: EdgeInsets.all(4.w),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Reason:', style: theme.textTheme.titleSmall),
                                      Text(reason),
                                      SizedBox(height: 2.h),
                                      if (status == 'open')
                                        Row(
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
}
