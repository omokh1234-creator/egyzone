import 'package:egyzone/presentation/forgot_password_screen/forgot_password_screen.dart';
import 'package:egyzone/presentation/home_screen/home_screen.dart';
import 'package:egyzone/presentation/login_screen/login_screen.dart';
import 'package:egyzone/presentation/product_details_screen/product_detail_screen.dart';
import 'package:egyzone/presentation/profile_screen/profile_screen.dart';
import 'package:egyzone/presentation/register_screen/register_screen.dart';
import 'package:egyzone/presentation/search_screen/search_screen.dart';
import 'package:egyzone/presentation/shopping_cart_screen/shopping_cart_screen.dart';
import 'package:egyzone/presentation/splash_screen/splash_screen.dart';
import 'package:egyzone/presentation/checkout_screen/checkout_screen.dart';
import 'package:egyzone/presentation/chat_bot_screen/chat_bot_screen.dart';
import 'package:egyzone/presentation/notifications_screen/notifications_screen.dart';
import 'package:egyzone/presentation/seller_screen/seller_inventory_screen.dart';
import 'package:egyzone/presentation/admin_screen/admin_moderation_screen.dart';
import 'package:egyzone/presentation/seller_screen/add_product_screen.dart';
import 'package:egyzone/presentation/seller_screen/edit_product_screen.dart';
import 'package:egyzone/presentation/admin_screen/create_coupon_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:egyzone/core/providers/auth_provider.dart';

class AppRoutes {
  AppRoutes._();

  static const String initial = '/splash-screen';
  static const String splash = '/splash-screen';
  static const String login = '/login-screen';
  static const String register = '/register-screen';
  static const String forgotPassword = '/forgot-password-screen';
  static const String home = '/home-screen';
  static const String productDetail = '/product-detail-screen';
  static const String shoppingCart = '/shopping-cart-screen';
  static const String search = '/search-screen';
  static const String profile = '/profile-screen';
  static const String checkout = '/checkout-screen';
  static const String chatBot = '/chat-bot-screen';
  static const String notifications = '/notifications-screen';
  static const String sellerInventory = '/seller/inventory';
  static const String adminModeration = '/admin/moderation';
  static const String addProduct = '/seller/add-product';
  static const String editProduct = '/seller/edit-product';
  static const String createCoupon = '/admin/create-coupon';

  static final Map<String, WidgetBuilder> routes = {
    splash: (context) => const SplashScreen(),
    login: (context) => const LoginScreen(),
    register: (context) => const RegisterScreen(),
    forgotPassword: (context) => const ForgotPasswordScreen(),
    home: (context) => const HomeScreen(),
    shoppingCart: (context) => const CartScreen(),
    search: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return SearchScreen(
        initialQuery: args?['query'],
        initialCategory: args?['category'],
        initialSortBy: args?['sortBy'],
      );
    },
    profile: (context) => const ProfileScreen(),
    checkout: (context) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return CheckoutScreen(
        total: args?['total'] ?? 0.0,
        promoCode: args?['promoCode'],
      );
    },
    chatBot: (context) => const ChatBotScreen(),

    // ProductDetailScreen reads arguments passed via Navigator.pushNamed
    productDetail: (context) {
      final args = ModalRoute.of(context)?.settings.arguments;
      final productData =
          args is Map<String, dynamic> ? args : <String, dynamic>{};
      return ProductDetailScreen(productData: productData);
    },
    notifications: (context) => const NotificationsScreen(),
    sellerInventory: (context) => const SellerInventoryScreen(),
    adminModeration: (context) => const AdminModerationScreen(),
    addProduct: (context) => const AddProductScreen(),
    editProduct: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return EditProductScreen(productData: args ?? {});
    },
    createCoupon: (context) => const CreateCouponScreen(),
  };

  static void navigateToRoot(BuildContext context) {
    if (!context.mounted) return;
    final auth = context.read<AuthProvider>();
    final role = auth.displayRole.toLowerCase();
    String rootRoute = home;
    if (role == 'admin') {
      rootRoute = adminModeration;
    } else if (role == 'seller') {
      rootRoute = sellerInventory;
    }

    Navigator.pushNamedAndRemoveUntil(
      context,
      rootRoute,
      (route) => false,
    );
  }

  static void navigateToScreen(BuildContext context, String routeName,
      {Object? arguments}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => routes[routeName]!(context),
        settings: RouteSettings(arguments: arguments),
      ),
    ).then((_) {
      if (!context.mounted) return;
      if (routeName != home && routeName != adminModeration && routeName != sellerInventory) {
        navigateToRoot(context);
      }
    });
  }
}
