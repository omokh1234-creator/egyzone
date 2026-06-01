import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';

/// App-wide localization helper.
///
/// Usage:
///   import 'package:egyzone/core/localization/app_localizations.dart';
///   ...
///   Text(AppLocalizations.of(context).homeTitle)
///
/// Or shorthand via extension:
///   Text(context.tr('home_title'))
class AppLocalizations {
  final String languageCode;

  AppLocalizations(this.languageCode);

  static AppLocalizations of(BuildContext context) {
    final code = context.watch<LanguageProvider>().locale.languageCode;
    return AppLocalizations(code);
  }

  /// Returns the translated string for [key].
  /// Falls back to English if Arabic translation is missing.
  String tr(String key) {
    final arMap = _arStrings[key];
    if (languageCode == 'ar' && arMap != null) return arMap;
    return _enStrings[key] ?? key;
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // English strings (source of truth)
  // ─────────────────────────────────────────────────────────────────────────────
  static const Map<String, String> _enStrings = {
    // ── General ──────────────────────────────────────────────────────────────
    'app_name': 'EgyZone',
    'ok': 'OK',
    'cancel': 'Cancel',
    'save': 'Save',
    'delete': 'Delete',
    'close': 'Close',
    'confirm': 'Confirm',
    'loading': 'Loading...',
    'error': 'Error',
    'retry': 'Retry',
    'search': 'Search',
    'no_results': 'No results found',
    'something_went_wrong': 'Something went wrong. Please try again.',

    // ── Bottom Navigation ─────────────────────────────────────────────────────
    'nav_home': 'Home',
    'nav_cart': 'Cart',
    'nav_saved': 'Saved',
    'nav_profile': 'Profile',
    'nav_orders': 'Orders',

    // ── Login Screen ──────────────────────────────────────────────────────────
    'login_title': 'Welcome Back',
    'login_subtitle': 'Sign in to continue',
    'login_email': 'Email',
    'login_password': 'Password',
    'login_forgot_password': 'Forgot Password?',
    'login_btn': 'Sign In',
    'login_no_account': "Don't have an account?",
    'login_register': 'Register',
    'login_email_hint': 'Enter your email',
    'login_password_hint': 'Enter your password',
    'login_email_required': 'Email is required',
    'login_email_invalid': 'Please enter a valid email',
    'login_password_required': 'Password is required',
    'login_success': 'Login successful!',
    'login_failed': 'Login failed. Please check your credentials.',

    // ── Register Screen ───────────────────────────────────────────────────────
    'register_title': 'Create Account',
    'register_subtitle': 'Join EgyZone today',
    'register_full_name': 'Full Name',
    'register_full_name_hint': 'Enter your full name',
    'register_email': 'Email',
    'register_email_hint': 'Enter your email',
    'register_password': 'Password',
    'register_password_hint': 'Create a password',
    'register_confirm_password': 'Confirm Password',
    'register_confirm_password_hint': 'Re-enter your password',
    'register_phone': 'Phone Number',
    'register_phone_hint': 'Enter your phone number',
    'register_btn': 'Create Account',
    'register_have_account': 'Already have an account?',
    'register_login': 'Sign In',
    'register_name_required': 'Full name is required',
    'register_passwords_no_match': 'Passwords do not match',
    'register_success': 'Account created successfully!',

    // ── Forgot Password ───────────────────────────────────────────────────────
    'forgot_title': 'Forgot Password',
    'forgot_subtitle': 'Enter your email to reset your password',
    'forgot_email': 'Email',
    'forgot_email_hint': 'Enter your email',
    'forgot_btn': 'Send Reset Link',
    'forgot_back_login': 'Back to Login',
    'forgot_success': 'Reset link sent to your email',

    // ── Home Screen ───────────────────────────────────────────────────────────
    'home_search_hint': 'Search products...',
    'home_categories': 'Categories',
    'home_see_all': 'See All',
    'home_featured': 'Featured Products',
    'home_new_arrivals': 'New Arrivals',
    'home_best_sellers': 'Best Sellers',
    'home_all': 'All',
    'home_no_products': 'No products available',
    'home_greeting_morning': 'Good Morning',
    'home_greeting_afternoon': 'Good Afternoon',
    'home_greeting_evening': 'Good Evening',
    'home_welcome': 'Welcome to EgyZone',

    // ── Product Details ───────────────────────────────────────────────────────
    'product_add_to_cart': 'Add to Cart',
    'product_buy_now': 'Buy Now',
    'product_description': 'Description',
    'product_reviews': 'Reviews',
    'product_specifications': 'Specifications',
    'product_in_stock': 'In Stock',
    'product_out_of_stock': 'Out of Stock',
    'product_quantity': 'Quantity',
    'product_save': 'Save',
    'product_share': 'Share',
    'product_added_to_cart': 'Added to cart!',
    'product_saved': 'Product saved!',
    'product_unsaved': 'Product removed from saved.',
    'product_seller': 'Seller',
    'product_free_shipping': 'Free Shipping',
    'product_rating': 'Rating',
    'product_no_reviews': 'No reviews yet',
    'product_write_review': 'Write a Review',
    'product_related': 'Related Products',
    'product_price': 'Price',

    // ── Shopping Cart ─────────────────────────────────────────────────────────
    'cart_title': 'My Cart',
    'cart_empty': 'Your cart is empty',
    'cart_empty_subtitle': 'Start shopping to add items to your cart',
    'cart_shop_now': 'Shop Now',
    'cart_subtotal': 'Subtotal',
    'cart_shipping': 'Shipping',
    'cart_total': 'Total',
    'cart_free_shipping': 'Free',
    'cart_checkout': 'Proceed to Checkout',
    'cart_remove': 'Remove',
    'cart_coupon': 'Apply Coupon',
    'cart_coupon_hint': 'Enter coupon code',
    'cart_coupon_apply': 'Apply',
    'cart_coupon_remove': 'Remove',
    'cart_coupon_applied': 'Coupon applied!',
    'cart_coupon_invalid': 'Invalid coupon code',
    'cart_item_removed': 'Item removed from cart',
    'cart_continue_shopping': 'Continue Shopping',
    'cart_items': 'items',
    'cart_item': 'item',
    'cart_discount': 'Discount',
    'cart_order_summary': 'Order Summary',

    // ── Profile Screen ────────────────────────────────────────────────────────
    'profile_title': 'Profile',
    'profile_edit': 'Edit Profile',
    'profile_orders': 'My Orders',
    'profile_saved': 'Saved Items',
    'profile_addresses': 'Addresses',
    'profile_settings': 'SETTINGS',
    'profile_support': 'SUPPORT',
    'profile_session': 'SESSION',
    'profile_theme': 'Theme',
    'profile_language': 'Language',
    'profile_notifications': 'Notifications',
    'profile_help': 'Help Center',
    'profile_about': 'About Us',
    'profile_logout': 'Logout',
    'profile_logout_confirm': 'Are you sure you want to logout?',
    'profile_logout_yes': 'Logout',
    'profile_logout_cancel': 'Cancel',
    'profile_member_since': 'Member since',
    'profile_select_language': 'Select Language',
    'profile_language_changed_en': 'Language changed to English',
    'profile_no_email': 'No email provided',
    'profile_edit_coming_soon': 'Profile editing coming soon!',
    'profile_help_coming_soon': 'Help Center Coming Soon!',
    'profile_about_coming_soon': 'About Us Coming Soon!',

    // ── Orders ────────────────────────────────────────────────────────────────
    'orders_title': 'My Orders',
    'orders_empty': 'No orders yet',
    'orders_empty_subtitle': 'Your orders will appear here',
    'orders_status_pending': 'Pending',
    'orders_status_processing': 'Processing',
    'orders_status_shipped': 'Shipped',
    'orders_status_delivered': 'Delivered',
    'orders_status_cancelled': 'Cancelled',
    'orders_total': 'Total',
    'orders_date': 'Order Date',
    'orders_id': 'Order #',
    'orders_details': 'View Details',
    'orders_reorder': 'Reorder',

    // ── Search ────────────────────────────────────────────────────────────────
    'search_title': 'Search',
    'search_hint': 'Search for products...',
    'search_no_results': 'No products found',
    'search_try_different': 'Try a different search term',
    'search_filters': 'Filters',
    'search_sort': 'Sort By',
    'search_sort_price_low': 'Price: Low to High',
    'search_sort_price_high': 'Price: High to Low',
    'search_sort_newest': 'Newest First',
    'search_sort_rating': 'Highest Rated',

    // ── Checkout ──────────────────────────────────────────────────────────────
    'checkout_title': 'Checkout',
    'checkout_address': 'Delivery Address',
    'checkout_payment': 'Payment Method',
    'checkout_order_summary': 'Order Summary',
    'checkout_place_order': 'Place Order',
    'checkout_address_hint': 'Enter delivery address',
    'checkout_name_hint': 'Full Name',
    'checkout_phone_hint': 'Phone Number',
    'checkout_city_hint': 'City',
    'checkout_success': 'Order placed successfully!',
    'checkout_cash_on_delivery': 'Cash on Delivery',

    // ── Notifications ─────────────────────────────────────────────────────────
    'notifications_title': 'Notifications',
    'notifications_empty': 'No notifications yet',
    'notifications_mark_read': 'Mark all as read',
  };

  // ─────────────────────────────────────────────────────────────────────────────
  // Arabic translations
  // ─────────────────────────────────────────────────────────────────────────────
  static const Map<String, String> _arStrings = {
    // ── General ──────────────────────────────────────────────────────────────
    'app_name': 'إيجي زون',
    'ok': 'موافق',
    'cancel': 'إلغاء',
    'save': 'حفظ',
    'delete': 'حذف',
    'close': 'إغلاق',
    'confirm': 'تأكيد',
    'loading': 'جاري التحميل...',
    'error': 'خطأ',
    'retry': 'إعادة المحاولة',
    'search': 'بحث',
    'no_results': 'لا توجد نتائج',
    'something_went_wrong': 'حدث خطأ ما. يرجى المحاولة مجدداً.',

    // ── Bottom Navigation ─────────────────────────────────────────────────────
    'nav_home': 'الرئيسية',
    'nav_cart': 'السلة',
    'nav_saved': 'المحفوظات',
    'nav_profile': 'الحساب',
    'nav_orders': 'الطلبات',

    // ── Login Screen ──────────────────────────────────────────────────────────
    'login_title': 'مرحباً بعودتك',
    'login_subtitle': 'سجّل دخولك للمتابعة',
    'login_email': 'البريد الإلكتروني',
    'login_password': 'كلمة المرور',
    'login_forgot_password': 'نسيت كلمة المرور؟',
    'login_btn': 'تسجيل الدخول',
    'login_no_account': 'ليس لديك حساب؟',
    'login_register': 'إنشاء حساب',
    'login_email_hint': 'أدخل بريدك الإلكتروني',
    'login_password_hint': 'أدخل كلمة المرور',
    'login_email_required': 'البريد الإلكتروني مطلوب',
    'login_email_invalid': 'يرجى إدخال بريد إلكتروني صحيح',
    'login_password_required': 'كلمة المرور مطلوبة',
    'login_success': 'تم تسجيل الدخول بنجاح!',
    'login_failed': 'فشل تسجيل الدخول. يرجى التحقق من بياناتك.',

    // ── Register Screen ───────────────────────────────────────────────────────
    'register_title': 'إنشاء حساب',
    'register_subtitle': 'انضم إلى إيجي زون اليوم',
    'register_full_name': 'الاسم الكامل',
    'register_full_name_hint': 'أدخل اسمك الكامل',
    'register_email': 'البريد الإلكتروني',
    'register_email_hint': 'أدخل بريدك الإلكتروني',
    'register_password': 'كلمة المرور',
    'register_password_hint': 'أنشئ كلمة مرور',
    'register_confirm_password': 'تأكيد كلمة المرور',
    'register_confirm_password_hint': 'أعد إدخال كلمة المرور',
    'register_phone': 'رقم الهاتف',
    'register_phone_hint': 'أدخل رقم هاتفك',
    'register_btn': 'إنشاء الحساب',
    'register_have_account': 'لديك حساب بالفعل؟',
    'register_login': 'تسجيل الدخول',
    'register_name_required': 'الاسم الكامل مطلوب',
    'register_passwords_no_match': 'كلمتا المرور غير متطابقتين',
    'register_success': 'تم إنشاء الحساب بنجاح!',

    // ── Forgot Password ───────────────────────────────────────────────────────
    'forgot_title': 'نسيت كلمة المرور',
    'forgot_subtitle': 'أدخل بريدك الإلكتروني لإعادة تعيين كلمة المرور',
    'forgot_email': 'البريد الإلكتروني',
    'forgot_email_hint': 'أدخل بريدك الإلكتروني',
    'forgot_btn': 'إرسال رابط إعادة التعيين',
    'forgot_back_login': 'العودة لتسجيل الدخول',
    'forgot_success': 'تم إرسال رابط إعادة التعيين إلى بريدك الإلكتروني',

    // ── Home Screen ───────────────────────────────────────────────────────────
    'home_search_hint': 'ابحث عن منتجات...',
    'home_categories': 'الفئات',
    'home_see_all': 'عرض الكل',
    'home_featured': 'منتجات مميزة',
    'home_new_arrivals': 'وصل حديثاً',
    'home_best_sellers': 'الأكثر مبيعاً',
    'home_all': 'الكل',
    'home_no_products': 'لا توجد منتجات متاحة',
    'home_greeting_morning': 'صباح الخير',
    'home_greeting_afternoon': 'مساء الخير',
    'home_greeting_evening': 'مساء الخير',
    'home_welcome': 'مرحباً بك في إيجي زون',

    // ── Product Details ───────────────────────────────────────────────────────
    'product_add_to_cart': 'أضف إلى السلة',
    'product_buy_now': 'اشترِ الآن',
    'product_description': 'الوصف',
    'product_reviews': 'التقييمات',
    'product_specifications': 'المواصفات',
    'product_in_stock': 'متوفر',
    'product_out_of_stock': 'غير متوفر',
    'product_quantity': 'الكمية',
    'product_save': 'حفظ',
    'product_share': 'مشاركة',
    'product_added_to_cart': 'تمت الإضافة إلى السلة!',
    'product_saved': 'تم حفظ المنتج!',
    'product_unsaved': 'تمت إزالة المنتج من المحفوظات.',
    'product_seller': 'البائع',
    'product_free_shipping': 'شحن مجاني',
    'product_rating': 'التقييم',
    'product_no_reviews': 'لا توجد تقييمات بعد',
    'product_write_review': 'اكتب تقييماً',
    'product_related': 'منتجات ذات صلة',
    'product_price': 'السعر',

    // ── Shopping Cart ─────────────────────────────────────────────────────────
    'cart_title': 'سلة التسوق',
    'cart_empty': 'سلتك فارغة',
    'cart_empty_subtitle': 'ابدأ التسوق لإضافة منتجات إلى سلتك',
    'cart_shop_now': 'تسوق الآن',
    'cart_subtotal': 'المجموع الفرعي',
    'cart_shipping': 'الشحن',
    'cart_total': 'الإجمالي',
    'cart_free_shipping': 'مجاني',
    'cart_checkout': 'إتمام الشراء',
    'cart_remove': 'إزالة',
    'cart_coupon': 'تطبيق كوبون',
    'cart_coupon_hint': 'أدخل كود الكوبون',
    'cart_coupon_apply': 'تطبيق',
    'cart_coupon_remove': 'إزالة',
    'cart_coupon_applied': 'تم تطبيق الكوبون!',
    'cart_coupon_invalid': 'كود الكوبون غير صالح',
    'cart_item_removed': 'تمت إزالة المنتج من السلة',
    'cart_continue_shopping': 'مواصلة التسوق',
    'cart_items': 'منتجات',
    'cart_item': 'منتج',
    'cart_discount': 'الخصم',
    'cart_order_summary': 'ملخص الطلب',

    // ── Profile Screen ────────────────────────────────────────────────────────
    'profile_title': 'الحساب الشخصي',
    'profile_edit': 'تعديل الملف الشخصي',
    'profile_orders': 'طلباتي',
    'profile_saved': 'المحفوظات',
    'profile_addresses': 'العناوين',
    'profile_settings': 'الإعدادات',
    'profile_support': 'الدعم',
    'profile_session': 'الجلسة',
    'profile_theme': 'المظهر',
    'profile_language': 'اللغة',
    'profile_notifications': 'الإشعارات',
    'profile_help': 'مركز المساعدة',
    'profile_about': 'من نحن',
    'profile_logout': 'تسجيل الخروج',
    'profile_logout_confirm': 'هل أنت متأكد أنك تريد تسجيل الخروج؟',
    'profile_logout_yes': 'تسجيل الخروج',
    'profile_logout_cancel': 'إلغاء',
    'profile_member_since': 'عضو منذ',
    'profile_select_language': 'اختر اللغة',
    'profile_language_changed_en': 'تم تغيير اللغة إلى الإنجليزية',
    'profile_no_email': 'لم يتم تقديم بريد إلكتروني',
    'profile_edit_coming_soon': 'تعديل الملف الشخصي قريباً!',
    'profile_help_coming_soon': 'مركز المساعدة قريباً!',
    'profile_about_coming_soon': 'من نحن قريباً!',

    // ── Orders ────────────────────────────────────────────────────────────────
    'orders_title': 'طلباتي',
    'orders_empty': 'لا توجد طلبات بعد',
    'orders_empty_subtitle': 'ستظهر طلباتك هنا',
    'orders_status_pending': 'قيد الانتظار',
    'orders_status_processing': 'قيد المعالجة',
    'orders_status_shipped': 'تم الشحن',
    'orders_status_delivered': 'تم التسليم',
    'orders_status_cancelled': 'ملغي',
    'orders_total': 'الإجمالي',
    'orders_date': 'تاريخ الطلب',
    'orders_id': 'طلب رقم ',
    'orders_details': 'عرض التفاصيل',
    'orders_reorder': 'إعادة الطلب',

    // ── Search ────────────────────────────────────────────────────────────────
    'search_title': 'البحث',
    'search_hint': 'ابحث عن منتجات...',
    'search_no_results': 'لم يتم العثور على منتجات',
    'search_try_different': 'جرّب مصطلح بحث مختلف',
    'search_filters': 'الفلاتر',
    'search_sort': 'الترتيب حسب',
    'search_sort_price_low': 'السعر: من الأقل إلى الأعلى',
    'search_sort_price_high': 'السعر: من الأعلى إلى الأقل',
    'search_sort_newest': 'الأحدث أولاً',
    'search_sort_rating': 'الأعلى تقييماً',

    // ── Checkout ──────────────────────────────────────────────────────────────
    'checkout_title': 'إتمام الشراء',
    'checkout_address': 'عنوان التسليم',
    'checkout_payment': 'طريقة الدفع',
    'checkout_order_summary': 'ملخص الطلب',
    'checkout_place_order': 'تأكيد الطلب',
    'checkout_address_hint': 'أدخل عنوان التسليم',
    'checkout_name_hint': 'الاسم الكامل',
    'checkout_phone_hint': 'رقم الهاتف',
    'checkout_city_hint': 'المدينة',
    'checkout_success': 'تم تقديم الطلب بنجاح!',
    'checkout_cash_on_delivery': 'الدفع عند الاستلام',

    // ── Notifications ─────────────────────────────────────────────────────────
    'notifications_title': 'الإشعارات',
    'notifications_empty': 'لا توجد إشعارات بعد',
    'notifications_mark_read': 'تعليم الكل كمقروء',
  };
}

/// Extension for concise access: `context.tr('key')`
extension LocalizationExtension on BuildContext {
  String tr(String key) => AppLocalizations.of(this).tr(key);
}
