import 'package:flutter/foundation.dart';

import '../models/category_model.dart';
import '../models/product_model.dart';
import '../services/product_service.dart';

class CategoryProvider extends ChangeNotifier {
  List<ProductCategory> _categories = [];
  bool _isLoading = false;
  String? _error;

  List<ProductCategory> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<String> get categoryNames =>
      _categories.map((c) => c.name).where((n) => n.isNotEmpty).toList();

  List<String> subcategoryNames(ProductCategory? category) {
    if (category == null) return [];
    return category.subCategories
        .map((s) => s.name)
        .where((n) => n.isNotEmpty)
        .toList();
  }

  ProductCategory? findCategory(String name) {
    try {
      return _categories.firstWhere((c) => c.name == name);
    } catch (_) {
      return null;
    }
  }

  ProductSubCategory? findSubCategory(ProductCategory? category, String name) {
    if (category == null) return null;
    try {
      return category.subCategories.firstWhere((s) => s.name.toLowerCase().trim() == name.toLowerCase().trim());
    } catch (_) {
      return null;
    }
  }

  List<String> brandNames(ProductSubCategory? subCategory) {
    if (subCategory == null) return [];
    return subCategory.brands
        .map((b) => b.name)
        .where((n) => n.isNotEmpty)
        .toList();
  }


