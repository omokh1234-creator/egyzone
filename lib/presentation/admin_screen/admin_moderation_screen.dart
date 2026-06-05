import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/cart_provider.dart';
import '../../core/services/admin_service.dart';
import '../../widgets/custom_bottom_bar.dart';
import 'admin_users_tab.dart';
import 'admin_products_tab.dart';
import 'admin_reports_tab.dart';
import 'admin_sellers_tab.dart';
import 'admin_coupons_tab.dart';

class AdminModerationScreen extends StatefulWidget {
  const AdminModerationScreen({super.key});

  @override
  State<AdminModerationScreen> createState() => _AdminModerationScreenState();
}

class _AdminModerationScreenState extends State<AdminModerationScreen> {
  Map<String, dynamic>? _dashboardStats;
  bool _isLoadingDashboard = true;

  @override
  void initState() {
    super.initState();
    _fetchDashboard();
  }

  Future<void> _fetchDashboard() async {
    setState(() => _isLoadingDashboard = true);
    try {
      final stats = await AdminService.getDashboard();
      if (mounted) {
        setState(() {
          _dashboardStats = stats;
          _isLoadingDashboard = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingDashboard = false);
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
      child: DefaultTabController(
        length: 6,
        child: Scaffold(
          backgroundColor: colorScheme.surface,
          appBar: AppBar(
            title: const Text('Admin Panel'),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                tooltip: 'Notifications',
                onPressed: () => Navigator.pushNamed(context, '/notifications-screen'),
              ),
              IconButton(
                icon: const Icon(Icons.confirmation_number),
                tooltip: 'Create Coupon',
                onPressed: () => Navigator.pushNamed(context, '/admin/create-coupon'),
              ),
            ],
            bottom: const TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.center,
              tabs: [
                Tab(icon: Icon(Icons.dashboard), text: 'Dashboard'),
                Tab(icon: Icon(Icons.people), text: 'Users'),
                Tab(icon: Icon(Icons.inventory), text: 'Products'),
                Tab(icon: Icon(Icons.report_problem), text: 'Reports'),
                Tab(icon: Icon(Icons.store), text: 'Sellers'),
                Tab(icon: Icon(Icons.confirmation_number), text: 'Coupons'),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              _buildDashboardTab(context),
              const AdminUsersTab(),
              const AdminProductsTab(),
              const AdminReportsTab(),
              const AdminSellersTab(),
              const AdminCouponsTab(),
            ],
          ),
          bottomNavigationBar: CustomBottomBar(
            currentRoute: '/admin/moderation',
            role: role,
            cartItemCount: context.watch<CartProvider>().totalItems,
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardTab(BuildContext context) {
    if (_isLoadingDashboard) {
      return const Center(child: CircularProgressIndicator());
    }

    final theme = Theme.of(context);
    final usersCount = _dashboardStats?['totalUsers']?.toString() ?? '0';
    final pendingCount = _dashboardStats?['pendingProducts']?.toString() ?? '0';
    final reportsCount = _dashboardStats?['openReports']?.toString() ?? '0';

    return RefreshIndicator(
      onRefresh: _fetchDashboard,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'System Overview',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: 2.h),
            _buildStatCard(
              context,
              title: 'Total Users',
              value: usersCount,
              icon: Icons.people_alt_rounded,
              colors: [const Color(0xFF4CA1AF), const Color(0xFF2C3E50)],
              fullWidth: true,
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    title: 'Pending Approvals',
                    value: pendingCount,
                    icon: Icons.pending_actions_rounded,
                    colors: [const Color(0xFFFF9966), const Color(0xFFFF5E62)],
                  ),
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: _buildStatCard(
                    context,
                    title: 'Open Reports',
                    value: reportsCount,
                    icon: Icons.report_problem_rounded,
                    colors: [const Color(0xFFED213A), const Color(0xFF93291E)],
                  ),
                ),
              ],
            ),
            SizedBox(height: 4.h),
            Text(
              'Quick Actions',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: 2.h),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8A2387), Color(0xFFE94057), Color(0xFFF27121)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE94057).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => Navigator.pushNamed(context, '/admin/create-coupon'),
                  child: Padding(
                    padding: EdgeInsets.all(4.w),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(3.w),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.confirmation_number_rounded, color: Colors.white, size: 28),
                        ),
                        SizedBox(width: 4.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Generate Coupon',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Create a new discount code',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 28),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 4.h),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context,
      {required String title,
      required String value,
      required IconData icon,
      required List<Color> colors,
      bool fullWidth = false}) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors.last.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              if (!fullWidth)
                const Icon(Icons.trending_up, color: Colors.white70, size: 20),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
