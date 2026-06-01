import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../core/providers/cart_provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/order_service.dart';
import '../../widgets/custom_app_bar.dart';

class CheckoutScreen extends StatefulWidget {
  final double total;
  final String? promoCode;

  const CheckoutScreen({
    super.key,
    required this.total,
    this.promoCode,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  int _currentStep = 0;
  String _selectedPaymentMethod = 'Credit Card';
  Map<String, dynamic>? _selectedAddress;
  List<Map<String, dynamic>> _addresses = [];
  bool _isLoadingAddresses = false;
  bool _isPlacingOrder = false;

  @override
  void initState() {
    super.initState();
    _loadServerCart();
    _fetchAddresses();
  }

  Future<void> _fetchAddresses() async {
    setState(() => _isLoadingAddresses = true);
    try {
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/api/Addresses'),
        headers: await AuthService.authHeaders,
      );
      if (response.statusCode == 200) {
        final list = AuthService.parseResponseList(response.body)
            .whereType<Map<String, dynamic>>()
            .toList();
        setState(() {
          _addresses = list;
          if (_addresses.isNotEmpty) {
            _selectedAddress = _addresses.first;
          }
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoadingAddresses = false);
    }
  }

  Future<void> _loadServerCart() async {
    try {
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/api/Cart'),
        headers: await AuthService.authHeaders,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('Server cart loaded: ${data['cartItems']?.length} items');
      }
    } catch (_) {}
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
        Fluttertoast.showToast(msg: 'Failed to add address');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error adding address');
    }
  }

  void _showAddAddressDialog() {
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
              decoration: const InputDecoration(labelText: 'Street'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: cityController,
              decoration: const InputDecoration(labelText: 'City'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: countryController,
              decoration: const InputDecoration(labelText: 'Country'),
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
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _placeOrder() async {
    if (_selectedAddress == null) {
      Fluttertoast.showToast(msg: 'Please select a delivery address');
      return;
    }

    setState(() => _isPlacingOrder = true);

    try {
      final headers = await AuthService.authHeaders;
      if (!mounted) return;
      final cartProvider = context.read<CartProvider>();
      final cartItems = cartProvider.items;

      if (cartItems.isEmpty) {
        Fluttertoast.showToast(msg: 'Your cart is empty locally');
        setState(() => _isPlacingOrder = false);
        return;
      }

      // ── Step 1: Wipe the server-side cart completely ──
      debugPrint('Checkout: Wiping server cart...');
      try {
        final getCartRes = await http.get(
          Uri.parse('${AuthService.baseUrl}/api/CartItems'),
          headers: headers,
        );
        if (getCartRes.statusCode == 200) {
          final List<dynamic> itemsToClear = AuthService.parseResponseList(getCartRes.body);
          for (final item in itemsToClear) {
            final id = item['cartItemId'] ?? item['id'] ?? item['productId'];
            await http.delete(
              Uri.parse('${AuthService.baseUrl}/api/CartItems/$id'),
              headers: headers,
            );
          }
        }
      } catch (e) {
        debugPrint('Checkout: Error during cart wipe: $e');
      }

      // ── Step 1.5: Aggressive ID Detection & Address Check ──
      debugPrint('Checkout: Starting Aggressive ID Detection...');
      String? userId;
      int? customerId;
      
      // Check for addresses first - sometimes this "initializes" the customer
      try {
        final addrRes = await http.get(Uri.parse('${AuthService.baseUrl}/api/Addresses'), headers: headers);
        if (addrRes.statusCode == 200) {
          final List<dynamic> addresses = AuthService.parseResponseList(addrRes.body);
          debugPrint('Checkout: Found ${addresses.length} addresses.');
          if (addresses.isEmpty) {
            debugPrint('Checkout: WARNING! No addresses found. This might be why the cart is "empty".');
          }
        }
      } catch (_) {}

      // Attempt to find IDs in profiles
      try {
        final res = await http.get(Uri.parse('${AuthService.baseUrl}/api/UserProfile/profile'), headers: headers);
        if (res.statusCode == 200) {
          final profile = jsonDecode(res.body);
          userId = (profile['userId'] ?? profile['id'] ?? profile['email'])?.toString();
          final dynamic cid = profile['customerId'] ?? profile['customer']?['customerId'];
          if (cid != null) customerId = int.tryParse(cid.toString());
        }
      } catch (_) {}

      debugPrint('Checkout: FINAL IDENTITY -> UserID: $userId, CustomerID: $customerId');

      // ── Step 2: Re-add all items to server ──────────
      debugPrint('Checkout: Re-adding ${cartItems.length} items to server...');
      for (final item in cartItems) {
        final dynamic rawId = item['productId'] ?? item['id'];
        final int? productId = (rawId is int) ? rawId : int.tryParse(rawId.toString());
        final int quantity = (item['quantity'] as num?)?.toInt() ?? 1;

        if (productId != null) {
          await http.post(
            Uri.parse('${AuthService.baseUrl}/api/CartItems'),
            headers: headers,
            body: jsonEncode({
              'productId': productId,
              'quantity': quantity,
              // Try sending BOTH to be safe
              if (userId != null) 'userId': userId,
              if (customerId != null) 'customerId': customerId,
            }),
          );
        }
      }

      // Wait longer for the server to sync the items to the order table
      await Future.delayed(const Duration(milliseconds: 1500));

      // ── Step 3: Verify server cart content ─────────────────────────
      final verifyRes = await http.get(
        Uri.parse('${AuthService.baseUrl}/api/CartItems'),
        headers: headers,
      );
      if (verifyRes.statusCode == 200) {
        debugPrint('🔍 FINAL_SERVER_CART_CONTENT: ${verifyRes.body}');
      }
      if (verifyRes.statusCode == 200) {
        final List<dynamic> serverItems = AuthService.parseResponseList(verifyRes.body);
        debugPrint('Checkout: Server confirms ${serverItems.length} items in cart');
        if (serverItems.isEmpty) {
          throw Exception('Server cart is still empty after sync. Please try again.');
        }
      }

      // ── Step 4: Final Place Order ──────────────────────────────────────────
      debugPrint('Checkout: Sending final place-order request...');
      
      final int? addressId = _selectedAddress?['addressId'] ?? _selectedAddress?['id'];
      final String paymentMethod = _selectedPaymentMethod == 'Cash on Delivery' ? 'Cash' : _selectedPaymentMethod;

      await OrderService.placeOrder(
        paymentMethod: paymentMethod,
        addressId: addressId,
        couponCode: widget.promoCode,
      );

      cartProvider.clearCart();
      _showSuccessDialog();
    } catch (e) {
      debugPrint('Checkout Error: $e');
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      if (errorMsg.contains('فاضيه')) {
        Fluttertoast.showToast(
            msg: 'Sync issue. Trying auto-fix, please press order again.',
            toastLength: Toast.LENGTH_LONG);
      } else {
        Fluttertoast.showToast(msg: errorMsg);
      }
    } finally {
      if (mounted) setState(() => _isPlacingOrder = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary, size: 80),
            const SizedBox(height: 20),
            Text('Order Placed!',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 10),
            const Text(
              'Your order has been successfully placed and is being processed.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.pushNamedAndRemoveUntil(
                      context, '/home-screen', (route) => false);
                },
                child: const Text('Back to Home'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/home-screen',
          (route) => false,
        );
      },
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'Checkout',
          showBackButton: true,
          showSearchButton: false,
          showCartButton: false,
          onBackButtonPressed: () {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/home-screen',
              (route) => false,
            );
          },
        ),
      body: Stepper(
        type: StepperType.horizontal,
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep < 2) {
            setState(() => _currentStep++);
          } else {
            _placeOrder();
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() => _currentStep--);
          }
        },
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: 24.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isPlacingOrder ? null : details.onStepContinue,
                    child: _isPlacingOrder
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(_currentStep == 2 ? 'Place Order' : 'Continue'),
                  ),
                ),
                if (_currentStep > 0) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: details.onStepCancel,
                      child: const Text('Back'),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
        steps: [
          Step(
            title: const Text('Shipping'),
            isActive: _currentStep >= 0,
            state: _currentStep > 0 ? StepState.complete : StepState.indexed,
            content: _buildShippingStep(),
          ),
          Step(
            title: const Text('Payment'),
            isActive: _currentStep >= 1,
            state: _currentStep > 1 ? StepState.complete : StepState.indexed,
            content: _buildPaymentStep(),
          ),
          Step(
            title: const Text('Review'),
            isActive: _currentStep >= 2,
            content: _buildReviewStep(),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildShippingStep() {
    final theme = Theme.of(context);
    if (_isLoadingAddresses) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Select Delivery Address', style: theme.textTheme.titleMedium),
            TextButton.icon(
              onPressed: _showAddAddressDialog,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add New'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_addresses.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24.0),
            child: Center(child: Text('No addresses found. Please add one.')),
          )
        else
          ..._addresses.map((addr) => RadioListTile<Map<String, dynamic>>(
                // ignore: deprecated_member_use
                value: addr,
                // ignore: deprecated_member_use
                groupValue: _selectedAddress,
                // ignore: deprecated_member_use
                onChanged: (val) => setState(() => _selectedAddress = val),
                title: Text(addr['street'] ?? ''),
                subtitle: Text('${addr['city']}, ${addr['country']}'),
              )),
      ],
    );
  }

  Widget _buildPaymentStep() {
    final theme = Theme.of(context);
    final methods = ['Credit Card', 'PayPal', 'Cash on Delivery'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Select Payment Method', style: theme.textTheme.titleMedium),
        const SizedBox(height: 16),
        ...methods.map((method) => RadioListTile<String>(
              // ignore: deprecated_member_use
              value: method,
              // ignore: deprecated_member_use
              groupValue: _selectedPaymentMethod,
              // ignore: deprecated_member_use
              onChanged: (val) => setState(() => _selectedPaymentMethod = val!),
              title: Text(method),
              secondary: Icon(_getPaymentIcon(method)),
            )),
      ],
    );
  }

  IconData _getPaymentIcon(String method) {
    switch (method) {
      case 'Credit Card':
        return Icons.credit_card;
      case 'PayPal':
        return Icons.account_balance_wallet;
      default:
        return Icons.money;
    }
  }

  Widget _buildReviewStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildReviewSection('Shipping To',
            '${_selectedAddress?['street']}\n${_selectedAddress?['city']}, ${_selectedAddress?['country']}'),
        const Divider(),
        _buildReviewSection('Payment Method', _selectedPaymentMethod),
        const Divider(),
        _buildReviewSection(
            'Order Total', 'ج.م ${widget.total.toStringAsFixed(2)}'),
      ],
    );
  }

  Widget _buildReviewSection(String title, String content) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: theme.textTheme.labelLarge
                  ?.copyWith(color: theme.colorScheme.primary)),
          const SizedBox(height: 4),
          Text(content, style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }
}
