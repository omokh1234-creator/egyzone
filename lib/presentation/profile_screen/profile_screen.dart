import 'dart:convert';
import 'package:egyzone/core/providers/auth_provider.dart';
import 'package:egyzone/core/providers/cart_provider.dart';
import 'package:egyzone/core/providers/language_provider.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:sizer/sizer.dart';
import 'package:provider/provider.dart';

import '../../core/app_export.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/order_service.dart';
import '../../core/services/user_profile_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';
import './widgets/order_list_card.dart';
import './widgets/notification_toggle_widget.dart';
import './widgets/profile_header_widget.dart';
import './widgets/profile_section_widget.dart';
import './widgets/theme_toggle_widget.dart';
import '../../core/providers/saved_items_provider.dart';

import './widgets/review_dialog.dart';
import './widgets/order_item_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _userProfile;
  bool _isLoading = false;
  List<Map<String, dynamic>> _addresses = [];
  bool _isLoadingAddresses = false;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh profile when user logs in (e.g. from guest prompt)
    final auth = context.read<AuthProvider>();
    if (auth.isLoggedIn && _userProfile == null && !_isLoading) {
      _fetchUserProfile();
    }
  }

  //           Fetch Profile                                                                                                                                                                         
  Future<void> _fetchUserProfile() async {
    // Don't even try if there's no token
    final token = await AuthService.getToken();
    if (token == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final profile = await UserProfileService.getProfile();
      if (profile != null) {
        setState(() => _userProfile = profile);
      }
    } catch (e) {
      // Silently fail - UI shows default guest values
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  //           Edit Profile                                                                                                                                                                            
  void _showEditProfileDialog() {
    final theme = Theme.of(context);
    final nameController =
        TextEditingController(text: _userProfile?['fullName'] ?? '');
    final phoneController =
        TextEditingController(text: _userProfile?['phoneNumber'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Profile', style: theme.textTheme.titleLarge),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Full Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone Number'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateProfile(
                nameController.text.trim(),
                phoneController.text.trim(),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateProfile(String fullName, String phoneNumber) async {
    try {
      final response = await http.put(
        Uri.parse('${AuthService.baseUrl}/api/UserProfile/update'),
        headers: await AuthService.authHeaders,
        body: jsonEncode({
          'fullName': fullName,
          'phoneNumber': phoneNumber,
        }),
      );
      if (response.statusCode == 200) {
        await _fetchUserProfile();
        Fluttertoast.showToast(msg: 'Profile updated successfully!');
      } else {
        final data = jsonDecode(response.body);
        Fluttertoast.showToast(
            msg: data['message'] ?? 'Failed to update profile');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error updating profile');
    }
  }

  //           Change Password                                                                                                                                                                   
  void _showChangePasswordDialog() {
    final theme = Theme.of(context);
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Change Password', style: theme.textTheme.titleLarge),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Current Password'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New Password'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirm Password'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (newController.text != confirmController.text) {
                Fluttertoast.showToast(msg: 'Passwords do not match');
                return;
              }
              Navigator.pop(context);
              _changePassword(
                currentController.text.trim(),
                newController.text.trim(),
                confirmController.text.trim(),
              );
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  Future<void> _changePassword(
    String currentPassword,
    String newPassword,
    String confirmPassword,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/api/UserProfile/change-password'),
        headers: await AuthService.authHeaders,
        body: jsonEncode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
          'confirmPassword': confirmPassword,
        }),
      );
      if (response.statusCode == 200) {
        Fluttertoast.showToast(msg: 'Password changed successfully!');
      } else {
        final data = jsonDecode(response.body);
        Fluttertoast.showToast(
            msg: data['message'] ?? 'Failed to change password');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error changing password');
    }
  }

  //           Addresses                                                                                                                                                                                     
  Future<void> _fetchAddresses() async {
    setState(() => _isLoadingAddresses = true);
    try {
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/api/Addresses'),
        headers: await AuthService.authHeaders,
      );
      if (response.statusCode == 200) {
        setState(() => _addresses = AuthService.parseResponseList(response.body)
            .whereType<Map<String, dynamic>>()
            .toList());
      }
    } catch (e) {
      // Fail silently     the UI already shows an appropriate empty state or loader
    } finally {
      if (mounted) setState(() => _isLoadingAddresses = false);
    }
  }

  Future<void> _addAddress(String street, String city, String country) async {
    try {
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/api/Addresses'),
        headers: await AuthService.authHeaders,
        body: jsonEncode({
          'street': street,
          'city': city,
          'country': country,
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        await _fetchAddresses();
        Fluttertoast.showToast(msg: 'Address added successfully!');
      } else {
        final data = jsonDecode(response.body);
        Fluttertoast.showToast(msg: data['message'] ?? 'Failed to add address');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error adding address');
    }
  }

  Future<bool> _deleteAddress(dynamic id) async {
    if (id == null) {
      Fluttertoast.showToast(msg: 'Error: Address ID not found');
      return false;
    }
    try {
      final response = await http.delete(
        Uri.parse('${AuthService.baseUrl}/api/Addresses/$id'),
        headers: await AuthService.authHeaders,
      );
      if (response.statusCode == 200 || response.statusCode == 204) {
        await _fetchAddresses();
        Fluttertoast.showToast(msg: 'Address removed');
        return true;
      } else {
        String error = 'Failed to delete address';
        try {
          final data = jsonDecode(response.body);
          error = data['message'] ?? error;
        } catch (_) {}
        Fluttertoast.showToast(msg: '$error (${response.statusCode})');
        return false;
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error deleting address');
      return false;
    }
  }

  void _showAddressesBottomSheet() async {
    await _fetchAddresses();
    if (!mounted) return;
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          height: 70.h,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('My Addresses', style: theme.textTheme.titleLarge),
                    IconButton(
                      icon:
                          Icon(Icons.close, color: theme.colorScheme.onSurface),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              Divider(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
                height: 1,
              ),

              // Address list
              Expanded(
                child: _isLoadingAddresses
                    ? const Center(child: CircularProgressIndicator())
                    : _addresses.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.location_off_outlined,
                                  size: 60,
                                  color: theme.colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.3),
                                ),
                                SizedBox(height: 1.5.h),
                                Text(
                                  'No addresses yet',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                SizedBox(height: 0.3.h),
                                Text(
                                  'Add your first delivery address',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant
                                        .withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: EdgeInsets.all(3.w),
                            itemCount: _addresses.length,
                            separatorBuilder: (_, __) => SizedBox(height: 0.6.h),
                            itemBuilder: (context, index) {
                              final address = _addresses[index];
                              return Container(
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: theme.colorScheme.outline
                                        .withValues(alpha: 0.2),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: theme.colorScheme.shadow
                                          .withValues(alpha: 0.05),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ListTile(
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary
                                          .withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.location_on,
                                      color: theme.colorScheme.primary,
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(
                                    address['street'] ?? '',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${address['city'] ?? ''}, ${address['country'] ?? ''}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  trailing: IconButton(
                                    icon: Icon(
                                      Icons.delete_outline,
                                      color: theme.colorScheme.error,
                                      size: 20,
                                    ),
                                    onPressed: () async {
                                      // 1. Identify the address ID
                                      final id = address['id'] ??
                                          address['addressId'] ??
                                          address['AddressId'] ??
                                          address['ID'] ??
                                          address['addressID'] ??
                                          address['AddressID'];

                                      // 2. Optimistic Update: Remove from UI immediately
                                      setSheetState(() {
                                        _addresses.removeWhere((a) {
                                          final aid = a['id'] ??
                                              a['addressId'] ??
                                              a['AddressId'] ??
                                              a['ID'] ??
                                              a['addressID'] ??
                                              a['AddressID'];
                                          return aid == id;
                                        });
                                      });

                                      // 3. Perform actual deletion
                                      final success = await _deleteAddress(id);

                                      // 4. If it failed, refresh to restore the item
                                      if (!success && mounted) {
                                        await _fetchAddresses();
                                        setSheetState(() {});
                                      }
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
              ),

              // Add address button
              Padding(
                padding: EdgeInsets.fromLTRB(4.w, 0.8.h, 4.w, 2.h),
                child: SizedBox(
                  width: double.infinity,
                  height: 5.5.h,
                  child: ElevatedButton.icon(
                    onPressed: () => _showAddAddressDialog(setSheetState),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: Icon(
                      Icons.add_location_alt_outlined,
                      color: theme.colorScheme.onPrimary,
                    ),
                    label: Text(
                      'Add New Address',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddAddressDialog(StateSetter setSheetState) {
    final theme = Theme.of(context);
    final streetController = TextEditingController();
    final cityController = TextEditingController();
    final countryController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add New Address', style: theme.textTheme.titleLarge),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: streetController,
              decoration: const InputDecoration(
                labelText: 'Street',
                prefixIcon: Icon(Icons.edit_road_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: cityController,
              decoration: const InputDecoration(
                labelText: 'City',
                prefixIcon: Icon(Icons.location_city_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: countryController,
              decoration: const InputDecoration(
                labelText: 'Country',
                prefixIcon: Icon(Icons.flag_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (streetController.text.isEmpty ||
                  cityController.text.isEmpty ||
                  countryController.text.isEmpty) {
                Fluttertoast.showToast(msg: 'Please fill in all fields');
                return;
              }
              Navigator.pop(context);
              await _addAddress(
                streetController.text.trim(),
                cityController.text.trim(),
                countryController.text.trim(),
              );
              setSheetState(() {});
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  //           Orders & Payments                                                                                                                                                             
  Future<void> _fetchMyOrders() async {
    try {
      final headers = await AuthService.authHeaders;
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/api/Orders/my-orders'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        // Use parseResponseList to handle both direct lists and wrapped {"data":[...]} responses
        List<dynamic> orders = AuthService.parseResponseList(response.body);

        // Filter out cancelled orders
        orders = orders.where((order) {
          if (order is! Map<String, dynamic>) return true;
          final status = (order['status'] ?? order['Status'] ?? '').toString().toLowerCase();
          return status != 'cancelled';
        }).toList();

        // Enrich order items: if 'product' object is missing but productId is present,
        // fetch the product details from the API
        final enrichedOrders = await Future.wait(orders.map((order) async {
          if (order is! Map<String, dynamic>) return order;
          
          // API returns 'items' in the my-orders response
          final items = (order['items'] ?? order['OrderItems'] ?? order['orderItems']) as List?;
          if (items == null || items.isEmpty) return order;

          final enrichedItems = await Future.wait(items.map((item) async {
            if (item is! Map<String, dynamic>) return item;
            
            // If we already have a product object or a valid imageUrl, skip enrichment
            final hasProduct = item['product'] != null || item['Product'] != null;
            final hasImageUrl = item['imageUrl'] != null && item['imageUrl'].toString().isNotEmpty;
            if (hasProduct || hasImageUrl) return item;

            final productId = item['productId'] ?? item['ProductId'];
            if (productId == null) return item;

            try {
              final pResp = await http.get(
                Uri.parse('${AuthService.baseUrl}/api/Products/$productId'),
                headers: headers,
              );
              if (pResp.statusCode == 200) {
                final productData = jsonDecode(pResp.body);
                // Return item with the full product object attached for the card to use
                return {...item, 'product': productData};
              }
            } catch (_) {}
            return item;
          }));

          return {...order, 'items': enrichedItems};
        }));

        if (!mounted) return;
        _showOrdersBottomSheet(enrichedOrders);
      } else {
        if (!mounted) return;
        Fluttertoast.showToast(msg: 'Failed to load orders (${response.statusCode})');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error loading orders');
    }
  }

  Future<void> _fetchMyPayments() async {
    try {
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/api/Payments/my-payments'),
        headers: await AuthService.authHeaders,
      );
      if (response.statusCode == 200) {
        // Use parseResponseList to handle wrapped API responses
        final List<dynamic> payments = AuthService.parseResponseList(response.body);
        if (!mounted) return;
        _showPaymentsBottomSheet(payments);
      } else {
        if (!mounted) return;
        Fluttertoast.showToast(msg: 'Failed to load payments (${response.statusCode})');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error loading payments');
    }
  }

  //           Logout                                                                                                                                                                                              
  void _showLogoutConfirmation() {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Logout', style: theme.textTheme.titleLarge),
        content: const Text('Are you sure you want to log out of your account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            onPressed: () {
              Navigator.pop(context);
              _logout();
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    await AuthService.clearAuthData();
    if (!mounted) return;
    context.read<AuthProvider>().logout();
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/home-screen',
      (route) => false,
    );
  }

  Future<void> _cancelOrder(dynamic orderId) async {
    final theme = Theme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cancel Order', style: theme.textTheme.titleLarge),
        content: const Text('Are you sure you want to cancel this order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await OrderService.cancelOrder(orderId is int ? orderId : int.parse(orderId.toString()));
        if (!mounted) return;
        Fluttertoast.showToast(msg: 'Order cancelled successfully');
        Navigator.pop(context); // Close bottom sheet
        _fetchMyOrders(); // Refresh orders
      } catch (e) {
        Fluttertoast.showToast(msg: e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  //           Bottom Sheets                                                                                                                                                                         
  void _showOrdersBottomSheet(List<dynamic> orders) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 65.h,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(3.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('My Orders', style: theme.textTheme.titleLarge),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Divider(
                color: theme.colorScheme.outline.withValues(alpha: 0.2), height: 1),
            Expanded(
              child: orders.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_bag_outlined,
                              size: 60,
                              color: theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.3)),
                          SizedBox(height: 1.5.h),
                          Text('No orders yet',
                              style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.symmetric(vertical: 0.6.h),
                      itemCount: orders.length,
                      itemBuilder: (context, index) {
                        final order = orders[index];
                        return OrderListCard(
                          order: order,
                          onTap: () => _showOrderItemsForReview(order),
                          onCancel: () => _cancelOrder(order['orderId']),
                          onReview: () => _showOrderItemsForReview(order),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPaymentsBottomSheet(List<dynamic> payments) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 65.h,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(3.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('My Payments', style: theme.textTheme.titleLarge),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Divider(
                color: theme.colorScheme.outline.withValues(alpha: 0.2), height: 1),
            Expanded(
              child: payments.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.payment_outlined,
                              size: 60,
                              color: theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.3)),
                          SizedBox(height: 1.5.h),
                          Text('No payments yet',
                              style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.all(3.w),
                      itemCount: payments.length,
                      itemBuilder: (context, index) {
                        final payment = payments[index];
                        return Container(
                          margin: EdgeInsets.only(bottom: 1.5.h),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: theme.colorScheme.outline.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(2.5.w),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Payment #${payment['paymentId']}',
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                    _buildStatusBadge(payment['paymentStatus'] ?? 'Success', theme),
                                  ],
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'Method: ${payment['paymentMethod'] ?? 'N/A'}',
                                  style: theme.textTheme.bodyMedium,
                                ),
                                if (payment['paidAt'] != null) ...[
                                  SizedBox(height: 3),
                                  Text(
                                    'Paid on: ${payment['paidAt'].toString().split('T')[0]}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showWishlist() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 65.h,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(3.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Wishlist', style: theme.textTheme.titleLarge),
                  IconButton(
                    icon: CustomIconWidget(
                      iconName: 'close',
                      size: 6.w,
                      color: theme.colorScheme.onSurface,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Divider(
                color: theme.colorScheme.outline.withValues(alpha: 0.2), height: 1),
            Expanded(
              child: Consumer<SavedItemsProvider>(
                builder: (context, savedProvider, child) {
                  final items = savedProvider.items;
                  if (items.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.favorite_border,
                              size: 60,
                              color: theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.3)),
                          SizedBox(height: 1.5.h),
                          Text('No saved items',
                              style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    );
                  }
                  return GridView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 1.w, vertical: 0.6.h),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.59,
                      crossAxisSpacing: 1.5.w,
                      mainAxisSpacing: 0.6.h,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _buildWishlistCard(item);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWishlistCard(Map<String, dynamic> item) {
    final theme = Theme.of(context);
    final savedItemsProvider = context.read<SavedItemsProvider>();
    final cartProvider = context.read<CartProvider>();
    
    final id = item['id'] ?? item['productId'];
    final name = item['name'] as String? ?? 'Product';
    final imageUrl = item['image'] as String? ?? item['imageUrl'] as String? ?? '';
    final priceStr = item['price']?.toString() ?? '0.00';
    final price = double.tryParse(priceStr) ?? 0.0;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: CustomImageWidget(
                  imageUrl: imageUrl.isNotEmpty ? imageUrl : null,
                  width: double.infinity,
                  height: 21.h,
                  fit: BoxFit.cover,
                  semanticLabel: name,
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => savedItemsProvider.toggleItem({'id': id, 'name': name, 'price': price, 'imageUrl': imageUrl}),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withValues(alpha: 0.8),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.favorite,
                      color: Colors.red,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(2.5.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: theme.textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 0.3.h),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 18),
                      SizedBox(width: 1.w),
                      Text(
                        '4.5',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            'ج.م ',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontSize: (theme.textTheme.titleMedium?.fontSize ?? 16) * 0.6,
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          Text(
                            price.toStringAsFixed(2),
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w100,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () {
                          cartProvider.addItem({
                            'id': id,
                            'name': name,
                            'price': price,
                            'imageUrl': imageUrl,
                          });
                          Fluttertoast.showToast(msg: 'Added to cart');
                        },
                        child: Container(
                          padding: EdgeInsets.all(1.5.w),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.shopping_bag_outlined,
                            color: theme.colorScheme.onPrimary,
                            size: 19,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Section Builders ─────────────────────────────────────────────────────
  Widget _buildWishlistSection() {
    return Consumer<SavedItemsProvider>(
      builder: (context, savedProvider, child) {
        return ProfileSectionWidget(
          title: 'WISHLIST',
          items: [
            ProfileMenuItem(
              icon: 'favorite',
              title: 'Saved Items',
              badge: savedProvider.items.length.toString(),
              onTap: () => _showWishlist(),
            ),
            ProfileMenuItem(
              icon: 'notifications',
              title: 'Price Drop Alerts',
              trailing: const NotificationToggleWidget(type: 'price_drop'),
              onTap: () =>
                  Fluttertoast.showToast(msg: 'Price Drop Alerts Coming Soon!'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAccountSection(AuthProvider auth) {
    return ProfileSectionWidget(
      title: 'ACCOUNT',
      items: [
        ProfileMenuItem(
          icon: 'person',
          title: 'Edit Profile',
          onTap: _showEditProfileDialog,
        ),
        ProfileMenuItem(
          icon: 'lock',
          title: 'Change Password',
          onTap: _showChangePasswordDialog,
        ),
        if (!auth.isAdmin && !auth.isSeller)
          ProfileMenuItem(
            icon: 'location_on',
            title: 'Addresses',
            onTap: _showAddressesBottomSheet,
          ),
      ],
    );
  }

  Widget _buildOrdersSection() {
    return ProfileSectionWidget(
      title: 'MY ORDERS',
      items: [
        ProfileMenuItem(
          icon: 'shopping_bag',
          title: 'My Orders',
          onTap: () => _fetchMyOrders(),
        ),
        ProfileMenuItem(
          icon: 'payment',
          title: 'My Payments',
          onTap: () => _fetchMyPayments(),
        ),
      ],
    );
  }

  Widget _buildDeliveryPaymentSection() {
    return ProfileSectionWidget(
      title: 'DELIVERY & PAYMENT',
      items: [
        ProfileMenuItem(
          icon: 'local_shipping',
          title: 'Delivery Methods',
          onTap: () =>
              Fluttertoast.showToast(msg: 'Delivery Methods Coming Soon!'),
        ),
        ProfileMenuItem(
          icon: 'payment',
          title: 'Payment Methods',
          onTap: () =>
              Fluttertoast.showToast(msg: 'Payment Methods Coming Soon!'),
        ),
      ],
    );
  }

  Widget _buildRoleBasedSection() {
    final auth = context.read<AuthProvider>();
    if (auth.isAdmin) {
      return ProfileSectionWidget(
        title: 'ADMINISTRATION',
        items: [
          ProfileMenuItem(
            icon: 'gavel',
            title: 'Platform Moderation',
            onTap: () => Navigator.pushNamed(context, '/admin/moderation'),
          ),
          ProfileMenuItem(
            icon: 'analytics',
            title: 'Platform Statistics',
            onTap: () => Fluttertoast.showToast(msg: 'Statistics Coming Soon!'),
          ),
        ],
      );
    } else if (auth.isSeller) {
      return ProfileSectionWidget(
        title: 'STORE MANAGEMENT',
        items: [
          ProfileMenuItem(
            icon: 'inventory_2',
            title: 'Manage Inventory',
            onTap: () => Navigator.pushNamed(context, '/seller/inventory'),
          ),
          ProfileMenuItem(
            icon: 'storefront',
            title: 'Shop Settings',
            onTap: () => Fluttertoast.showToast(msg: 'Shop Settings Coming Soon!'),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildSettingsSection() {
    return ProfileSectionWidget(
      title: 'SETTINGS',
      items: [
        ProfileMenuItem(
          icon: 'dark_mode',
          title: 'Theme',
          trailing: const ThemeToggleWidget(),
        ),
        ProfileMenuItem(
          icon: 'language',
          title: 'Language',
          onTap: _showLanguageDialog,
        ),
      ],
    );
  }

  Widget _buildSupportSection() {
    return ProfileSectionWidget(
      title: 'SUPPORT',
      items: [
        ProfileMenuItem(
          icon: 'help',
          title: 'Help Center',
          onTap: () => Fluttertoast.showToast(msg: 'Help Center Coming Soon!'),
        ),
        ProfileMenuItem(
          icon: 'info',
          title: 'About Us',
          onTap: () => Fluttertoast.showToast(msg: 'About Us Coming Soon!'),
        ),
      ],
    );
  }

  void _showLanguageDialog() {
    final theme = Theme.of(context);
    final langProvider = context.read<LanguageProvider>();
    final currentCode = langProvider.locale.languageCode;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          currentCode == 'ar' ? 'اللغة' : 'Language',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.language,
              size: 60,
              color: theme.colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              currentCode == 'ar' ? 'قريباً!' : 'Coming soon!',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              currentCode == 'ar' ? 'ميزة تغيير اللغة قريباً' : 'Language switching coming soon',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              currentCode == 'ar' ? 'إغلاق' : 'Close',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutSection() {
    return ProfileSectionWidget(
      title: 'SESSION',
      items: [
        ProfileMenuItem(
          icon: 'logout',
          title: 'Logout',
          onTap: _showLogoutConfirmation,
        ),
      ],
    );
  }

  //           Build                                                                                                                                                                                                 
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        AppRoutes.navigateToRoot(context);
      },
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.95),
        appBar: CustomAppBar(
          title: 'Profile',
          style: CustomAppBarStyle.standard,
          showBackButton: true,
          onBackButtonPressed: () {
            AppRoutes.navigateToRoot(context);
          },
          showSearchButton: false,
          showCartButton: !auth.isAdmin && !auth.isSeller,
          cartItemCount: context.watch<CartProvider>().totalItems,
        ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchUserProfile,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    ProfileHeaderWidget(userProfile: _userProfile),
                    
                    if (_userProfile != null && _userProfile?['role'] != null)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 0.5.h),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Account Type: ${_userProfile!['role']}',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    
                    SizedBox(height: 1.h),
                    
                    // Shared sections (Visible to both Guest & Auth)
                    if (!auth.isAdmin && !auth.isSeller) _buildWishlistSection(),
                    _buildRoleBasedSection(),
                    _buildSettingsSection(),

                    // Auth-only sections
                    if (_userProfile != null) ...[
                      _buildAccountSection(auth),
                      if (!auth.isAdmin && !auth.isSeller) ...[
                        _buildOrdersSection(),
                        _buildDeliveryPaymentSection(),
                      ],
                      _buildSupportSection(),
                      _buildLogoutSection(),
                    ] else ...[
                      // Extra prompt for guests at the bottom
                      Padding(
                        padding: EdgeInsets.all(4.w),
                        child: Text(
                          'Sign in to see your orders and save addresses.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                    ],
                    SizedBox(height: 1.h),
                    
                    // App version at bottom
                    Text(
                      'App Version 1.0.0',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: CustomBottomBar(
        currentRoute: '/profile-screen',
        cartItemCount: context.watch<CartProvider>().totalItems,
        role: context.watch<AuthProvider>().displayRole,
      ),
    ),
  );
}

  Widget _buildStatusBadge(String status, ThemeData theme) {
    Color color;
    switch (status.toLowerCase()) {
      case 'completed':
      case 'delivered':
      case 'paid':
      case 'success':
        color = Colors.green;
        break;
      case 'pending':
      case 'processing':
        color = Colors.orange;
        break;
      case 'cancelled':
      case 'failed':
        color = Colors.red;
        break;
      default:
        color = theme.colorScheme.primary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        status,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showOrderItemsForReview(Map<String, dynamic> order) {
    final theme = Theme.of(context);
    final items = order['orderItems'] as List<dynamic>? ?? [];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 45.h,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(3.w),
              child: Text('Rate your items', style: theme.textTheme.titleLarge),
            ),
            Expanded(
              child: items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 60, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
                          SizedBox(height: 1.5.h),
                          Text('No items found in this order', style: theme.textTheme.titleMedium),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 1.w, vertical: 0.6.h),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 100.w > 600 ? 3 : 2,
                        childAspectRatio: 0.59,
                        crossAxisSpacing: 1.5.w,
                        mainAxisSpacing: 0.6.h,
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final product = item['product'] as Map<String, dynamic>?;
                        final productName = product?['name'] ?? 'Unknown Product';
                        
                        final dynamic rawId = item['productId'] ??
                                   item['ProductId'] ??
                                   product?['productId'] ??
                                   product?['id'] ??
                                   0;
                        final int productId = (rawId is int) ? rawId : (int.tryParse(rawId.toString()) ?? 0);

                        if (productId == 0) return const SizedBox.shrink();

                        return OrderItemCard(
                          item: item,
                          onReview: () async {
                            Navigator.pop(context);
                            final result = await showDialog<bool>(
                              context: context,
                              builder: (context) => ReviewDialog(
                                productId: productId,
                                productName: productName,
                              ),
                            );
                            if (result == true) {
                              _fetchMyOrders();
                            }
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

