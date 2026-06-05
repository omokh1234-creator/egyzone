import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/cart_provider.dart';
import '../../core/services/seller_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';

class SellerDashboardScreen extends StatefulWidget {
  const SellerDashboardScreen({super.key});

  @override
  State<SellerDashboardScreen> createState() => _SellerDashboardScreenState();
}

class _SellerDashboardScreenState extends State<SellerDashboardScreen> {
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
      final stats = await SellerService.getSellerDashboard();
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
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: CustomAppBar(
          title: 'Seller Dashboard',
          style: CustomAppBarStyle.standard,
          showBackButton: false,
          showSearchButton: false,
          showCartButton: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () => Navigator.pushNamed(context, '/notifications-screen'),
            ),
          ],
        ),
        body: _isLoadingDashboard
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _fetchDashboard,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.all(4.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Store Overview',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      _buildStatCard(
                        context,
                        title: 'Total Products',
                        value: _dashboardStats?['overview']?['totalProducts']?.toString() ?? '0',
                        icon: Icons.inventory_2_rounded,
                        colors: [const Color(0xFF4CA1AF), const Color(0xFF2C3E50)],
                        fullWidth: true,
                      ),
                      SizedBox(height: 2.h),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              context,
                              title: 'Total Orders',
                              value: _dashboardStats?['overview']?['totalOrders']?.toString() ?? '0',
                              icon: Icons.shopping_cart_rounded,
                              colors: [const Color(0xFFFF9966), const Color(0xFFFF5E62)],
                            ),
                          ),
                          SizedBox(width: 4.w),
                          Expanded(
                            child: _buildStatCard(
                              context,
                              title: 'Total Revenue',
                              value: _dashboardStats?['overview']?['totalRevenue']?.toString() ?? '0',
                              icon: Icons.attach_money_rounded,
                              colors: [const Color(0xFFED213A), const Color(0xFF93291E)],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 2.h),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              context,
                              title: 'Pending Orders',
                              value: _dashboardStats?['overview']?['pendingOrders']?.toString() ?? '0',
                              icon: Icons.pending_actions_rounded,
                              colors: [const Color(0xFF667eea), const Color(0xFF764ba2)],
                            ),
                          ),
                          SizedBox(width: 4.w),
                          Expanded(
                            child: _buildStatCard(
                              context,
                              title: 'Completed Orders',
                              value: _dashboardStats?['overview']?['completedOrders']?.toString() ?? '0',
                              icon: Icons.check_circle_rounded,
                              colors: [const Color(0xFF11998e), const Color(0xFF38ef7d)],
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
                      _buildQuickActionCard(
                        context,
                        title: 'Add New Product',
                        subtitle: 'List a new product in your store',
                        icon: Icons.add_circle_rounded,
                        onTap: () => Navigator.pushNamed(context, '/seller/add-product'),
                        colors: [const Color(0xFF8A2387), const Color(0xFFE94057), const Color(0xFFF27121)],
                      ),
                      SizedBox(height: 2.h),
                      _buildQuickActionCard(
                        context,
                        title: 'View Inventory',
                        subtitle: 'Manage your product listings',
                        icon: Icons.inventory_rounded,
                        onTap: () => Navigator.pushNamed(context, '/seller/inventory'),
                        colors: [const Color(0xFF4CA1AF), const Color(0xFF2C3E50)],
                      ),
                      SizedBox(height: 2.h),
                      _buildQuickActionCard(
                        context,
                        title: 'Manage Orders',
                        subtitle: 'View and update order statuses',
                        icon: Icons.receipt_long_rounded,
                        onTap: () => Navigator.pushNamed(context, '/seller/orders'),
                        colors: [const Color(0xFF11998e), const Color(0xFF38ef7d)],
                      ),
                      SizedBox(height: 2.h),
                      _buildQuickActionCard(
                        context,
                        title: 'Edit Store Profile',
                        subtitle: 'Update store name and details',
                        icon: Icons.store_rounded,
                        onTap: () => Navigator.pushNamed(context, '/seller/edit-profile'),
                        colors: [const Color(0xFF667eea), const Color(0xFF764ba2)],
                      ),
                      SizedBox(height: 4.h),
                    ],
                  ),
                ),
              ),
        bottomNavigationBar: CustomBottomBar(
          currentRoute: '/seller/dashboard',
          role: role,
          cartItemCount: context.watch<CartProvider>().totalItems,
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

  Widget _buildQuickActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    required List<Color> colors,
  }) {
    final theme = Theme.of(context);
    return Container(
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
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
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
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        subtitle,
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
    );
  }
}
