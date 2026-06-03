import 'dart:async';
import 'package:egyzone/presentation/product_details_screen/product_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/custom_icon_widget.dart';
import '../../core/models/product_model.dart';
import '../../core/services/product_service.dart';
import './widgets/empty_search_widget.dart';
import './widgets/filter_bottom_sheet_widget.dart';
import './widgets/no_results_widget.dart';
import './widgets/product_grid_widget.dart';
import './widgets/recent_searches_widget.dart';
import './widgets/search_bar_widget.dart';
import './widgets/search_suggestions_widget.dart';

class SearchScreen extends StatefulWidget {
  final String? initialQuery;
  final String? initialCategory;
  final String? initialSortBy;

  const SearchScreen({
    super.key,
    this.initialQuery,
    this.initialCategory,
    this.initialSortBy,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _debounceTimer;

  List<String> _recentSearches = [];
  List<Map<String, dynamic>> _searchSuggestions = [];
  List<Product> _searchResults = [];
  List<Product> _allProducts = [];
  bool _isSearching = false;
  bool _isLoadingProducts = false;
  bool _showSuggestions = false;

  // Filter States
  List<String> _selectedCategories = [];
  RangeValues _priceRange = const RangeValues(0, 20000);
  double _minRating = 0.0;
  String _sortBy = 'Relevance';

  @override
  void initState() {
    super.initState();
    if (widget.initialSortBy != null) {
      _sortBy = widget.initialSortBy!;
    }
    if (widget.initialCategory != null) {
      _selectedCategories = [widget.initialCategory!];
    }
    _loadRecentSearches();
    _fetchProducts();

    // Only focus if we aren't auto-searching
    if (widget.initialCategory == null && widget.initialQuery == null) {
      _searchFocusNode.requestFocus();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchProducts() async {
    setState(() => _isLoadingProducts = true);
    try {
      final products = await ProductService.fetchProducts(
        isApproved: null, // Include both approved and unapproved products
        pageSize: 200, // Fetch more products for search
      );
      setState(() {
        _allProducts = products;
      });

      // If initialized with specific criteria, perform search automatically
      if (widget.initialQuery != null ||
          widget.initialCategory != null ||
          widget.initialSortBy != null) {
        if (widget.initialQuery != null) {
          _searchController.text = widget.initialQuery!;
        }
        _performSearch(_searchController.text);
      }
    } catch (e) {
      // Silently fail — search will just show empty
    } finally {
      if (mounted) setState(() => _isLoadingProducts = false);
    }
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _recentSearches = prefs.getStringList('recent_searches') ?? [];
    });
  }

  Future<void> _saveRecentSearch(String query) async {
    if (query.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    _recentSearches.remove(query);
    _recentSearches.insert(0, query);
    if (_recentSearches.length > 10) {
      _recentSearches = _recentSearches.sublist(0, 10);
    }
    await prefs.setStringList('recent_searches', _recentSearches);
    setState(() {});
  }

  Future<void> _deleteRecentSearch(String query) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _recentSearches.remove(query);
    });
    await prefs.setStringList('recent_searches', _recentSearches);
  }

  void _generateSuggestions(String query) {
    if (query.isEmpty) {
      setState(() {
        _showSuggestions = false;
        _searchSuggestions = [];
      });
      return;
    }

    final tempSuggestions = <Map<String, dynamic>>[];
    final lowerQuery = query.toLowerCase();

    for (var product in _allProducts) {
      final String productCategory = product.normalizedCategory;
      final matchesCategory = _selectedCategories.isEmpty ||
          _selectedCategories.any((sel) => _namesMatch(productCategory, sel));

      if (!matchesCategory) continue;

      final name = product.name;
      final index = name.toLowerCase().indexOf(lowerQuery);

      if (index != -1) {
        tempSuggestions.add({
          'type': 'product',
          'text': name,
          'matchIndex': index,
        });
      }
    }

    tempSuggestions.sort(
        (a, b) => (a['matchIndex'] as int).compareTo(b['matchIndex'] as int));

    setState(() {
      _searchSuggestions = tempSuggestions
          .map((e) => {'type': e['type'], 'text': e['text']})
          .take(8)
          .toList();
      _showSuggestions = _searchSuggestions.isNotEmpty;
    });
  }

  bool _namesMatch(String apiName, String uiName) {
    String norm(String s) => s
        .toLowerCase()
        .trim()
        .replaceAll(',', '')
        .replaceAll(RegExp(r'\s+'), ' ');
    String compact(String s) => norm(s).replaceAll(' ', '');

    final na = norm(apiName);
    final nb = norm(uiName);

    if (na == nb) return true; // exact after normalise
    if (compact(apiName) == compact(uiName)) return true; // compound words

    // Use word boundaries to prevent "Men" matching "Women"
    final nbEscaped = RegExp.escape(nb);
    final naEscaped = RegExp.escape(na);

    final hasWordBInA = RegExp('\\b$nbEscaped\\b').hasMatch(na);
    final hasWordAInB = RegExp('\\b$naEscaped\\b').hasMatch(nb);

    if (hasWordBInA || hasWordAInB) return true;

    // Fallback for partial matches that are NOT "men" vs "women"
    if ((nb == 'men' && na.contains('women')) ||
        (na == 'men' && nb.contains('women'))) {
      return false;
    }

    return na.contains(nb) || nb.contains(na);
  }

