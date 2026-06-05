import 'package:egyzone/presentation/home_screen/widgets/category_filter_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../../core/models/product_model.dart';
import '../../core/providers/cart_provider.dart';
import '../../core/providers/category_provider.dart';
import '../../core/providers/notification_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/product_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';
import './widgets/hero_banner_widget.dart';
import './widgets/product_grid_widget.dart';
import '../product_details_screen/product_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();

  // '' = nothing selected (show all); non-empty = active filter.
  String _selectedCategory = '';
  String _selectedSubcategory = '';
  String _selectedBrand = '';

  /// All products fetched from the API (unfiltered master list).
  List<Product> _allProducts = [];

  /// Products shown to the user after applying filters.
  List<Product> _displayedProducts = [];

  bool _isLoadingProducts = false;

  /// Unique, sorted brand names relevant to the current subcategory selection
  /// Derived from CategoryProvider which has brands organized by subcategory
  List<String> get _availableBrands {
    if (_selectedSubcategory.isEmpty) return [];
    final categoryProvider = context.read<CategoryProvider>();
    final categoryObj = categoryProvider.findCategory(_selectedCategory);
    final subObj = categoryProvider.findSubCategory(categoryObj, _selectedSubcategory);
    if (subObj == null) return [];
    return categoryProvider.brandNames(subObj)..sort();
  }

  // ──────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Load API categories (for ID mapping) and all products in parallel
      await Future.wait([
        context.read<CategoryProvider>().fetchCategories(),
        _fetchAllProducts(),
      ]);
    });
  }

  Future<void> _fetchBrands() async {
    // No longer needed - brands are now fetched from CategoryProvider
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {}

  // ── API fetch ──────────────────────────────────────────────────────────────

  Future<void> _fetchAllProducts() async {
    if (!mounted) return;
    setState(() => _isLoadingProducts = true);
    try {
      // fetchAllProducts paginates through every page so no product is missed
      final products = await ProductService.fetchAllProducts(isApproved: true);
      if (mounted) {
        // Sort by productId descending so latest products are at the top
        _allProducts = products..sort((a, b) => b.productId.compareTo(a.productId));
        
        // Sync the CategoryProvider with the actual products found in the list
        context.read<CategoryProvider>().updateFromProducts(products);
        
        _applyFilter();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading products: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingProducts = false);
    }
  }

  Future<void> _refreshProducts() => _fetchAllProducts();

  // ── Filter ─────────────────────────────────────────────────────────────────

  /// Filters [_allProducts] by selected category / subcategory / brand.
  void _applyFilter() {
    if (!mounted) return;

    _displayedProducts = _allProducts.where((p) {
      // 1. Category check (client-side since API doesn't support categoryId)
      if (_selectedCategory.isNotEmpty) {
        if (!_namesMatch(p.normalizedCategory, _selectedCategory)) return false;
      }

      // 2. Subcategory check (client-side for consistency)
      if (_selectedSubcategory.isNotEmpty) {
        if (!_namesMatch(p.normalizedSubCategory, _selectedSubcategory)) return false;
      }

      // 3. Brand check (client-side for consistency)
      if (_selectedBrand.isNotEmpty) {
        if (!_namesMatch(p.normalizedBrand, _selectedBrand)) return false;
      }
      return true;
    }).toList();

    setState(() {});
  }

  bool _namesMatch(String normalizedApiName, String uiName) {
    final na = normalizedApiName;
    final nb = Product.normalize(uiName);

    if (na == nb) return true;
    if (Product.compact(na) == Product.compact(nb)) return true;

    final nbEscaped = RegExp.escape(nb);
    final naEscaped = RegExp.escape(na);

    final hasWordBInA = RegExp('\\b$nbEscaped\\b').hasMatch(na);
    final hasWordAInB = RegExp('\\b$naEscaped\\b').hasMatch(nb);

    if (hasWordBInA || hasWordAInB) return true;

    if ((nb == 'men' && na.contains('women')) ||
        (na == 'men' && nb.contains('women'))) {
      return false;
    }

    return na.contains(nb) || nb.contains(na);
  }

  // ── Event handlers ─────────────────────────────────────────────────────────

  /// '' = deselect (tap again to unselect).
  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;   // '' when deselected
      _selectedSubcategory = '';      // reset downstream
      _selectedBrand = '';
    });
    _applyFilter();
  }

  void _onSubcategorySelected(String sub) {
    final categoryProvider = context.read<CategoryProvider>();
    final categoryObj = categoryProvider.findCategory(_selectedCategory);
    final subObj = categoryProvider.findSubCategory(categoryObj, sub);
    
    setState(() {
      _selectedSubcategory = sub;     // '' when deselected
      _selectedBrand = '';
    });
    _applyFilter();
  }

  void _onBrandSelected(String brand) {
    setState(() {
      _selectedBrand = brand; // '' when deselected
    });
    _applyFilter();
  }

  void _onAddToCart(Product product) {
    context.read<CartProvider>().addItem(product.toMap());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} added to cart'),
        action: SnackBarAction(
          label: 'VIEW CART',
          onPressed: () =>
              Navigator.pushNamed(context, '/shopping-cart-screen'),
        ),
      ),
    );
  }

  void _onProductTap(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(productData: product.toMap()),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cartCount = context.select<CartProvider, int>((p) => p.totalItems);
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: CustomAppBar(
          title: 'EGYZONE',
          style: CustomAppBarStyle.standard,
          showBackButton: false,
          showSearchButton: true,
          showCartButton: true,
          showChatBotButton: true,
          cartItemCount: cartCount,
          onSearchTap: () => Navigator.pushNamed(context, '/search-screen'),
          onCartTap: () =>
              Navigator.pushNamed(context, '/shopping-cart-screen'),
          onChatBotTap: () =>
              Navigator.pushNamed(context, '/chat-bot-screen'),
          actions: [
            Consumer<NotificationProvider>(
              builder: (context, provider, _) {
                final count = provider.unreadCount;
                return SizedBox(
                  width: 40,
                  height: 40,
                  child: IconButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/notifications-screen'),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                    icon: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(Icons.notifications_none_outlined, size: 24),
                        if (count > 0)
                          Positioned(
                            right: -2,
                            top: -2,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                count > 9 ? '9+' : count.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _refreshProducts,
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              // ── Hero banner ────────────────────────────────────────────
              const SliverToBoxAdapter(child: HeroBannerWidget()),

              // ── Category filter ─────────────────────────────────────────
              Consumer<CategoryProvider>(
                builder: (context, provider, _) {
                  // Exclude empty strings; provider.categoryNames has no 'All'
                  final categories = provider.categoryNames
                      .where((c) => c.isNotEmpty)
                      .toList();
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 0.4.h),
                      child: CategoryFilterWidget(
                        categories: categories,
                        selectedCategory: _selectedCategory,
                        onCategorySelected: _onCategorySelected,
                      ),
                    ),
                  );
                },
              ),

              // ── Subcategory filter — shown when category selected ────────
              if (_selectedCategory.isNotEmpty)
                Consumer<CategoryProvider>(
                  builder: (context, provider, _) {
                    final catObj = provider.findCategory(_selectedCategory);
                    final subcategories = provider
                        .subcategoryNames(catObj)
                        .where((s) => s.isNotEmpty && s != 'All')
                        .toList();
                    if (subcategories.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 0.4.h),
                        child: CategoryFilterWidget(
                          categories: subcategories,
                          selectedCategory: _selectedSubcategory,
                          onCategorySelected: _onSubcategorySelected,
                        ),
                      ),
                    );
                  },
                ),

              // ── Brand filter — only when subcategory selected & brands exist
              if (_selectedSubcategory.isNotEmpty && _availableBrands.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 0.4.h),
                    child: CategoryFilterWidget(
                      categories: _availableBrands,
                      selectedCategory: _selectedBrand,
                      onCategorySelected: _onBrandSelected,
                    ),
                  ),
                ),

              // ── Products area ──────────────────────────────────────────
              if (_isLoadingProducts)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_displayedProducts.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_bag_outlined,
                          size: 64,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                        ),
                        SizedBox(height: 1.h),
                        Text(
                          'No products found',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color:
                                theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ProductGridWidget(
                  products: _displayedProducts.map((p) => p.toMap()).toList(),
                  onProductTap: (product) => _onProductTap(Product.fromJson(product)),
                  onAddToCart: (product) => _onAddToCart(Product.fromJson(product)),
                ),
            ],
          ),
        ),
        bottomNavigationBar: CustomBottomBar(
          currentRoute: '/home-screen',
          cartItemCount: cartCount,
          role: context.select<AuthProvider, String>((p) => p.displayRole),
        ),
      ),
    );
  }
}
