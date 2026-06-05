
import 'package:egyzone/presentation/shopping_cart_screen/widgets/empty_card_widget.dart';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../../core/providers/cart_provider.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';
import './widgets/cart_item_card.dart';
import './widgets/cart_summary_card.dart';

import '../../routes/app_routes.dart';
import '../../widgets/auth_gate_widget.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {

  bool _isValidatingCoupon = false;

  @override
  void initState() {
    super.initState();
    // No need to load server cart here anymore as CartProvider handles it globally
  }

  // ─── Coupon validation ────────────────────────────────────────────────────
  Future<void> _validateAndApplyCoupon(String code) async {
    final cleanCode = code.trim().toUpperCase();
    if (cleanCode.isEmpty) {
      context.read<CartProvider>().removeCoupon();
      return;
    }

    setState(() => _isValidatingCoupon = true);

    try {
      final cartProvider = context.read<CartProvider>();
      await cartProvider.applyCoupon(cleanCode);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Coupon applied! You save ج.م  ${cartProvider.discount.toStringAsFixed(2).replaceAll('.00', '')}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        context.read<CartProvider>().removeCoupon();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isValidatingCoupon = false);
    }
  }

  // ─── Place order ──────────────────────────────────────────────────────────
  // Step 1: Sync local cart items to the server.
  // Step 2: Call place-order.
  // The API returns plain Arabic text (e.g. "سلتك فاضية") on some errors,
  // so jsonDecode is wrapped in try/catch to prevent crashes.


  // ─── Remove cart item from API ────────────────────────────────────────────
  Future<void> _removeCartItem(dynamic id) async {
    context.read<CartProvider>().removeItem(id);
  }

  // ─── Dialogs ──────────────────────────────────────────────────────────────
  void _showPromoCodeDialog() {
    final theme = Theme.of(context);
    final cart = context.read<CartProvider>();
    final controller = TextEditingController(
        text: cart.appliedCoupon != null ? cart.appliedCoupon!['code'] : '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Enter Promo Code', style: theme.textTheme.titleLarge),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Promo Code',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _isValidatingCoupon
                ? null
                : () {
                    Navigator.of(context).pop();
                    _validateAndApplyCoupon(controller.text.trim());
                  },
            child: _isValidatingCoupon
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _showClearCartDialog() {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cart'),
        content: const Text(
            'Are you sure you want to remove all items from your cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<CartProvider>().clearCart();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cart cleared'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }





  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final cartItems = cartProvider.items;
    final subtotal = cartProvider.subtotal;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: CustomAppBar(
        title: 'Shopping Cart',
        style: CustomAppBarStyle.standard,
        showBackButton: true,
        showSearchButton: false,
        showCartButton: false,
        actions: cartItems.isNotEmpty
            ? [
                TextButton(
                  onPressed: _showClearCartDialog,
                  child: Text(
                    'Clear Cart',
                    style: TextStyle(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ]
            : null,
      ),
      body: cartItems.isEmpty
          ? EmptyCartWidget(
              onStartShopping: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/home-screen',
                  (route) => false,
                );
              },
            )
          : ListView.builder(
              padding: EdgeInsets.only(bottom: 20.h),
              itemCount: cartItems.length,
              itemBuilder: (context, index) {
                final item = cartItems[index];
                return CartItemCard(
                  item: item,
                  onRemove: () => _removeCartItem(item['id']),
                  onIncrement: () => cartProvider.increment(item['id']),
                  onDecrement: () => cartProvider.decrement(item['id']),
                  onSaveForLater: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${item['name']} saved for later.'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                );
              },
            ),
      bottomNavigationBar: cartItems.isEmpty
          ? CustomBottomBar(
              currentRoute: '/shopping-cart-screen',
              cartItemCount: 0,
            )
          : CartSummaryCard(
              subtotal: subtotal,
              tax: subtotal * 0.012,
              shipping: 0,
              total: (subtotal * 1.012) - cartProvider.discount,
              isCartEmpty: cartItems.isEmpty,
              onCheckout: () async {
                // Gate: user must be authenticated before checkout
                final ok = await requireAuth(
                  context,
                  reason: 'Sign in to place your order',
                );
                if (!ok || !context.mounted) return;
                // Sync cart to server for the now-authenticated user
                await context.read<CartProvider>().refreshFromServer();
                if (!context.mounted) return;
                Navigator.pushNamed(
                  context,
                  AppRoutes.checkout,
                  arguments: {
                    'total': (subtotal * 1.012) - cartProvider.discount,
                    'promoCode': cartProvider.appliedCoupon?['code'],
                  },
                );
              },
              onPromoCodeTap: _showPromoCodeDialog,
              hasPromoCode: cartProvider.appliedCoupon != null,
              promoCodeDiscount: cartProvider.discount.toString(),
            ),
    );
  }
}
