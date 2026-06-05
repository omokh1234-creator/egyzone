import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/models/product_model.dart';
import '../../core/providers/category_provider.dart';
import '../../core/services/product_service.dart';
import './widgets/empty_search_widget.dart';
import './widgets/filter_bottom_sheet_widget.dart';
import './widgets/no_results_widget.dart';
import './widgets/product_grid_widget.dart';
import './widgets/recent_searches_widget.dart';
import './widgets/search_bar_widget.dart';
import './widgets/search_suggestions_widget.dart';

class SearchScreen extends StatefulWidget {
  final String? initialCategory;
  final String? initialSortBy;

  const SearchScreen({
    super.key,
    this.initialCategory,
    this.initialSortBy,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with WidgetsBindingObserver {
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
    WidgetsBinding.instance.addObserver(this);
    _loadRecentSearches();
    _fetchProducts().then((_) {
      if (widget.initialCategory != null) {
        _selectedCategories = [widget.initialCategory!];
        _performSearch('');
      } else if (widget.initialSortBy != null) {
        _sortBy = widget.initialSortBy!;
        _performSearch('');
      }
    });
    _searchFocusNode.requestFocus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _fetchProducts();
    }
  }

  Future<void> _fetchProducts() async {
    setState(() => _isLoadingProducts = true);
    try {
      // fetchAllProducts paginates through every page so no product is missed
      final products = await ProductService.fetchAllProducts(isApproved: true);
      if (mounted) {
        setState(() {
          _allProducts = products;
        });
        context.read<CategoryProvider>().updateFromProducts(products);
      }
    } catch (e) {
      debugPrint('Error fetching products: $e');
    } finally {
      if (mounted) setState(() => _isLoadingProducts = false);
    }
  }

  Future<void> _performApiSearch(String query) async {
    setState(() => _isSearching = true);
    try {
      // Paginate through all search result pages
      final all = <Product>[];
      int page = 1;
      const batchSize = 100;
      while (true) {
        final batch = await ProductService.fetchProducts(
          search: query.isEmpty ? null : query,
          minPrice: _priceRange.start > 0 ? _priceRange.start : null,
          maxPrice: _priceRange.end < 20000 ? _priceRange.end : null,
          isApproved: true,
          page: page,
          pageSize: batchSize,
        );
        all.addAll(batch);
        if (batch.length < batchSize) break; // last page
        page++;
      }
      if (mounted) {
        setState(() {
          _searchResults = all;
          _isSearching = false;
        });
      }
    } catch (e) {
      debugPrint('Error searching products: $e');
      if (mounted) {
        setState(() => _isSearching = false);
      }
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

  void _generateSuggestions(String query) {
    if (query.isEmpty) {
      setState(() {
        _showSuggestions = false;
        _searchSuggestions = [];
      });
      return;
    }

    // Capture provider reference before async gap to avoid context-across-async-gap lint
    final categoryProvider = context.read<CategoryProvider>();

    // Use API to get search results for suggestions
    _performApiSearch(query).then((_) {
      if (!mounted) return;
      final tempSuggestions = <Map<String, dynamic>>[];

      // Categories to exclude from suggestions
      const excludedCategories = {
        'furniture',
        'home & furniture',
        'home and furniture',
      };

      // Add category suggestions with subcategories (excluding furniture)
      final lowerQuery = query.toLowerCase();
      for (final category in categoryProvider.categories) {
        final catLower = category.name.toLowerCase().trim();
        // Skip furniture-related categories
        if (excludedCategories.any((ex) => catLower.contains('furnitur'))) continue;
        if (category.name.toLowerCase().contains(lowerQuery)) {
          final subCategories = category.subCategories.map((s) => s.name).toList();
          tempSuggestions.add({
            'type': 'category',
            'text': category.name,
            'subCategories': subCategories,
          });
        }
      }

      // Add product suggestions from API results
      for (var product in _searchResults) {
        tempSuggestions.add({
          'type': 'product',
          'text': product.name,
          'imageUrl': product.imageUrl,
          'price': product.price,
        });
      }

      setState(() {
        _searchSuggestions = tempSuggestions.take(10).toList();
        _showSuggestions = _searchSuggestions.isNotEmpty;
      });
    });
  }

  void _performSearch(String query) {
    _searchFocusNode.unfocus();
    _saveRecentSearch(query);

    setState(() {
      _isSearching = true;
      _showSuggestions = false;
      _searchController.text = query;
    });

    // If query is empty and category is selected, use client-side filtering from all products
    if (query.isEmpty && _selectedCategories.isNotEmpty) {
      var results = _allProducts.where((product) {
        return _selectedCategories.any((sel) => _namesMatch(product.normalizedCategory, sel));
      }).toList();

      // Filter by rating
      if (_minRating > 0) {
        results = results.where((product) => product.rating >= _minRating).toList();
      }

      // Sort results
      if (_sortBy == 'Price Low-High') {
        results.sort((a, b) => a.price.compareTo(b.price));
      } else if (_sortBy == 'Price High-Low') {
        results.sort((a, b) => b.price.compareTo(a.price));
      } else if (_sortBy == 'Rating') {
        results.sort((a, b) => b.rating.compareTo(a.rating));
      } else if (_sortBy == 'Newest') {
        results.sort((a, b) => b.productId.compareTo(a.productId));
      }

      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } else {
      // Use API-based search for text queries
      _performApiSearch(query).then((_) {
        // Apply client-side filters for category and rating (API doesn't support these)
        var results = _searchResults;
        
        // Filter by category
        if (_selectedCategories.isNotEmpty) {
          results = results.where((product) {
            return _selectedCategories.any((sel) => _namesMatch(product.normalizedCategory, sel));
          }).toList();
        }

        // Filter by rating
        if (_minRating > 0) {
          results = results.where((product) => product.rating >= _minRating).toList();
        }

        // Sort results
        if (_sortBy == 'Price Low-High') {
          results.sort((a, b) => a.price.compareTo(b.price));
        } else if (_sortBy == 'Price High-Low') {
          results.sort((a, b) => b.price.compareTo(a.price));
        } else if (_sortBy == 'Rating') {
          results.sort((a, b) => b.rating.compareTo(a.rating));
        } else if (_sortBy == 'Newest') {
          results.sort((a, b) => b.productId.compareTo(a.productId));
        }

        setState(() {
          _searchResults = results;
        });
      });
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
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
              _searchResults.clear();
            });
            _searchController.clear();
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh,
                color: Theme.of(context).colorScheme.onSurface),
            onPressed: _fetchProducts,
          ),
          IconButton(
            icon: Icon(Icons.filter_list,
                color: Theme.of(context).colorScheme.onSurface),
            onPressed: _showFilterBottomSheet,
          ),
        ],
      ),
      body: _buildBody(),
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
        onSuggestionTap: (suggestion, type) {
          setState(() {
            _showSuggestions = false;
            _searchController.text = suggestion;
          });
          if (type == 'category') {
            setState(() {
              _selectedCategories = [suggestion];
            });
            _performSearch('');
          } else {
            _performSearch(suggestion);
          }
        },
      );
    }

    if (_searchController.text.isEmpty && _searchResults.isEmpty) {
      if (_recentSearches.isNotEmpty) {
        return RecentSearchesWidget(
          searches: _recentSearches,
          onSearchSelected: _performSearch,
          onDeleteSearch: (query) async {
            final prefs = await SharedPreferences.getInstance();
            setState(() {
              _recentSearches.remove(query);
            });
            await prefs.setStringList('recent_searches', _recentSearches);
          },
          onClearAll: () async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('recent_searches');
            setState(() => _recentSearches.clear());
          },
        );
      }
      return EmptySearchWidget(
        onCategoryTap: (category) {
          setState(() {
            _selectedCategories = [category];
          });
          _performSearch('');
        },
      );
    }

    if (_searchResults.isNotEmpty) {
      return ProductGridWidget(
        products: _searchResults.map((p) => p.toMap()).toList(),
        onProductTap: (product) {
          Navigator.pushNamed(
            context,
            '/product-detail-screen',
            arguments: product,
          );
        },
      );
    }

    return NoResultsWidget(
      searchQuery: _searchController.text,
      onCategoryTap: (category) {
        setState(() {
          _selectedCategories = [category];
        });
        _performSearch('');
      },
    );
  }
}
