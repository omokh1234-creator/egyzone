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
      return category.subCategories.firstWhere((s) => s.name == name);
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
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
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
      final brandName = product.brandName?.trim();

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
          (b) => b.name.toLowerCase().trim() == brandName.toLowerCase(),
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
                  brandId: product.brandId ?? 0,
                  name: brandName,
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

        // Filter brands: only keep those with products
        List<ProductBrand> filteredBrands = [];
        if (brandsWithProducts.containsKey(catKey) &&
            brandsWithProducts[catKey]!.containsKey(subKey)) {
          filteredBrands = sub.brands.where((brand) {
            final brandKey = brand.name.toLowerCase().trim();
            return brandsWithProducts[catKey]![subKey]!.contains(brandKey);
          }).toList();
        }

        // Return new subcategory with filtered brands
        return ProductSubCategory(
          subCategoryId: sub.subCategoryId,
          name: sub.name,
          categoryId: sub.categoryId,
          brands: filteredBrands,
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