  Future<void> fetchCategories() async {
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Uses ProductService which correctly calls /api/Categories
      // and returns the full nested hierarchy in one call
      _categories = await ProductService.fetchCategories();

      // Populate all brands for all subcategories (workaround since API doesn't include brandId in products)
      _populateAllBrandsForSubcategories();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error fetching categories/brands: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _populateBrands(List<Map<String, dynamic>> brandsData) {
    // Create a map of brandId -> brand name
    final Map<int, String> brandMap = {};
    for (final brand in brandsData) {
      final brandId = brand['brandId'] as int?;
      final name = brand['name'] as String?;
      if (brandId != null && name != null && name.isNotEmpty) {
        brandMap[brandId] = name;
      }
    }

    // Store brand map for later use in updateFromProducts
    _brandMap = brandMap;
  }

  Map<int, String> _brandMap = {};

  void _populateAllBrandsForSubcategories() {
    // Populate brands for subcategories based on product details (workaround since API doesn't include brandId in products)
    // Fetch product details for each product to get brand information
    _populateBrandsFromProductDetails();
  }

  Future<void> _populateBrandsFromProductDetails() async {
    try {
      // Fetch all products to get their IDs
      final products = await ProductService.fetchProducts();
      debugPrint('Fetched ${products.length} products to extract brand information');

      // Create a map of subcategoryId -> set of brandIds
      final Map<int, Set<int>> subcategoryBrandIds = {};

      // Fetch product details for each product (N+1 API calls - inefficient but necessary workaround)
      for (final product in products) {
        try {
          final productDetail = await ProductService.fetchProductDetail(product.productId);
          if (productDetail != null) {
            final brandId = productDetail.brandId;
            final subCategoryId = productDetail.subCategoryId;
            if (brandId != null && subCategoryId != null && _brandMap.containsKey(brandId)) {
              if (!subcategoryBrandIds.containsKey(subCategoryId)) {
                subcategoryBrandIds[subCategoryId] = {};
              }
              subcategoryBrandIds[subCategoryId]!.add(brandId);
            }
          }
        } catch (e) {
          // Skip products that fail to fetch details
          debugPrint('Error fetching product detail for ${product.productId}: $e');
        }
      }

      debugPrint('Mapped brands to ${subcategoryBrandIds.length} subcategories from product details');

      // Populate brands for each subcategory based on the mapping
      for (final category in _categories) {
        for (final subcategory in category.subCategories) {
          final brandIds = subcategoryBrandIds[subcategory.subCategoryId] ?? {};
          final brands = brandIds.map((brandId) => ProductBrand(
            brandId: brandId,
            name: _brandMap[brandId]!,
            subCategoryId: subcategory.subCategoryId,
          )).toList();

          debugPrint('Subcategory ${subcategory.name}: ${brands.length} brands from product details');

          // Update subcategory with brands
          final updatedSubcategory = ProductSubCategory(
            subCategoryId: subcategory.subCategoryId,
            name: subcategory.name,
            categoryId: subcategory.categoryId,
            brands: brands,
          );

          // Update category with updated subcategory
          final updatedSubcategories = category.subCategories.map((sub) {
            if (sub.subCategoryId == subcategory.subCategoryId) {
              return updatedSubcategory;
            }
            return sub;
          }).toList();

          final updatedCategory = ProductCategory(
            categoryId: category.categoryId,
            name: category.name,
            subCategories: updatedSubcategories,
          );

          // Update categories list
          final index = _categories.indexWhere((c) => c.categoryId == category.categoryId);
          if (index != -1) {
            _categories[index] = updatedCategory;
          }
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error populating brands from product details: $e');
    }
  }

  /// Merges product-derived category/subcategory/brand data into existing categories.
  /// Filters out categories/subcategories/brands that have no products.
  void updateFromProducts(List<Product> products) {
    // If no products, clear all categories (show nothing)
    if (products.isEmpty) {
      _categories = [];
      notifyListeners();
      return;
    }

    // Use a map for easy lookup by name (seed with existing API categories)
    final Map<String, ProductCategory> categoryMap = {
      for (var c in _categories) c.name.toLowerCase().trim(): c
    };

    // Track which categories/subcategories/brands have products
    final Set<String> categoriesWithProducts = {};
    final Map<String, Set<String>> subcategoriesWithProducts = {};
    final Map<String, Map<String, Set<String>>> brandsWithProducts = {};

    for (final product in products) {
      final catName = product.categoryName?.trim() ?? 'General';
      final subName = product.subCategoryName?.trim() ?? 'General';
      final catKey = catName.toLowerCase();

      // Track category has products
      categoriesWithProducts.add(catKey);

      // 1. Ensure Category exists
      if (!categoryMap.containsKey(catKey)) {
        categoryMap[catKey] = ProductCategory(
          categoryId: 0, // Temporary ID
          name: catName,
          subCategories: [],
        );
      }
      final category = categoryMap[catKey]!;

      // Track subcategory has products
      if (!subcategoriesWithProducts.containsKey(catKey)) {
        subcategoriesWithProducts[catKey] = {};
      }
      final subKey = subName.toLowerCase();
      subcategoriesWithProducts[catKey]!.add(subKey);

      // 2. Ensure SubCategory exists in this Category
      ProductSubCategory? subCategory;
      try {
        subCategory = category.subCategories.firstWhere(
          (s) => s.name.toLowerCase().trim() == subName.toLowerCase(),
        );
      } catch (_) {
        subCategory = ProductSubCategory(
          subCategoryId: product.subCategoryId ?? 0,
          name: subName,
          categoryId: category.categoryId,
          brands: [],
        );
        // Create new category with updated subcategories list
        categoryMap[catKey] = ProductCategory(
          categoryId: category.categoryId,
          name: category.name,
          subCategories: [...category.subCategories, subCategory],
        );
      }

      // 3. Ensure Brand exists in this SubCategory
      final brandId = product.brandId;
      String? brandName = product.brandName?.trim();

      // Try to get brand name from brand map if brandId is available
      if (brandId != null && _brandMap.containsKey(brandId)) {
        brandName = _brandMap[brandId];
      }

      if (brandName != null && brandName.isNotEmpty) {
        // Track brand has products
        if (!brandsWithProducts.containsKey(catKey)) {
          brandsWithProducts[catKey] = {};
        }
        if (!brandsWithProducts[catKey]!.containsKey(subKey)) {
          brandsWithProducts[catKey]![subKey] = {};
        }
        final brandKey = brandName.toLowerCase();
        brandsWithProducts[catKey]![subKey]!.add(brandKey);

        final hasBrand = subCategory.brands.any(
          (b) => b.name.toLowerCase().trim() == brandName?.toLowerCase(),
        );
        if (!hasBrand) {
          // Get updated category
          final updatedCat = categoryMap[catKey]!;
          // Find the subcategory and create new one with updated brands
          final updatedSubCategories = updatedCat.subCategories.map((sub) {
            if (sub.name.toLowerCase().trim() == subName.toLowerCase()) {
              return ProductSubCategory(
                subCategoryId: sub.subCategoryId,
                name: sub.name,
                categoryId: sub.categoryId,
                brands: [...sub.brands, ProductBrand(
                  brandId: brandId ?? 0,
                  name: brandName!,
                  subCategoryId: sub.subCategoryId,
                )],
              );
            }
            return sub;
          }).toList();

          categoryMap[catKey] = ProductCategory(
            categoryId: updatedCat.categoryId,
            name: updatedCat.name,
            subCategories: updatedSubCategories,
          );
        }
      }
    }

    // Filter categories: only keep those with products
    final filteredCategories = categoryMap.values.map((cat) {
      final catKey = cat.name.toLowerCase().trim();
      if (!categoriesWithProducts.contains(catKey)) return null;

      // Filter subcategories: only keep those with products
      final filteredSubCategories = cat.subCategories.map((sub) {
        final subKey = sub.name.toLowerCase().trim();
        if (!subcategoriesWithProducts[catKey]!.contains(subKey)) return null;

        // Don't filter brands - show all brands for the subcategory
        // Return new subcategory with all brands
        return ProductSubCategory(
          subCategoryId: sub.subCategoryId,
          name: sub.name,
          categoryId: sub.categoryId,
          brands: sub.brands,
        );
      }).whereType<ProductSubCategory>().toList();

      // Also remove categories that end up with no subcategories after filtering
      if (filteredSubCategories.isEmpty) return null;

      // Return new category with filtered subcategories
      return ProductCategory(
        categoryId: cat.categoryId,
        name: cat.name,
        subCategories: filteredSubCategories,
      );
    }).whereType<ProductCategory>().toList();

    _categories = filteredCategories
      ..sort((a, b) => a.name.compareTo(b.name));

    notifyListeners();
  }
}