  void _performSearch(String query) {
    if (query.trim().isEmpty &&
        _selectedCategories.isEmpty &&
        _sortBy == 'Relevance') return;
    _searchFocusNode.unfocus();
    _saveRecentSearch(query);

    setState(() {
      _isSearching = true;
      _showSuggestions = false;
      _searchController.text = query;
    });

    var results = _allProducts.where((product) {
      final String name = product.normalizedName;
      final String productCategory = product.normalizedCategory;
      final String productSubCategory = product.normalizedSubCategory;

      final normalizedQuery = Product.normalize(query);
      // Matches if name contains query OR category matches query OR subcategory matches query
      final matchesQuery = name.contains(normalizedQuery) ||
          _namesMatch(productCategory, query) ||
          _namesMatch(productSubCategory, query);

      final matchesCategory = _selectedCategories.isEmpty ||
          _selectedCategories.any((sel) => _namesMatch(productCategory, sel));

      final double price = product.price;
      final matchesPrice =
          price >= _priceRange.start && price <= _priceRange.end;

      final matchesRating = product.rating >= _minRating;

      return matchesQuery && matchesCategory && matchesPrice && matchesRating;
    }).toList();

    if (_sortBy == 'Price Low-High') {
      results.sort((a, b) => a.price.compareTo(b.price));
    } else if (_sortBy == 'Price High-Low') {
      results.sort((a, b) => b.price.compareTo(a.price));
    } else if (_sortBy == 'Rating') {
      results.sort((a, b) => b.rating.compareTo(a.rating));
    } else if (_sortBy == 'Newest') {
      results.sort((a, b) => b.productId.compareTo(a.productId));
    } else if (_sortBy == 'Relevance' && query.trim().isNotEmpty) {
      final lowerQuery = query.toLowerCase();
      results.sort((a, b) {
        final aName = a.normalizedName;
        final bName = b.normalizedName;

        int aIndex = aName.indexOf(lowerQuery);
        int bIndex = bName.indexOf(lowerQuery);

        // If matched by category instead of name, push to the end
        if (aIndex == -1) aIndex = 9999;
        if (bIndex == -1) bIndex = 9999;

        if (aIndex != bIndex) {
          return aIndex.compareTo(bIndex);
        }
        return aName.compareTo(bName); // Alphabetical fallback
      });
    }

    setState(() {
      _searchResults = results;
      _isSearching = false;
    });
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterBottomSheetWidget(
        selectedCategories: _selectedCategories,
        priceRange: _priceRange,
        minRating: _minRating,
        sortBy: _sortBy,
        onApply: (categories, range, rating, sort) {
          setState(() {
            _selectedCategories = categories;
            _priceRange = range;
            _minRating = rating;
            _sortBy = sort;
          });
          _performSearch(_searchController.text);
        },
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
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Theme.of(context).colorScheme.surface,
          leading: IconButton(
            icon: Icon(Icons.arrow_back,
                color: Theme.of(context).colorScheme.onSurface),
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/home-screen',
                (route) => false,
              );
            },
          ),
          titleSpacing: 0,
          title: SearchBarWidget(
            controller: _searchController,
            focusNode: _searchFocusNode,
            onChanged: (val) {
              _debounceTimer?.cancel();
              _debounceTimer = Timer(const Duration(milliseconds: 300), () {
                _generateSuggestions(val);
              });
            },
            onSubmitted: _performSearch,
            onClear: () {
              setState(() {
                _showSuggestions = false;
                _selectedCategories = [];
                _priceRange = const RangeValues(0, 20000);
                _minRating = 0.0;
                _sortBy = 'Relevance';
              });
              if (_searchController.text.isNotEmpty) {
                _searchController.clear();
                _performSearch('');
              } else {
                setState(() {
                  _searchResults.clear();
                });
              }
            },
          ),
          actions: [
            IconButton(
              icon: CustomIconWidget(
                  iconName: 'tune',
                  color: Theme.of(context).colorScheme.onSurface,
                  size: 24),
              onPressed: _showFilterBottomSheet,
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoadingProducts) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_showSuggestions && _searchSuggestions.isNotEmpty) {
      return SearchSuggestionsWidget(
        suggestions: _searchSuggestions,
        onSuggestionTap: (suggestion) => _performSearch(suggestion),
      );
    }

    if (_searchController.text.isEmpty && _searchResults.isEmpty) {
      if (_recentSearches.isNotEmpty) {
        return RecentSearchesWidget(
          searches: _recentSearches,
          onSearchSelected: _performSearch,
          onDeleteSearch: _deleteRecentSearch,
          onClearAll: () async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('recent_searches');
            setState(() => _recentSearches.clear());
          },
        );
      }
      return EmptySearchWidget(
          onCategoryTap: (category) => _performSearch(category));
    }

    if (_searchResults.isNotEmpty) {
      return ProductGridWidget(
        products: _searchResults.map((p) => p.toMap()).toList(),
        onProductTap: (product) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(productData: product),
            ),
          );
        },
      );
    }

    return NoResultsWidget(
      searchQuery: _searchController.text,
      onCategoryTap: (category) => _performSearch(category),
    );
  }
}
